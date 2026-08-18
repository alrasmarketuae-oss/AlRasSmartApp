import 'dart:async';
import 'dart:io';

import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/serveses/cached_constants.dart' as cache;
import 'package:alrasmarket/features/ai_assistant/data/ai_assistant_realtime_service.dart';
import 'package:alrasmarket/features/ai_assistant/data/ai_assistant_repository.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/widgets/ai_ad_plan_form.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/widgets/ai_product_listings.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/widgets/ai_support_callback_form.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/views/ai_assistant_history_view.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/features/company/domain/usecases/create_ad_usecases.dart';
import 'package:alrasmarket/features/company/presentation/helpers/create_ad_form_mapper.dart';
import 'package:alrasmarket/core/media/video_compressor.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/widgets/ai_voice_call_overlay.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Assistant accent ramp, used across the header, avatars, and the send button
/// so the screen reads as an AI surface rather than a normal support chat.
const _aiGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [LightColor.defaultColor, LightColor.lightBlue],
);

class _AiChatColors {
  const _AiChatColors({required this.isDark, this.planMode = false});

  final bool isDark;
  final bool planMode;

  factory _AiChatColors.of(BuildContext context) => _AiChatColors(
        isDark: Theme.of(context).brightness == Brightness.dark,
      );

  Color get scaffoldBg => planMode
      ? const Color(0xFF2A2208)
      : (isDark ? const Color(0xFF0B1220) : const Color(0xFFF6F8FC));

  Color get assistantBubbleBg => Colors.white;

  Color get assistantBorder =>
      isDark ? const Color(0xFFE6EAF2) : const Color(0xFFE6EAF2);

  Color get primaryText =>
      isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1F2937);

  Color get mutedText =>
      isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

  Color get composerBg =>
      isDark ? const Color(0xFF0F172A) : Colors.white;

  Color get composerBorder =>
      isDark ? const Color(0xFF1F2937) : const Color(0xFFE6EAF2);

  Color get thinkingPanelBg => planMode
      ? const Color(0xFF3A2F10)
      : Colors.white;

  Color get thinkingPanelBorder => planMode
      ? const Color(0xFFF0D48A)
      : const Color(0xFFE6EAF2);

  Color get thinkingText =>
      planMode ? const Color(0xFFF8E7B0) : const Color(0xFF4B5563);

  Color get pathCode =>
      planMode ? const Color(0xFFE6A817) : const Color(0xFF2E77CC);
}

enum _AiVoiceGender { female, male }

class AiAssistantView extends StatefulWidget {
  const AiAssistantView({super.key});

  @override
  State<AiAssistantView> createState() => _AiAssistantViewState();
}

