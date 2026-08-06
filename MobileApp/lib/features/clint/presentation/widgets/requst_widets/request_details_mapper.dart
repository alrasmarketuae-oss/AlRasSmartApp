import 'package:alrasmarket/core/utils/string_display_format.dart';
import 'package:alrasmarket/core/utils/thousands_separator_input_formatter.dart';
import 'package:alrasmarket/core/utils/relative_time_formatter.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/company/presentation/models/create_ad_packing_options.dart';
import 'package:alrasmarket/generated/l10n.dart';

class RequestDetailsMapper {
  RequestDetailsMapper._();

  static String title(MyListingProductModel product, S s) {
    final name = product.productName.capitalizeFirst();
    return name.isEmpty ? s.product : name;
  }

  static String descriptionText(MyListingProductModel product) {
    return product.description.trim();
  }

  static List<String> specificationItems(MyListingProductModel product) {
    final description = product.description.trim();
    if (description.isEmpty) return [];

    // Optional notes block after a blank line; first block = required specs.
    final specsBlock = description.contains('\n\n')
        ? description.split(RegExp(r'\n\n+')).first
        : description;

    final lines = _lines(specsBlock);
    if (lines.isNotEmpty) return lines;
    return [specsBlock];
  }

  static String additionalNotesText(MyListingProductModel product) {
    final description = product.description.trim();
    if (description.contains('\n\n')) {
      return description.split(RegExp(r'\n\n+')).skip(1).join('\n\n').trim();
    }
    return '';
  }

  static String quantityText(
    MyListingProductModel product, {
    bool preferRetail = false,
  }) {
    final quantity =
        product.quantityForChannel(preferRetail: preferRetail).trim();
    if (quantity.isEmpty) return '';

    final unit = product.unitNameForChannel(preferRetail: preferRetail).trim();
    final displayQty = ThousandsNumberInput.formatRaw(
      quantity,
      allowDecimal: true,
    );
    final qty = displayQty.isEmpty ? quantity : displayQty;
    return unit.isEmpty ? qty : '$qty $unit';
  }

  static String deliveryAddress(MyListingProductModel product) {
    final port = product.shipping.routeToPort.trim();
    final country = product.shipping.routeToCountry.trim();
    if (port.isNotEmpty && country.isNotEmpty) return '$port, $country';
    if (country.isNotEmpty) return country;
    if (port.isNotEmpty) return port;

    return product.shipping.displayRoute.trim();
  }

  static String destinationPortName(MyListingProductModel product) =>
      product.shipping.routeToPort.trim();

  static String loadingPortName(MyListingProductModel product) =>
      product.shipping.routeFromPort.trim();

  static String destinationCountryName(MyListingProductModel product) =>
      product.shipping.routeToCountry.trim();

  static String originCountryName(MyListingProductModel product) =>
      product.shipping.routeFromCountry.trim();

  static bool isBookingFulfillment(MyListingProductModel product) {
    final notes = product.shipping.additionalShippingNotes.trim().toLowerCase();
    if (notes == 'booking') return true;
    return product.shipping.routeToPort.trim().isNotEmpty ||
        product.shipping.routeFromPort.trim().isNotEmpty;
  }

  static String specificationsText(MyListingProductModel product) {
    final items = specificationItems(product);
    if (items.isNotEmpty) return items.join(', ');
    return descriptionText(product);
  }

  static String packagingText(MyListingProductModel product) {
    return CreateAdPackingOptions.displayText(product.packaging);
  }

  static String packagingDisplay(
    MyListingProductModel product,
    S s, {
    required bool isAr,
    int? packagingOverride,
  }) {
    return CreateAdPackingOptions.displayText(
      packagingOverride ?? product.packaging,
      s: s,
    );
  }

  static String notesText(MyListingProductModel product) {
    final notes = additionalNotesText(product);
    if (notes.isNotEmpty) return notes;
    return '';
  }

  static String requestedReceiptDateText(MyListingProductModel product) {
    final duration = product.shippingDuration.trim();
    if (duration.isEmpty) return '';

    final parsedDate = DateTime.tryParse(duration);
    if (parsedDate != null) {
      final month = parsedDate.month.toString().padLeft(2, '0');
      final day = parsedDate.day.toString().padLeft(2, '0');
      return '${parsedDate.year}/$month/$day';
    }

    if (duration.contains('/') || duration.contains('-')) return duration;
    return '';
  }

  static String formattedPostingDate(MyListingProductModel product, S s) {
    return RelativeTimeFormatter.format(s, product.createdAt);
  }

  static List<String> _lines(String text) {
    return text
        .split(RegExp(r'[\n\r]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }
}
