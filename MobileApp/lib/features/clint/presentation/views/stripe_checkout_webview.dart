import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class StripeCheckoutLauncher {
  StripeCheckoutLauncher._();

  static Future<bool> open(String checkoutUrl) async {
    final uri = Uri.tryParse(checkoutUrl);
    if (uri == null) return false;

    // Do not use canLaunchUrl on Android 11+ — it returns false without
    // manifest queries and blocks opening the browser.
    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (opened) return true;
    } catch (e) {
      debugPrint('[StripeCheckoutLauncher] externalApplication failed: $e');
    }

    try {
      return await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (e) {
      debugPrint('[StripeCheckoutLauncher] platformDefault failed: $e');
      return false;
    }
  }
}
