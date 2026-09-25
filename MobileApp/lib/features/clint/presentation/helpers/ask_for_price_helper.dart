import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/utils/product_price_formatter.dart';
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
    final imagePath =
        product.images.isNotEmpty ? product.images.first.trim() : '';

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

    // Customer-facing price after commissions (same numbers the client catalog shows).
    final customerPrice = ProductPriceFormatter.unitPriceLabel(
      product,
      preferRetail: product.preferRetailFromSearchListing,
      s: s,
    ).trim();
    if (customerPrice.isNotEmpty) {
      buffer.writeln('Customer Price: $customerPrice');
    }

    if (product.description.trim().isNotEmpty) {
      buffer.writeln('Description: ${product.description}');
    }
    if (product.ownerId.trim().isNotEmpty) {
      buffer.writeln('Supplier ID: ${product.ownerId}');
    }

    return buffer.toString().trim();
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
