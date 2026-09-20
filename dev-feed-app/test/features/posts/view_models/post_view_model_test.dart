import 'package:dev_feed_app/src/common/patterns/result_pattern.dart';
import 'package:dev_feed_app/src/common/patterns/state_pattern.dart';
import 'package:dev_feed_app/src/features/posts/exceptions/post_exception.dart';
import 'package:dev_feed_app/src/features/posts/models/author_model.dart';
import 'package:dev_feed_app/src/features/posts/models/post_model.dart';
import 'package:dev_feed_app/src/features/posts/view_models/post_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../post_mocks.mocks.dart';

void main() {
  late MockPostRepository mockRepository;
  late PostViewModelImpl viewModel;

  final samplePost = PostModel(
    id: 1,
    title: 'Post 1',
    content: 'Content 1',
    latitude: 10,
    longitude: 20,
    createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
    author: const AuthorModel(
      authorId: 1,
      name: 'John',
      email: 'john@example.com',
    ),
  );

  setUpAll(() {
    provideDummy<ResultPattern<List<PostModel>, PostException>>(
      ErrorResult(error: PostException('dummy')),
    );
    provideDummy<ResultPattern<PostModel, PostException>>(
      ErrorResult(error: PostException('dummy')),
    );
  });

  setUp(() {
    mockRepository = MockPostRepository();
    viewModel = PostViewModelImpl(postRepository: mockRepository);
  });

  tearDown(() => viewModel.dispose());

  test('initial state', () {
    expect(viewModel.state.posts, isA<InitialState>());
    expect(viewModel.state.mutation, isA<InitialState>());
    expect(viewModel.state.deleted, isA<InitialState>());
  });

  test('getAllPosts success', () async {
    when(mockRepository.findAllPosts()).thenAnswer(
      (_) async => SuccessResult(value: [samplePost]),
    );

    await viewModel.getAllPosts();

    expect(
      viewModel.state.posts,
      isA<SuccessState<List<PostModel>, PostException>>(),
    );
  });

  test('createPost refreshes list on success', () async {
    when(
      mockRepository.createPost(
        title: anyNamed('title'),
        content: anyNamed('content'),
      ),
    ).thenAnswer((_) async => SuccessResult(value: samplePost));
    when(mockRepository.findAllPosts()).thenAnswer(
      (_) async => SuccessResult(value: [samplePost]),
    );

    await viewModel.createPost(title: 'T', content: 'Content long enough');

    verify(mockRepository.findAllPosts()).called(1);
  });
}
