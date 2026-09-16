import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/helpers/ai_chat_heuristics.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/models/ai_chat_message.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/theme/ai_chat_colors.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/widgets/ai_product_listings.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/widgets/ai_support_callback_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class AiAvatar extends StatelessWidget {
  const AiAvatar({super.key, required this.size, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: onDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1)
            : Border.all(color: const Color(0xFFE6EAF2)),
        boxShadow: [
          BoxShadow(
            color: LightColor.defaultColor.withValues(alpha: 0.16),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        AppAssets.aiAgentIcon,
        fit: BoxFit.contain,
      ),
    );
  }
}

class AiSwipeToReply extends StatefulWidget {
  const AiSwipeToReply({
    super.key,
    required this.onReply,
    required this.child,
  });

  final VoidCallback onReply;
  final Widget child;

  @override
  State<AiSwipeToReply> createState() => _AiSwipeToReplyState();
}

class _AiSwipeToReplyState extends State<AiSwipeToReply> {
  double _dragDx = 0;
  bool _triggered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragDx = (_dragDx + details.delta.dx).clamp(-80.0, 80.0);
        });
        if (!_triggered && _dragDx.abs() >= 36) {
          _triggered = true;
          widget.onReply();
        }
      },
      onHorizontalDragEnd: (_) {
        setState(() {
          _dragDx = 0;
          _triggered = false;
        });
      },
      onHorizontalDragCancel: () {
        setState(() {
          _dragDx = 0;
          _triggered = false;
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_dragDx.abs() > 12)
            Align(
              alignment: _dragDx > 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Icon(
                  Icons.reply_rounded,
                  color: LightColor.defaultColor,
                  size: 22.sp,
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(_dragDx, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class AiMessageBubble extends StatelessWidget {
  const AiMessageBubble({
    super.key,
    required this.message,
    required this.colors,
    required this.onPickAdMedia,
    required this.uploadingAdMedia,
    this.sessionId,
    this.onSupportCallbackSubmitted,
  });

  final AiChatMessage message;
  final AiChatColors colors;
  final VoidCallback onPickAdMedia;
  final bool uploadingAdMedia;
  final String? sessionId;
  final VoidCallback? onSupportCallbackSubmitted;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    // Defensive: even if the hub flag was dropped mid-stream, show the form
    // when the assistant reply itself invites the user to leave contact details.
    final showSupportForm = !isUser &&
        (message.showSupportCallbackForm ||
            looksLikeSupportCallbackCue(message.text) ||
            looksLikeTemporaryAssistantFailure(message.text));
    final bubble = Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
      constraints: BoxConstraints(maxWidth: 0.72.sw),
      decoration: BoxDecoration(
        gradient: isUser ? aiGradient : null,
        color: isUser ? null : colors.assistantBubbleBg,
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(16.r),
          topEnd: Radius.circular(16.r),
          bottomStart: Radius.circular(isUser ? 16.r : 4.r),
          bottomEnd: Radius.circular(isUser ? 4.r : 16.r),
        ),
        border: isUser ? null : Border.all(color: colors.assistantBorder),
        boxShadow: [
          BoxShadow(
            color: isUser
                ? LightColor.defaultColor.withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: colors.isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser && message.thinkingSteps.isNotEmpty) ...[
              // Legacy history may still have stored thinking; show as plain prose only.
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Text(
                  message.thinkingSteps.join(' '),
                  style: TextStyle(
                    fontSize: 13.sp,
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                    color: colors.mutedText,
                  ),
                ),
              ),
            ],
            if (message.replyPreview != null &&
                message.replyPreview!.trim().isNotEmpty) ...[
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: isUser
                      ? Colors.white.withValues(alpha: 0.18)
                      : const Color(0xFFF3F6FB),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border(
                    left: BorderSide(
                      color: isUser ? Colors.white : LightColor.defaultColor,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  message.replyPreview!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    height: 1.3,
                    color: isUser
                        ? Colors.white.withValues(alpha: 0.92)
                        : colors.mutedText,
                  ),
                ),
              ),
            ],
            if (message.text.isNotEmpty)
              Directionality(
                textDirection: detectAiTextDirection(message.text),
                child: _LinkifiedMessageText(
                  text: message.text,
                  style: TextStyle(
                    color: isUser ? Colors.white : const Color(0xFF1F2937),
                    fontSize: 15.sp,
                    height: 1.5,
                  ),
                ),
              ),
            if (!isUser && message.showMediaUpload) ...[
              SizedBox(height: 10.h),
              OutlinedButton.icon(
                onPressed: uploadingAdMedia ? null : onPickAdMedia,
                icon: uploadingAdMedia
                    ? SizedBox(
                        width: 14.w,
                        height: 14.w,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.photo_library_outlined, size: 16.sp),
                label: Text(
                  isAr ? 'إضافة صور / فيديو للإعلان' : 'Add ad photos / video',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: LightColor.defaultColor,
                  side: BorderSide(
                    color: LightColor.defaultColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                const AiAvatar(size: 26),
                SizedBox(width: 8.w),
              ],
              Flexible(
                child: GestureDetector(
                  onLongPress: () async {
                    await Clipboard.setData(ClipboardData(text: message.text));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isAr ? 'تم نسخ الرسالة' : 'Message copied',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: bubble,
                ),
              ),
            ],
          ),
          if (showSupportForm)
            AiSupportCallbackForm(
              key: ValueKey(
                'support-${message.responseId ?? message.text.hashCode}',
              ),
              question: message.supportQuestion,
              sessionId: sessionId,
              onSubmitted: onSupportCallbackSubmitted,
            ),
          if (!isUser && message.listings.isNotEmpty)
            AiProductListings(
              key: ValueKey(
                'listings-${message.responseId ?? 0}-${message.listings.length}',
              ),
              products: message.listings,
            ),
        ],
      ),
    );
  }
}

class _LinkifiedMessageText extends StatelessWidget {
  const _LinkifiedMessageText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  static final RegExp _markdownLink = RegExp(
    r'\[([^\]]+)\]\(((?:https?://|mailto:)[^)]+)\)',
    caseSensitive: false,
  );

  static final RegExp _markdownBold = RegExp(r'\*\*(.+?)\*\*');

  static String _isolateLatinRuns(String input) {
    return input.replaceAllMapped(
      RegExp(r'[A-Za-z0-9][A-Za-z0-9_\-./@:#%&*+=\(\)\[\],!? ]*'),
      (match) {
        final value = match.group(0)?.trimRight() ?? '';
        if (value.isEmpty) return '';
        return '\u2066$value\u2069';
      },
    );
  }

  List<InlineSpan> _parseSegment(String segment) {
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in _markdownBold.allMatches(segment)) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(
            text: _isolateLatinRuns(segment.substring(cursor, match.start)),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: _isolateLatinRuns(match.group(1)!),
          style: style.copyWith(fontWeight: FontWeight.w700),
        ),
      );
      cursor = match.end;
    }
    if (cursor < segment.length) {
      spans.add(TextSpan(text: _isolateLatinRuns(segment.substring(cursor))));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in _markdownLink.allMatches(text)) {
      if (match.start > cursor) {
        spans.addAll(_parseSegment(text.substring(cursor, match.start)));
      }
      final label = match.group(1)!;
      final target = match.group(2)!;
      final isWeb = target.toLowerCase().startsWith('http://') ||
          target.toLowerCase().startsWith('https://');
      if (isWeb) {
        spans.addAll(_parseSegment(label));
      } else {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => _openLink(target),
              child: Text(
                label,
                style: style.copyWith(
                  color: LightColor.defaultColor,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: LightColor.defaultColor,
                ),
              ),
            ),
          ),
        );
      }
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.addAll(_parseSegment(text.substring(cursor)));
    }

    return Directionality(
      textDirection: detectAiTextDirection(text),
      child: Text.rich(TextSpan(style: style, children: spans)),
    );
  }

  Future<void> _openLink(String target) async {
    final uri = Uri.tryParse(target);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
