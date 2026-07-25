class RegisterDto {
  final String fullName;
  final String email;
  final String password;
  final String roleName;
  final int? genderId;
  final String? dateOfBirth;
  final int? nationalityId;
  final String? profileImage;
  final String? storeName;
  final String? commercialLicensePath;
  final String? sellerIdentityPath;

  RegisterDto({
    required this.fullName,
    required this.email,
    required this.password,
    required this.roleName,
    this.genderId,
    this.dateOfBirth,
    this.nationalityId,
    this.profileImage,
    this.storeName,
    this.commercialLicensePath,
    this.sellerIdentityPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'passwordHash': password, // Backend expects passwordHash
      'password': password, // Also send as password for compatibility
      'roleName': roleName,
      if (genderId != null) 'genderId': genderId,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (nationalityId != null) 'nationalityId': nationalityId,
      if (profileImage != null) 'profileImage': profileImage,
      if (storeName != null) 'storeName': storeName,
      if (commercialLicensePath != null)
        'commercialLicensePath': commercialLicensePath,
      if (sellerIdentityPath != null) 'sellerIdentityPath': sellerIdentityPath,
    };
  }
}
