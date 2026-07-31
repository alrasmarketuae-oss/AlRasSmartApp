import 'package:alrasmarket/core/router/where_to_go.dart';
import 'package:alrasmarket/features/auth/presentation/views/complet_register.dart';
import 'package:alrasmarket/features/auth/presentation/views/login_view.dart';
import 'package:alrasmarket/features/auth/presentation/views/otp_view.dart';
import 'package:alrasmarket/features/auth/presentation/views/recording_view.dart';
import 'package:alrasmarket/features/auth/presentation/views/under_review.dart';
import 'package:alrasmarket/features/clint/presentation/views/caregories_view.dart';
import 'package:alrasmarket/features/clint/presentation/views/category_products_view.dart';
import 'package:alrasmarket/features/clint/presentation/views/cart_view.dart';
import 'package:alrasmarket/features/clint/presentation/views/payment_cancel_view.dart';
import 'package:alrasmarket/features/clint/presentation/views/payment_success_view.dart';
import 'package:alrasmarket/features/clint/presentation/views/product_search_results_view.dart';
import 'package:alrasmarket/features/clint/presentation/views/home_layout.dart';
import 'package:alrasmarket/features/clint/data/models/my_order_model.dart';
import 'package:alrasmarket/features/clint/presentation/views/track_order_view.dart';
import 'package:alrasmarket/features/clint/presentation/views/profile_views/change_password.dart';
import 'package:alrasmarket/features/clint/presentation/views/profile_views/saved_addresses_view.dart';
import 'package:alrasmarket/features/clint/presentation/views/profile_views/saved_ads_view.dart';
import 'package:alrasmarket/features/clint/presentation/views/profile_views/edit_profile_view.dart';
import 'package:alrasmarket/features/clint/presentation/views/profile_views/language_screen.dart';
import 'package:alrasmarket/features/clint/presentation/views/profile_views/notification.dart';
import 'package:alrasmarket/features/clint/presentation/views/profile_views/privacy_policy.dart';
import 'package:alrasmarket/features/chat/presentation/views/support_chat_view.dart';
import 'package:alrasmarket/features/clint/presentation/views/profile_views/technical_support.dart';
import 'package:alrasmarket/features/clint/presentation/views/profile_views/supplier_balance_view.dart';
import 'package:alrasmarket/features/clint/presentation/views/screens/booking_views/booking_details.dart';
import 'package:alrasmarket/features/clint/presentation/views/screens/booking_views/booking_success.dart';
import 'package:alrasmarket/features/clint/presentation/views/screens/requsts_views/requst_details.dart';
import 'package:alrasmarket/features/clint/presentation/views/screens/requsts_views/submit_offer.dart';
import 'package:alrasmarket/features/clint/presentation/views/screens/requsts_views/submit_offer_success_view.dart';
import 'package:alrasmarket/features/clint/presentation/views/services_views/booking_service_view.dart';
import 'package:alrasmarket/features/clint/presentation/views/services_views/requsts_service_view.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/confirm_circal.dart';
import 'package:alrasmarket/features/company/presentation/views/home_layout.dart';
import 'package:alrasmarket/features/shipping_company/presentation/views/shipping_complet_register_view.dart';
import 'package:alrasmarket/features/shipping_company/presentation/views/shipping_home_layout.dart';
import 'package:alrasmarket/features/shipping_company/presentation/views/shipping_login_view.dart';
import 'package:alrasmarket/features/shipping_company/data/models/shipping_company_post_model.dart';
import 'package:alrasmarket/features/shipping_company/presentation/views/shipping_ad_form_view.dart';
import 'package:alrasmarket/features/shipping_company/presentation/views/shipping_register_view.dart';
import 'package:alrasmarket/features/company/presentation/views/ad_request_offers_view.dart';
import 'package:alrasmarket/features/company/presentation/views/my_ads_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/views/reset_password/check_email_screen.dart';
import '../../features/auth/presentation/views/reset_password/reset_password_screen.dart';
import '../../features/auth/presentation/views/register_view.dart';

import '../../features/clint/presentation/views/screens/booking_views/send_booking_order.dart';
import '../../features/clint/presentation/views/services_views/offers_service_view.dart';
import '../../features/clint/presentation/views/screens/retail_views/product_details.dart';
import '../../features/clint/presentation/views/services_views/retail_service_view.dart';
import '../../features/clint/presentation/views/services_views/shipping_price_service_view.dart';
import '../../features/person/presentation/views/person_home_layout.dart';

