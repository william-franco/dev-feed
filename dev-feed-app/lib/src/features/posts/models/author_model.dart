class AuthorModel {
  final int authorId;
  final String name;
  final String email;

  const AuthorModel({
    required this.authorId,
    required this.name,
    required this.email,
  });

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    return AuthorModel(
      authorId: json['authorId'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'authorId': authorId,
    'name': name,
    'email': email,
  };
}
