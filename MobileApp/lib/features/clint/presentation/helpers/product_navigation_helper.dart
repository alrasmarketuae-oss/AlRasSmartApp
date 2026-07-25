import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProductNavigationHelper {
  ProductNavigationHelper._();

  /// Personal customers always use the retail cart channel when the product
  /// supports retail. Companies keep wholesale Purchase Order for catalog ads.
  static bool resolvePreferRetailChannel(bool preferRetailChannel) {
    return preferRetailChannel ||
        AuthService.instance.isPersonalCustomerAccount;
  }

  /// [preferRetailChannel]: retail feed → Add to Cart (hybrid uses retail
  /// pricing). Home / category for companies → Purchase Order (hybrid wholesale).
  static void openDetails(
    BuildContext context,
    MyListingProductModel product, {
    bool? isOffer,
    bool preferRetailChannel = false,
  }) {
    final useRetailChannel = resolvePreferRetailChannel(preferRetailChannel);

    if (product.isRequestProduct) {
      context.push(
        AppRoutes.kRequestDetailsView,
        extra: {'product': product},
      );
      return;
    }

    // Retail channel: pure retail + hybrids with retail pricing → cart.
    if (useRetailChannel && product.isRetailFeedProduct) {
      context.push(
        AppRoutes.kRetailProductDetailsView,
        extra: {
          'product': product,
          'isOffer': false,
          'preferRetailChannel': true,
        },
      );
      return;
    }

    // Wholesale / category catalog (incl. hybrids): Purchase Order.
    if (product.isCategoryCatalogProduct) {
      context.push(AppRoutes.kBookingDetailsView, extra: {'product': product});
      return;
    }

    if (product.isPureRetailProduct) {
      context.push(
        AppRoutes.kRetailProductDetailsView,
        extra: {
          'product': product,
          'isOffer': false,
          'preferRetailChannel': true,
        },
      );
      return;
    }

    if (product.productTypeName.trim().toLowerCase() == 'booking' ||
        product.productTypeId == 2) {
      context.push(AppRoutes.kBookingDetailsView, extra: {'product': product});
      return;
    }

    final offer = isOffer ?? product.isOfferProduct;
    if (offer) {
      context.push(
        AppRoutes.kRetailProductDetailsView,
        extra: {'product': product, 'isOffer': true},
      );
      return;
    }

    context.push(
      AppRoutes.kRetailProductDetailsView,
      extra: {
        'product': product,
        'isOffer': false,
        'preferRetailChannel': useRetailChannel,
      },
    );
  }
}
