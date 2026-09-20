import 'package:dev_feed_app/src/common/constants/api_constant.dart';
import 'package:dev_feed_app/src/common/patterns/result_pattern.dart';
import 'package:dev_feed_app/src/common/services/location_service.dart';
import 'package:dev_feed_app/src/features/posts/exceptions/post_exception.dart';
import 'package:dev_feed_app/src/features/posts/models/post_model.dart';
import 'package:dev_feed_app/src/features/posts/repositories/post_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../post_mocks.mocks.dart';

void main() {
  late MockConnectionService mockConnection;
  late MockHttpService mockHttp;
  late MockLocationService mockLocation;
  late PostRepositoryImpl repository;

  setUp(() {
    mockConnection = MockConnectionService();
    mockHttp = MockHttpService();
    mockLocation = MockLocationService();
    repository = PostRepositoryImpl(
      connectionService: mockConnection,
      httpService: mockHttp,
      locationService: mockLocation,
    );
    when(mockConnection.isConnected).thenReturn(true);
  });

  final postJson = {
    'id': 1,
    'title': 'Title',
    'content': 'Content',
    'latitude': 1.0,
    'longitude': 2.0,
    'createdAt': '2024-01-01T00:00:00.000Z',
    'author': {'authorId': 1, 'name': 'Author', 'email': 'a@b.com'},
  };

  test('findAllPosts returns list on 200', () async {
    when(mockConnection.checkConnection()).thenAnswer((_) async {});
    when(mockHttp.getData(path: ApiConstant.posts)).thenAnswer(
      (_) async => (statusCode: 200, data: [postJson], error: null),
    );

    final result = await repository.findAllPosts();

    expect(result, isA<SuccessResult<List<PostModel>, PostException>>());
    final posts = (result as SuccessResult<List<PostModel>, PostException>).value;
    expect(posts, hasLength(1));
    expect(posts.first.title, 'Title');
  });

  test('createPost sends coordinates from location service', () async {
    when(mockConnection.checkConnection()).thenAnswer((_) async {});
    when(mockLocation.getCurrentLocation()).thenAnswer(
      (_) async => LocationPosition(latitude: 10, longitude: 20),
    );
    when(
      mockHttp.postData(path: ApiConstant.posts, body: anyNamed('body')),
    ).thenAnswer(
      (_) async => (statusCode: 201, data: postJson, error: null),
    );

    final result = await repository.createPost(
      title: 'Title',
      content: 'Content body here',
    );

    expect(result, isA<SuccessResult<PostModel, PostException>>());
    verify(
      mockHttp.postData(
        path: ApiConstant.posts,
        body: argThat(
          containsPair('latitude', 10.0),
          named: 'body',
        ),
      ),
    ).called(1);
  });

  test('createPost uses 0,0 when location is unavailable', () async {
    when(mockConnection.checkConnection()).thenAnswer((_) async {});
    when(mockLocation.getCurrentLocation()).thenAnswer((_) async => null);
    when(
      mockHttp.postData(path: ApiConstant.posts, body: anyNamed('body')),
    ).thenAnswer(
      (_) async => (statusCode: 201, data: postJson, error: null),
    );

    await repository.createPost(
      title: 'Title',
      content: 'Content body here',
    );

    verify(
      mockHttp.postData(
        path: ApiConstant.posts,
        body: argThat(
          allOf(
            containsPair('latitude', 0.0),
            containsPair('longitude', 0.0),
          ),
          named: 'body',
        ),
      ),
    ).called(1);
  });
}
