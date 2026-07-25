class CreateProductResponse {
  const CreateProductResponse({
    required this.productId,
    this.requiresAdminReview = true,
  });

  final String productId;
  final bool requiresAdminReview;

  factory CreateProductResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['requiresAdminReview'];
    final requiresReview = raw is bool
        ? raw
        : raw?.toString().toLowerCase() != 'false';
    return CreateProductResponse(
      productId: json['productId']?.toString() ?? '',
      requiresAdminReview: requiresReview,
    );
  }
}
