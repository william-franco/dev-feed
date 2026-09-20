using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Scalar.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

var jwtSection = builder.Configuration.GetSection("Jwt");
var jwtKey = jwtSection["Key"] ?? throw new InvalidOperationException("Jwt:Key is required.");
var jwtIssuer = jwtSection["Issuer"] ?? "dev-feed";
var jwtAudience = jwtSection["Audience"] ?? "dev-feed";
var jwtExpiresMinutes = int.Parse(jwtSection["ExpiresInMinutes"] ?? "60");
var refreshExpiresDays = int.Parse(jwtSection["RefreshExpiresInDays"] ?? "7");

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite(builder.Configuration.GetConnectionString("Default")));

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtIssuer,
            ValidAudience = jwtAudience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
            ClockSkew = TimeSpan.Zero
        };
    });

builder.Services.AddAuthorization();

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});

builder.Services.AddOpenApi();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.Migrate();
}

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
}

app.UseCors();
app.UseAuthentication();
app.UseAuthorization();

// --- Auth ---

app.MapPost("/auth/register", async (RegisterRequest request, AppDbContext db) =>
{
    if (string.IsNullOrWhiteSpace(request.Name) ||
        string.IsNullOrWhiteSpace(request.Email) ||
        string.IsNullOrWhiteSpace(request.Password))
    {
        return Results.BadRequest(new { message = "Name, email and password are required." });
    }

    var email = request.Email.Trim().ToLowerInvariant();
    if (await db.Users.AnyAsync(u => u.Email == email))
    {
        return Results.Conflict(new { message = "Email already registered." });
    }

    var user = new User
    {
        Name = request.Name.Trim(),
        Email = email,
        Password = BCrypt.Net.BCrypt.HashPassword(request.Password),
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow
    };

    db.Users.Add(user);
    await db.SaveChangesAsync();

    var tokens = await CreateTokenPairAsync(db, user, jwtKey, jwtIssuer, jwtAudience, jwtExpiresMinutes, refreshExpiresDays);
    return Results.Ok(new AuthResponse(tokens.AccessToken, tokens.RefreshToken, UserDto.FromEntity(user)));
})
.WithTags("Auth")
.WithName("Register");

app.MapPost("/auth/login", async (LoginRequest request, AppDbContext db) =>
{
    if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
    {
        return Results.BadRequest(new { message = "Email and password are required." });
    }

    var email = request.Email.Trim().ToLowerInvariant();
    var user = await db.Users.FirstOrDefaultAsync(u => u.Email == email);
    if (user is null || !BCrypt.Net.BCrypt.Verify(request.Password, user.Password))
    {
        return Results.Unauthorized();
    }

    var tokens = await CreateTokenPairAsync(db, user, jwtKey, jwtIssuer, jwtAudience, jwtExpiresMinutes, refreshExpiresDays);
    return Results.Ok(new AuthResponse(tokens.AccessToken, tokens.RefreshToken, UserDto.FromEntity(user)));
})
.WithTags("Auth")
.WithName("Login");

app.MapPost("/auth/refresh", async (RefreshRequest request, AppDbContext db) =>
{
    if (string.IsNullOrWhiteSpace(request.RefreshToken))
    {
        return Results.BadRequest(new { message = "Refresh token is required." });
    }

    var stored = await db.RefreshTokens
        .Include(r => r.User)
        .FirstOrDefaultAsync(r => r.Token == request.RefreshToken && r.RevokedAt == null);

    if (stored is null || stored.ExpiresAt <= DateTime.UtcNow)
    {
        return Results.Unauthorized();
    }

    stored.RevokedAt = DateTime.UtcNow;
    var tokens = await CreateTokenPairAsync(db, stored.User!, jwtKey, jwtIssuer, jwtAudience, jwtExpiresMinutes, refreshExpiresDays);
    await db.SaveChangesAsync();

    return Results.Ok(new TokenResponse(tokens.AccessToken, tokens.RefreshToken));
})
.WithTags("Auth")
.WithName("Refresh");

