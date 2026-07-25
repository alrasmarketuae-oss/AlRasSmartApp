class GeoPortModel {
  const GeoPortModel({
    required this.id,
    required this.portNameEn,
    this.portNameAr,
    required this.unLocode,
  });

  final int id;
  final String portNameEn;
  final String? portNameAr;
  final String unLocode;

  /// Prefer English for create/edit ad geo matching (Arabic port names incomplete).
  String get englishName {
    final en = portNameEn.trim();
    if (en.isNotEmpty) return en;
    return portNameAr?.trim() ?? '';
  }

  String get displayName => englishName;

  factory GeoPortModel.fromJson(Map<String, dynamic> json) {
    return GeoPortModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      portNameEn: json['portNameEn']?.toString() ??
          json['PortNameEn']?.toString() ??
          '',
      portNameAr: json['portNameAr']?.toString() ??
          json['PortNameAr']?.toString(),
      unLocode: json['unLocode']?.toString() ??
          json['UnLocode']?.toString() ??
          '',
    );
  }
}
