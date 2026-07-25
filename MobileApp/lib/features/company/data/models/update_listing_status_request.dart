class UpdateListingStatusRequest {
  const UpdateListingStatusRequest({required this.isActive});

  final bool isActive;

  Map<String, dynamic> toJson() => {'isActive': isActive};
}
