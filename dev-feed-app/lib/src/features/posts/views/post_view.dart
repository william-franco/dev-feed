import 'package:dev_feed_app/src/common/patterns/state_pattern.dart';
import 'package:dev_feed_app/src/common/state_management/state_management.dart';
import 'package:dev_feed_app/src/features/posts/models/post_screen_state.dart';
import 'package:dev_feed_app/src/features/posts/models/post_model.dart';
import 'package:dev_feed_app/src/features/posts/routes/post_routes.dart';
import 'package:dev_feed_app/src/features/settings/routes/setting_routes.dart';
import 'package:dev_feed_app/src/features/posts/view_models/post_view_model.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

class PostView extends StatefulWidget {
  final PostViewModel postViewModel;

  const PostView({super.key, required this.postViewModel});

  @override
  State<PostView> createState() => _PostViewState();
}

class _PostViewState extends State<PostView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.postViewModel.getAllPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed de Posts'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(SettingRoutes.setting),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await widget.postViewModel.getAllPosts();
        },
        child: StateBuilderWidget<PostViewModel, PostScreenState>(
          viewModel: widget.postViewModel,
          builder: (context, screenState) {
            return switch (screenState.posts) {
              InitialState() => const SizedBox.shrink(),
              LoadingState() => const Center(
                child: CircularProgressIndicator(),
              ),
              ErrorState(:final error) => _buildErrorState(error.toString()),
              SuccessState(:final data) => _buildSuccessState(data),
            };
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreatePost(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => widget.postViewModel.getAllPosts(),
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(List<PostModel> posts) {
    if (posts.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum post encontrado.\nToque em + para criar um novo post.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => widget.postViewModel.getAllPosts(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return _PostCard(
            post: post,
            onTap: () => _navigateToPostDetail(context, post),
            onEdit: () => _navigateToEditPost(context, post),
            onDelete: () => _confirmDelete(context, post),
          );
        },
      ),
    );
  }

  void _navigateToCreatePost(BuildContext context) {
    context.push(PostRoutes.postForm, extra: widget.postViewModel);
  }

  void _navigateToPostDetail(BuildContext context, PostModel post) {
    context.push(
      PostRoutes.postDetail(post.id),
      extra: {'post': post, 'viewModel': widget.postViewModel},
    );
  }

  void _navigateToEditPost(BuildContext context, PostModel post) {
    context.push(
      PostRoutes.postForm,
      extra: {'post': post, 'viewModel': widget.postViewModel},
    );
  }

  void _confirmDelete(BuildContext context, PostModel post) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir este post?'),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              dialogContext.pop();
              widget.postViewModel.deletePost(post.id);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PostCard({
    required this.post,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Excluir',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                post.content,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    post.author.name,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${post.latitude.toStringAsFixed(4)}, ${post.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              ...[
                const SizedBox(height: 4),
                Text(
                  _formatDate(post.createdAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
