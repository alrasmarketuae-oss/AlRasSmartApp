import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/utils/thousands_separator_input_formatter.dart';

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
    required this.container20ftPriceUsd,
    required this.container40ftPriceUsd,
    required this.publisherUserId,
    required this.publisherName,
    this.minDurationDays,
    this.maxDurationDays,
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
  final double container20ftPriceUsd;
  final double container40ftPriceUsd;
  final String publisherUserId;
  final String publisherName;
  final int? minDurationDays;
  final int? maxDurationDays;
  final String? publisherImgPath;
  final DateTime? createdAt;

  factory InternationalShippingPostModel.fromJson(Map<String, dynamic> json) {
    return InternationalShippingPostModel(
      id: json['id'] as int? ?? 0,
      fromCountry: json['fromCountry']?.toString() ?? '',
      fromPort: json['fromPort']?.toString() ?? '',
      toCountry: json['toCountry']?.toString() ?? '',
      toPort: json['toPort']?.toString() ?? '',
      priceUsd: _toDouble(json['priceUsd']),
      shippingCostUsd: _toDouble(json['shippingCostUsd']),
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      container20ftPriceUsd: _toDouble(json['container20ftPriceUsd']),
      container40ftPriceUsd: _toDouble(json['container40ftPriceUsd']),
      publisherUserId: json['publisherUserId']?.toString() ?? '',
      publisherName: json['publisherName']?.toString() ?? '',
      minDurationDays: _toInt(json['minDurationDays']),
      maxDurationDays: _toInt(json['maxDurationDays']),
      publisherImgPath: _resolveImagePath(
        json['publisherImgPath'] ??
            json['imgPath'] ??
            json['ImgPath'] ??
            json['companyImagePath'] ??
            json['publisherImagePath'],
      ),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  static String? _resolveImagePath(Object? path) {
    if (path == null) return null;
    final value = path.toString().trim();
    if (value.isEmpty) return null;
    if (value.startsWith('assets/')) return value;
    return ApiConstants.resolveMediaUrl(value);
  }

  static double _toDouble(Object? value) =>
      ThousandsNumberInput.parseDoubleOrZero(value);

  static int? _toInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