app.MapPost("/auth/logout", async (RefreshRequest request, AppDbContext db) =>
{
    if (string.IsNullOrWhiteSpace(request.RefreshToken))
    {
        return Results.BadRequest(new { message = "Refresh token is required." });
    }

    var stored = await db.RefreshTokens.FirstOrDefaultAsync(r => r.Token == request.RefreshToken && r.RevokedAt == null);
    if (stored is not null)
    {
        stored.RevokedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();
    }

    return Results.NoContent();
})
.WithTags("Auth")
.WithName("Logout");

app.MapGet("/auth/me", async (ClaimsPrincipal user, AppDbContext db) =>
{
    var userId = GetUserId(user);
    if (userId is null) return Results.Unauthorized();

    var entity = await db.Users.FindAsync(userId.Value);
    if (entity is null) return Results.NotFound();

    return Results.Ok(UserDto.FromEntity(entity));
})
.RequireAuthorization()
.WithTags("Auth")
.WithName("GetProfile");

// --- Posts (public read) ---

app.MapGet("/posts", async (AppDbContext db) =>
{
    var posts = await db.Posts
        .Include(p => p.Author)
        .OrderByDescending(p => p.CreatedAt)
        .ToListAsync();

    return Results.Ok(posts.Select(PostDto.FromEntity));
})
.WithTags("Posts")
.WithName("ListPosts");

app.MapGet("/posts/{id:int}", async (int id, AppDbContext db) =>
{
    var post = await db.Posts.Include(p => p.Author).FirstOrDefaultAsync(p => p.Id == id);
    return post is null ? Results.NotFound() : Results.Ok(PostDto.FromEntity(post));
})
.WithTags("Posts")
.WithName("GetPost");

// --- Posts (protected write) ---

app.MapPost("/posts", async (PostRequest request, ClaimsPrincipal user, AppDbContext db) =>
{
    var userId = GetUserId(user);
    if (userId is null) return Results.Unauthorized();

    if (string.IsNullOrWhiteSpace(request.Title))
    {
        return Results.BadRequest(new { message = "Title is required." });
    }

    var post = new Post
    {
        Title = request.Title.Trim(),
        Content = request.Content?.Trim() ?? string.Empty,
        Latitude = request.Latitude,
        Longitude = request.Longitude,
        AuthorId = userId.Value,
        CreatedAt = DateTime.UtcNow
    };

    db.Posts.Add(post);
    await db.SaveChangesAsync();
    await db.Entry(post).Reference(p => p.Author).LoadAsync();

    return Results.Created($"/posts/{post.Id}", PostDto.FromEntity(post));
})
.RequireAuthorization()
.WithTags("Posts")
.WithName("CreatePost");

app.MapPut("/posts/{id:int}", async (int id, PostUpdateRequest request, ClaimsPrincipal user, AppDbContext db) =>
{
    var userId = GetUserId(user);
    if (userId is null) return Results.Unauthorized();

    var post = await db.Posts.FindAsync(id);
    if (post is null) return Results.NotFound();
    if (post.AuthorId != userId.Value) return Results.Forbid();

    if (!string.IsNullOrWhiteSpace(request.Title)) post.Title = request.Title.Trim();
    if (request.Content is not null) post.Content = request.Content.Trim();
    if (request.Latitude.HasValue) post.Latitude = request.Latitude.Value;
    if (request.Longitude.HasValue) post.Longitude = request.Longitude.Value;
    post.UpdatedAt = DateTime.UtcNow;

    await db.SaveChangesAsync();
    await db.Entry(post).Reference(p => p.Author).LoadAsync();

    return Results.Ok(PostDto.FromEntity(post));
})
.RequireAuthorization()
.WithTags("Posts")
.WithName("UpdatePost");

app.MapDelete("/posts/{id:int}", async (int id, ClaimsPrincipal user, AppDbContext db) =>
{
    var userId = GetUserId(user);
    if (userId is null) return Results.Unauthorized();

    var post = await db.Posts.FindAsync(id);
    if (post is null) return Results.NotFound();
    if (post.AuthorId != userId.Value) return Results.Forbid();

    var postTitle = post.Title;
    db.Posts.Remove(post);
    await db.SaveChangesAsync();

    return Results.Ok(new DeletePostResponse(
        "Post excluido",
        $"O post {postTitle} foi removido permanentemente"));
})
.RequireAuthorization()
.WithTags("Posts")
.WithName("DeletePost");

app.Run();

// --- Helpers ---