abstract class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static const String krecording = '/recording';
  //static const String kOnBoardingView = '/onBoardingView';
  static const String kLoginView = '/LoginView';
  static const String kForgotPasswordView = '/ForgotPasswordView';
  static const String kResetPasswordView = '/ResetPasswordView';
  //
  static const String kRegisterView = '/RegisterView';
  static const String kCompletRegisterView = '/CompletRegisterView';
  static const String kOtpVerificationView = '/OtpVerificationView';
  static const String kUnderReviewView = '/CompanyWaitingView';
  static const String kClientHomeView = '/ClientHomeView';
  static const String kCompanyHomeView = '/CompanyHomeView';
  static const String kShippingLoginView = '/ShippingLoginView';
  static const String kShippingRegisterView = '/ShippingRegisterView';
  static const String kShippingCompletRegisterView = '/ShippingCompletRegisterView';
  static const String kShippingCompanyHomeView = '/ShippingCompanyHomeView';
  static const String kShippingAddAdView = '/ShippingAddAdView';
  static const String kShippingEditAdView = '/ShippingEditAdView';
  static const String kShippingManageOffersView = '/ShippingManageOffersView';
  //clint categories view
  static const String kCategoriesView = '/CategoriesView';
  static const String kCategoryProductsView = '/CategoryProductsView';
  //clint services views
  static const String kBookingServiceView = '/BookingServiceView';
  static const String kOffersServiceView = '/OffersServiceView';

  static const String kRetailServiceView = '/RetailServiceView';
  static const String kShippingPriceServiceView = '/ShippingPriceServiceView';
  static const String kRequestsServiceView = '/RequestsServiceView';

  static const String kConfirmCircalView = '/ConfirmCircalView';
  //profile views
  static const String kEditProfileView = '/EditProfileView';
  static const String kChangePasswordView = '/ChangePasswordView';
  static const String kSavedAddressesView = '/SavedAddressesView';
  static const String kSavedAdsView = '/SavedAdsView';
  static const String kNotificationsView = '/NotificationsView';
  static const String kLanguageView = '/LanguageView';
  static const String kTermsAndConditions = '/TermsAndConditions';
  static const String kTechnicalSupportView = '/TechnicalSupportView';
  static const String kSupportChatView = '/SupportChatView';
  static const String kMyAdsView = '/MyAdsView';
  static const String kSupplierBalanceView = '/SupplierBalanceView';
  static const String kAdRequestOffersView = '/AdRequestOffersView';
  static const String kSubmitOfferView = '/SubmitOfferView';
  static const String kSubmitOfferSuccessView = '/SubmitOfferSuccessView';
  static const String kRequestDetailsView = '/RequestDetailsView';
  static const String kBookingDetailsView = '/BookingDetailsView';
  static const String kSendBookingOrderView = '/SendBookingOrderView';
  static const String kBookingSuccessView = '/BookingSuccessView';
  static const String kRetailProductDetailsView = '/RetailProductDetailsView';
  static const String kCartView = '/CartView';
  static const String kProductSearchResultsView = '/ProductSearchResultsView';
  static const String kTrackOrderView = '/TrackOrderView';
  static const String kPaymentSuccessView = '/payment-success';
  static const String kPaymentCancelView = '/payment-cancel';
  static const String kPersonHomeView = '/PersonHomeView';

  /// Path of the route that owns [context].
  ///
  /// Read from [GoRouterState] rather than the router configuration, whose uri
  /// deliberately ignores routes added by [GoRouter.push].
  static String currentLocation(BuildContext context) {
    try {
      return GoRouterState.of(context).uri.path;
    } catch (_) {
      return '';
    }
  }

  /// True when [path] is already the visible route, so pushing it again is a no-op.
  static bool isCurrent(BuildContext context, String path) =>
      currentLocation(context) == path;

  /// True when pushing [path] from [context] would duplicate a page: either it
  /// is already shown, or a previous tap already navigated away from it.
  static bool shouldSkipPush(BuildContext context, String path) =>
      isCurrent(context, path) || ModalRoute.of(context)?.isCurrent == false;

  static final router = GoRouter(
    navigatorKey: navigatorKey,
    redirect: (context, state) {
      final uri = state.uri;
      if (uri.scheme == 'alrasmarket') {
        if (uri.host == 'payment-success') {
          final sessionId = uri.queryParameters['session_id'] ?? '';
          return sessionId.isEmpty
              ? kPaymentSuccessView
              : '$kPaymentSuccessView?session_id=$sessionId';
        }
        if (uri.host == 'payment-cancel') {
          return kPaymentCancelView;
        }
      }

      // Important: do NOT force-redirect every route.
      // Only decide initial entry when app opens at "/".
      if (state.matchedLocation != '/') return null;

      return whereToGo();
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SizedBox.shrink()),

      GoRoute(
        path: krecording,
        builder: (context, state) {
          return const RecordingView(); //UnderReviewView(),
        },
      ),
      GoRoute(path: kLoginView, builder: (context, state) => const LoginView()),
      GoRoute(
        path: kForgotPasswordView,
        builder: (context, state) {
          final email = state.extra?.toString() ?? '';
          return CheckEmailScreen(initialEmail: email);
        },
      ),
      GoRoute(
        path: kResetPasswordView,
        builder: (context, state) {
          final email = state.extra?.toString() ?? '';
          return ResetPasswordScreen(email: email);
        },
      ),
      GoRoute(
        path: kRegisterView,
        builder: (context, state) {
          final extra = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : const <String, dynamic>{};
          return RegisterView(isSupplierCompany: extra['isCompany'] == true);
        },
      ),
      GoRoute(
        path: kCompletRegisterView,
        builder: (context, state) {
          final extra = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : const <String, dynamic>{};

          return CompletRegisterView(registrationData: extra);
        },
      ),
      GoRoute(
        path: kOtpVerificationView,
        builder: (context, state) {
          final extra = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : const <String, dynamic>{};
          final queryEmail = state.uri.queryParameters['email'] ?? '';
          return OtpVerificationView(
            email: extra['email']?.toString() ?? queryEmail,
          );
        },
      ),
      GoRoute(
        path: kClientHomeView,
        builder: (context, state) {
          return const HomeLayout();
        },
      ),

      GoRoute(
        path: kUnderReviewView,
        builder: (context, state) => const UnderReviewView(),
      ),
      GoRoute(
        path: kCompanyHomeView,
        builder: (context, state) => const CompanyHomeLayout(),
      ),
      GoRoute(
        path: kShippingLoginView,
        builder: (context, state) => const ShippingLoginView(),
      ),
      GoRoute(
        path: kShippingRegisterView,
        builder: (context, state) => const ShippingRegisterView(),
      ),
      GoRoute(
        path: kShippingCompletRegisterView,
        builder: (context, state) {
          final extra = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : const <String, dynamic>{};
          return ShippingCompletRegisterView(registrationData: extra);
        },
      ),
      GoRoute(
        path: kShippingCompanyHomeView,
        builder: (context, state) => const ShippingHomeLayout(),
      ),
      GoRoute(
        path: kShippingAddAdView,
        builder: (context, state) => const ShippingAdFormView(),
      ),
      GoRoute(
        path: kShippingEditAdView,
        builder: (context, state) {
          final post = state.extra;
          return ShippingAdFormView(
            existingPost: post is ShippingCompanyPostModel ? post : null,
          );
        },
      ),
      GoRoute(
        path: kShippingManageOffersView,
        builder: (context, state) => const ManageShippingOffersView(),
      ),
      GoRoute(
        path: kPersonHomeView,
        builder: (context, state) => const PersonHomeLayout(),
      ),
      GoRoute(
        path: kBookingServiceView,
        builder: (context, state) => const BookingServiceView(),
      ),
      GoRoute(
        path: kOffersServiceView,
        builder: (context, state) => const OffersServiceView(),
      ),
      GoRoute(
        path: kRetailServiceView,
        builder: (context, state) => const RetailServiceView(),
      ),
      GoRoute(
        path: kShippingPriceServiceView,
        builder: (context, state) => const ShippingPriceServiceView(),
      ),
      GoRoute(
        path: kCategoriesView,
        builder: (context, state) => const CategoriesView(),
      ),
      GoRoute(
        path: kCategoryProductsView,
        builder: (context, state) {
          final categoryId =
              int.tryParse(state.uri.queryParameters['categoryId'] ?? '') ?? 0;
          final categoryTitle =
              state.uri.queryParameters['title'] ?? 'Category';
          return CategoryProductsView(
            categoryId: categoryId,
            categoryTitle: categoryTitle,
          );
        },
      ),
      GoRoute(
        path: kRequestsServiceView,
        builder: (context, state) => const RequestsServiceView(),
      ),
      GoRoute(
        path: kConfirmCircalView,
        builder: (context, state) {
          final extra = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : const <String, dynamic>{};
          return ConfirmCircalView(
            productId: extra['productId'] as String?,
          );
        },
      ),
      GoRoute(
        path: kEditProfileView,
        builder: (context, state) => const EditProfileView(),
      ),
      GoRoute(
        path: kChangePasswordView,
        builder: (context, state) => const ChangePasswordView(),
      ),
      GoRoute(
        path: kSavedAddressesView,
        builder: (context, state) => const SavedAddressesView(),
      ),
      GoRoute(
        path: kSavedAdsView,
        builder: (context, state) => const SavedAdsView(),
      ),
      GoRoute(
        path: kNotificationsView,
        builder: (context, state) => const NotificationsView(),
      ),
      GoRoute(
        path: kLanguageView,
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: kTermsAndConditions,
        builder: (context, state) => const PrivacyPolicy(),
      ),
      GoRoute(
        path: kTechnicalSupportView,
        builder: (context, state) => const TechnicalSupportView(),
      ),
      GoRoute(
        path: kSupportChatView,
        builder: (context, state) => const SupportChatView(),
      ),
      GoRoute(
        path: kMyAdsView,
        builder: (context, state) {
          final extra = state.extra;
          String? highlightProductId;
          if (extra is Map) {
            highlightProductId =
                extra['highlightProductId']?.toString() ??
                extra['productId']?.toString();
          }
          return MyAdsView(highlightProductId: highlightProductId);
        },
      ),
      GoRoute(
        path: kSupplierBalanceView,
        builder: (context, state) => const SupplierBalanceView(),
      ),
      GoRoute(
        path: kAdRequestOffersView,
        builder: (context, state) {
          final extra = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : const <String, dynamic>{};
          return AdRequestOffersView(
            product: extra['product'],
            preferRetailPricing: extra['preferRetailPricing'] == true,
            preferCategoryLabel: extra['preferCategoryLabel'] == true,
            showBothPricingChannels: extra['showBothPricingChannels'] == true,
          );
        },
      ),
      GoRoute(
        path: kRequestDetailsView,
        builder: (context, state) {
          final extra = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : const <String, dynamic>{};
          return RequestDetailsView(product: extra['product']);
        },
      ),
      GoRoute(
        path: kSubmitOfferView,
        builder: (context, state) {
          final extra = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : const <String, dynamic>{};
          return SubmitOfferView(
            product: extra['product'],
            toUserId: extra['toUserId']?.toString() ?? '',
          );
        },
      ),
      GoRoute(
        path: kSubmitOfferSuccessView,
        builder: (context, state) => const SubmitOfferSuccessView(),
      ),
      GoRoute(
        path: kBookingDetailsView,
        builder: (context, state) {
          final extra = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : const <String, dynamic>{};
          return BookingDetailsView(product: extra['product']);
        },
      ),
      GoRoute(
        path: kSendBookingOrderView,
        builder: (context, state) {
          final extra = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : const <String, dynamic>{};
          return SendBookingOrderView(product: extra['product']);
        },
      ),
      GoRoute(
        path: kBookingSuccessView,
        builder: (context, state) {
          final extra = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : const <String, dynamic>{};
          final orderNumber = extra['orderNumber'] as String? ?? '12345';
          return BookingSuccessView(orderNumber: orderNumber);
        },
      ),
      GoRoute(
        path: kRetailProductDetailsView,
        builder: (context, state) {
          final extra = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : const <String, dynamic>{};
          return RetailProductDetailsView(
            product: extra['product'],
            isOffer: extra['isOffer'] as bool? ?? false,
            preferRetailChannel:
                extra['preferRetailChannel'] as bool? ?? false,
          );
        },
      ),
      GoRoute(path: kCartView, builder: (context, state) => const CartView()),
      GoRoute(
        path: kProductSearchResultsView,
        builder: (context, state) {
          final extra = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : const <String, dynamic>{};
          return ProductSearchResultsView(
            key: ValueKey(
              '${extra['query'] ?? ''}|${extra['imagePath'] ?? ''}|${extra['historyId'] ?? ''}|${extra['replayCached'] ?? false}',
            ),
            initialQuery: extra['query']?.toString(),
            imagePath: extra['imagePath']?.toString(),
            historyId: extra['historyId']?.toString(),
            replayCached: extra['replayCached'] == true,
          );
        },
      ),
      GoRoute(
        path: kTrackOrderView,
        builder: (context, state) {
          final extra = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : const <String, dynamic>{};
          final order = extra['order'];
          final orderId = int.tryParse(extra['orderId']?.toString() ?? '');
          return TrackOrderView(
            order: order is MyOrderModel ? order : null,
            orderId: orderId,
            showBuyerActions: extra['showBuyerActions'] != false,
          );
        },
      ),
      GoRoute(
        path: kPaymentSuccessView,
        builder: (context, state) {
          final sessionId = state.uri.queryParameters['session_id'] ?? '';
          return PaymentSuccessView(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: kPaymentCancelView,
        builder: (context, state) => const PaymentCancelView(),
      ),
    ],
  );
}
