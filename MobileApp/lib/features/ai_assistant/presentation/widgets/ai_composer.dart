import 'dart:async';
import 'dart:io';

import 'package:alrasmarket/core/platform/app_paths.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/theme/ai_chat_colors.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/widgets/ai_ad_plan_form.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';

class AiComposer extends StatefulWidget {
  const AiComposer({
    super.key,
    required this.controller,
    required this.isThinking,
    required this.onSend,
    required this.colors,
    required this.draftImageCount,
    required this.hasDraftVideo,
    this.planMode = false,
    this.onPickAdMedia,
    this.uploadingAdMedia = false,
    this.replyPreview = '',
    this.onCancelReply,
    this.voiceConversationMode = false,
    this.assistantSpeaking = false,
    this.onVoiceTurnRetry,
    this.onListeningChanged,
    this.onTranscribingChanged,
  });

  final TextEditingController controller;
  final bool isThinking;
  final VoidCallback onSend;
  final AiChatColors colors;
  final int draftImageCount;
  final bool hasDraftVideo;
  final bool planMode;
  final VoidCallback? onPickAdMedia;
  final bool uploadingAdMedia;
  final String replyPreview;
  final VoidCallback? onCancelReply;
  final bool voiceConversationMode;
  final bool assistantSpeaking;
  final VoidCallback? onVoiceTurnRetry;
  final ValueChanged<bool>? onListeningChanged;
  final ValueChanged<bool>? onTranscribingChanged;

  @override
  State<AiComposer> createState() => AiComposerState();
}

