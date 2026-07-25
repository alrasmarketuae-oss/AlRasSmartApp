import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/cached_constants.dart';

/// Decides the initial home route from cached auth flags.
String whereToGo() {
  final hasToken = token != null && token!.isNotEmpty;
  final hasEmail = email != null && email!.isNotEmpty;
  final hasAccount = hasToken || hasEmail || isVerified != null;

  if (!hasAccount) {
    return AppRoutes.krecording;
  }

  // Full app access requires a real API token from a verified + approved account.
  if (!hasToken) {
    if (isVerified != true) {
      final em = email ?? '';
      return '${AppRoutes.kOtpVerificationView}?email=${Uri.encodeComponent(em)}';
    }
    if ((isCompanyAccount == true || isShippingCompanyAccount == true) &&
        isApproved != true) {
      return AppRoutes.kUnderReviewView;
    }
    return AppRoutes.krecording;
  }

  if (isVerified != true) {
    final em = email ?? '';
    return '${AppRoutes.kOtpVerificationView}?email=${Uri.encodeComponent(em)}';
  }

  if (isShippingCompanyAccount == true) {
    if (isApproved != true) {
      return AppRoutes.kUnderReviewView;
    }
    return AppRoutes.kShippingCompanyHomeView;
  }

  if (isCompanyAccount != true) {
    return AppRoutes.kPersonHomeView;
  }

  if (isApproved != true) {
    return AppRoutes.kUnderReviewView;
  }

  if (isCustomer == true) {
    return AppRoutes.kClientHomeView;
  }
  return AppRoutes.kCompanyHomeView;
}
