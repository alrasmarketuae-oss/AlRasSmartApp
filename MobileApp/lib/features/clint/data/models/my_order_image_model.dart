class MyOrderImageModel {
  const MyOrderImageModel({
    required this.id,
    required this.path,
  });

  final int id;
  final String path;

  factory MyOrderImageModel.fromJson(Map<String, dynamic> json) {
    return MyOrderImageModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      path: json['path']?.toString() ?? '',
    );
  }
}
