import 'dart:io';

import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:flutter/foundation.dart';

/// Configures dart:io HTTP for CDN/API image loads (CachedNetworkImage, Image.network, videos).
void configureMediaHttpOverrides() {
  HttpOverrides.global = _MediaHttpOverrides(
    allowBadCertificates: kDebugMode || ApiConstants.isLocal,
  );
}

class _MediaHttpOverrides extends HttpOverrides {
  _MediaHttpOverrides({required this.allowBadCertificates});

  final bool allowBadCertificates;

  static const _userAgent =
      'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36 '
      'AlRasMarket/1.0';

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context)
      ..userAgent = _userAgent
      ..connectionTimeout = const Duration(seconds: 25)
      ..idleTimeout = const Duration(seconds: 30)
      ..autoUncompress = true;

    if (allowBadCertificates) {
      client.badCertificateCallback = (cert, host, port) => true;
    }
    return client;
  }
}
