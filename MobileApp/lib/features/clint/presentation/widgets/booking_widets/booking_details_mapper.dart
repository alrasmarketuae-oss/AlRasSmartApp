import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/utils/product_quantity_formatter.dart';
import 'package:alrasmarket/core/utils/product_price_formatter.dart';
import 'package:alrasmarket/features/clint/presentation/models/product_media_item.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';

class BookingDetailsMapper {
  BookingDetailsMapper._();

  static List<String> imageUrls(MyListingProductModel product) {
    final urls = product.images
        .where(_isImagePath)
        .map(_resolveAssetUrl)
        .whereType<String>()
        .toList();
    if (urls.isNotEmpty) return urls;

    final primary = product.primaryImageUrl;
    if (primary != null && _isImagePath(primary)) return [primary];
    return urls;
  }

  static String? videoUrl(MyListingProductModel product) {
    return _resolveAssetUrl(product.videoPath);
  }

  static List<ProductMediaItem> mediaItems(MyListingProductModel product) {
    final items = <ProductMediaItem>[];

    for (final image in product.images) {
      if (!_isImagePath(image)) continue;
      final url = _resolveAssetUrl(image);
      if (url != null) {
        items.add(ProductMediaItem(url: url, kind: ProductMediaKind.image));
      }
    }

    for (final videoMetadata in product.allVideos) {
      final video = _resolveAssetUrl(videoMetadata.path);
      if (video != null) {
        items.add(
          ProductMediaItem(
            url: video,
            kind: ProductMediaKind.video,
            isMuted: videoMetadata.isMuted,
          ),
        );
      }
    }

    if (items.isEmpty) {
      final primary = product.primaryImageUrl;
      if (primary != null) {
        items.add(ProductMediaItem(url: primary, kind: ProductMediaKind.image));
      }
    }

    return items;
  }

  static String? cardThumbnailUrl(MyListingProductModel product) {
    final images = imageUrls(product);
    if (images.isNotEmpty) return images.first;
    return null;
  }

  static int? cardVideoDurationSeconds(MyListingProductModel product) {
    final raw = product.videoDurationSeconds.trim();
    final parsed = int.tryParse(raw);
    if (parsed != null && parsed > 0) return parsed;
    return null;
  }

  static bool _isImagePath(String path) {
    final lower = path.trim().toLowerCase();
    if (lower.isEmpty) return false;
    return !lower.endsWith('.mp4') &&
        !lower.endsWith('.mov') &&
        !lower.endsWith('.webm') &&
        !lower.endsWith('.m4v') &&
        !lower.endsWith('.avi') &&
        !lower.endsWith('.mkv');
  }

  static bool hasVideo(MyListingProductModel product) =>
      videoUrl(product) != null;

  static String? _resolveAssetUrl(String path) {
    final url = ApiConstants.resolveMediaUrl(path);
    return url.isEmpty ? null : url;
  }

  static String minimumOrderLabel(MyListingProductModel product, S s) {
    return ProductQuantityFormatter.minimumOrderLabel(product, s);
  }

  static String priceLabel(MyListingProductModel product, S s) {
    final amount = ProductPriceFormatter.amount(product);
    if (amount.isEmpty) return '${s.dollar} —';
    return ProductPriceFormatter.unitPriceLabel(product, s: s);
  }

  static List<String> specificationItems(MyListingProductModel product) {
    final lines = product.description
        .split(RegExp(r'[\n\r]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.length > 1) return lines;
    return const [];
  }

  static String shippingText(MyListingProductModel product) {
    final duration = product.shippingDuration.trim();
    if (duration.isNotEmpty) return duration;

    final notes = product.shipping.additionalShippingNotes.trim();
    if (notes.isNotEmpty) return notes;

    final route = product.shipping.displayRoute.trim();
    if (route.isNotEmpty) return route;

    return '';
  }

  static String supplierNotesText(MyListingProductModel product) {
    final notes = product.supplierNotes.trim();
    if (notes.isEmpty || isInternalModerationNote(notes)) return '';
    return notes;
  }

  /// Admin/auto-moderation system notes must not appear on public ad details.
  static bool isInternalModerationNote(String notes) {
    final normalized = notes.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return normalized.startsWith('auto-approved') ||
        normalized.contains('auto-approved:') ||
        normalized.startsWith('موافقة تلقائية') ||
        normalized.contains('auto approved') ||
        _isModerationRejectionNote(normalized);
  }

  /// Rejection reasons are stored in SupplierNotes while an ad is rejected; hide any
  /// stale value that survived into an approved ad (e.g. legacy data before the fix).
  static bool _isModerationRejectionNote(String normalized) {
    return normalized.contains('remove violations, then edit and resubmit') ||
        normalized.contains('contains insults/profanity') ||
        normalized.contains('أزل المخالفات ثم عدّل الإعلان') ||
        normalized.contains('يحتوي على ألفاظ نابية');
  }

  static String descriptionText(MyListingProductModel product) {
    return product.description.trim();
  }

  static String retailDescriptionText(MyListingProductModel product) {
    final retail = product.retailDescription.trim();
    if (retail.isNotEmpty) return retail;
    return product.description.trim();
  }

  static List<String> retailSpecificationItems(MyListingProductModel product) {
    final lines = specificationItemsFromText(retailDescriptionText(product));
    if (lines.length > 1) return lines;
    return const [];
  }

  static List<String> specificationItemsFromText(String text) {
    return text
        .split(RegExp(r'[\n\r]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
