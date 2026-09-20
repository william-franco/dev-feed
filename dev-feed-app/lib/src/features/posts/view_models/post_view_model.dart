import 'package:dev_feed_app/src/common/patterns/state_pattern.dart';
import 'package:dev_feed_app/src/common/state_management/state_management.dart';
import 'package:dev_feed_app/src/features/posts/exceptions/post_exception.dart';
import 'package:dev_feed_app/src/features/posts/models/deleted_post_model.dart';
import 'package:dev_feed_app/src/features/posts/models/post_model.dart';
import 'package:dev_feed_app/src/features/posts/models/post_screen_state.dart';
import 'package:dev_feed_app/src/features/posts/repositories/post_repository.dart';
import 'package:flutter/foundation.dart';

typedef _ViewModel = StateManagement<PostScreenState>;

abstract interface class PostViewModel extends _ViewModel {
  Future<void> getAllPosts();
  Future<void> createPost({required String title, required String content});
  Future<void> updatePost({
    required int id,
    required String title,
    required String content,
  });
  Future<void> deletePost(int id);
  void resetPostState();
  void resetDeletedPostState();
}

class PostViewModelImpl extends _ViewModel implements PostViewModel {
  final PostRepository postRepository;

  PostViewModelImpl({required this.postRepository});

  @override
  PostScreenState build() => const PostScreenState();

  @override
  Future<void> getAllPosts() async {
    _emit(state.copyWith(posts: const LoadingState()));
    final result = await postRepository.findAllPosts();
    final postsState = result.fold<PostsState>(
      onSuccess: (value) => SuccessState(data: value),
      onError: (error) => ErrorState(error: error),
    );
    _emit(state.copyWith(posts: postsState));
  }

  @override
  Future<void> createPost({
    required String title,
    required String content,
  }) async {
    _emit(state.copyWith(mutation: const LoadingState()));
    final result = await postRepository.createPost(
      title: title,
      content: content,
    );
    final mutationState = result.fold<PostMutationState>(
      onSuccess: (value) => SuccessState(data: value),
      onError: (error) => ErrorState(error: error),
    );
    _emit(state.copyWith(mutation: mutationState));

    if (mutationState is SuccessState<PostModel, PostException>) {
      await getAllPosts();
    }
  }

  @override
  Future<void> updatePost({
    required int id,
    required String title,
    required String content,
  }) async {
    _emit(state.copyWith(mutation: const LoadingState()));
    final result = await postRepository.updatePost(
      id: id,
      title: title,
      content: content,
    );
    final mutationState = result.fold<PostMutationState>(
      onSuccess: (value) => SuccessState(data: value),
      onError: (error) => ErrorState(error: error),
    );
    _emit(state.copyWith(mutation: mutationState));

    if (mutationState is SuccessState<PostModel, PostException>) {
      await getAllPosts();
    }
  }

  @override
  Future<void> deletePost(int id) async {
    _emit(state.copyWith(deleted: const LoadingState()));
    final result = await postRepository.deletePost(id);
    final deletedState = result.fold<DeletedPostState>(
      onSuccess: (value) => SuccessState(data: value),
      onError: (error) => ErrorState(error: error),
    );
    _emit(state.copyWith(deleted: deletedState));

    if (deletedState is SuccessState<DeletedPostModel, PostException>) {
      await getAllPosts();
    }
  }

  @override
  void resetPostState() {
    _emit(state.copyWith(mutation: const InitialState()));
  }

  @override
  void resetDeletedPostState() {
    _emit(state.copyWith(deleted: const InitialState()));
  }

  void _emit(PostScreenState newState) {
    emitState(newState);
    debugPrint('PostViewModel: $state');
  }
}
