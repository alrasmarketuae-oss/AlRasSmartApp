import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/features/clint/data/models/app_notification_model.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_details_opener.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/company_cubit.dart';
import 'package:alrasmarket/features/person/presentation/controller/cubit/person_cubit.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationNavigationHelper {
  NotificationNavigationHelper._();

  /// Pending My Orders card highlight (set on notification tap, consumed by list).
  static final ValueNotifier<int?> pendingHighlightOrderId =
      ValueNotifier<int?>(null);

  static Future<void> open(
    BuildContext context,
    AppNotificationModel item,
  ) async {
    final route = item.navigationRoute.toLowerCase();
    final referenceId = item.referenceId.trim();
    final title = item.title.toLowerCase();
    final typeName = item.typeName.toLowerCase().trim();
    final looksLikeOrder = typeName == 'order' ||
        typeName == 'new_order' ||
        typeName == 'product_order' ||
        typeName.contains('order_status') ||
        typeName.contains('order_placed') ||
        typeName.contains('order_refund') ||
        typeName.contains('order_created') ||
        title.contains('new order') ||
        title.contains('طلب جديد');
    // Only open the request-offers screen for real request-ad offers.
    // Legacy product-order pushes used type=request_offer + "New offer available".
    final looksLikeRequestOffer = title.contains('offer on your request') ||
        title.contains('عرض جديد على طلبك') ||
        title.contains('عرض على طلبك') ||
        (typeName == 'request_offer' &&
            !looksLikeOrder &&
            !title.contains('new offer available') &&
            title.trim() != 'عرض جديد متاح');

    if (route == 'profile') {
      context.push(AppRoutes.kEditProfileView);
      return;
    }

    if (route == 'track_order' || route == 'orders') {
      openMyOrdersTab(
        context,
        highlightOrderId: int.tryParse(referenceId),
      );
      return;
    }

    if (route == 'my_offers') {
      context.push(AppRoutes.kMyAdsView);
      return;
    }

    if (route == 'my_ads') {
      // Request-ad offers → offers page; product purchases → My Ads + highlight.
      if (looksLikeRequestOffer) {
        final companyCubit = sl<CompanyCubit>();
        final listing = companyCubit.findListingProduct(referenceId);
        final product = listing ??
            MyListingProductModel.notificationStub(productId: referenceId);
        context.push(
          AppRoutes.kAdRequestOffersView,
          extra: {'product': product},
        );
        return;
      }

      context.push(
        AppRoutes.kMyAdsView,
        extra: referenceId.isEmpty
            ? null
            : <String, dynamic>{'highlightProductId': referenceId},
      );
      return;
    }

    if (looksLikeOrder) {
      // Seller new-order rows usually carry productId as referenceId.
      if (typeName == 'new_order' ||
          typeName == 'product_order' ||
          typeName == 'order') {
        context.push(
          AppRoutes.kMyAdsView,
          extra: referenceId.isEmpty
              ? null
              : <String, dynamic>{'highlightProductId': referenceId},
        );
        return;
      }
      openMyOrdersTab(
        context,
        highlightOrderId: int.tryParse(referenceId),
      );
      return;
    }

    if (route == 'product-detail' || route == 'product_detail') {
      if (referenceId.isNotEmpty) {
        await ProductDetailsOpener.openByProductId(
          context,
          productId: referenceId,
        );
      } else {
        context.push(AppRoutes.kMyAdsView);
      }
      return;
    }

    if (route.contains('offer') && !looksLikeOrder && !looksLikeRequestOffer) {
      context.push(AppRoutes.kOffersServiceView);
      return;
    }

    if (route.contains('request')) {
      context.push(AppRoutes.kRequestsServiceView);
      return;
    }

    if (route.contains('chat')) {
      context.push(AppRoutes.kSupportChatView);
      return;
    }

    if (referenceId.isNotEmpty &&
        (route.contains('order') || int.tryParse(referenceId) != null)) {
      openMyOrdersTab(
        context,
        highlightOrderId: int.tryParse(referenceId),
      );
    }
  }

  /// Opens the bottom-bar My Orders tab and optionally highlights an order card.
  static void openMyOrdersTab(
    BuildContext context, {
    int? highlightOrderId,
  }) {
    if (highlightOrderId != null && highlightOrderId > 0) {
      pendingHighlightOrderId.value = highlightOrderId;
    }

    final auth = AuthService.instance;
    if (auth.isPersonalCustomerAccount) {
      sl<PersonCubit>().setTab(1);
      context.go(AppRoutes.kPersonHomeView);
      return;
    }

    if (auth.isSupplierAccount || auth.isCompanyCustomerAccount) {
      sl<CompanyCubit>().setTab(2);
      // Company customers share client home with company account flag.
      if (auth.isCompanyCustomerAccount) {
        sl<ClintCubit>().setTab(2);
        context.go(AppRoutes.kClientHomeView);
      } else {
        context.go(AppRoutes.kCompanyHomeView);
      }
      return;
    }

    sl<ClintCubit>().setTab(2);
    context.go(AppRoutes.kClientHomeView);
  }
}
