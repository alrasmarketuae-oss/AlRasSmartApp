class AdminCompanyModel {
  const AdminCompanyModel({
    required this.id,
    required this.displayName,
    this.email,
    this.isCustomer = false,
    this.isShipping = false,
    this.imagePath,
  });

  final String id;
  final String displayName;
  final String? email;
  final bool isCustomer;
  final bool isShipping;
  final String? imagePath;

  factory AdminCompanyModel.fromJson(Map<String, dynamic> json) {
    final roleId = json['roleId'] ?? json['RoleId'];
    final roleName =
        (json['roleName'] ?? json['RoleName'] ?? '').toString().toLowerCase();
    final companyName = _firstNonEmpty([
      json['companyNameAr'],
      json['CompanyNameAr'],
      json['companyNameEn'],
      json['CompanyNameEn'],
      json['companyName'],
      json['CompanyName'],
    ]);
    final fullName = _firstNonEmpty([
      json['fullNameAr'],
      json['FullNameAr'],
      json['fullNameEn'],
      json['FullNameEn'],
      json['fullName'],
      json['FullName'],
    ]);

    final email = _firstNonEmpty([json['email'], json['Email']]);

    return AdminCompanyModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      displayName: companyName ?? fullName ?? email ?? '',
      email: email,
      isCustomer: json['isCustomer'] == true || json['IsCustomer'] == true,
      isShipping: roleId == 5 ||
          roleId?.toString() == '5' ||
          roleName == 'shippingcompany',
      imagePath: _firstNonEmpty([json['imgPath'], json['ImgPath']]),
    );
  }

  static String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }
}
