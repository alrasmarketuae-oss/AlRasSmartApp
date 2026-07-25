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
  });

  factory AccountApprovalStatusModel.fromJson(Map<String, dynamic> json) {
    final rawToken = json['token'] ?? json['Token'];
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
      isShippingCompanyAccount: json['isShippingCompanyAccount'] == true ||
          json['IsShippingCompanyAccount'] == true,
      isCustomer: json['isCustomer'] == true || json['IsCustomer'] == true,
    );
  }
}
