/// Parses Ask-for-price support-chat payloads shared with the admin dashboard.
class AskForPricePayload {
  const AskForPricePayload({
    required this.productId,
    this.imagePath,
    this.productName,
    this.productCode,
    this.supplierId,
    this.quantityLabel,
    this.customerPriceLabel,
  });

  final String productId;
  final String? imagePath;
  final String? productName;
  final String? productCode;
  final String? supplierId;
  final String? quantityLabel;
  /// Customer-facing unit price after commissions (stable English key in message).
  final String? customerPriceLabel;

  static const String productMarkerPrefix = 'ASK_FOR_PRICE_PRODUCT:';

  static final RegExp _marker =
      RegExp(r'ASK_FOR_PRICE_PRODUCT:\s*([0-9a-fA-F-]{36})', caseSensitive: false);
  static final RegExp _productIdLine =
      RegExp(r'(?:^|\n)\s*Product ID:\s*([0-9a-fA-F-]{36})', caseSensitive: false);
  static final RegExp _anyUuid = RegExp(
    r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
  );
  static final RegExp _imageLine =
      RegExp(r'(?:^|\n)\s*Image:\s*(.+)(?:\n|$)', caseSensitive: false);
  static final RegExp _nameLine = RegExp(
    r'(?:^|\n)\s*(?:Product Name|اسم المنتج|اسم الإعلان)\s*[:：]\s*(.+)(?:\n|$)',
    caseSensitive: false,
  );
  static final RegExp _codeLine = RegExp(
    r'(?:^|\n)\s*(?:Product Code|كود المنتج)\s*[:：]\s*(.+)(?:\n|$)',
    caseSensitive: false,
  );
  static final RegExp _supplierLine =
      RegExp(r'(?:^|\n)\s*Supplier ID:\s*([0-9a-fA-F-]{36})', caseSensitive: false);
  static final RegExp _quantityLine = RegExp(
    r'(?:^|\n)\s*(?:Quantity|الكمية|الكميه)\s*[:：]\s*(.+)(?:\n|$)',
    caseSensitive: false,
  );
  static final RegExp _customerPriceLine = RegExp(
    r'(?:^|\n)\s*(?:Customer Price|سعر العميل)\s*[:：]\s*(.+)(?:\n|$)',
    caseSensitive: false,
  );
  static final RegExp _askHint =
      RegExp(r'ask\s*for\s*price|طلب\s*سعر|اطلب\s*السعر|اسأل\s*عن\s*السعر', caseSensitive: false);

  static AskForPricePayload? tryParse(String? content) {
    final text = content?.trim() ?? '';
    if (text.isEmpty) return null;

    final markerMatch = _marker.firstMatch(text);
    final idLineMatch = _productIdLine.firstMatch(text);
    final hintMatch = _askHint.hasMatch(text);
    final uuidMatch = _anyUuid.firstMatch(text);

    final productId = (markerMatch?.group(1) ??
            idLineMatch?.group(1) ??
            (hintMatch ? uuidMatch?.group(0) : null))
        ?.trim();
    if (productId == null || productId.isEmpty) return null;

    String? line(RegExp re) => re.firstMatch(text)?.group(1)?.trim();

    return AskForPricePayload(
      productId: productId,
      imagePath: line(_imageLine),
      productName: line(_nameLine),
      productCode: line(_codeLine),
      supplierId: line(_supplierLine),
      quantityLabel: line(_quantityLine),
      customerPriceLabel: line(_customerPriceLine),
    );
  }

  static bool looksLike(String? content) => tryParse(content) != null;
}
