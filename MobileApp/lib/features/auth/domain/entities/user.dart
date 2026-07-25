class User {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String roleName;
  final String roleId;
  final String? token;
  final int? genderId;
  final String? dateOfBirth;
  final String? profileImage;
  final String? storeName;

  User({
    
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.roleName,
    required this.roleId,
    this.token,
    this.genderId,
    this.dateOfBirth,
    this.profileImage,
    this.storeName,
  });
}
