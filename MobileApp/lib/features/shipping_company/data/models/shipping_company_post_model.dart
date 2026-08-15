import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/utils/thousands_separator_input_formatter.dart';

class ShippingCompanyPostModel {
  const ShippingCompanyPostModel({
    required this.id,
    required this.fromCountry,
    required this.fromPort,
    required this.toCountry,
    required this.toPort,
    required this.phoneNumber,
    required this.status,
    required this.isApproved,
    this.container20ftPriceUsd,
    this.container40ftPriceUsd,
    this.minDurationDays,
    this.maxDurationDays,
    this.details = '',
    this.publisherName = '',
    this.publisherImgPath,
    this.createdAt,
  });

  final int id;
  final String fromCountry;
  final String fromPort;
  final String toCountry;
  final String toPort;
  final double? container20ftPriceUsd;
  final double? container40ftPriceUsd;
  final String phoneNumber;
  final String status;
  final bool isApproved;
  final int? minDurationDays;
  final int? maxDurationDays;
  final String details;
  final String publisherName;
  final String? publisherImgPath;
  final DateTime? createdAt;

  bool get isActive => status.toLowerCase() == 'active' && isApproved;
  bool get isUnderReview => status.toLowerCase().contains('review') || !isApproved;
  bool get isRejected => status.toLowerCase() == 'rejected';

  factory ShippingCompanyPostModel.fromJson(Map<String, dynamic> json) {
    return ShippingCompanyPostModel(
      id: _toInt(json['id'] ?? json['Id']) ?? 0,
      fromCountry: _readString(json, const ['fromCountry', 'FromCountry']),
      fromPort: _readString(json, const ['fromPort', 'FromPort']),
      toCountry: _readString(json, const ['toCountry', 'ToCountry']),
      toPort: _readString(json, const ['toPort', 'ToPort']),
      container20ftPriceUsd: _toPositiveDouble(
        json['container20ftPriceUsd'] ?? json['Container20ftPriceUsd'],
      ),
      container40ftPriceUsd: _toPositiveDouble(
        json['container40ftPriceUsd'] ?? json['Container40ftPriceUsd'],
      ),
      phoneNumber: _readString(json, const ['phoneNumber', 'PhoneNumber']),
      status: _readString(json, const ['status', 'Status']),
      isApproved: json['isApproved'] == true || json['IsApproved'] == true,
      minDurationDays: _toInt(json['minDurationDays'] ?? json['MinDurationDays']),
      maxDurationDays: _toInt(json['maxDurationDays'] ?? json['MaxDurationDays']),
      details: _readString(json, const ['details', 'Details']),
      publisherName: _readString(json, const ['publisherName', 'PublisherName']),
      publisherImgPath: _resolveImagePath(
        json['publisherImgPath'] ?? json['PublisherImgPath'],
      ),
      createdAt: DateTime.tryParse(
        (json['createdAt'] ?? json['CreatedAt'])?.toString() ?? '',
      ),
    );
  }

  Map<String, dynamic> toRequestJson({required String phone}) => {
        'fromCountryName': fromCountry,
        'fromPortName': fromPort,
        'toCountryName': toCountry,
        'toPortName': toPort,
        'phoneNumber': phone,
        'container20ftPriceUsd': container20ftPriceUsd,
        'container40ftPriceUsd': container40ftPriceUsd,
        'minDurationDays': minDurationDays,
        'maxDurationDays': maxDurationDays,
        'details': details.isEmpty ? null : details,
      };

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static int? _toInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static String? _resolveImagePath(Object? path) {
    if (path == null) return null;
    final value = path.toString().trim();
    if (value.isEmpty) return null;
    if (value.startsWith('assets/')) return value;
    return ApiConstants.resolveMediaUrl(value);
  }

  static double? _toPositiveDouble(Object? value) {
    if (value == null) return null;
    final parsed = value is num
        ? value.toDouble()
        : ThousandsNumberInput.parseDouble(value.toString());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }
}

class ShippingCompanyStatsModel {
  const ShippingCompanyStatsModel({
    required this.activeCount,
    required this.underReviewCount,
    required this.rejectedCount,
  });

  final int activeCount;
  final int underReviewCount;
  final int rejectedCount;

  factory ShippingCompanyStatsModel.fromJson(Map<String, dynamic> json) {
    return ShippingCompanyStatsModel(
      activeCount: json['activeCount'] as int? ?? 0,
      underReviewCount: json['underReviewCount'] as int? ?? 0,
      rejectedCount: json['rejectedCount'] as int? ?? 0,
    );
  }
}

class ShippingCompanyDashboardModel {
  const ShippingCompanyDashboardModel({
    required this.companyName,
    required this.email,
    required this.phoneNumber,
    required this.commercialRegister,
    required this.taxNumber,
    required this.stats,
    required this.posts,
    this.imgPath,
  });

  final String companyName;
  final String email;
  final String phoneNumber;
  final String commercialRegister;
  final String taxNumber;
  final String? imgPath;
  final ShippingCompanyStatsModel stats;
  final List<ShippingCompanyPostModel> posts;

  factory ShippingCompanyDashboardModel.fromJson(Map<String, dynamic> json) {
    final postsRaw = json['posts'];
    return ShippingCompanyDashboardModel(
      companyName: json['companyName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      commercialRegister: json['commercialRegister']?.toString() ?? '',
      taxNumber: json['taxNumber']?.toString() ?? '',
      imgPath: _resolveAssetUrl(json['imgPath']),
      stats: ShippingCompanyStatsModel.fromJson(
        json['stats'] as Map<String, dynamic>? ?? const {},
      ),
      posts: postsRaw is List
          ? postsRaw
              .whereType<Map>()
              .map((e) => ShippingCompanyPostModel.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
    );
  }
}

String? _resolveAssetUrl(Object? path) {
  if (path == null) return null;
  final value = path.toString().trim();
  if (value.isEmpty) return null;
  if (value.startsWith('assets/')) return value;
  return ApiConstants.resolveMediaUrl(value);
}
