import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Opens admin live chat and auto-sends a structured Ask-for-price product summary.
class AskForPriceHelper {
  AskForPriceHelper._();

  static String buildMessage(MyListingProductModel product, S s) {
    final buffer = StringBuffer()
      ..writeln(s.askForPriceChatIntro)
      ..writeln()
      ..writeln('${s.productName}: ${product.productName}')
      ..writeln('${s.productCode}: ${product.productCode}')
      ..writeln('Product ID: ${product.productId}');

    if (product.categoryName.trim().isNotEmpty) {
      buffer.writeln('${s.category}: ${product.categoryName}');
    }
    if (product.productTypeName.trim().isNotEmpty) {
      buffer.writeln('Type: ${product.productTypeName}');
    }
    if (product.quantity.trim().isNotEmpty) {
      buffer.writeln(
        '${s.quantity}: ${product.quantity} ${product.unitName}'.trim(),
      );
    }
    if (product.description.trim().isNotEmpty) {
      buffer.writeln('${s.description}: ${product.description}');
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
