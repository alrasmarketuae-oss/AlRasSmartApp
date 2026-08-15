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
      id: json['id'] as int? ?? 0,
      fromCountry: json['fromCountry']?.toString() ?? '',
      fromPort: json['fromPort']?.toString() ?? '',
      toCountry: json['toCountry']?.toString() ?? '',
      toPort: json['toPort']?.toString() ?? '',
      container20ftPriceUsd: _toPositiveDouble(json['container20ftPriceUsd']),
      container40ftPriceUsd: _toPositiveDouble(json['container40ftPriceUsd']),
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      isApproved: json['isApproved'] == true || json['IsApproved'] == true,
      minDurationDays: json['minDurationDays'] as int?,
      maxDurationDays: json['maxDurationDays'] as int?,
      details: json['details']?.toString() ?? '',
      publisherName: json['publisherName']?.toString() ?? '',
      publisherImgPath: _resolveImagePath(json['publisherImgPath']),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
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
