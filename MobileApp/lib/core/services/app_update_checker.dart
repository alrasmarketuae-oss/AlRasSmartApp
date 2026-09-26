import 'package:alrasmarket/core/helper/cach_helper.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum AppUpdateKind { none, soft, force }

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.kind,
    required this.latestVersion,
    required this.installedVersion,
    required this.storeUrl,
    this.messageAr,
    this.messageEn,
  });

  final AppUpdateKind kind;
  final String latestVersion;
  final String installedVersion;
  final String storeUrl;
  final String? messageAr;
  final String? messageEn;
}

/// Checks public `/settings/app-version` against the installed app version.
class AppUpdateChecker {
  AppUpdateChecker._();

  static const _dismissedKey = 'app_update_dismissed_version';
  static const _defaultAndroidStore =
      'https://play.google.com/store/apps/details?id=com.mergespice.alrasmarket';
  static const _defaultIosStore =
      'https://apps.apple.com/gb/app/al-ras-smart/id6795899781';

  static Future<AppUpdateInfo?> check() async {
    if (kIsWeb) return null;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return null;
    }

    try {
      final package = await PackageInfo.fromPlatform();
      final installed = package.version.trim();
      if (installed.isEmpty) return null;

      final response = await DioHelper.getData(
        url: ApiConstants.publicAppVersionEndPoint,
        receiveTimeout: const Duration(seconds: 8),
      );
      final data = response?.data;
      if (data is! Map) return null;

      final isIos = defaultTargetPlatform == TargetPlatform.iOS;
      final latest = _readString(
            data,
            isIos ? 'iosLatestVersion' : 'androidLatestVersion',
            isIos ? 'IosLatestVersion' : 'AndroidLatestVersion',
          ) ??
          '';
      final min = _readString(
            data,
            isIos ? 'iosMinVersion' : 'androidMinVersion',
            isIos ? 'IosMinVersion' : 'AndroidMinVersion',
          ) ??
          '';
      final storeUrl = _readString(
            data,
            isIos ? 'iosStoreUrl' : 'androidStoreUrl',
            isIos ? 'IosStoreUrl' : 'AndroidStoreUrl',
          ) ??
          (isIos ? _defaultIosStore : _defaultAndroidStore);
      final messageAr =
          _readString(data, 'messageAr', 'MessageAr') ??
          _readString(data, 'appUpdateMessageAr', 'AppUpdateMessageAr');
      final messageEn =
          _readString(data, 'messageEn', 'MessageEn') ??
          _readString(data, 'appUpdateMessageEn', 'AppUpdateMessageEn');

      final belowMin = min.isNotEmpty && _compareVersions(installed, min) < 0;
      final belowLatest =
          latest.isNotEmpty && _compareVersions(installed, latest) < 0;

      if (!belowMin && !belowLatest) return null;

      if (belowMin) {
        return AppUpdateInfo(
          kind: AppUpdateKind.force,
          latestVersion: latest.isNotEmpty ? latest : min,
          installedVersion: installed,
          storeUrl: storeUrl,
          messageAr: messageAr,
          messageEn: messageEn,
        );
      }

      // Soft update — skip if user already dismissed this latest version.
      final dismissed = CachHelper.getData(_dismissedKey)?.toString();
      if (dismissed != null &&
          dismissed.isNotEmpty &&
          _compareVersions(dismissed, latest) >= 0) {
        return null;
      }

      return AppUpdateInfo(
        kind: AppUpdateKind.soft,
        latestVersion: latest,
        installedVersion: installed,
        storeUrl: storeUrl,
        messageAr: messageAr,
        messageEn: messageEn,
      );
    } catch (e, st) {
      debugPrint('AppUpdateChecker failed: $e\n$st');
      return null;
    }
  }

  static Future<void> dismissSoftUpdate(String latestVersion) async {
    await CachHelper.saveData(key: _dismissedKey, value: latestVersion);
  }

  static String? _readString(Map data, String camel, String pascal) {
    final value = data[camel] ?? data[pascal];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  /// Returns &lt;0 if a &lt; b, 0 if equal, &gt;0 if a &gt; b.
  static int _compareVersions(String a, String b) {
    final left = a.trim().replaceFirst(RegExp(r'^[vV]'), '').split('.');
    final right = b.trim().replaceFirst(RegExp(r'^[vV]'), '').split('.');
    final len = left.length > right.length ? left.length : right.length;
    for (var i = 0; i < len; i++) {
      final l = i < left.length ? int.tryParse(left[i]) ?? 0 : 0;
      final r = i < right.length ? int.tryParse(right[i]) ?? 0 : 0;
      if (l != r) return l.compareTo(r);
    }
    return 0;
  }
}
