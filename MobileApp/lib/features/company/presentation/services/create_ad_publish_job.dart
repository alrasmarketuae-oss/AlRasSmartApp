import 'package:alrasmarket/features/company/data/models/create_ad_product_request.dart';

/// Snapshot of a create-ad publish payload for background processing.
///
/// Multiple jobs can sit in [CreateAdPublishQueue] as an array so the user
/// can publish several ads in a row while compression/upload continue.
class CreateAdPublishJob {
  CreateAdPublishJob({
    required this.id,
    required this.token,
    required this.request,
    required this.imagePaths,
    required this.documentPaths,
    this.rawVideoPath,
    this.compressedVideoPath,
    this.productName = '',
    this.skipDocuments = false,
    this.createdProductId,
  });

  final String id;
  final String token;

  /// Product fields without compressed video attached yet.
  final CreateAdProductRequest request;

  /// Local image paths to compress then upload after create.
  final List<String> imagePaths;

  /// Local document paths to upload after create.
  final List<String> documentPaths;

  /// Original local video path.
  final String? rawVideoPath;

  /// Set after compression so a resume skips re-encoding.
  final String? compressedVideoPath;

  final String productName;
  final bool skipDocuments;

  /// Set after the product row is created so a resume won't duplicate it.
  final String? createdProductId;

  CreateAdPublishJob copyWith({
    List<String>? imagePaths,
    String? compressedVideoPath,
    String? createdProductId,
    CreateAdProductRequest? request,
  }) {
    return CreateAdPublishJob(
      id: id,
      token: token,
      request: request ?? this.request,
      imagePaths: imagePaths ?? this.imagePaths,
      documentPaths: documentPaths,
      rawVideoPath: rawVideoPath,
      compressedVideoPath: compressedVideoPath ?? this.compressedVideoPath,
      productName: productName,
      skipDocuments: skipDocuments,
      createdProductId: createdProductId ?? this.createdProductId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'token': token,
        'request': request.toJson(),
        'imagePaths': imagePaths,
        'documentPaths': documentPaths,
        'rawVideoPath': rawVideoPath,
        'compressedVideoPath': compressedVideoPath,
        'productName': productName,
        'skipDocuments': skipDocuments,
        'createdProductId': createdProductId,
      };

  factory CreateAdPublishJob.fromJson(Map<String, dynamic> json) {
    return CreateAdPublishJob(
      id: json['id'] as String,
      token: json['token'] as String? ?? '',
      request: CreateAdProductRequest.fromJson(
        Map<String, dynamic>.from(json['request'] as Map),
      ),
      imagePaths: (json['imagePaths'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      documentPaths: (json['documentPaths'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      rawVideoPath: json['rawVideoPath'] as String?,
      compressedVideoPath: json['compressedVideoPath'] as String?,
      productName: json['productName'] as String? ?? '',
      skipDocuments: json['skipDocuments'] as bool? ?? false,
      createdProductId: json['createdProductId'] as String?,
    );
  }
}
