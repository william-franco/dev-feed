import 'package:dev_feed_app/src/common/patterns/state_pattern.dart';
import 'package:dev_feed_app/src/common/state_management/state_management.dart';
import 'package:dev_feed_app/src/features/posts/models/deleted_post_model.dart';
import 'package:dev_feed_app/src/features/posts/models/post_screen_state.dart';
import 'package:dev_feed_app/src/features/posts/exceptions/post_exception.dart';
import 'package:dev_feed_app/src/features/posts/models/author_model.dart';
import 'package:dev_feed_app/src/features/posts/models/post_model.dart';
import 'package:dev_feed_app/src/features/posts/routes/post_routes.dart';
import 'package:dev_feed_app/src/features/posts/view_models/post_view_model.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

class PostDetailView extends StatefulWidget {
  final PostModel post;
  final PostViewModel postViewModel;

  const PostDetailView({
    super.key,
    required this.post,
    required this.postViewModel,
  });

  @override
  State<PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<PostDetailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Post'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: StateConsumerWidget<PostViewModel, PostScreenState>(
        viewModel: widget.postViewModel,
        listener: (context, screenState) {
          final deleted = screenState.deleted;
          if (deleted is SuccessState<DeletedPostModel, PostException>) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Post excluído com sucesso!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            widget.postViewModel.resetDeletedPostState();
            context.pop();
          }
          if (deleted is ErrorState<DeletedPostModel, PostException>) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(deleted.error.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
            widget.postViewModel.resetDeletedPostState();
          }
        },
        builder: (context, screenState) {
          PostModel currentPost = widget.post;
          final postsState = screenState.posts;
          if (postsState is SuccessState<List<PostModel>, PostException>) {
            currentPost = postsState.data.firstWhere(
              (p) => p.id == widget.post.id,
              orElse: () => widget.post,
            );
          }
          return _buildContent(currentPost);
        },
      ),
    );
  }

  Widget _buildContent(PostModel currentPost) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            icon: Icons.numbers,
            label: 'ID do Post',
            value: currentPost.id.toString(),
          ),
          const SizedBox(height: 16),
          _buildAuthorCard(currentPost.author),
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: Icons.calendar_today,
            label: 'Criado em',
            value: _formatDate(currentPost.createdAt),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Título'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                currentPost.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Conteúdo'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                currentPost.content,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLocationCard(currentPost.latitude, currentPost.longitude),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToEdit(context),
              icon: const Icon(Icons.edit),
              label: const Text('Editar Post'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmDelete(context),
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text(
                'Excluir Post',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.blue),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorCard(AuthorModel author) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(radius: 24, child: Icon(Icons.person, size: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Autor',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    author.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (author.email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      author.email,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(double latitude, double longitude) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, size: 24, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Localização',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Latitude',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        latitude.toStringAsFixed(6),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Longitude',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        longitude.toStringAsFixed(6),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToEdit(BuildContext context) {
    context.push(
      PostRoutes.postForm,
      extra: {'post': widget.post, 'viewModel': widget.postViewModel},
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text(
          'Tem certeza que deseja excluir este post? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              dialogContext.pop();
              widget.postViewModel.deletePost(widget.post.id);
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
