class DeletedPostModel {
  final String title;
  final String description;

  const DeletedPostModel({required this.title, required this.description});

  factory DeletedPostModel.fromJson(Map<String, dynamic> json) {
    return DeletedPostModel(
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }
}
