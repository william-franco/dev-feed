import 'package:dev_feed_app/src/common/services/connection_service.dart';
import 'package:dev_feed_app/src/common/services/http_service.dart';
import 'package:dev_feed_app/src/common/services/location_service.dart';
import 'package:dev_feed_app/src/features/posts/repositories/post_repository.dart';
import 'package:dev_feed_app/src/features/posts/view_models/post_view_model.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([
  ConnectionService,
  HttpService,
  LocationService,
  PostRepository,
  PostViewModel,
])
void main() {}
