import 'package:dev_feed_app/src/features/auth/routes/auth_routes.dart';
import 'package:dev_feed_app/src/features/posts/routes/post_routes.dart';
import 'package:dev_feed_app/src/features/settings/routes/setting_routes.dart';
import 'package:go_router/go_router.dart';

class Routes {
  static String get home => AuthRoutes.auth;

  final routes = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: home,
    routes: [
      ...AuthRoutes().routes,
      ...PostRoutes().routes,
      ...SettingRoutes().routes,
    ],
  );
}
