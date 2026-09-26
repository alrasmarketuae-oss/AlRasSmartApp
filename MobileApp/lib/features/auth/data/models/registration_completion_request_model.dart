class RegistrationCompletionRequestModel {
  const RegistrationCompletionRequestModel({
    required this.missingLocation,
    required this.missingImages,
    required this.missingDocuments,
    this.message,
    this.userMessage,
    this.requestedAtUtc,
  });

  final bool missingLocation;
  final bool missingImages;
  final bool missingDocuments;
  final String? message;
  final String? userMessage;
  final DateTime? requestedAtUtc;

  bool get hasAnyMissing =>
      missingLocation || missingImages || missingDocuments;

  factory RegistrationCompletionRequestModel.fromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return const RegistrationCompletionRequestModel(
        missingLocation: false,
        missingImages: false,
        missingDocuments: false,
      );
    }

    DateTime? requestedAt;
    final rawAt = json['requestedAtUtc'] ?? json['RequestedAtUtc'];
    if (rawAt != null) {
      requestedAt = DateTime.tryParse(rawAt.toString());
    }

    return RegistrationCompletionRequestModel(
      missingLocation:
          json['missingLocation'] == true || json['MissingLocation'] == true,
      missingImages:
          json['missingImages'] == true || json['MissingImages'] == true,
      missingDocuments:
          json['missingDocuments'] == true || json['MissingDocuments'] == true,
      message: json['message']?.toString() ?? json['Message']?.toString(),
      userMessage:
          json['userMessage']?.toString() ?? json['UserMessage']?.toString(),
      requestedAtUtc: requestedAt,
    );
  }
}
