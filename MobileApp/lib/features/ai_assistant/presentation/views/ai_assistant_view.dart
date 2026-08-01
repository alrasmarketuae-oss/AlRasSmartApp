import 'dart:async';

import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/features/ai_assistant/data/ai_assistant_realtime_service.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Assistant accent ramp, used across the header, avatars, and the send button
/// so the screen reads as an AI surface rather than a normal support chat.
const _aiGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [LightColor.defaultColor, LightColor.lightBlue],
);

class AiAssistantView extends StatefulWidget {
  const AiAssistantView({super.key});

  @override
  State<AiAssistantView> createState() => _AiAssistantViewState();
}

class _AiAssistantViewState extends State<AiAssistantView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  final _realtime = AiAssistantRealtimeService();
  Future<void>? _connectFuture;
  bool _isThinking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = S.of(context);
      setState(() {
        _messages.add(_ChatMessage(text: s.aiAssistantWelcome, isUser: false));
      });
      _connectFuture = _connect();
    });
  }

  @override
  void dispose() {
    unawaited(_realtime.close());
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isThinking) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _controller.clear();
      _isThinking = true;
    });
    _scrollToEnd();

    try {
      final language = Localizations.localeOf(context).languageCode == 'ar'
          ? 'ar'
          : 'en';
      await (_connectFuture ??= _connect());
      await _realtime.ask(message: text, language: language);
    } catch (_) {
      _connectFuture = null;
      _showConnectionError();
    }
    _scrollToEnd();
  }

  Future<void> _connect() async {
    await _realtime.connect(
      onThinking: (value) {
        if (!mounted) return;
        setState(() => _isThinking = value);
        _scrollToEnd();
      },
      onResponseStarted: () {
        if (!mounted) return;
        setState(() {
          _isThinking = false;
          _messages.add(_ChatMessage(text: '', isUser: false));
        });
      },
      onDelta: (value) {
        if (!mounted) return;
        setState(() {
          if (_messages.isEmpty || _messages.last.isUser) {
            _messages.add(_ChatMessage(text: value, isUser: false));
          } else {
            _messages.last.text += value;
          }
        });
        _scrollToEnd();
      },
      onCompleted: (answer) {
        if (!mounted) return;
        setState(() {
          _isThinking = false;
          if (answer.isNotEmpty &&
              (_messages.isEmpty ||
                  _messages.last.isUser ||
                  _messages.last.text.isEmpty)) {
            if (_messages.isNotEmpty && !_messages.last.isUser) {
              _messages.last.text = answer;
            } else {
              _messages.add(_ChatMessage(text: answer, isUser: false));
            }
          }
        });
        _scrollToEnd();
      },
      onError: (_) => _showConnectionError(),
    );
  }

  void _showConnectionError() {
    if (!mounted) return;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    setState(() {
      _isThinking = false;
      _messages.add(
        _ChatMessage(
          text: isAr
              ? 'تعذر الوصول للمساعد الآن. حاول مرة أخرى أو تواصل مع المحادثة المباشرة من الملف الشخصي.'
              : 'The assistant is unavailable right now. Please try again or use Live Chat from Profile.',
          isUser: false,
        ),
      );
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: Column(
        children: [
          const _AiChatHeader(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
              itemCount: _messages.length + (_isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isThinking && index == _messages.length) {
                  return const _ThinkingBubble();
                }
                return _MessageBubble(message: _messages[index]);
              },
            ),
          ),
          _AiComposer(
            controller: _controller,
            isThinking: _isThinking,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _AiChatHeader extends StatelessWidget {
  const _AiChatHeader();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      padding: EdgeInsets.fromLTRB(12.w, topInset + 10.h, 16.w, 16.h),
      decoration: BoxDecoration(
        gradient: _aiGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: LightColor.defaultColor.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (context.canPop())
                IconButton(
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tightFor(
                    width: 36.w,
                    height: 36.w,
                  ),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18.sp,
                    color: Colors.white,
                  ),
                ),
              SizedBox(width: 4.w),
              const _AiAvatar(size: 40, onDark: true),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.aiAssistantTitle,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Container(
                          width: 7.w,
                          height: 7.w,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6EE7A8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          s.aiAssistantFabLabel,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 14.sp,
                  color: Colors.white,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    s.aiAssistantSubtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      height: 1.4,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiAvatar extends StatelessWidget {
  const _AiAvatar({required this.size, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        gradient: onDark ? null : _aiGradient,
        color: onDark ? Colors.white.withValues(alpha: 0.22) : null,
        shape: BoxShape.circle,
        border: onDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1)
            : null,
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        size: (size * 0.5).sp,
        color: Colors.white,
      ),
    );
  }
}

class _ChatMessage {
  _ChatMessage({required this.text, required this.isUser});
  String text;
  final bool isUser;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final bubble = Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
      constraints: BoxConstraints(maxWidth: 0.72.sw),
      decoration: BoxDecoration(
        gradient: isUser ? _aiGradient : null,
        color: isUser ? null : Colors.white,
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(16.r),
          topEnd: Radius.circular(16.r),
          bottomStart: Radius.circular(isUser ? 16.r : 4.r),
          bottomEnd: Radius.circular(isUser ? 4.r : 16.r),
        ),
        border: isUser ? null : Border.all(color: const Color(0xFFE6EAF2)),
        boxShadow: [
          BoxShadow(
            color: isUser
                ? LightColor.defaultColor.withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: _LinkifiedMessageText(
        text: message.text,
        style: TextStyle(
          color: isUser ? Colors.white : const Color(0xFF1F2937),
          fontSize: 13.sp,
          height: 1.5,
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const _AiAvatar(size: 26),
            SizedBox(width: 8.w),
          ],
          Flexible(child: bubble),
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

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in _markdownLink.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      final label = match.group(1)!;
      final target = match.group(2)!;
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
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return Text.rich(TextSpan(style: style, children: spans));
  }

  Future<void> _openLink(String target) async {
    final uri = Uri.tryParse(target);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _ThinkingBubble extends StatefulWidget {
  const _ThinkingBubble();

  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _AiAvatar(size: 26),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadiusDirectional.only(
                topStart: Radius.circular(16.r),
                topEnd: Radius.circular(16.r),
                bottomEnd: Radius.circular(16.r),
                bottomStart: Radius.circular(4.r),
              ),
              border: Border.all(color: const Color(0xFFE6EAF2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.aiAssistantThinking,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                SizedBox(width: 8.w),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Row(
                      children: List.generate(3, (i) {
                        final t = (_controller.value + i * 0.2) % 1.0;
                        final opacity =
                            0.3 +
                            (0.7 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0));
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2.w),
                          child: Opacity(
                            opacity: opacity,
                            child: Container(
                              width: 6.w,
                              height: 6.w,
                              decoration: const BoxDecoration(
                                color: LightColor.defaultColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiComposer extends StatelessWidget {
  const _AiComposer({
    required this.controller,
    required this.isThinking,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isThinking;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE6EAF2))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  style: TextStyle(fontSize: 13.sp),
                  decoration: InputDecoration(
                    hintText: s.aiAssistantHint,
                    hintStyle: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF9AA3B2),
                    ),
                    prefixIcon: Icon(
                      Icons.auto_awesome_rounded,
                      size: 16.sp,
                      color: LightColor.defaultColor,
                    ),
                    prefixIconConstraints: BoxConstraints(minWidth: 38.w),
                    filled: true,
                    fillColor: const Color(0xFFF3F6FB),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.r),
                      borderSide: const BorderSide(color: Color(0xFFE6EAF2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.r),
                      borderSide: const BorderSide(
                        color: LightColor.defaultColor,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Opacity(
                opacity: isThinking ? 0.5 : 1,
                child: GestureDetector(
                  onTap: isThinking ? null : onSend,
                  child: Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      gradient: _aiGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: LightColor.defaultColor.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      size: 19.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
