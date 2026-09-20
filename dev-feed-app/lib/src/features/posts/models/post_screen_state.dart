import 'package:dev_feed_app/src/common/patterns/state_pattern.dart';
import 'package:dev_feed_app/src/features/posts/exceptions/post_exception.dart';
import 'package:dev_feed_app/src/features/posts/models/deleted_post_model.dart';
import 'package:dev_feed_app/src/features/posts/models/post_model.dart';

typedef PostsState = StatePattern<List<PostModel>, PostException>;
typedef PostMutationState = StatePattern<PostModel, PostException>;
typedef DeletedPostState = StatePattern<DeletedPostModel, PostException>;

class PostScreenState {
  final PostsState posts;
  final PostMutationState mutation;
  final DeletedPostState deleted;

  const PostScreenState({
    this.posts = const InitialState(),
    this.mutation = const InitialState(),
    this.deleted = const InitialState(),
  });

  PostScreenState copyWith({
    PostsState? posts,
    PostMutationState? mutation,
    DeletedPostState? deleted,
  }) {
    return PostScreenState(
      posts: posts ?? this.posts,
      mutation: mutation ?? this.mutation,
      deleted: deleted ?? this.deleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostScreenState &&
          posts == other.posts &&
          mutation == other.mutation &&
          deleted == other.deleted;

  @override
  int get hashCode => Object.hash(posts, mutation, deleted);
}
