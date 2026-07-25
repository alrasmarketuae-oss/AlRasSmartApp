import 'package:alrasmarket/core/serveses/profile_service.dart';
import 'package:flutter/foundation.dart';

/// Uploads a locally picked profile image after the user is authenticated.
class PendingProfileImageUploader {
  PendingProfileImageUploader._();

  static String? _pendingPath;

  static void setPending(String? path) {
    final trimmed = path?.trim();
    _pendingPath = (trimmed != null && trimmed.isNotEmpty) ? trimmed : null;
  }

  static Future<void> uploadIfPending() async {
    final path = _pendingPath;
    if (path == null) return;
    _pendingPath = null;
    try {
      await ProfileService.instance.uploadMyProfileImage(path);
    } catch (e) {
      debugPrint('PendingProfileImageUploader failed: $e');
    }
  }
}
