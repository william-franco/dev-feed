import 'package:dev_feed_app/src/common/constants/api_constant.dart';
import 'package:dev_feed_app/src/common/patterns/result_pattern.dart';
import 'package:dev_feed_app/src/common/services/connection_service.dart';
import 'package:dev_feed_app/src/common/services/http_service.dart';
import 'package:dev_feed_app/src/common/services/location_service.dart';
import 'package:dev_feed_app/src/features/posts/exceptions/post_exception.dart';
import 'package:dev_feed_app/src/features/posts/models/deleted_post_model.dart';
import 'package:dev_feed_app/src/features/posts/models/post_model.dart';

typedef PostsResult = ResultPattern<List<PostModel>, PostException>;
typedef PostResult = ResultPattern<PostModel, PostException>;
typedef DeletePostResult = ResultPattern<DeletedPostModel, PostException>;

abstract interface class PostRepository {
  Future<PostsResult> findAllPosts();
  Future<PostResult> createPost({
    required String title,
    required String content,
  });
  Future<PostResult> updatePost({
    required int id,
    required String title,
    required String content,
  });
  Future<DeletePostResult> deletePost(int id);
}

class PostRepositoryImpl implements PostRepository {
  final ConnectionService connectionService;
  final HttpService httpService;
  final LocationService locationService;

  PostRepositoryImpl({
    required this.connectionService,
    required this.httpService,
    required this.locationService,
  });

  @override
  Future<PostsResult> findAllPosts() async {
    try {
      await connectionService.checkConnection();

      if (!connectionService.isConnected) {
        return ErrorResult(error: PostException('Dispositivo sem conexão.'));
      }

      final result = await httpService.getData(path: ApiConstant.posts);

      if (result.statusCode == 200 && result.data != null) {
        final posts = (result.data as List)
            .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return SuccessResult(value: posts);
      }

      return ErrorResult(
        error: PostException('Falha ao carregar posts: ${result.statusCode}'),
      );
    } catch (error) {
      return ErrorResult(error: PostException('Erro inesperado: $error'));
    }
  }

  Future<Map<String, double>> _resolveCoordinates() async {
    final position = await locationService.getCurrentLocation();
    return {
      'latitude': position?.latitude ?? 0.0,
      'longitude': position?.longitude ?? 0.0,
    };
  }

  @override
  Future<PostResult> createPost({
    required String title,
    required String content,
  }) async {
    try {
      await connectionService.checkConnection();

      if (!connectionService.isConnected) {
        return ErrorResult(error: PostException('Dispositivo sem conexão.'));
      }

      final coords = await _resolveCoordinates();
      final result = await httpService.postData(
        path: ApiConstant.posts,
        body: {
          'title': title,
          'content': content,
          'latitude': coords['latitude'],
          'longitude': coords['longitude'],
        },
      );

      if (result.statusCode == 201 && result.data != null) {
        return SuccessResult(
          value: PostModel.fromJson(result.data as Map<String, dynamic>),
        );
      }

      return ErrorResult(
        error: PostException('Falha ao criar post: ${result.statusCode}'),
      );
    } catch (error) {
      return ErrorResult(error: PostException('Erro inesperado: $error'));
    }
  }

  @override
  Future<PostResult> updatePost({
    required int id,
    required String title,
    required String content,
  }) async {
    try {
      await connectionService.checkConnection();

      if (!connectionService.isConnected) {
        return ErrorResult(error: PostException('Dispositivo sem conexão.'));
      }

      final coords = await _resolveCoordinates();
      final result = await httpService.putData(
        path: '${ApiConstant.posts}/$id',
        body: {
          'title': title,
          'content': content,
          'latitude': coords['latitude'],
          'longitude': coords['longitude'],
        },
      );

      if (result.statusCode == 200 && result.data != null) {
        return SuccessResult(
          value: PostModel.fromJson(result.data as Map<String, dynamic>),
        );
      }

      return ErrorResult(
        error: PostException('Falha ao atualizar post: ${result.statusCode}'),
      );
    } catch (error) {
      return ErrorResult(error: PostException('Erro inesperado: $error'));
    }
  }

  @override
  Future<DeletePostResult> deletePost(int id) async {
    try {
      await connectionService.checkConnection();

      if (!connectionService.isConnected) {
        return ErrorResult(error: PostException('Dispositivo sem conexão.'));
      }

      final result = await httpService.deleteData(path: '${ApiConstant.posts}/$id');

      if (result.statusCode == 200 && result.data != null) {
        return SuccessResult(
          value: DeletedPostModel.fromJson(result.data as Map<String, dynamic>),
        );
      }

      return ErrorResult(
        error: PostException('Falha ao excluir post: ${result.statusCode}'),
      );
    } catch (error) {
      return ErrorResult(error: PostException('Erro inesperado: $error'));
    }
  }
}
