class DomesticEmirateModel {
  const DomesticEmirateModel({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.priceAed,
  });

  final int id;
  final String nameEn;
  final String nameAr;
  final double priceAed;

  factory DomesticEmirateModel.fromJson(Map<String, dynamic> json) {
    return DomesticEmirateModel(
      id: _parseInt(json['id']),
      nameEn: json['emirateNameEn']?.toString() ?? '',
      nameAr: json['emirateNameAr']?.toString() ?? '',
      priceAed: _parseDouble(json['priceAed']),
    );
  }

  String displayName(bool isArabic) => isArabic && nameAr.isNotEmpty ? nameAr : nameEn;

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
