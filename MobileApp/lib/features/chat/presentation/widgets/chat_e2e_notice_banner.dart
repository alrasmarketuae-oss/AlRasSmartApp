import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shown once when the user first opens support chat.
class ChatE2eNoticeBanner extends StatefulWidget {
  const ChatE2eNoticeBanner({super.key});

  @override
  State<ChatE2eNoticeBanner> createState() => _ChatE2eNoticeBannerState();
}

class _ChatE2eNoticeBannerState extends State<ChatE2eNoticeBanner> {
  static const _prefsKey = 'support_chat_e2e_notice_seen_v1';
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_prefsKey) ?? false;
    if (!mounted) return;
    setState(() => _visible = !seen);
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
    if (!mounted) return;
    setState(() => _visible = false);
  }

  Future<void> _openLearnMore() async {
    final uri = Uri.parse(ApiConstants.encryptedMessagesInfoUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final s = S.of(context);
    return Material(
      color: const Color(0xFFEFF6FF),
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 10.h, 10.w, 10.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Icon(
                Icons.lock_outline_rounded,
                color: const Color(0xFF1D4ED8),
                size: 20.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.chatE2eNoticeTitle,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    s.chatE2eNoticeBody,
                    style: TextStyle(
                      fontSize: 12.sp,
                      height: 1.35,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  GestureDetector(
                    onTap: _openLearnMore,
                    child: Text(
                      s.chatE2eNoticeReadMore,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2563EB),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _dismiss,
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.close, size: 18.sp, color: const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
