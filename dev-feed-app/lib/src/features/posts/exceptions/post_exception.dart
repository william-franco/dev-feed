class PostException implements Exception {
  final String message;

  const PostException(this.message);

  @override
  String toString() => message;
}