class _AiAssistantViewState extends State<AiAssistantView> {
  static const _voiceGenderPrefKey = 'ai.assistant.voice.gender';
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _composerKey = GlobalKey<_AiComposerState>();
  final List<_ChatMessage> _messages = [];
  final _realtime = AiAssistantRealtimeService();
  final _historyRepository = AiAssistantRepository();
  final FlutterTts _tts = FlutterTts();
  bool _historyLoading = false;
  bool _voiceReady = false;
  bool _voiceConversationMode = false;
  bool _assistantSpeaking = false;
  _AiVoiceGender _voiceGender = _AiVoiceGender.female;
  Future<void>? _connectFuture;
  bool _isThinking = false;
  final List<String> _thinkingSteps = [];
  DateTime? _thinkingStartedAt;
  bool _pendingAdMediaButton = false;
  final List<String> _draftImagePaths = [];
  String? _draftVideoPath;
  int? _draftVideoDurationSeconds;
  bool _uploadingAdMedia = false;
  final _imagePicker = ImagePicker();
  final _draftOps = sl<ProductDraftOpsUseCase>();
  bool _planMode = false;
  AiAdPlanKind? _planInitialKind;
  int _nextResponseId = 0;
  int? _inFlightResponseId;
  final Map<int, String> _questionForResponse = {};
  _ChatMessage? _replyTo;
  @override
  void initState() {
    super.initState();
    unawaited(_initVoice());
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
    // Mark closed before awaiting so an in-flight connect cannot revive the hub.
    unawaited(_realtime.close());
    unawaited(_tts.stop());
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initVoice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_voiceGenderPrefKey);
      _voiceGender =
          saved == 'male' ? _AiVoiceGender.male : _AiVoiceGender.female;
    } catch (_) {}

    try {
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.05);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);
      _tts.setCompletionHandler(() {
        _assistantSpeaking = false;
        unawaited(_onAssistantSpeechFinished());
      });
      _tts.setCancelHandler(() {
        _assistantSpeaking = false;
      });
      _voiceReady = true;
    } catch (_) {
      _voiceReady = false;
    }

    if (mounted) setState(() {});
  }

  Future<void> _setVoiceConversationMode(bool enabled) async {
    setState(() => _voiceConversationMode = enabled);
    if (!enabled) {
      await _tts.stop();
      _assistantSpeaking = false;
      _composerKey.currentState?.cancelVoiceCapture();
      return;
    }

    if (!mounted || _isThinking || _assistantSpeaking) return;
    await _beginVoiceConversationLoop();
  }

  Future<void> _beginVoiceConversationLoop() async {
    if (!mounted || !_voiceConversationMode || _isThinking || _assistantSpeaking) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted || !_voiceConversationMode || _isThinking || _assistantSpeaking) {
      return;
    }
    await _composerKey.currentState?.beginVoiceTurn(autoSend: true);
  }

  Future<void> _onAssistantSpeechFinished() async {
    if (!mounted || !_voiceConversationMode || _isThinking) return;
    await _beginVoiceConversationLoop();
  }

  String _textForSpeech(String text) {
    var clean = text.trim();
    clean = clean.replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1');
    clean = clean.replaceAll('**', '').replaceAll('*', '');
    clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();
    return clean;
  }

  Future<void> _setVoiceGender(_AiVoiceGender gender) async {
    setState(() => _voiceGender = gender);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _voiceGenderPrefKey,
        gender == _AiVoiceGender.male ? 'male' : 'female',
      );
    } catch (_) {}
  }

  Future<void> _showVoicePicker() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    var conversationEnabled = _voiceConversationMode;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isAr ? 'المحادثة الصوتية' : 'Voice conversation',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr
                          ? 'فعّل الوضع الصوتي لتتكلموا مع بعض بالصوت. الردود النصية العادية بدون صوت.'
                          : 'Turn on voice mode to talk back and forth. Normal text replies stay silent.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.sp,
                        height: 1.35,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: conversationEnabled,
                      onChanged: (value) async {
                        setSheetState(() => conversationEnabled = value);
                        await _setVoiceConversationMode(value);
                      },
                      title: Text(isAr ? 'محادثة صوتية' : 'Voice conversation'),
                      subtitle: Text(
                        isAr
                            ? 'تتكلم → المساعد يرد بصوت → المايك يفتح تاني'
                            : 'You speak → assistant replies aloud → mic opens again',
                      ),
                    ),
                    const Divider(height: 1),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        isAr ? 'صوت المساعد' : 'Assistant voice',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                    RadioListTile<_AiVoiceGender>(
                      value: _AiVoiceGender.female,
                      groupValue: _voiceGender,
                      onChanged: (value) {
                        if (value == null) return;
                        _setVoiceGender(value);
                        setSheetState(() {});
                      },
                      title: Text(isAr ? 'صوت بنت' : 'Female voice'),
                    ),
                    RadioListTile<_AiVoiceGender>(
                      value: _AiVoiceGender.male,
                      groupValue: _voiceGender,
                      onChanged: (value) {
                        if (value == null) return;
                        _setVoiceGender(value);
                        setSheetState(() {});
                      },
                      title: Text(isAr ? 'صوت راجل' : 'Male voice'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _ensureTtsLanguage(String langCode) async {
    final candidates = langCode == 'ar'
        ? const ['ar-SA', 'ar-AE', 'ar-EG', 'ar']
        : const ['en-US', 'en-GB', 'en'];
    for (final locale in candidates) {
      try {
        final ok = await _tts.isLanguageAvailable(locale);
        if (ok == true) {
          await _tts.setLanguage(locale);
          return true;
        }
      } catch (_) {}
    }
    try {
      await _tts.setLanguage(candidates.first);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _applyAssistantVoice(String langCode) async {
    final pitch = _voiceGender == _AiVoiceGender.female ? 1.06 : 0.92;
    await _tts.setPitch(pitch);
    final rate = _voiceGender == _AiVoiceGender.female ? 0.48 : 0.46;
    await _tts.setSpeechRate(rate);
    final voices = await _tts.getVoices;
    if (voices is! List || voices.isEmpty) return;

    final targetWords = _voiceGender == _AiVoiceGender.female
        ? <String>['female', 'woman', 'girl', 'feminine', 'samantha', 'zira', 'premium', 'natural']
        : <String>['male', 'man', 'boy', 'masculine', 'david', 'daniel', 'premium', 'natural'];

    dynamic best;
    var bestScore = -999;
    for (final v in voices) {
      if (v is! Map) continue;
      final locale = (v['locale'] ?? '').toString().toLowerCase();
      if (langCode == 'ar' && !locale.startsWith('ar')) continue;
      if (langCode != 'ar' && !locale.startsWith('en')) continue;

      final blob = v.values.join(' ').toString().toLowerCase();
      var score = 0;
      for (final word in targetWords) {
        if (blob.contains(word)) score += 5;
      }
      if (blob.contains('enhanced') || blob.contains('neural')) score += 10;
      if (blob.contains('premium') || blob.contains('natural')) score += 10;
      if (blob.contains('wavenet') || blob.contains('standard')) score += 3;
      if (score > bestScore) {
        best = v;
        bestScore = score;
      }
    }

    if (best != null) {
      await _tts.setVoice(Map<String, String>.from(best));
    }
  }

  Future<void> _speakAssistantReply(String text) async {
    if (!_voiceConversationMode) return;
    final clean = _textForSpeech(text);
    if (!_voiceReady || clean.isEmpty) {
      unawaited(_onAssistantSpeechFinished());
      return;
    }

    final langCode = Localizations.localeOf(context).languageCode;
    _composerKey.currentState?.cancelVoiceCapture();

    try {
      await _tts.stop();
      if (!await _ensureTtsLanguage(langCode)) {
        unawaited(_onAssistantSpeechFinished());
        return;
      }
      await _applyAssistantVoice(langCode);
      if (!mounted) return;
      setState(() => _assistantSpeaking = true);
      await _tts.speak(clean);
    } catch (_) {
      _assistantSpeaking = false;
      unawaited(_onAssistantSpeechFinished());
    }
  }

  String _previewForReply(_ChatMessage? message) {
    if (message == null) return '';
    return message.text.trim();
  }

  void _setReply(_ChatMessage message) {
    final preview = _previewForReply(message);
    if (preview.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _replyTo = message);
  }

  Future<void> _send() async {
    final visibleText = _controller.text.trim();
    if (visibleText.isEmpty || _isThinking) return;

    FocusManager.instance.primaryFocus?.unfocus();

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final replyTo = _replyTo;
    final replyPreview = _previewForReply(replyTo);
    if (!_planMode && looksLikeAiAdCreationIntent(visibleText)) {
      final auth = AuthService.instance;
      final canCreate = auth.isSupplierAccount ||
          auth.isCompanyCustomerAccount ||
          cache.isShippingCompanyAccount == true;
      final detected = detectAiAdPlanKind(visibleText);
      final unauthorizedReason = _unauthorizedAdCreateReason(
        isAr: isAr,
        canCreate: canCreate,
        detected: detected,
        isCompanyCustomer: auth.isCompanyCustomerAccount,
        isShipping: cache.isShippingCompanyAccount == true,
      );
      if (unauthorizedReason != null) {
        setState(() {
          _messages.add(_ChatMessage(text: visibleText, isUser: true));
          _controller.clear();
          _messages.add(
            _ChatMessage(
              text: unauthorizedReason,
              isUser: false,
            ),
          );
        });
        return;
      }
      final locked = lockedKindForAccount();
      setState(() {
        _planMode = true;
        _planInitialKind = locked ?? detected;
        _pendingAdMediaButton = true;
      });
    } else if (_planMode) {
      // Keep media upload available throughout plan-mode chat.
      _pendingAdMediaButton = true;
    }

    // User wants to leave plan mode from chat.
    if (_planMode && _looksLikeCancelPlan(visibleText)) {
      setState(() {
        _messages.add(_ChatMessage(text: visibleText, isUser: true));
        _controller.clear();
      });
      _cancelAdPlan();
      return;
    }

    var apiText = visibleText;
    if (replyTo != null && replyPreview.isNotEmpty) {
      final quoted = replyPreview.length > 900
          ? '${replyPreview.substring(0, 900)}…'
          : replyPreview;
      apiText = isAr
          ? 'المستخدم بيرد على الرسالة التالية:\n"""\n$quoted\n"""\nسؤاله/رسالته الجديدة:\n"""\n$visibleText\n"""\nجاوب على الرسالة المقتبسة حسب سؤاله الجديد.'
          : 'The user is replying to this previous message:\n"""\n$quoted\n"""\nTheir new question/message:\n"""\n$visibleText\n"""\nAnswer using the quoted message as the subject they are asking about.';
    }
    if (_planMode) {
      final kind = planKindLabel(_planInitialKind);
      final buffer = StringBuffer()..writeln('[PLAN_MODE]');
      if (isAr) {
        buffer.writeln(
          kind != null
              ? 'نوع الإعلان: $kind. ابق في وضع الخطة بالمحادثة ورد بالعربي فقط.'
              : 'ابق في وضع الخطة بالمحادثة لإنشاء الإعلان ورد بالعربي فقط.',
        );
        buffer.writeln(
          'اعرض كل الحقول المطلوبة بالعربي. إذا الرد ناقص، قل صراحة ما الناقص قبل استدعاء أداة الإنشاء.',
        );
      } else {
        buffer.writeln(
          kind != null
              ? 'Ad type hint: $kind. Stay in conversational Plan Mode.'
              : 'Stay in conversational Plan Mode for create-ad.',
        );
        buffer.writeln(
          'List required fields clearly. If the user reply is incomplete, '
          'explicitly say what is still missing before calling any create tool.',
        );
      }
      if (_planInitialKind == AiAdPlanKind.booking) {
        final priorUserTexts = _messages
            .where((m) => m.isUser)
            .map((m) => m.text)
            .toList()
            .reversed;
        final incoterm = resolveBookingPriceTypeFromChat(
          priorUserTexts,
          visibleText,
        );
        buffer.writeln(bookingIncotermPlanHint(incoterm: incoterm, isAr: isAr));
      }
      buffer.writeln(apiText);
      apiText = buffer.toString();
    }

    if (_draftImagePaths.isNotEmpty || _draftVideoPath != null) {
      final buffer = StringBuffer(apiText);
      if (_draftImagePaths.isNotEmpty) {
        buffer.writeln();
        buffer.write('[draft_image_paths: ${_draftImagePaths.join(' | ')}]');
      }
      if (_draftVideoPath != null) {
        buffer.writeln();
        buffer.write(
          '[draft_video_path: $_draftVideoPath'
          '${_draftVideoDurationSeconds != null ? ', duration: $_draftVideoDurationSeconds' : ''}]',
        );
      }
      apiText = buffer.toString();
    }

    // Do not seed fake "thinking" copy here. Steps come only from backend MCP
    // tool calls (aiThinkingStep). Ordinary Q&A shows a spinner with no steps.
    setState(() {
      _messages.add(_ChatMessage(
        text: visibleText,
        isUser: true,
        replyPreview: replyPreview.isEmpty ? null : replyPreview,
      ));
      _controller.clear();
      _replyTo = null;
      _isThinking = true;
      _thinkingStartedAt = DateTime.now();
      _thinkingSteps.clear();
      _draftImagePaths.clear();
      _draftVideoPath = null;
      _draftVideoDurationSeconds = null;
    });
    _scrollToEnd();

    try {
      final language = isAr ? 'ar' : 'en';
      final responseId = ++_nextResponseId;
      _inFlightResponseId = responseId;
      _questionForResponse[responseId] = visibleText;
      await (_connectFuture ??= _connect());
      await _realtime.ask(message: apiText, language: language);
    } catch (_) {
      _connectFuture = null;
      _showConnectionError();
    }
    _scrollToEnd();
  }

  bool _looksLikeCancelPlan(String text) {
    final q = text.trim().toLowerCase();
    const markers = [
      'الغاء',
      'إلغاء',
      'الغي',
      'ألغي',
      'cancel',
      'exit plan',
      'quit plan',
      'خروج من الخطة',
      'اقفل الخطة',
    ];
    return markers.any(q.contains);
  }

  String? _unauthorizedAdCreateReason({
    required bool isAr,
    required bool canCreate,
    required AiAdPlanKind? detected,
    required bool isCompanyCustomer,
    required bool isShipping,
  }) {
    if (!canCreate) {
      return isAr
          ? 'حسابك غير مخوّل بإنشاء إعلانات. تقدر تتصفح وتشتري وتتبع طلباتك، ولو حابب تنشر إعلانات سجّل كحساب مورد أو شركة.'
          : 'Your account is not authorized to create ads. You can browse, buy, and track orders; register as a supplier or company to publish ads.';
    }
    if (isCompanyCustomer &&
        detected != null &&
        detected != AiAdPlanKind.request) {
      return isAr
          ? 'حساب عميل الشركة غير مخوّل بإنشاء هذا النوع. المسموح لك فقط إعلان طلب (Request).'
          : 'A company customer account is not authorized for that ad type. You can only create Request ads.';
    }
    if (isShipping &&
        detected != null &&
        detected != AiAdPlanKind.shipping) {
      return isAr
          ? 'حساب شركة الشحن غير مخوّل بإنشاء إعلانات المنتجات. المسموح لك فقط إعلان شحن.'
          : 'A shipping company account is not authorized to create product ads. You can only create shipping ads.';
    }
    return null;
  }

  void _cancelAdPlan() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    setState(() {
      _planMode = false;
      _planInitialKind = null;
      _pendingAdMediaButton = false;
      _messages.add(
        _ChatMessage(
          text: isAr
              ? 'تم إلغاء وضع الخطة. تقدر تكتب أي سؤال تاني.'
              : 'Plan mode cancelled. You can ask anything else.',
          isUser: false,
        ),
      );
    });
  }

  Future<void> _pickAdMedia() async {
    if (_uploadingAdMedia || _isThinking) return;
    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'سجّل الدخول أولاً'
                : 'Please sign in first',
          ),
        ),
      );
      return;
    }

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    setState(() {
      _uploadingAdMedia = true;
      _isThinking = true;
      _thinkingStartedAt ??= DateTime.now();
      _thinkingSteps.add(
        isAr ? 'جاري رفع الوسائط…' : 'Uploading media…',
      );
    });
    _scrollToEnd();

    try {
      final picked = await _imagePicker.pickMultipleMedia();
      if (picked.isEmpty) {
        if (!mounted) return;
        setState(() {
          _uploadingAdMedia = false;
          _isThinking = false;
        });
        return;
      }

      final imagePaths = <String>[];
      final videoPaths = <String>[];
      for (final item in picked) {
        final path = item.path;
        if (path.isEmpty) continue;
        if (CreateAdFormMapper.isVideoPath(path)) {
          videoPaths.add(path);
        } else {
          imagePaths.add(path);
        }
      }

      var uploadedImages = 0;
      for (final imagePath in imagePaths) {
        final result = await _draftOps.uploadDraftImage(
          filePath: imagePath,
          token: token,
        );
        result.fold(
          (_) {},
          (remotePath) {
            if (!_draftImagePaths.contains(remotePath)) {
              _draftImagePaths.add(remotePath);
              uploadedImages++;
            }
          },
        );
      }

      if (videoPaths.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _thinkingSteps.add(
            isAr ? 'جاري رفع الفيديو…' : 'Uploading video…',
          );
        });
        final videoPath = videoPaths.first;
        final videoResult = await _draftOps.uploadDraftVideo(
          filePath: videoPath,
          token: token,
        );
        String? uploadedVideoPath;
        videoResult.fold(
          (_) {},
          (remotePath) => uploadedVideoPath = remotePath,
        );
        if (uploadedVideoPath != null) {
          _draftVideoPath = uploadedVideoPath;
          final duration = await VideoCompressor.readDurationSecondsRounded(
            videoPath,
            maxSeconds: CreateAdFormMapper.maxProductVideoDurationSeconds,
          );
          _draftVideoDurationSeconds = duration > 0 ? duration : 30;
        }
      }

      if (!mounted) return;
      if (uploadedImages > 0 || _draftVideoPath != null) {
        setState(() {
          if (uploadedImages > 0) {
            _thinkingSteps.add(
              isAr
                  ? 'تم رفع $uploadedImages صورة بنجاح'
                  : 'Uploaded $uploadedImages image(s) successfully',
            );
          }
          if (_draftVideoPath != null) {
            _thinkingSteps.add(
              isAr ? 'تم رفع الفيديو بنجاح' : 'Video uploaded successfully',
            );
          }
        });
      }
    } catch (_) {
      // Ignore picker/upload errors; user can retry.
    }

    if (!mounted) return;
    setState(() {
      _uploadingAdMedia = false;
      _isThinking = false;
    });
    _scrollToEnd();
  }

  Future<void> _connect() async {
    await _realtime.connect(
      onThinking: (value) {
        if (!mounted) return;
        setState(() {
          if (value) {
            _isThinking = true;
            _thinkingStartedAt ??= DateTime.now();
          } else if (_messages.isEmpty ||
              _messages.last.isUser ||
              _messages.last.text.isEmpty) {
            // Keep the live thinking bubble until streaming starts.
            _isThinking = true;
          } else {
            _isThinking = false;
          }
        });
        _scrollToEnd();
      },
      onThinkingStep: (step) {
        if (!mounted) return;
        setState(() {
          _isThinking = true;
          if (_thinkingSteps.isEmpty || _thinkingSteps.last != step) {
            _thinkingSteps.add(step);
          }
        });
        _scrollToEnd();
      },
      onResponseStarted: () {
        if (!mounted) return;
        final trace = List<String>.from(_thinkingSteps);
        final started = _thinkingStartedAt;
        final durationMs = started == null
            ? null
            : DateTime.now().difference(started).inMilliseconds;
        final responseId = _inFlightResponseId;
        setState(() {
          _thinkingSteps.clear();
          _thinkingStartedAt = null;
          // Steps live on the assistant bubble now — hide the empty live bubble.
          _isThinking = false;
          _messages.add(
            _ChatMessage(
              text: '',
              isUser: false,
              thinkingSteps: trace,
              thinkingDurationMs: durationMs,
              showMediaUpload: _pendingAdMediaButton || _planMode,
              responseId: responseId,
            ),
          );
          // Keep the button available for the whole plan-mode conversation.
          if (!_planMode) {
            _pendingAdMediaButton = false;
          }
        });
      },
      onDelta: (value) {
        if (!mounted) return;
        setState(() {
          if (_messages.isEmpty || _messages.last.isUser) {
            _messages.add(
              _ChatMessage(
                text: value,
                isUser: false,
                thinkingSteps: List<String>.from(_thinkingSteps),
              ),
            );
            _thinkingSteps.clear();
          } else {
            _messages.last.text += value;
          }
        });
        _scrollToEnd();
      },
      onCompleted: (answer, {required offerSupportCallback, listings, thinkingSteps}) {
        if (!mounted) return;
        final isAr = Localizations.localeOf(context).languageCode == 'ar';
        var finalAnswer = answer;
        if (looksLikeTemporaryAssistantFailure(answer) &&
            _shouldIgnoreAssistantError()) {
          finalAnswer = isAr
              ? 'تم إنشاء الإعلان بنجاح وإرساله للمراجعة من الإدارة.'
              : 'Your ad was created and submitted for admin review.';
        }
        final responseId = _inFlightResponseId;
        final supportQuestion = responseId == null
            ? null
            : _questionForResponse[responseId];
        final parsedListings = AiProductListings.parse(listings);
        final parsedThinking = thinkingSteps
                ?.map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList() ??
            <String>[];
        setState(() {
          _isThinking = false;
          _inFlightResponseId = null;
          if (finalAnswer.isNotEmpty) {
            final targetIndex = responseId == null
                ? (_messages.lastIndexWhere((m) => !m.isUser))
                : _messages.lastIndexWhere(
                    (m) => !m.isUser && m.responseId == responseId,
                  );
            if (targetIndex >= 0) {
              final target = _messages[targetIndex];
              if (target.text.isEmpty ||
                  looksLikeTemporaryAssistantFailure(target.text)) {
                target.text = finalAnswer;
              }
              if (parsedThinking.isNotEmpty) {
                final merged = <String>[
                  ...target.thinkingSteps,
                  ...parsedThinking.where(
                    (step) => !target.thinkingSteps.contains(step),
                  ),
                ];
                target.thinkingSteps
                  ..clear()
                  ..addAll(merged);
              } else if (target.thinkingSteps.isEmpty &&
                  _thinkingSteps.isNotEmpty) {
                target.thinkingSteps
                  ..clear()
                  ..addAll(_thinkingSteps);
              }
              if (parsedListings.isNotEmpty) {
                target.listings = parsedListings;
              }
              target.showSupportCallbackForm = offerSupportCallback;
              target.supportQuestion = supportQuestion;
            } else if (_messages.isEmpty || _messages.last.isUser) {
              _messages.add(
                _ChatMessage(
                  text: finalAnswer,
                  isUser: false,
                  thinkingSteps: parsedThinking.isNotEmpty
                      ? parsedThinking
                      : List<String>.from(_thinkingSteps),
                  showSupportCallbackForm: offerSupportCallback,
                  supportQuestion: supportQuestion,
                  responseId: responseId,
                  listings: parsedListings,
                ),
              );
            }
          } else if (offerSupportCallback) {
            _messages.add(
              _ChatMessage(
                text: isAr
                    ? 'اكتب اسمك ورقم تليفونك وبريدك الإلكتروني، وهيتم الاتصال بيك خلال خمس دقايق.'
                    : 'Please leave your name, phone, and email — we’ll call you within five minutes.',
                isUser: false,
                showSupportCallbackForm: true,
                supportQuestion: supportQuestion,
                responseId: responseId,
              ),
            );
          }
          _thinkingSteps.clear();
          if (_planMode && looksLikeAdCreateSuccess(finalAnswer)) {
            _planMode = false;
            _planInitialKind = null;
            _pendingAdMediaButton = false;
          } else if (_planMode &&
              _messages.isNotEmpty &&
              !_messages.last.isUser) {
            // Ensure the upload button stays on the latest assistant bubble.
            _messages.last.showMediaUpload = true;
          }
        });
        _scrollToEnd();
        if (_voiceConversationMode && finalAnswer.isNotEmpty) {
          unawaited(_speakAssistantReply(finalAnswer));
        } else if (_voiceConversationMode) {
          unawaited(_onAssistantSpeechFinished());
        }
      },
      onError: (message) {
        if (_shouldIgnoreAssistantError()) return;
        _showConnectionError();
        if (_voiceConversationMode) {
          unawaited(_onAssistantSpeechFinished());
        }
      },
    );
  }

  bool _shouldIgnoreAssistantError() {
    for (final step in _thinkingSteps) {
      if (_looksLikeAdCreationThinkingStep(step)) return true;
    }

    if (_messages.isEmpty || _messages.last.isUser) return false;

    final last = _messages.last;
    if (last.text.isNotEmpty && looksLikeAdCreateSuccess(last.text)) {
      return true;
    }

    for (final step in last.thinkingSteps) {
      if (_looksLikeAdCreationThinkingStep(step)) return true;
    }

    return false;
  }

  bool _looksLikeAdCreationThinkingStep(String step) {
    final q = step.toLowerCase();
    const markers = [
      'تم إنشاء',
      'تم رفع',
      'جاري إنشاء',
      'إرساله للمراجعة',
      'ad created',
      'uploaded',
    ];
    return markers.any(q.contains);
  }

  void _showConnectionError() {
    if (!mounted) return;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final responseId = _inFlightResponseId;
    final supportQuestion = responseId == null
        ? null
        : _questionForResponse[responseId];
    setState(() {
      _isThinking = false;
      _inFlightResponseId = null;
      _thinkingSteps.clear();
      _messages.add(
        _ChatMessage(
          text: isAr
              ? 'تعذر الوصول للمساعد الآن. سيب اسمك ورقم تليفونك وبريدك في النموذج تحت، وفريق الدعم الفني هيتواصل معاك خلال خمس دقايق.'
              : 'The assistant is unavailable right now. Leave your name, phone, and email below — technical support will call you within five minutes.',
          isUser: false,
          showSupportCallbackForm: true,
          supportQuestion: supportQuestion,
          responseId: responseId,
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

  Future<void> _openHistorySheet() async {
    if (!AuthService.instance.isAuthenticated) return;

    final selected = await Navigator.of(context).push<AiConversationSummary>(
      MaterialPageRoute(
        builder: (_) => AiAssistantHistoryView(
          activeSessionId: _realtime.sessionId,
        ),
      ),
    );

    if (selected == null || !mounted) return;
    await _loadConversationHistory(selected);
  }

  Future<void> _loadConversationHistory(AiConversationSummary summary) async {
    final token = AuthService.instance.currentToken;
    if (token == null) return;

    setState(() => _historyLoading = true);
    final result = await _historyRepository.getConversationMessages(
      token: token,
      conversationId: summary.id,
      limit: 50,
    );
    if (!mounted) return;
    setState(() => _historyLoading = false);

    result.fold(
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).aiAssistantHistoryLoadMessagesError)),
        );
      },
      (page) {
        _realtime.attachToSession(summary.clientSessionId);
        setState(() {
          _planMode = false;
          _pendingAdMediaButton = false;
          _messages
            ..clear()
            ..addAll(
              page.messages.map(
                (message) => _ChatMessage(
                  text: message.content,
                  isUser: message.role.toLowerCase() == 'user',
                  listings: AiProductListings.parse(message.listings),
                  thinkingSteps: List<String>.from(message.thinkingSteps),
                ),
              ),
            );
        });
        _scrollToEnd();
      },
    );
  }

  AiCallPhase get _callPhase {
    if (_assistantSpeaking) return AiCallPhase.speaking;
    if (_isThinking) return AiCallPhase.thinking;
    return AiCallPhase.listening;
  }

  @override
  Widget build(BuildContext context) {
    final colors = _planMode
        ? const _AiChatColors(isDark: true, planMode: true)
        : _AiChatColors.of(context);
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: Stack(
        children: [
          Column(
            children: [
              _AiChatHeader(
                planMode: _planMode,
                onCancelPlan: _planMode ? _cancelAdPlan : null,
                onOpenHistory: AuthService.instance.isAuthenticated
                    ? (_historyLoading ? null : _openHistorySheet)
                    : null,
                historyLoading: _historyLoading,
                onOpenVoiceSettings: _showVoicePicker,
                voiceGender: _voiceGender,
                voiceConversationMode: _voiceConversationMode,
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
                  itemCount: _messages.length + (_isThinking ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isThinking && index == _messages.length) {
                      return _ThinkingBubble(
                        steps: List<String>.from(_thinkingSteps),
                        startedAt: _thinkingStartedAt,
                        colors: colors,
                      );
                    }
                    return _SwipeToReply(
                      onReply: () => _setReply(_messages[index]),
                      child: _MessageBubble(
                      message: _messages[index],
                      colors: colors,
                      onPickAdMedia: _pickAdMedia,
                      uploadingAdMedia: _uploadingAdMedia,
                      sessionId: _realtime.sessionId,
                      onSupportCallbackSubmitted: () {
                        setState(() {
                          _messages[index].showSupportCallbackForm = false;
                        });
                      },
                    ),
                    );
                  },
                ),
              ),
              _AiComposer(
                key: _composerKey,
                controller: _controller,
                isThinking: _isThinking,
                onSend: _send,
                colors: colors,
                planMode: _planMode,
                onPickAdMedia: _planMode ? _pickAdMedia : null,
                uploadingAdMedia: _uploadingAdMedia,
                draftImageCount: _draftImagePaths.length,
                hasDraftVideo: _draftVideoPath != null,
                replyPreview: _previewForReply(_replyTo),
                onCancelReply: _replyTo == null ? null : () => setState(() => _replyTo = null),
                voiceConversationMode: _voiceConversationMode,
                assistantSpeaking: _assistantSpeaking,
                onVoiceTurnRetry: _onAssistantSpeechFinished,
                onListeningChanged: (v) {
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
          if (_voiceConversationMode)
            Positioned.fill(
              child: AiVoiceCallOverlay(
                phase: _callPhase,
                onEndCall: () => _setVoiceConversationMode(false),
                thinkingSteps: List<String>.from(_thinkingSteps),
              ),
            ),
        ],
      ),
    );
  }
}

