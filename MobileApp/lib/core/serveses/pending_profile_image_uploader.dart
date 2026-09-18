import 'dart:async';

import 'package:alrasmarket/core/helper/cach_helper.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/serveses/profile_service.dart';
import 'package:flutter/foundation.dart';

/// Uploads a locally picked profile image after the user is authenticated.
class PendingProfileImageUploader {
  PendingProfileImageUploader._();

  static const _cacheKey = 'pending_profile_image_path';
  static String? _pendingPath;

  static void setPending(String? path) {
    final trimmed = path?.trim();
    _pendingPath = (trimmed != null && trimmed.isNotEmpty) ? trimmed : null;
    if (_pendingPath == null) {
      unawaited(CachHelper.removeData(_cacheKey));
    } else {
      unawaited(CachHelper.saveData(key: _cacheKey, value: _pendingPath));
    }
  }

  static Future<void> uploadIfPending() async {
    final path = _pendingPath ?? CachHelper.getData(_cacheKey)?.toString();
    if (path == null || path.trim().isEmpty) return;
    if (!AuthService.instance.isAuthenticated) {
      // Keep pending until a real session exists (e.g. after company approval).
      _pendingPath = path;
      return;
    }

    try {
      await ProfileService.instance.uploadMyProfileImage(path);
      _pendingPath = null;
      await CachHelper.removeData(_cacheKey);
    } catch (e) {
      // Keep path so a later login/approval can retry.
      _pendingPath = path;
      debugPrint('PendingProfileImageUploader failed: $e');
    }
  }
}
