/// Parses Ask-supplier price confirmation payloads shared with the admin dashboard.
class AskSupplierPricePayload {
  const AskSupplierPricePayload._({
    required this.kind,
    required this.productId,
    this.confirmed,
    this.productName,
    this.productCode,
    this.unitName,
    this.quantityLabel,
    this.supplierPriceLabel,
    this.newSupplierPriceLabel,
    this.imagePath,
  });

  factory AskSupplierPricePayload.ask({
    required String productId,
    String? productName,
    String? productCode,
    String? unitName,
    String? quantityLabel,
    String? supplierPriceLabel,
    String? imagePath,
  }) {
    return AskSupplierPricePayload._(
      kind: AskSupplierPayloadKind.ask,
      productId: productId,
      productName: productName,
      productCode: productCode,
      unitName: unitName,
      quantityLabel: quantityLabel,
      supplierPriceLabel: supplierPriceLabel,
      imagePath: imagePath,
    );
  }

  factory AskSupplierPricePayload.reply({
    required String productId,
    required bool confirmed,
    String? unitName,
    String? newSupplierPriceLabel,
  }) {
    return AskSupplierPricePayload._(
      kind: AskSupplierPayloadKind.reply,
      productId: productId,
      confirmed: confirmed,
      unitName: unitName,
      newSupplierPriceLabel: newSupplierPriceLabel,
    );
  }

  final AskSupplierPayloadKind kind;
  final String productId;
  final bool? confirmed;
  final String? productName;
  final String? productCode;
  final String? unitName;
  final String? quantityLabel;
  final String? supplierPriceLabel;
  final String? newSupplierPriceLabel;
  final String? imagePath;

  static const String productMarkerPrefix = 'ASK_SUPPLIER_PRODUCT:';

  static final RegExp _productMarker = RegExp(
    r'ASK_SUPPLIER_PRODUCT:\s*([0-9a-fA-F-]{36})',
    caseSensitive: false,
  );
  static final RegExp _nameLine = RegExp(
    r'(?:^|\n)\s*(?:Product Name|اسم المنتج|اسم الإعلان)\s*[:：]\s*(.+)(?:\n|$)',
    caseSensitive: false,
  );
  static final RegExp _codeLine = RegExp(
    r'(?:^|\n)\s*(?:Product Code|كود المنتج)\s*[:：]\s*(.+)(?:\n|$)',
    caseSensitive: false,
  );
  static final RegExp _unitLine = RegExp(
    r'(?:^|\n)\s*(?:Unit|الوحدة|الوحده)\s*[:：]\s*(.+)(?:\n|$)',
    caseSensitive: false,
  );
  static final RegExp _quantityLine = RegExp(
    r'(?:^|\n)\s*(?:Quantity|الكمية|الكميه)\s*[:：]\s*(.+)(?:\n|$)',
    caseSensitive: false,
  );
  static final RegExp _supplierPriceLine = RegExp(
    r'(?:^|\n)\s*(?:Supplier Price|سعر المورد)\s*[:：]\s*(.+)(?:\n|$)',
    caseSensitive: false,
  );
  static final RegExp _newSupplierPriceLine = RegExp(
    r'(?:^|\n)\s*(?:New Supplier Price|السعر الجديد)\s*[:：]\s*(.+)(?:\n|$)',
    caseSensitive: false,
  );
  static final RegExp _imageLine = RegExp(
    r'(?:^|\n)\s*Image:\s*(.+)(?:\n|$)',
    caseSensitive: false,
  );

  static AskSupplierPricePayload? tryParse(String? content) {
    final text = content?.trim() ?? '';
    if (text.isEmpty) return null;

    final productId = _productMarker.firstMatch(text)?.group(1)?.trim();
    if (productId == null || productId.isEmpty) return null;

    String? line(RegExp re) => re.firstMatch(text)?.group(1)?.trim();

    if (RegExp(r'ASK_SUPPLIER_REPLY:\s*YES', caseSensitive: false).hasMatch(text)) {
      return AskSupplierPricePayload.reply(
        productId: productId,
        confirmed: true,
        unitName: line(_unitLine),
      );
    }

    if (RegExp(r'ASK_SUPPLIER_REPLY:\s*NO', caseSensitive: false).hasMatch(text)) {
      return AskSupplierPricePayload.reply(
        productId: productId,
        confirmed: false,
        unitName: line(_unitLine),
        newSupplierPriceLabel: line(_newSupplierPriceLine),
      );
    }

    if (!RegExp(r'ASK_SUPPLIER_PRICE', caseSensitive: false).hasMatch(text)) {
      return null;
    }

    return AskSupplierPricePayload.ask(
      productId: productId,
      productName: line(_nameLine),
      productCode: line(_codeLine),
      unitName: line(_unitLine),
      quantityLabel: line(_quantityLine),
      supplierPriceLabel: line(_supplierPriceLine),
      imagePath: line(_imageLine),
    );
  }

  static bool looksLike(String? content) => tryParse(content) != null;

  static String buildYesReply({required String productId}) {
    return 'ASK_SUPPLIER_REPLY:YES\n$productMarkerPrefix$productId';
  }

  static String buildNoReply({
    required String productId,
    required double newSupplierPrice,
    String? unitName,
  }) {
    final lines = <String>[
      'ASK_SUPPLIER_REPLY:NO',
      '$productMarkerPrefix$productId',
      'New Supplier Price: $newSupplierPrice',
    ];
    final unit = unitName?.trim();
    if (unit != null && unit.isNotEmpty) {
      lines.add('Unit: $unit');
    }
    return lines.join('\n');
  }
}

enum AskSupplierPayloadKind { ask, reply }
