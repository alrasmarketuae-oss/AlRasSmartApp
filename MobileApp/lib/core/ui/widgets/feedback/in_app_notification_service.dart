import 'dart:async';

import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/services/notification_alert_sound.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Top in-app banner shown while the app is in the foreground.
class InAppNotificationService {
  InAppNotificationService._();

  static final InAppNotificationService instance = InAppNotificationService._();

  OverlayEntry? _entry;
  Timer? _dismissTimer;

  void show({
    required String title,
    required String body,
    VoidCallback? onTap,
    Duration autoDismiss = const Duration(seconds: 6),
    bool playSound = true,
  }) {
    if (playSound) {
      unawaited(NotificationAlertSound.instance.playOnce());
    }

    _dismissTimer?.cancel();
    _remove();

    final context = AppRoutes.navigatorKey.currentContext;
    if (context == null) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _entry = OverlayEntry(
      builder: (ctx) {
        final top = MediaQuery.paddingOf(ctx).top + 8.h;
        return Positioned(
          top: top,
          left: 16.w,
          right: 16.w,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12.r),
            color: Colors.white,
            child: InkWell(
              borderRadius: BorderRadius.circular(12.r),
              onTap: () {
                _remove();
                onTap?.call();
              },
              child: Padding(
                padding: EdgeInsets.fromLTRB(14.w, 12.h, 8.w, 12.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: LightColor.defaultColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_active_outlined,
                        color: LightColor.defaultColor,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          if (body.trim().isNotEmpty) ...[
                            SizedBox(height: 4.h),
                            Text(
                              body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: LightColor.greyTextColor,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close, size: 18.sp),
                      onPressed: _remove,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_entry!);
    _dismissTimer = Timer(autoDismiss, _remove);
  }

  void _remove() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _entry?.remove();
    _entry = null;
  }
}
