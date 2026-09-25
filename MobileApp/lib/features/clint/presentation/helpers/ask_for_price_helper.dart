import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/features/chat/presentation/helpers/ask_for_price_payload.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Opens admin live chat and auto-sends a structured Ask-for-price product summary.
class AskForPriceHelper {
  AskForPriceHelper._();

  /// Machine-readable marker parsed by mobile + admin dashboard chat bubbles.
  static const String productMarkerPrefix =
      AskForPricePayload.productMarkerPrefix;

  static String buildMessage(MyListingProductModel product, S s) {
    final imagePath = product.images
        .map((path) => path.trim())
        .firstWhere(
          (path) => path.isNotEmpty && !_looksLikeVideoPath(path),
          orElse: () => '',
        );
    final videoPath = imagePath.isNotEmpty
        ? ''
        : (product.allVideoPaths.isNotEmpty
            ? product.allVideoPaths.first.trim()
            : '');

    // English-stable keys so dashboard/mobile parsers stay locale-independent.
    final buffer = StringBuffer()
      ..writeln(s.askForPriceChatIntro)
      ..writeln('$productMarkerPrefix${product.productId}')
      ..writeln()
      ..writeln('Product Name: ${product.productName}')
      ..writeln('Product Code: ${product.productCode}')
      ..writeln('Product ID: ${product.productId}');

    if (imagePath.isNotEmpty) {
      buffer.writeln('Image: $imagePath');
    }
    if (videoPath.isNotEmpty) {
      buffer.writeln('Video: $videoPath');
    }
    if (product.categoryName.trim().isNotEmpty) {
      buffer.writeln('Category: ${product.categoryName}');
    }
    if (product.productTypeName.trim().isNotEmpty) {
      buffer.writeln('Type: ${product.productTypeName}');
    }
    if (product.quantity.trim().isNotEmpty) {
      buffer.writeln(
        'Quantity: ${product.quantity} ${product.unitName}'.trim(),
      );
    }

    // Never embed catalog prices — Ask for price means the buyer must not see amounts.

    if (product.description.trim().isNotEmpty) {
      buffer.writeln('Description: ${product.description}');
    }
    if (product.ownerId.trim().isNotEmpty) {
      buffer.writeln('Supplier ID: ${product.ownerId}');
    }

    return buffer.toString().trim();
  }

  static bool _looksLikeVideoPath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv');
  }

  static Future<void> openSupportChatWithProduct({
    required BuildContext context,
    required MyListingProductModel product,
  }) async {
    if (!AuthService.instance.isAuthenticated) {
      context.push(AppRoutes.kLoginView);
      return;
    }

    final s = S.of(context);
    final message = buildMessage(product, s);
    await context.push(
      AppRoutes.kSupportChatView,
      extra: {'initialMessage': message},
    );
  }
}
