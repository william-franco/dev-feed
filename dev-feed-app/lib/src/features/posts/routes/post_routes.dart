import 'package:dev_feed_app/src/common/dependency_injectors/dependency_injector.dart';
import 'package:dev_feed_app/src/features/posts/models/post_model.dart';
import 'package:dev_feed_app/src/features/posts/view_models/post_view_model.dart';
import 'package:dev_feed_app/src/features/posts/views/post_detail_view.dart';
import 'package:dev_feed_app/src/features/posts/views/post_form_view.dart';
import 'package:dev_feed_app/src/features/posts/views/post_view.dart';
import 'package:go_router/go_router.dart';

class PostRoutes {
  static String get posts => '/posts';
  static String get postForm => '/posts/form';
  static String postDetail(int id) => '/posts/$id';

  List<GoRoute> get routes => _routes;

  final List<GoRoute> _routes = [
    GoRoute(
      path: posts,
      builder: (context, state) {
        return PostView(postViewModel: locator<PostViewModel>());
      },
    ),
    GoRoute(
      path: postForm,
      builder: (context, state) {
        final extra = state.extra;

        if (extra is Map<String, dynamic>) {
          return PostFormView(
            postViewModel: extra['viewModel'] as PostViewModel,
            post: extra['post'] as PostModel?,
          );
        }

        return PostFormView(postViewModel: locator<PostViewModel>());
      },
    ),
    GoRoute(
      path: '/posts/:id',
      builder: (context, state) {
        final extras = state.extra! as Map<String, dynamic>;
        return PostDetailView(
          post: extras['post'] as PostModel,
          postViewModel: extras['viewModel'] as PostViewModel,
        );
      },
    ),
  ];
}
