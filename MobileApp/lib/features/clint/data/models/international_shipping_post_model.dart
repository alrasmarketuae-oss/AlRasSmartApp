import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/utils/thousands_separator_input_formatter.dart';
import 'package:alrasmarket/features/shipping_company/data/models/shipping_company_post_model.dart';

class InternationalShippingPostModel {
  const InternationalShippingPostModel({
    required this.id,
    required this.fromCountry,
    required this.fromPort,
    required this.toCountry,
    required this.toPort,
    required this.priceUsd,
    required this.shippingCostUsd,
    required this.phoneNumber,
    required this.publisherUserId,
    required this.publisherName,
    this.container20ftPriceUsd,
    this.container40ftPriceUsd,
    this.minDurationDays,
    this.maxDurationDays,
    this.details = '',
    this.publisherImgPath,
    this.createdAt,
  });

  final int id;
  final String fromCountry;
  final String fromPort;
  final String toCountry;
  final String toPort;
  final double priceUsd;
  final double shippingCostUsd;
  final String phoneNumber;
  final double? container20ftPriceUsd;
  final double? container40ftPriceUsd;
  final String publisherUserId;
  final String publisherName;
  final int? minDurationDays;
  final int? maxDurationDays;
  final String details;
  final String? publisherImgPath;
  final DateTime? createdAt;

  factory InternationalShippingPostModel.fromShippingCompany(
    ShippingCompanyPostModel post, {
    String publisherName = '',
    String? publisherImgPath,
  }) {
    return InternationalShippingPostModel(
      id: post.id,
      fromCountry: post.fromCountry,
      fromPort: post.fromPort,
      toCountry: post.toCountry,
      toPort: post.toPort,
      priceUsd: post.container20ftPriceUsd ?? post.container40ftPriceUsd ?? 0,
      shippingCostUsd: 0,
      phoneNumber: post.phoneNumber,
      container20ftPriceUsd: post.container20ftPriceUsd,
      container40ftPriceUsd: post.container40ftPriceUsd,
      publisherUserId: '',
      publisherName: publisherName.isNotEmpty
          ? publisherName
          : post.publisherName,
      minDurationDays: post.minDurationDays,
      maxDurationDays: post.maxDurationDays,
      details: post.details,
      publisherImgPath: publisherImgPath ?? post.publisherImgPath,
      createdAt: post.createdAt,
    );
  }

  factory InternationalShippingPostModel.fromJson(Map<String, dynamic> json) {
    return InternationalShippingPostModel(
      id: _toInt(json['id'] ?? json['Id']) ?? 0,
      fromCountry: _readString(
        json,
        const ['fromCountry', 'FromCountry', 'fromCountryNameEn', 'FromCountryNameEn'],
      ),
      fromPort: _readString(
        json,
        const ['fromPort', 'FromPort', 'fromPortNameEn', 'FromPortNameEn'],
      ),
      toCountry: _readString(
        json,
        const ['toCountry', 'ToCountry', 'toCountryNameEn', 'ToCountryNameEn'],
      ),
      toPort: _readString(
        json,
        const ['toPort', 'ToPort', 'toPortNameEn', 'ToPortNameEn'],
      ),
      priceUsd: _toDouble(json['priceUsd'] ?? json['PriceUsd']) ?? 0,
      shippingCostUsd: _toDouble(json['shippingCostUsd'] ?? json['ShippingCostUsd']) ?? 0,
      phoneNumber: _readString(json, const ['phoneNumber', 'PhoneNumber']),
      container20ftPriceUsd: _toPositiveDouble(
        json['container20ftPriceUsd'] ?? json['Container20ftPriceUsd'],
      ),
      container40ftPriceUsd: _toPositiveDouble(
        json['container40ftPriceUsd'] ?? json['Container40ftPriceUsd'],
      ),
      publisherUserId: _readString(json, const ['publisherUserId', 'PublisherUserId']),
      publisherName: _readString(json, const ['publisherName', 'PublisherName']),
      minDurationDays: _toInt(json['minDurationDays'] ?? json['MinDurationDays']),
      maxDurationDays: _toInt(json['maxDurationDays'] ?? json['MaxDurationDays']),
      details: _readString(json, const ['details', 'Details']),
      publisherImgPath: _resolveImagePath(
        json['publisherImgPath'] ??
            json['PublisherImgPath'] ??
            json['imgPath'] ??
            json['ImgPath'] ??
            json['companyImagePath'] ??
            json['publisherImagePath'],
      ),
      createdAt: DateTime.tryParse(
        (json['createdAt'] ?? json['CreatedAt'])?.toString() ?? '',
      ),
    );
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static String? _resolveImagePath(Object? path) {
    if (path == null) return null;
    final value = path.toString().trim();
    if (value.isEmpty) return null;
    if (value.startsWith('assets/')) return value;
    return ApiConstants.resolveMediaUrl(value);
  }

  static double? _toDouble(Object? value) =>
      ThousandsNumberInput.parseDouble(value?.toString());

  static double? _toPositiveDouble(Object? value) {
    if (value == null) return null;
    final parsed = value is num
        ? value.toDouble()
        : ThousandsNumberInput.parseDouble(value.toString());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  static int? _toInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
