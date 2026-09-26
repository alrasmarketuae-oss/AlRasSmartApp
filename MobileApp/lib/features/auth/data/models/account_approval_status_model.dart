import 'registration_completion_request_model.dart';

class AccountApprovalStatusModel {
  final bool exists;
  final String? email;
  final String? id;
  final String? name;
  final String? phone;
  final String? roleName;
  final String? token;
  final bool isApproved;
  final bool isVerified;
  final bool isCompanyAccount;
  final bool isShippingCompanyAccount;
  final bool isCustomer;
  final bool isPendingAdminApproval;
  final bool needsRegistrationCompletion;
  final RegistrationCompletionRequestModel? registrationCompletionRequest;
  final String? message;

  const AccountApprovalStatusModel({
    required this.exists,
    this.email,
    this.id,
    this.name,
    this.phone,
    this.roleName,
    this.token,
    required this.isApproved,
    required this.isVerified,
    this.isCompanyAccount = false,
    this.isShippingCompanyAccount = false,
    this.isCustomer = false,
    this.isPendingAdminApproval = false,
    this.needsRegistrationCompletion = false,
    this.registrationCompletionRequest,
    this.message,
  });

  factory AccountApprovalStatusModel.fromJson(Map<String, dynamic> json) {
    final rawToken = json['token'] ?? json['Token'];
    final rawCompletion =
        json['registrationCompletionRequest'] ??
        json['RegistrationCompletionRequest'];
    Map<String, dynamic>? completionMap;
    if (rawCompletion is Map<String, dynamic>) {
      completionMap = rawCompletion;
    } else if (rawCompletion is Map) {
      completionMap = Map<String, dynamic>.from(rawCompletion);
    }

    final completion = completionMap == null
        ? null
        : RegistrationCompletionRequestModel.fromJson(completionMap);

    return AccountApprovalStatusModel(
      exists: json['exists'] == true || json['Exists'] == true,
      email: json['email']?.toString() ?? json['Email']?.toString(),
      id: json['id']?.toString() ?? json['Id']?.toString(),
      name: json['name']?.toString() ?? json['Name']?.toString(),
      phone: json['phone']?.toString() ?? json['Phone']?.toString(),
      roleName: json['roleName']?.toString() ?? json['RoleName']?.toString(),
      token: rawToken is String && rawToken.isNotEmpty ? rawToken : null,
      isApproved: json['isApproved'] == true || json['IsApproved'] == true,
      isVerified: json['isVerified'] == true || json['IsVerified'] == true,
      isCompanyAccount:
          json['isCompanyAccount'] == true || json['IsCompanyAccount'] == true,
      isShippingCompanyAccount:
          json['isShippingCompanyAccount'] == true ||
          json['IsShippingCompanyAccount'] == true,
      isCustomer: json['isCustomer'] == true || json['IsCustomer'] == true,
      isPendingAdminApproval:
          json['isPendingAdminApproval'] == true ||
          json['IsPendingAdminApproval'] == true,
      needsRegistrationCompletion:
          json['needsRegistrationCompletion'] == true ||
          json['NeedsRegistrationCompletion'] == true ||
          (completion?.hasAnyMissing ?? false),
      registrationCompletionRequest: completion,
      message: json['message']?.toString() ?? json['Message']?.toString(),
    );
  }
}