class _AiChatHeader extends StatelessWidget {
  const _AiChatHeader({
    this.planMode = false,
    this.onCancelPlan,
    this.onOpenHistory,
    this.historyLoading = false,
    this.onOpenVoiceSettings,
    this.voiceGender = _AiVoiceGender.female,
    this.voiceConversationMode = false,
  });

  final bool planMode;
  final VoidCallback? onCancelPlan;
  final VoidCallback? onOpenHistory;
  final bool historyLoading;
  final VoidCallback? onOpenVoiceSettings;
  final _AiVoiceGender voiceGender;
  final bool voiceConversationMode;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final topInset = MediaQuery.paddingOf(context).top;
    final gradient = planMode
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE6A817), Color(0xFFF0D48A)],
          )
        : _aiGradient;

    return Container(
      padding: EdgeInsets.fromLTRB(12.w, topInset + 10.h, 16.w, 16.h),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: (planMode ? AiAdPlanColors.accent : LightColor.defaultColor)
                .withValues(alpha: 0.25),
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
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        planMode
                            ? (isAr ? 'وضع الخطة' : 'Plan mode')
                            : s.aiAssistantTitle,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Container(
                          width: 7.w,
                          height: 7.w,
                          decoration: BoxDecoration(
                            color: planMode
                                ? const Color(0xFFFFF8E7)
                                : const Color(0xFF6EE7A8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          planMode
                              ? (isAr ? 'إنشاء إعلان' : 'Create ad')
                              : s.aiAssistantFabLabel,
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
              if (onOpenHistory != null)
                historyLoading
                    ? Padding(
                        padding: EdgeInsetsDirectional.only(end: 8.w),
                        child: SizedBox(
                          width: 22.w,
                          height: 22.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : IconButton(
                        onPressed: onOpenHistory,
                        icon: Icon(
                          Icons.history_rounded,
                          color: Colors.white,
                          size: 22.sp,
                        ),
                      ),
              if (onOpenVoiceSettings != null)
                IconButton(
                  onPressed: onOpenVoiceSettings,
                  tooltip: voiceConversationMode
                      ? (isAr ? 'محادثة صوتية شغّالة' : 'Voice conversation on')
                      : (isAr ? 'المحادثة الصوتية' : 'Voice conversation'),
                  icon: Icon(
                    voiceConversationMode
                        ? Icons.headset_mic_rounded
                        : (voiceGender == _AiVoiceGender.female
                            ? Icons.record_voice_over_rounded
                            : Icons.mic_rounded),
                    color: voiceConversationMode
                        ? const Color(0xFFFFF176)
                        : Colors.white,
                    size: 21.sp,
                  ),
                ),
              if (onCancelPlan != null)
                TextButton(
                  onPressed: onCancelPlan,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    minimumSize: Size(0, 32.h),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    isAr ? 'إلغاء' : 'Cancel',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
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
                  planMode ? Icons.route_rounded : Icons.auto_awesome_rounded,
                  size: 14.sp,
                  color: Colors.white,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    planMode
                        ? (isAr
                            ? 'قولّي البيانات اللي عندك — ولو نسيت حاجة هذكّرك بيها.'
                            : 'Tell me what you have — if something is missing, I will list it.')
                        : s.aiAssistantSubtitle,
                    style: TextStyle(
                      fontSize: 10.sp,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.92),
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

class _ChatMessage {
  _ChatMessage({
    required this.text,
    required this.isUser,
    List<String>? thinkingSteps,
    this.thinkingDurationMs,
    this.showMediaUpload = false,
    this.showSupportCallbackForm = false,
    this.supportQuestion,
    this.responseId,
    this.replyPreview,
    List<MyListingProductModel>? listings,
  })  : thinkingSteps = thinkingSteps ?? <String>[],
        listings = listings ?? <MyListingProductModel>[];

  String text;
  final bool isUser;
  final List<String> thinkingSteps;
  final int? thinkingDurationMs;
  bool showMediaUpload;
  bool showSupportCallbackForm;
  String? supportQuestion;
  final int? responseId;
  final String? replyPreview;
  List<MyListingProductModel> listings;
}

class _SwipeToReply extends StatefulWidget {
  const _SwipeToReply({required this.onReply, required this.child});

  final VoidCallback onReply;
  final Widget child;

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply> {
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.colors,
    required this.onPickAdMedia,
    required this.uploadingAdMedia,
    this.sessionId,
    this.onSupportCallbackSubmitted,
  });
  final _ChatMessage message;
  final _AiChatColors colors;
  final VoidCallback onPickAdMedia;
  final bool uploadingAdMedia;
  final String? sessionId;
  final VoidCallback? onSupportCallbackSubmitted;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final bubble = Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
      constraints: BoxConstraints(maxWidth: 0.72.sw),
      decoration: BoxDecoration(
        gradient: isUser ? _aiGradient : null,
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
              _ThinkingTrace(
                steps: message.thinkingSteps,
                title: isAr ? 'التفكير' : 'Thinking',
                initiallyExpanded: true,
                durationMs: message.thinkingDurationMs,
                colors: colors,
              ),
              SizedBox(height: 8.h),
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
                textDirection: _detectTextDirection(message.text),
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
                  side: BorderSide(color: LightColor.defaultColor.withValues(alpha: 0.5)),
                ),
              ),
            ],
            if (!isUser && message.showSupportCallbackForm) ...[
              AiSupportCallbackForm(
                question: message.supportQuestion,
                sessionId: sessionId,
                onSubmitted: onSupportCallbackSubmitted,
              ),
            ],
          ],
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const _AiAvatar(size: 26),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                GestureDetector(
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
                if (!isUser && message.listings.isNotEmpty)
                  AiProductListings(products: message.listings),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThinkingTrace extends StatefulWidget {
  const _ThinkingTrace({
    required this.steps,
    required this.title,
    required this.colors,
    this.initiallyExpanded = false,
    this.live = false,
    this.durationMs,
  });

  final List<String> steps;
  final String title;
  final _AiChatColors colors;
  final bool initiallyExpanded;
  final bool live;
  final int? durationMs;

  @override
  State<_ThinkingTrace> createState() => _ThinkingTraceState();
}

class _ThinkingTraceState extends State<_ThinkingTrace> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final durationLabel = widget.durationMs == null
        ? null
        : (isAr
            ? '(${((widget.durationMs! / 1000).toStringAsFixed(1))} ث)'
            : '(${((widget.durationMs! / 1000).toStringAsFixed(1))}s)');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _expanded
                      ? Icons.expand_more_rounded
                      : Icons.chevron_right_rounded,
                  size: 16.sp,
                  color: widget.colors.mutedText,
                ),
                SizedBox(width: 2.w),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: widget.colors.mutedText,
                  ),
                ),
                if (durationLabel != null) ...[
                  SizedBox(width: 4.w),
                  Text(
                    durationLabel,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: widget.colors.mutedText,
                    ),
                  ),
                ],
                if (widget.live) ...[
                  SizedBox(width: 6.w),
                  SizedBox(
                    width: 12.w,
                    height: 12.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: LightColor.defaultColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_expanded)
          Container(
            width: double.infinity,
            margin: EdgeInsetsDirectional.only(start: 4.w, top: 4.h),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: widget.colors.thinkingPanelBg,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: widget.colors.thinkingPanelBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < widget.steps.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.only(top: 2.h, end: 6.w),
                          child: widget.live && i == widget.steps.length - 1
                              ? SizedBox(
                                  width: 12.w,
                                  height: 12.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.8,
                                    color: LightColor.defaultColor.withValues(alpha: 0.85),
                                  ),
                                )
                              : Icon(
                                  Icons.check_circle_outline,
                                  size: 13.sp,
                                  color: widget.colors.pathCode.withValues(alpha: 0.9),
                                ),
                        ),
                        Expanded(
                          child: _ThinkingStepText(
                            step: widget.steps[i],
                            colors: widget.colors,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ThinkingStepText extends StatelessWidget {
  const _ThinkingStepText({required this.step, required this.colors});

  final String step;
  final _AiChatColors colors;

  @override
  Widget build(BuildContext context) {
    final lines = step.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          _ThinkingLineText(line: line, colors: colors),
      ],
    );
  }
}

class _ThinkingLineText extends StatelessWidget {
  const _ThinkingLineText({required this.line, required this.colors});

  final String line;
  final _AiChatColors colors;

  static final RegExp _pathLine = RegExp(
    r'(product-(?:images|videos)/[^\s]+)',
    caseSensitive: false,
  );

  @override
  Widget build(BuildContext context) {
    final match = _pathLine.firstMatch(line);
    if (match == null) {
      return Text(
        line,
        style: TextStyle(
          fontSize: 10.5.sp,
          height: 1.35,
          color: colors.thinkingText,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final start = match.start;
    final end = match.end;
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: 10.5.sp,
          height: 1.35,
          color: colors.thinkingText,
          fontStyle: FontStyle.italic,
        ),
        children: [
          if (start > 0) TextSpan(text: line.substring(0, start)),
          TextSpan(
            text: line.substring(start, end),
            style: TextStyle(
              color: colors.pathCode,
              fontFamily: 'monospace',
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (end < line.length) TextSpan(text: line.substring(end)),
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
        spans.add(TextSpan(text: _isolateLatinRuns(segment.substring(cursor, match.start))));
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
      spans.addAll(_parseSegment(text.substring(cursor)));
    }

    return Directionality(
      textDirection: _detectTextDirection(text),
      child: Text.rich(TextSpan(style: style, children: spans)),
    );
  }

  Future<void> _openLink(String target) async {
    final uri = Uri.tryParse(target);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _ThinkingBubble extends StatefulWidget {
  const _ThinkingBubble({
    required this.steps,
    required this.colors,
    this.startedAt,
  });

  final List<String> steps;
  final _AiChatColors colors;
  final DateTime? startedAt;

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
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _AiAvatar(size: 26),
          SizedBox(width: 8.w),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: widget.colors.assistantBubbleBg,
                borderRadius: BorderRadiusDirectional.only(
                  topStart: Radius.circular(16.r),
                  topEnd: Radius.circular(16.r),
                  bottomEnd: Radius.circular(16.r),
                  bottomStart: Radius.circular(4.r),
                ),
                border: Border.all(color: widget.colors.assistantBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.aiAssistantThinking,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: widget.colors.mutedText,
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
                                  (0.7 *
                                          (1 - (t - 0.5).abs() * 2)
                                              .clamp(0.0, 1.0));
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
                  if (widget.steps.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    _ThinkingTrace(
                      steps: widget.steps,
                      title: isAr ? 'التفكير' : 'Thinking',
                      initiallyExpanded: true,
                      live: true,
                      durationMs: widget.startedAt == null
                          ? null
                          : DateTime.now()
                              .difference(widget.startedAt!)
                              .inMilliseconds,
                      colors: widget.colors,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

TextDirection _detectTextDirection(String text) {
  var arabic = 0;
  var latin = 0;
  for (final codeUnit in text.codeUnits) {
    if (codeUnit >= 0x0600 && codeUnit <= 0x06FF) {
      arabic++;
    } else if ((codeUnit >= 0x0041 && codeUnit <= 0x005A) ||
        (codeUnit >= 0x0061 && codeUnit <= 0x007A)) {
      latin++;
    }
  }
  if (arabic == 0 && latin == 0) return TextDirection.ltr;
  return arabic >= latin ? TextDirection.rtl : TextDirection.ltr;
}

bool looksLikeSupportCallbackIntent(String? message) {
  final q = (message ?? '').trim().toLowerCase();
  if (q.isEmpty) return false;
  const markers = <String>[
    'دعم فني',
    'الدعم الفني',
    'دعم بشري',
    'الدعم البشري',
    'كلم الدعم',
    'محتاج اكلم',
    'محتاج أكلم',
    'محتاج الدعم',
    'خدمة العملاء',
    'كلمني',
    'technical support',
    'tech support',
    'human support',
    'talk to support',
    'talk to technical',
    'talk with support',
    'speak to support',
    'speak with support',
    'contact support',
    'contact technical',
    'call support',
    'customer service',
    'customer care',
    'customer support',
    'support agent',
    'help desk',
    'live agent',
    'need support',
    'need technical',
    'need to talk',
    'need to speak',
    'want to talk',
    'want to speak',
    'talk to a human',
    'speak to a human',
    'real person',
    'real human',
    'phone support',
  ];
  return markers.any(q.contains);
}

bool looksLikeSupportCallbackCue(String answer) {
  final text = answer.trim().toLowerCase();
  if (text.isEmpty) return false;
  const markers = <String>[
    'خمس دقايق',
    'خلال خمس',
    'خلال 5',
    'النموذج تحت',
    'رقم تليفونك',
    'five minutes',
    'form below',
    'leave your name',
    'phone number, and email',
    'technical support will call',
    'we’ll call you',
    "we'll call you",
  ];
  return markers.any(text.contains);
}

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({
    required this.icon,
    required this.label,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final _AiChatColors colors;

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

class _AiComposer extends StatefulWidget {
  const _AiComposer({
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
  });

  final TextEditingController controller;
  final bool isThinking;
  final VoidCallback onSend;
  final _AiChatColors colors;
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

  @override
  State<_AiComposer> createState() => _AiComposerState();
}

class _AiComposerState extends State<_AiComposer> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _listening = false;
  bool _correcting = false;
  bool _awaitingConfirm = false;
  bool _finishing = false;
  bool _autoSendAfterTranscription = false;
  String _baseText = '';
  String? _recordingPath;

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
    if (_listening) {
      unawaited(_recorder.stop());
    }
    unawaited(_recorder.dispose());
    super.dispose();
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
    final dir = await getTemporaryDirectory();
    final filePath =
        p.join(dir.path, 'ai_voice_${DateTime.now().millisecondsSinceEpoch}.m4a');

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
  }

  Future<void> _finishListening() async {
    if (_finishing) return;
    if (!_listening && !_awaitingConfirm) return;
    _finishing = true;

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
    _finishing = false;
  }

  void _cancelVoice() {
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
                              ? '${widget.draftImageCount} صورة مرفقة'
                              : '${widget.draftImageCount} image(s) attached',
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
                                Icons.photo_library_outlined,
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
                          gradient: _aiGradient,
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

