import 'dart:io';

import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:flutter/foundation.dart';

/// Allows [Image.network] and other dart:io HTTP clients to load from
/// local HTTPS with self-signed certificates (debug / local API).
void configureDevHttpOverrides() {
  if (!kDebugMode && !ApiConstants.isLocal) return;
  HttpOverrides.global = _DevHttpOverrides();
}

class _DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}
