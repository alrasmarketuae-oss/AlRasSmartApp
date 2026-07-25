import 'dart:convert';

import 'package:alrasmarket/core/serveses/auth_service.dart';

class CompanyImageModel {
  final int id;
  final String imagePath;
  final bool isPrimary;

  const CompanyImageModel({
    required this.id,
    required this.imagePath,
    required this.isPrimary,
  });

  factory CompanyImageModel.fromJson(Map<String, dynamic> json) {
    return CompanyImageModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      imagePath: json['imagePath']?.toString() ?? json['ImagePath']?.toString() ?? '',
      isPrimary: json['isPrimary'] == true || json['IsPrimary'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'imagePath': imagePath,
    'isPrimary': isPrimary,
  };
}

class LoginResponseModel {
  final String? token;
  final String? id;
  final String? email;
  final String? name;
  final String? imgPath;
  final String? companyName;
  final String? roleName;
  final String? phone;
  final bool? isCompanyAccount;
  final bool? isShippingCompanyAccount;
  final bool? isApproved;
  final bool? isVerified;
  final bool? isCustomer;
  final String? licenseNumber;
  final String? licencePath;
  final bool? isRejected;
  final String? rejectionReason;

  LoginResponseModel({
    this.token,
    this.id,
    this.email,
    this.name,
    this.imgPath,
    this.companyName,
    this.roleName,
    this.phone,
    this.isCompanyAccount,
    this.isShippingCompanyAccount,
    this.isApproved,
    this.isVerified,
    this.isCustomer,
    this.licenseNumber,
    this.licencePath,
    this.isRejected,
    this.rejectionReason,
  });

  /// Backward-compat getters used across the app.
  String? get authToken => token;
  String? get personId => id;
  String? get fullName => name;
  String? get role => roleName;

  /// Company or shipping company waiting for admin approval.
  bool get isPendingAdminApproval =>
      (isCompanyAccount == true || isShippingCompanyAccount == true) &&
      isApproved != true;
  factory LoginResponseModel.fromJson(
    Map<String, dynamic> json, {
    bool persistSession = true,
  }) {
    final rawToken = json['token'] ?? json['Token'] ?? json['accessToken'];
    final token = rawToken is String && rawToken.isNotEmpty ? rawToken : null;

    String? id = _stringFromJson(
      json['id'] ?? json['Id'] ?? json['personId'] ?? json['PersonId'],
    );
    String? email = _stringFromJson(json['email'] ?? json['Email']);
    String? name = _stringFromJson(
      json['name'] ?? json['Name'] ?? json['fullName'] ?? json['FullName'],
    );
    String? roleName = _stringFromJson(
      json['roleName'] ?? json['RoleName'] ?? json['role'] ?? json['Role'],
    );
    final isCompanyAccount = _boolFromJson(
      json['isCompanyAccount'] ?? json['IsCompanyAccount'],
    );
    final isShippingCompanyAccount = _boolFromJson(
      json['isShippingCompanyAccount'] ?? json['IsShippingCompanyAccount'],
    ) ??
        (roleName?.toLowerCase() == 'shippingcompany');
    final isApproved = _boolFromJson(json['isApproved'] ?? json['IsApproved']);
    final isVerified = _boolFromJson(json['isVerified'] ?? json['IsVerified']);
    final isCustomer = _boolFromJson(json['isCustomer'] ?? json['IsCustomer']);

    if ((id == null || id.isEmpty) && token != null && token.isNotEmpty) {
      try {
        final payload = _decodeJwtPayload(token);
        id ??= _stringFromJson(payload['sub'] ?? payload['EntityId']);
        email ??= _stringFromJson(payload['email']);
        name ??= _stringFromJson(payload['fullName']);
        roleName ??= _stringFromJson(payload['role']);
      } catch (_) {
        // ignore JWT decoding errors and rely on body fields
      }
    }

    final isRejected = _boolFromJson(json['isRejected'] ?? json['IsRejected']);
    final rejectionReason = _stringFromJson(
      json['rejectionReason'] ?? json['RejectionReason'],
    );
    if (persistSession && isRejected == true) {
      return LoginResponseModel(
        token: token,
        id: id,
        email: email,
        name: name,
        roleName: roleName,
        isRejected: true,
        rejectionReason: rejectionReason,
      );
    }

    if (persistSession) {
      final parsedImagePath =
          _stringFromJson(json['imgPath'] ?? json['ImgPath']) ?? '';
      // Never persist an authenticated API session without a real token.
      // Pending/unverified flows keep email via dedicated AuthCubit handlers.
      if (token != null && token.isNotEmpty) {
        AuthService.instance.saveAuthData(
          personId: id ?? '',
          authToken: token,
          userRoleId: '',
          userEmail: email ?? '',
          fullName: name ?? '',
          userRole: roleName,
          companyWaiting: (isCompanyAccount == true ||
                  isShippingCompanyAccount == true) &&
              isApproved != true,
          approved: isApproved,
          isCustomerAcount: isCustomer,
          verified: isVerified,
          companyAccount: isCompanyAccount,
          shippingCompanyAccount: isShippingCompanyAccount,
          imagePath: parsedImagePath,
        );
      }
    }

    return LoginResponseModel(
      token: token,
      id: id,
      email: email,
      name: name,
      imgPath: _stringFromJson(json['imgPath'] ?? json['ImgPath']),
      companyName: _stringFromJson(json['companyName'] ?? json['CompanyName']),
      roleName: roleName,
      phone: _stringFromJson(json['phone'] ?? json['Phone']),
      isCompanyAccount: isCompanyAccount,
      isShippingCompanyAccount: isShippingCompanyAccount,
      isApproved: isApproved,
      isVerified: isVerified,
      isCustomer: isCustomer,
      licenseNumber: _stringFromJson(
        json['licenseNumber'] ?? json['LicenseNumber'],
      ),
      licencePath: _stringFromJson(
        json['licencePath'] ?? json['LicencePath'] ?? json['licensePath'],
      ),
      isRejected: isRejected,
      rejectionReason: rejectionReason,
    );
  }

  static String? _stringFromJson(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  static bool? _boolFromJson(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return null;
  }

  static Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw const FormatException('Invalid JWT');
    final payload = base64Url.normalize(parts[1]);
    final jsonStr = utf8.decode(base64Url.decode(payload));
    return json.decode(jsonStr) as Map<String, dynamic>;
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'id': id,
      'email': email,
      'name': name,
      'imgPath': imgPath,
      'companyName': companyName,
      'roleName': roleName,
      'phone': phone,
      'isCompanyAccount': isCompanyAccount,
      'isApproved': isApproved,
      'isVerified': isVerified,
      'isCustomer': isCustomer,
      'licenseNumber': licenseNumber,
      'licencePath': licencePath,
      'isRejected': isRejected,
      'rejectionReason': rejectionReason,
    };
  }
}