class AiComposerState extends State<AiComposer> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _listening = false;
  bool _correcting = false;
  bool _awaitingConfirm = false;
  bool _finishing = false;
  bool _autoSendAfterTranscription = false;
  String _baseText = '';
  String? _recordingPath;
  StreamSubscription<Amplitude>? _amplitudeSub;
  Timer? _silenceTimer;
  Timer? _maxRecordingTimer;
  bool _speechDetected = false;
  DateTime? _recordingStartedAt;

  static const _speechThresholdDb = -42.0;
  static const _silenceDuration = Duration(milliseconds: 900);
  static const _minRecordingDuration = Duration(milliseconds: 450);
  static const _maxRecordingDuration = Duration(seconds: 45);

  bool get isListening => _listening;
  bool get isTranscribing => _correcting;

  Future<void> finishVoiceTurn() => _finishListening();

  Future<void> beginVoiceTurn({bool autoSend = false}) async {
    if (!mounted || widget.isThinking || widget.assistantSpeaking) return;
    if (_listening || _correcting) return;
    _autoSendAfterTranscription = autoSend;
    await _toggleVoice();
  }

  void cancelVoiceCapture() {
    if (_listening || _correcting || _awaitingConfirm) {
      _cancelVoice();
    }
  }

  @override
  void dispose() {
    _stopVoiceActivityDetection();
    if (_listening) {
      unawaited(_recorder.stop());
    }
    unawaited(_recorder.dispose());
    super.dispose();
  }

  void _startVoiceActivityDetection() {
    _stopVoiceActivityDetection();
    _speechDetected = false;
    _recordingStartedAt = DateTime.now();

    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 120))
        .listen(_onVoiceAmplitude);

    _maxRecordingTimer = Timer(_maxRecordingDuration, () {
      if (_listening && mounted) {
        unawaited(_finishListening());
      }
    });
  }

  void _stopVoiceActivityDetection() {
    _amplitudeSub?.cancel();
    _amplitudeSub = null;
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _maxRecordingTimer?.cancel();
    _maxRecordingTimer = null;
    _speechDetected = false;
    _recordingStartedAt = null;
  }

  void _onVoiceAmplitude(Amplitude amp) {
    if (!_listening || !mounted) return;

    if (amp.current > _speechThresholdDb) {
      _speechDetected = true;
      _silenceTimer?.cancel();
      _silenceTimer = null;
      return;
    }

    if (!_speechDetected) return;

    final started = _recordingStartedAt;
    if (started != null &&
        DateTime.now().difference(started) < _minRecordingDuration) {
      return;
    }

    if (_silenceTimer?.isActive ?? false) return;

    _silenceTimer = Timer(_silenceDuration, () {
      if (_listening && _speechDetected && mounted) {
        unawaited(_finishListening());
      }
    });
  }

  Future<void> _toggleVoice() async {
    final s = S.of(context);
    if (widget.isThinking || _correcting || widget.assistantSpeaking) return;

    if (_listening) {
      await _finishListening();
      return;
    }

    if (!await _recorder.hasPermission()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.aiAssistantVoiceUnavailable)),
      );
      return;
    }

    _baseText = widget.controller.text.trim();
    final dirPath = await appTemporaryPath();
    if (dirPath == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.aiAssistantVoiceUnavailable)),
      );
      return;
    }
    final filePath =
        p.join(dirPath, 'ai_voice_${DateTime.now().millisecondsSinceEpoch}.m4a');

    try {
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1),
        path: filePath,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.aiAssistantVoiceUnavailable)),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _listening = true;
      _awaitingConfirm = false;
      _correcting = false;
      _recordingPath = filePath;
      widget.controller.text = _baseText;
    });
    widget.onListeningChanged?.call(true);

    if (widget.voiceConversationMode && _autoSendAfterTranscription) {
      _startVoiceActivityDetection();
    }
  }

  Future<void> _finishListening() async {
    if (_finishing) return;
    if (!_listening && !_awaitingConfirm) return;
    _finishing = true;
    _stopVoiceActivityDetection();

    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {
      path = _recordingPath;
    }

    if (!mounted) {
      _finishing = false;
      return;
    }

    setState(() {
      _listening = false;
      _correcting = true;
      _awaitingConfirm = false;
    });
    widget.onListeningChanged?.call(false);
    widget.onTranscribingChanged?.call(true);

    var finalSpoken = '';
    final audioPath = path ?? _recordingPath;
    if (audioPath != null && await File(audioPath).exists()) {
      try {
        if (!mounted) {
          _finishing = false;
          return;
        }
        final language =
            Localizations.localeOf(context).languageCode == 'ar' ? 'ar' : 'en';
        final formData = FormData.fromMap({
          'language': language,
          'audio': await MultipartFile.fromFile(
            audioPath,
            filename: p.basename(audioPath),
            contentType: MediaType('audio', 'mp4'),
          ),
        });
        final response = await DioHelper.uploadFile(
          url: ApiConstants.aiAssistantTranscribeVoiceEndPoint,
          formData: formData,
          token: AuthService.instance.currentToken,
        );
        final data = response?.data;
        if (data is Map) {
          final transcribed = data['text']?.toString().trim();
          if (transcribed != null && transcribed.isNotEmpty) {
            finalSpoken = transcribed;
          }
        }
      } catch (_) {
        // Keep empty / base text if transcription fails.
      } finally {
        try {
          await File(audioPath).delete();
        } catch (_) {}
      }
    }

    _recordingPath = null;

    if (!mounted) {
      _finishing = false;
      return;
    }

    if (finalSpoken.isEmpty) {
      final retryVoiceLoop =
          widget.voiceConversationMode && _autoSendAfterTranscription;
      setState(() {
        _correcting = false;
        _awaitingConfirm = false;
        _autoSendAfterTranscription = false;
        widget.controller.text = _baseText;
        widget.controller.selection = TextSelection.collapsed(
          offset: widget.controller.text.length,
        );
      });
      widget.onTranscribingChanged?.call(false);
      if (retryVoiceLoop) {
        widget.onVoiceTurnRetry?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).aiAssistantVoiceUnavailable)),
        );
      }
      _finishing = false;
      return;
    }

    final combined = [
      if (_baseText.isNotEmpty) _baseText,
      finalSpoken,
    ].join(' ').trim();

    if (_autoSendAfterTranscription && combined.isNotEmpty) {
      _autoSendAfterTranscription = false;
      setState(() {
        _correcting = false;
        _awaitingConfirm = false;
        widget.controller.text = combined;
        widget.controller.selection = TextSelection.collapsed(
          offset: widget.controller.text.length,
        );
      });
      widget.onTranscribingChanged?.call(false);
      _finishing = false;
      widget.onSend();
      return;
    }

    setState(() {
      _correcting = false;
      _awaitingConfirm = combined.isNotEmpty;
      widget.controller.text = combined;
      widget.controller.selection = TextSelection.collapsed(
        offset: widget.controller.text.length,
      );
    });
    widget.onTranscribingChanged?.call(false);
    _finishing = false;
  }

  void _cancelVoice() {
    _stopVoiceActivityDetection();
    unawaited(() async {
      try {
        final path = await _recorder.stop();
        final victim = path ?? _recordingPath;
        if (victim != null) {
          try {
            await File(victim).delete();
          } catch (_) {}
        }
      } catch (_) {}
    }());
    setState(() {
      _listening = false;
      _correcting = false;
      _awaitingConfirm = false;
      _finishing = false;
      _autoSendAfterTranscription = false;
      _recordingPath = null;
      widget.controller.text = _baseText;
      widget.controller.selection = TextSelection.collapsed(
        offset: widget.controller.text.length,
      );
    });
    widget.onListeningChanged?.call(false);
    widget.onTranscribingChanged?.call(false);
  }

  void _confirmSend() {
    setState(() {
      _listening = false;
      _correcting = false;
      _awaitingConfirm = false;
      _recordingPath = null;
    });
    widget.onSend();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final showStatus = _listening ||
        _correcting ||
        (_awaitingConfirm && !widget.voiceConversationMode) ||
        (widget.voiceConversationMode && widget.assistantSpeaking);
    return Container(
      decoration: BoxDecoration(
        color: widget.planMode
            ? const Color(0xFF2A2208)
            : widget.colors.composerBg,
        border: Border(
          top: BorderSide(
            color: widget.planMode
                ? AiAdPlanColors.border.withValues(alpha: 0.45)
                : widget.colors.composerBorder,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.voiceConversationMode)
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      widget.assistantSpeaking
                          ? (isAr ? 'المساعد بيتكلم…' : 'Assistant is speaking…')
                          : _listening
                              ? (isAr ? 'محادثة صوتية — تكلم الآن' : 'Voice chat — speak now')
                              : _correcting
                                  ? (isAr ? 'جاري فهم صوتك…' : 'Understanding your voice…')
                                  : (isAr
                                      ? 'محادثة صوتية شغّالة'
                                      : 'Voice conversation is on'),
                      style: TextStyle(
                        color: widget.assistantSpeaking
                            ? LightColor.defaultColor
                            : const Color(0xFFE11D48),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              if (widget.planMode)
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      isAr
                          ? 'وضع الخطة — اكتب البيانات في الشات'
                          : 'Plan mode — type the details in chat',
                      style: TextStyle(
                        color: AiAdPlanColors.border,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              if (widget.replyPreview.trim().isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.fromLTRB(12.w, 8.h, 4.w, 8.h),
                  decoration: BoxDecoration(
                    color: widget.planMode
                        ? const Color(0xFF3A2F10)
                        : const Color(0xFFF3F6FB),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border(
                      left: BorderSide(
                        color: LightColor.defaultColor,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.reply_rounded,
                        size: 18.sp,
                        color: LightColor.defaultColor,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.aiAssistantReplyTo,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: LightColor.defaultColor,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              widget.replyPreview.trim(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.sp,
                                height: 1.3,
                                color: widget.colors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: s.aiAssistantCancelReply,
                        onPressed: widget.onCancelReply,
                        icon: Icon(Icons.close_rounded, size: 18.sp),
                      ),
                    ],
                  ),
                ),
              if (widget.draftImageCount > 0 || widget.hasDraftVideo)
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
                    children: [
                      if (widget.draftImageCount > 0)
                        _AttachmentChip(
                          icon: Icons.image_outlined,
                          label: isAr
                              ? (widget.planMode
                                  ? '${widget.draftImageCount} صورة مرفقة'
                                  : '${widget.draftImageCount} بطاقة عمل')
                              : (widget.planMode
                                  ? '${widget.draftImageCount} image(s) attached'
                                  : '${widget.draftImageCount} business card(s)'),
                          colors: widget.colors,
                        ),
                      if (widget.hasDraftVideo)
                        _AttachmentChip(
                          icon: Icons.videocam_outlined,
                          label: isAr ? 'فيديو مرفق' : 'Video attached',
                          colors: widget.colors,
                        ),
                    ],
                  ),
                ),
              if (showStatus)
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    children: [
                      if (_correcting)
                        SizedBox(
                          width: 14.w,
                          height: 14.w,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          _listening
                              ? Icons.graphic_eq_rounded
                              : Icons.edit_note_rounded,
                          size: 16.sp,
                          color: _listening
                              ? const Color(0xFFE11D48)
                              : LightColor.defaultColor,
                        ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          widget.assistantSpeaking
                              ? (isAr ? 'المساعد بيتكلم…' : 'Assistant is speaking…')
                              : _listening
                                  ? (widget.voiceConversationMode
                                      ? s.aiAssistantListening
                                      : s.aiAssistantListening)
                                  : _correcting
                                      ? s.aiAssistantVoiceCorrecting
                                      : s.aiAssistantVoiceHint,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: _listening
                                ? const Color(0xFFE11D48)
                                : widget.colors.mutedText,
                          ),
                        ),
                      ),
                      if (_awaitingConfirm && !_correcting && !widget.voiceConversationMode) ...[
                        TextButton(
                          onPressed: _cancelVoice,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF64748B),
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                            minimumSize: Size(0, 32.h),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            s.aiAssistantVoiceCancel,
                            style: TextStyle(fontSize: 12.sp),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        TextButton(
                          onPressed: widget.isThinking ? null : _confirmSend,
                          style: TextButton.styleFrom(
                            foregroundColor: LightColor.defaultColor,
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                            minimumSize: Size(0, 32.h),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            s.aiAssistantVoiceSend,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.onPickAdMedia != null) ...[
                    GestureDetector(
                      onTap: (widget.isThinking ||
                              widget.uploadingAdMedia ||
                              _listening ||
                              _correcting)
                          ? null
                          : widget.onPickAdMedia,
                      child: Container(
                        width: 44.w,
                        height: 44.w,
                        decoration: BoxDecoration(
                          color: widget.planMode
                              ? AiAdPlanColors.accent.withValues(alpha: 0.18)
                              : (widget.colors.isDark
                                  ? const Color(0xFF243044)
                                  : const Color(0xFFE8F1FC)),
                          shape: BoxShape.circle,
                          border: widget.planMode
                              ? Border.all(color: AiAdPlanColors.border)
                              : null,
                        ),
                        child: widget.uploadingAdMedia
                            ? Padding(
                                padding: EdgeInsets.all(12.w),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.add_a_photo_outlined,
                                size: 22.sp,
                                color: widget.planMode
                                    ? AiAdPlanColors.accentDark
                                    : LightColor.defaultColor,
                              ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                  ],
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      minLines: 1,
                      maxLines: 4,
                      enabled: !_listening && !_correcting,
                      keyboardAppearance: widget.colors.isDark
                          ? Brightness.dark
                          : Brightness.light,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        if (_awaitingConfirm) {
                          _confirmSend();
                        } else if (!_listening && !_correcting) {
                          widget.onSend();
                        }
                      },
                      style: TextStyle(
                        inherit: false,
                        fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                        fontSize: 15.sp,
                        height: 1.35,
                        color: widget.colors.primaryText,
                      ),
                      cursorColor: LightColor.defaultColor,
                      decoration: InputDecoration(
                        hintText: s.aiAssistantHint,
                        hintStyle: TextStyle(
                          inherit: false,
                          fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          fontSize: 13.sp,
                          color: widget.colors.mutedText,
                        ),
                        prefixIcon: Padding(
                          padding: EdgeInsetsDirectional.only(
                            start: 10.w,
                            end: 4.w,
                          ),
                          child: Image.asset(
                            AppAssets.aiAgentIcon,
                            width: 20.w,
                            height: 20.w,
                            fit: BoxFit.contain,
                          ),
                        ),
                        prefixIconConstraints: BoxConstraints(minWidth: 38.w),
                        filled: true,
                        fillColor: _listening
                            ? (widget.colors.isDark
                                ? const Color(0xFF3B1520)
                                : const Color(0xFFFFF1F2))
                            : (widget.colors.isDark
                                ? const Color(0xFF1B2433)
                                : const Color(0xFFF3F6FB)),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 12.h,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.r),
                          borderSide: BorderSide(color: widget.colors.composerBorder),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.r),
                          borderSide: BorderSide(
                            color: _listening
                                ? const Color(0xFFFECACA)
                                : widget.colors.composerBorder,
                          ),
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
                  GestureDetector(
                    onTap: (widget.isThinking ||
                            _correcting ||
                            widget.assistantSpeaking)
                        ? null
                        : _toggleVoice,
                    child: Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        color: _listening
                            ? const Color(0xFFE11D48)
                            : widget.voiceConversationMode
                                ? LightColor.defaultColor.withValues(alpha: 0.18)
                                : (widget.colors.isDark
                                    ? const Color(0xFF243044)
                                    : const Color(0xFFE8F1FC)),
                        shape: BoxShape.circle,
                        border: widget.voiceConversationMode && !_listening
                            ? Border.all(color: LightColor.defaultColor)
                            : null,
                      ),
                      child: Icon(
                        _listening ? Icons.stop_rounded : Icons.mic_none_rounded,
                        size: 22.sp,
                        color: _listening
                            ? Colors.white
                            : LightColor.defaultColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Opacity(
                    opacity: (widget.isThinking || _correcting || _listening)
                        ? 0.5
                        : 1,
                    child: GestureDetector(
                      onTap: (widget.isThinking || _correcting || _listening)
                          ? null
                          : () {
                              if (_awaitingConfirm) {
                                _confirmSend();
                              } else {
                                widget.onSend();
                              }
                            },
                      child: Container(
                        width: 44.w,
                        height: 44.w,
                        decoration: BoxDecoration(
                          gradient: aiGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: LightColor.defaultColor
                                  .withValues(alpha: 0.35),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({
    required this.icon,
    required this.label,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final AiChatColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: colors.thinkingPanelBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.thinkingPanelBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: colors.pathCode),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: colors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}