static int? GetUserId(ClaimsPrincipal user)
{
    var claim = user.FindFirstValue(ClaimTypes.NameIdentifier) ?? user.FindFirstValue(JwtRegisteredClaimNames.Sub);
    return int.TryParse(claim, out var id) ? id : null;
}

static async Task<(string AccessToken, string RefreshToken)> CreateTokenPairAsync(
    AppDbContext db,
    User user,
    string jwtKey,
    string issuer,
    string audience,
    int expiresMinutes,
    int refreshExpiresDays)
{
    var accessToken = GenerateAccessToken(user, jwtKey, issuer, audience, expiresMinutes);
    var refreshToken = GenerateRefreshToken();

    db.RefreshTokens.Add(new RefreshToken
    {
        UserId = user.Id,
        Token = refreshToken,
        ExpiresAt = DateTime.UtcNow.AddDays(refreshExpiresDays),
        RevokedAt = null
    });

    await db.SaveChangesAsync();
    return (accessToken, refreshToken);
}

static string GenerateAccessToken(User user, string jwtKey, string issuer, string audience, int expiresMinutes)
{
    var claims = new[]
    {
        new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
        new Claim(JwtRegisteredClaimNames.Email, user.Email),
        new Claim(ClaimTypes.Name, user.Name),
        new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
    };

    var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
    var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
    var token = new JwtSecurityToken(
        issuer: issuer,
        audience: audience,
        claims: claims,
        expires: DateTime.UtcNow.AddMinutes(expiresMinutes),
        signingCredentials: credentials);

    return new JwtSecurityTokenHandler().WriteToken(token);
}

static string GenerateRefreshToken()
{
    var bytes = new byte[64];
    RandomNumberGenerator.Fill(bytes);
    return Convert.ToBase64String(bytes);
}

// --- Entities ---

class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Post> Posts => Set<Post>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>(e =>
        {
            e.HasIndex(u => u.Email).IsUnique();
        });

        modelBuilder.Entity<Post>(e =>
        {
            e.HasOne(p => p.Author)
                .WithMany(u => u.Posts)
                .HasForeignKey(p => p.AuthorId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<RefreshToken>(e =>
        {
            e.HasOne(r => r.User).WithMany().HasForeignKey(r => r.UserId).OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(r => r.Token).IsUnique();
        });
    }
}

class User
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public List<Post> Posts { get; set; } = [];
}

class Post
{
    public int Id { get; set; }
    public int AuthorId { get; set; }
    public User? Author { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

class RefreshToken
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public User? User { get; set; }
    public string Token { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public DateTime? RevokedAt { get; set; }
}

// --- DTOs ---

record RegisterRequest(string Name, string Email, string Password);
record LoginRequest(string Email, string Password);
record RefreshRequest([property: JsonPropertyName("refreshToken")] string RefreshToken);
record PostRequest(string Title, string? Content, double Latitude, double Longitude);
record PostUpdateRequest(string? Title, string? Content, double? Latitude, double? Longitude);

record AuthResponse(
    [property: JsonPropertyName("accessToken")] string AccessToken,
    [property: JsonPropertyName("refreshToken")] string RefreshToken,
    UserDto User);

record TokenResponse(
    [property: JsonPropertyName("accessToken")] string AccessToken,
    [property: JsonPropertyName("refreshToken")] string RefreshToken);

record UserDto(int Id, string Name, string Email, DateTime CreatedAt)
{
    public static UserDto FromEntity(User user) =>
        new(user.Id, user.Name, user.Email, user.CreatedAt);
}

record AuthorDto(
    [property: JsonPropertyName("authorId")] int AuthorId,
    string Name,
    string Email);

record PostDto(
    int Id,
    string Title,
    string Content,
    double Latitude,
    double Longitude,
    DateTime CreatedAt,
    AuthorDto Author)
{
    public static PostDto FromEntity(Post post) =>
        new(
            post.Id,
            post.Title,
            post.Content,
            post.Latitude,
            post.Longitude,
            post.CreatedAt,
            new AuthorDto(
                post.Author?.Id ?? post.AuthorId,
                post.Author?.Name ?? string.Empty,
                post.Author?.Email ?? string.Empty));
}

record DeletePostResponse(string Title, string Description);
