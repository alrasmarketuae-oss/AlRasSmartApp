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

  /// Seller new-order taps should open Sales (مبيعاتي), not Purchases.
  static bool pendingOpenIncomingTab = false;

  /// Request-offer taps should open Incoming (الواردة) on Request ads.
  static bool pendingOpenRequestOffersTab = false;

  static Future<void> open(
    BuildContext context,
    AppNotificationModel item,
  ) async {
    final route = item.navigationRoute.toLowerCase();
    final referenceId = item.referenceId.trim();
    final title = item.title.toLowerCase();
    final typeName = item.typeName.toLowerCase().trim();
    final orderId = int.tryParse(referenceId);
    final looksLikeOrder = typeName == 'order' ||
        typeName == 'new_order' ||
        typeName == 'product_order' ||
        typeName.contains('order_status') ||
        typeName.contains('order_placed') ||
        typeName.contains('order_refund') ||
        typeName.contains('order_created') ||
        title.contains('new order') ||
        title.contains('طلب جديد');
    final isOrderStatusUpdate = typeName.contains('order_status') ||
        typeName.contains('order_refund') ||
        route == 'track_order';
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

    // Buyer status updates (e.g. Received) must open tracking, not My Ads/Account.
    if (isOrderStatusUpdate && orderId != null && orderId > 0) {
      openTrackOrder(context, orderId: orderId);
      return;
    }

    if (route == 'track_order' || route == 'orders') {
      openMyOrdersTab(
        context,
        highlightOrderId: orderId,
        openIncoming: typeName == 'new_order' || typeName == 'order',
        openRequestOffers: typeName == 'request_offer' || looksLikeRequestOffer,
      );
      return;
    }

    // Legacy payloads used my_offers for buyer request-order status updates.
    if (route == 'my_offers' && looksLikeOrder && orderId != null && orderId > 0) {
      openTrackOrder(context, orderId: orderId);
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
      if (orderId != null && orderId > 0 && typeName.contains('order_status')) {
        openTrackOrder(context, orderId: orderId);
        return;
      }
      openMyOrdersTab(
        context,
        highlightOrderId: orderId,
        openIncoming: typeName == 'new_order' || typeName == 'order',
        openRequestOffers: typeName == 'request_offer' || looksLikeRequestOffer,
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

  /// Opens My Orders, then pushes the order tracking screen for [orderId].
  static void openTrackOrder(BuildContext context, {required int orderId}) {
    openMyOrdersTab(context, highlightOrderId: orderId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navContext = AppRoutes.navigatorKey.currentContext ?? context;
      if (!navContext.mounted) return;
      navContext.push(
        AppRoutes.kTrackOrderView,
        extra: <String, dynamic>{'orderId': orderId},
      );
    });
  }

  /// Opens the bottom-bar My Orders tab and optionally highlights an order card.
  static void openMyOrdersTab(
    BuildContext context, {
    int? highlightOrderId,
    bool openIncoming = false,
    bool openRequestOffers = false,
  }) {
    pendingOpenIncomingTab = openIncoming;
    pendingOpenRequestOffersTab = openRequestOffers;
    if (highlightOrderId != null && highlightOrderId > 0) {
      pendingHighlightOrderId.value = highlightOrderId;
    }

    final auth = AuthService.instance;
    if (auth.isPersonalCustomerAccount) {
      sl<PersonCubit>().setTab(2);
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
