import 'package:dev_feed_app/src/common/patterns/state_pattern.dart';
import 'package:dev_feed_app/src/common/state_management/state_management.dart';
import 'package:dev_feed_app/src/features/posts/exceptions/post_exception.dart';
import 'package:dev_feed_app/src/features/posts/models/post_model.dart';
import 'package:dev_feed_app/src/features/posts/models/post_screen_state.dart';
import 'package:dev_feed_app/src/features/posts/view_models/post_view_model.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

class PostFormView extends StatefulWidget {
  final PostViewModel postViewModel;
  final PostModel? post;

  const PostFormView({super.key, required this.postViewModel, this.post});

  @override
  State<PostFormView> createState() => _PostFormViewState();
}

class _PostFormViewState extends State<PostFormView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  bool get isEditing => widget.post != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post?.title);
    _contentController = TextEditingController(text: widget.post?.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Post' : 'Criar Post'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.postViewModel.resetPostState();
            context.pop();
          },
        ),
      ),
      body: StateConsumerWidget<PostViewModel, PostScreenState>(
        viewModel: widget.postViewModel,
        listener: (context, screenState) {
          final mutation = screenState.mutation;
          if (mutation is SuccessState<PostModel, PostException>) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isEditing
                      ? 'Post atualizado com sucesso!'
                      : 'Post criado com sucesso!',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            widget.postViewModel.resetPostState();
            context.pop();
          }
          if (mutation is ErrorState<PostModel, PostException>) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(mutation.error.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, screenState) {
          final isLoading = screenState.mutation is LoadingState;
          return _buildForm(isLoading: isLoading);
        },
      ),
    );
  }

  Widget _buildForm({required bool isLoading}) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Título',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
              hintText: 'Digite o título do post',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor, insira um título';
              }
              if (value.trim().length < 3) {
                return 'O título deve ter pelo menos 3 caracteres';
              }
              return null;
            },
            enabled: !isLoading,
            maxLength: 100,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: 'Conteúdo',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
              alignLabelWithHint: true,
              hintText: 'Digite o conteúdo do post',
            ),
            maxLines: 8,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor, insira o conteúdo';
              }
              if (value.trim().length < 10) {
                return 'O conteúdo deve ter pelo menos 10 caracteres';
              }
              return null;
            },
            enabled: !isLoading,
            maxLength: 500,
          ),
          const SizedBox(height: 16),
          _buildLocationInfo(),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    isEditing ? 'Salvar Alterações' : 'Criar Post',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Localização Automática',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'A localização será obtida automaticamente quando você criar ou editar o post.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade900,
                height: 1.4,
              ),
            ),
            if (isEditing && widget.post != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Localização atual:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Lat: ${widget.post!.latitude.toStringAsFixed(6)}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                'Long: ${widget.post!.longitude.toStringAsFixed(6)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();

      if (isEditing) {
        widget.postViewModel.updatePost(
          id: widget.post!.id,
          title: title,
          content: content,
        );
      } else {
        widget.postViewModel.createPost(title: title, content: content);
      }
    }
  }
}
