import 'dart:async';
import 'dart:io';

import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/features/ai_assistant/data/ai_assistant_voice_prefs.dart';
import 'package:alrasmarket/core/utils/dio_user_facing_message.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/serveses/cached_constants.dart' as cache;
import 'package:alrasmarket/features/ai_assistant/data/ai_assistant_realtime_service.dart';
import 'package:alrasmarket/features/ai_assistant/data/ai_assistant_repository.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/helpers/ai_chat_heuristics.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/helpers/ai_thinking_narrative.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/models/ai_chat_message.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/models/ai_voice_gender.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/theme/ai_chat_colors.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/widgets/ai_ad_plan_form.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/widgets/ai_chat_header.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/widgets/ai_composer.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/widgets/ai_message_bubble.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/widgets/ai_thinking_widgets.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/widgets/ai_product_listings.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/views/ai_assistant_history_view.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/features/company/domain/usecases/create_ad_usecases.dart';
import 'package:alrasmarket/features/company/presentation/helpers/create_ad_form_mapper.dart';
import 'package:alrasmarket/core/media/video_compressor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/widgets/ai_voice_call_overlay.dart';
import 'package:alrasmarket/features/ai_assistant/presentation/helpers/ai_assistant_tts_voice.dart';
import 'package:alrasmarket/features/ai_assistant/data/ai_voice_agent_controller.dart';
import 'package:flutter_tts/flutter_tts.dart';

part 'ai_assistant_view_voice.dart';
part 'ai_assistant_view_media.dart';

class AiAssistantView extends StatefulWidget {
  const AiAssistantView({
    super.key,
    this.startInVoiceCall = false,
    this.initialMessage,
  });

  final bool startInVoiceCall;
  /// Optional seed message sent automatically after the hub connects.
  final String? initialMessage;

  @override
  State<AiAssistantView> createState() => _AiAssistantViewState();
}

abstract class _AiAssistantViewStateBase extends State<AiAssistantView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _composerKey = GlobalKey<AiComposerState>();
  final List<AiChatMessage> _messages = [];
  final _realtime = AiAssistantRealtimeService();
  final _historyRepository = AiAssistantRepository();
  final FlutterTts _tts = FlutterTts();
  AiVoiceAgentController? _voiceAgent;
  AiVoiceAgentPhase _voiceAgentPhase = AiVoiceAgentPhase.connecting;
  String _voiceAssistantBuffer = '';
  bool _historyLoading = false;
  bool _voiceReady = false;
  bool _voiceConversationMode = false;
  bool _assistantSpeaking = false;
  bool _micMuted = false;
  bool _micListening = false;
  bool _micTranscribing = false;
  AiVoiceGender _voiceGender = AiVoiceGender.female;
  String? _appliedVoiceSignature;
  AiVoiceGender? _appliedVoiceGender;
  Future<void>? _connectFuture;
  bool _isThinking = false;
  final List<String> _thinkingSteps = [];
  List<String> _thinkingNarrative = const [];
  final List<String> _backendThinkingHints = [];
  Timer? _thinkingRevealTimer;
  Timer? _thinkingTickTimer;
  int _thinkingRevealIndex = 0;
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
  AiChatMessage? _replyTo;

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
}

class _AiAssistantViewState extends _AiAssistantViewStateBase
    with _AiAssistantVoiceMixin, _AiAssistantMediaMixin {
  @override
  void initState() {
    super.initState();
    unawaited(_initVoice());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = S.of(context);
      setState(() {
        _messages.add(AiChatMessage(text: s.aiAssistantWelcome, isUser: false));
      });
      _connectFuture = _connect().then((_) async {
        final seed = widget.initialMessage?.trim();
        if (!mounted || seed == null || seed.isEmpty) return;
        _controller.text = seed;
        await _send();
      });
    });
  }

  @override
  void dispose() {
    _stopThinkingReveal();
    // Mark closed before awaiting so an in-flight connect cannot revive the hub.
    unawaited(_voiceAgent?.dispose());
    unawaited(_realtime.close());
    unawaited(_tts.stop());
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _stopThinkingReveal() {
    _thinkingRevealTimer?.cancel();
    _thinkingRevealTimer = null;
    _thinkingTickTimer?.cancel();
    _thinkingTickTimer = null;
  }

  void _startThinkingNarrative(
    String query, {
    required bool isAr,
    required int seed,
  }) {
    _stopThinkingReveal();
    _thinkingNarrative = AiThinkingNarrative.generate(
      userQuery: query,
      isAr: isAr,
      seed: seed,
    );
    _backendThinkingHints.clear();
    _thinkingRevealIndex = 0;
    _thinkingSteps
      ..clear()
      ..addAll(
        _thinkingNarrative.isEmpty
            ? const <String>[]
            : <String>[_thinkingNarrative.first],
      );
    if (_thinkingSteps.isNotEmpty) {
      _thinkingRevealIndex = 1;
    }

    _thinkingRevealTimer = Timer.periodic(
      const Duration(milliseconds: 420),
      (_) {
        if (!mounted || !_isThinking) {
          _stopThinkingReveal();
          return;
        }
        final planned = AiThinkingNarrative.mergeBackendHints(
          narrative: _thinkingNarrative,
          backendSteps: _backendThinkingHints,
          isAr: isAr,
        );
        if (_thinkingRevealIndex >= planned.length) return;
        setState(() {
          final next = planned[_thinkingRevealIndex];
          if (_thinkingSteps.isEmpty || _thinkingSteps.last != next) {
            _thinkingSteps.add(next);
          }
          _thinkingRevealIndex++;
        });
        _scrollToEnd();
      },
    );

    _thinkingTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isThinking) setState(() {});
    });
  }

  List<String> _finalizeThinkingSteps({required bool isAr}) {
    final planned = AiThinkingNarrative.mergeBackendHints(
      narrative: _thinkingNarrative,
      backendSteps: _backendThinkingHints,
      isAr: isAr,
    );
    final out = <String>[];
    for (final line in _thinkingSteps) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (out.isEmpty || out.last != trimmed) out.add(trimmed);
    }
    for (final line in planned) {
      if (out.length >= 10) break;
      if (!out.contains(line)) out.add(line);
    }
    final done = isAr
        ? S.of(context).aiAgentActivityCompleted
        : S.of(context).aiAgentActivityCompleted;
    if (out.isNotEmpty && out.last != done) {
      if (out.length >= 10) {
        out[out.length - 1] = done;
      } else {
        out.add(done);
      }
    }
    return out;
  }

  String _previewForReply(AiChatMessage? message) {
    if (message == null) return '';
    return message.text.trim();
  }

  void _setReply(AiChatMessage message) {
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
          _messages.add(AiChatMessage(text: visibleText, isUser: true));
          _controller.clear();
          _messages.add(
            AiChatMessage(
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
        _messages.add(AiChatMessage(text: visibleText, isUser: true));
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

    // Live cinematic thinking starts immediately with a rich locale narrative.
    final responseId = ++_nextResponseId;
    setState(() {
      _messages.add(AiChatMessage(
        text: visibleText,
        isUser: true,
        replyPreview: replyPreview.isEmpty ? null : replyPreview,
      ));
      _controller.clear();
      _replyTo = null;
      _isThinking = true;
      _thinkingStartedAt = DateTime.now();
      _inFlightResponseId = responseId;
      _questionForResponse[responseId] = visibleText;
      _draftImagePaths.clear();
      _draftVideoPath = null;
      _draftVideoDurationSeconds = null;
    });
    _startThinkingNarrative(
      visibleText,
      isAr: isAr,
      seed: responseId * 9973 ^ visibleText.hashCode,
    );
    if (mounted) setState(() {});
    _scrollToEnd();

    try {
      final language = isAr ? 'ar' : 'en';
      await (_connectFuture ??= _connect());
      await _realtime.ask(message: apiText, language: language);
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
        setState(() {
          if (value) {
            _isThinking = true;
            _thinkingStartedAt ??= DateTime.now();
          } else {
            // Snapshot activity onto the reply bubble before hiding live status.
            _commitActivityToInFlightMessage();
            _isThinking = false;
          }
        });
        _scrollToEnd();
      },
      onThinkingStep: (step) {
        if (!mounted) return;
        final trimmed = step.trim();
        if (trimmed.isEmpty) return;
        setState(() {
          _isThinking = true;
          _thinkingStartedAt ??= DateTime.now();
          if (_backendThinkingHints.isEmpty ||
              _backendThinkingHints.last != trimmed) {
            _backendThinkingHints.add(trimmed);
            while (_backendThinkingHints.length > 6) {
              _backendThinkingHints.removeAt(0);
            }
          }
        });
        _scrollToEnd();
      },
      onResponseStarted: () {
        if (!mounted) return;
        final responseId = _inFlightResponseId;
        final isAr = Localizations.localeOf(context).languageCode == 'ar';
        setState(() {
          final activitySnap = _finalizeThinkingSteps(isAr: isAr);
          final durationMs = _thinkingStartedAt == null
              ? null
              : DateTime.now().difference(_thinkingStartedAt!).inMilliseconds;
          _stopThinkingReveal();
          _thinkingSteps.clear();
          _thinkingNarrative = const [];
          _backendThinkingHints.clear();
          _thinkingStartedAt = null;
          _isThinking = false;
          final existing = responseId == null
              ? -1
              : _messages.lastIndexWhere(
                  (m) => !m.isUser && m.responseId == responseId,
                );
          if (existing >= 0) {
            // Cards may have created the bubble first — keep listings.
            final prev = _messages[existing];
            final mergedSteps = prev.thinkingSteps.isNotEmpty
                ? List<String>.from(prev.thinkingSteps)
                : activitySnap;
            _messages[existing] = AiChatMessage(
              text: prev.text,
              isUser: false,
              thinkingSteps: mergedSteps,
              thinkingDurationMs: prev.thinkingDurationMs ?? durationMs,
              showMediaUpload:
                  _pendingAdMediaButton || _planMode || prev.showMediaUpload,
              showSupportCallbackForm: prev.showSupportCallbackForm,
              supportQuestion: prev.supportQuestion,
              responseId: prev.responseId ?? responseId,
              replyPreview: prev.replyPreview,
              listings: List<MyListingProductModel>.from(prev.listings),
            );
          } else {
            _messages.add(
              AiChatMessage(
                text: '',
                isUser: false,
                thinkingSteps: activitySnap,
                thinkingDurationMs: durationMs,
                showMediaUpload: _pendingAdMediaButton || _planMode,
                responseId: responseId,
              ),
            );
          }
          // Keep the button available for the whole plan-mode conversation.
          if (!_planMode) {
            _pendingAdMediaButton = false;
          }
        });
      },
      onDelta: (value) {
        if (!mounted) return;
        setState(() {
          if (_isThinking ||
              _thinkingSteps.isNotEmpty ||
              _thinkingNarrative.isNotEmpty) {
            _commitActivityToInFlightMessage();
          }
          _isThinking = false;
          _stopThinkingReveal();
          _thinkingSteps.clear();
          _thinkingNarrative = const [];
          _backendThinkingHints.clear();
          _thinkingStartedAt = null;
          final responseId = _inFlightResponseId;
          final byId = responseId == null
              ? -1
              : _messages.lastIndexWhere(
                  (m) => !m.isUser && m.responseId == responseId,
                );
          if (byId >= 0) {
            _messages[byId].text += value;
          } else if (_messages.isEmpty || _messages.last.isUser) {
            _messages.add(
              AiChatMessage(
                text: value,
                isUser: false,
                thinkingSteps: const [],
                responseId: responseId,
              ),
            );
          } else {
            _messages.last.text += value;
          }
        });
        _scrollToEnd();
      },
      onListings: (listings) {
        if (!mounted) return;
        final parsed = AiProductListings.parse(listings);
        if (parsed.isEmpty) return;
        _attachListingsToInFlightReply(parsed);
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
        var supportQuestion = responseId == null
            ? null
            : _questionForResponse[responseId];
        if (supportQuestion == null || supportQuestion.trim().isEmpty) {
          final fromHistory = _messages
              .reversed
              .where((m) => m.isUser)
              .map((m) => m.text.trim())
              .where((t) => t.isNotEmpty);
          supportQuestion = fromHistory.isEmpty ? null : fromHistory.first;
        } else {
          supportQuestion = supportQuestion.trim();
        }
        // Fallback: show callback form when user asked for human/tech support
        // even if the server flag is missing (older hub / phrasing miss).
        final shouldShowForm = offerSupportCallback ||
            looksLikeSupportCallbackIntent(supportQuestion) ||
            looksLikeSupportCallbackCue(finalAnswer) ||
            looksLikeTemporaryAssistantFailure(finalAnswer);
        final parsedListings = AiProductListings.parse(listings);
        final serverSteps = (thinkingSteps ?? const <String>[])
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
        var needsListingHydrate = false;
        setState(() {
          if (_isThinking ||
              _thinkingSteps.isNotEmpty ||
              _thinkingNarrative.isNotEmpty) {
            _commitActivityToInFlightMessage();
          }
          _isThinking = false;
          _stopThinkingReveal();
          _thinkingSteps.clear();
          _thinkingNarrative = const [];
          _backendThinkingHints.clear();
          _thinkingStartedAt = null;
          _inFlightResponseId = null;
          var targetIndex = responseId == null
              ? -1
              : _messages.lastIndexWhere(
                  (m) => !m.isUser && m.responseId == responseId,
                );
          // Fall back to the latest assistant bubble AFTER the latest user message
          // (never the welcome message at the top of a fresh chat).
          if (targetIndex < 0) {
            final lastUser = _messages.lastIndexWhere((m) => m.isUser);
            for (var i = _messages.length - 1; i > lastUser; i--) {
              if (!_messages[i].isUser) {
                targetIndex = i;
                break;
              }
            }
          }
          if (targetIndex >= 0) {
            final target = _messages[targetIndex];
            if (finalAnswer.isNotEmpty &&
                (target.text.isEmpty ||
                    looksLikeTemporaryAssistantFailure(target.text))) {
              target.text = finalAnswer;
            }
            final keptSteps = target.thinkingSteps.isNotEmpty
                ? List<String>.from(target.thinkingSteps)
                : List<String>.from(serverSteps);
            final nextListings = parsedListings.isNotEmpty
                ? List<MyListingProductModel>.from(parsedListings)
                : List<MyListingProductModel>.from(target.listings);
            // Replace list entry so ListView keys/rebuild pick up cards + form.
            _messages[targetIndex] = AiChatMessage(
              text: target.text,
              isUser: false,
              thinkingSteps: keptSteps,
              thinkingDurationMs: target.thinkingDurationMs,
              showMediaUpload: target.showMediaUpload,
              showSupportCallbackForm: shouldShowForm,
              supportQuestion: supportQuestion,
              responseId: target.responseId ?? responseId,
              replyPreview: target.replyPreview,
              listings: nextListings,
            );
            needsListingHydrate = nextListings.isEmpty;
          } else if (finalAnswer.isNotEmpty ||
              parsedListings.isNotEmpty ||
              shouldShowForm) {
            _messages.add(
              AiChatMessage(
                text: finalAnswer.isNotEmpty
                    ? finalAnswer
                    : (isAr
                        ? 'اكتب اسمك ورقم تليفونك وبريدك الإلكتروني، وهيتم الاتصال بيك خلال خمس دقايق.'
                        : 'Please leave your name, phone, and email — we\'ll call you within five minutes.'),
                isUser: false,
                thinkingSteps: List<String>.from(serverSteps),
                showSupportCallbackForm: shouldShowForm,
                supportQuestion: supportQuestion,
                responseId: responseId,
                listings: parsedListings,
              ),
            );
            needsListingHydrate = parsedListings.isEmpty;
          }
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
        // If SignalR dropped cards, pull them from the persisted conversation
        // (same source that already works when opening history).
        if (needsListingHydrate) {
          unawaited(_hydrateListingsFromHistory(responseId: responseId));
        }
        if (_voiceConversationMode && _voiceAgent == null && finalAnswer.isNotEmpty) {
          unawaited(_speakAssistantReply(finalAnswer));
        } else if (_voiceConversationMode && _voiceAgent == null) {
          unawaited(_onAssistantSpeechFinished());
        }
      },
      onError: (message) {
        // If text already streamed, SignalR may still fail on the completed
        // payload — keep the reply and still attach the support form when needed.
        if (_shouldIgnoreAssistantError()) {
          _attachSupportFormToInFlightReply();
          return;
        }
        _showConnectionError(message: message);
        if (_voiceConversationMode && _voiceAgent == null) {
          unawaited(_onAssistantSpeechFinished());
        }
      },
    );
  }

  /// Moves live activity steps onto the in-flight assistant bubble (collapsed later).
  void _commitActivityToInFlightMessage() {
    if (_thinkingSteps.isEmpty &&
        _thinkingNarrative.isEmpty &&
        _thinkingStartedAt == null) {
      return;
    }
    final responseId = _inFlightResponseId;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final snap = _finalizeThinkingSteps(isAr: isAr);
    final durationMs = _thinkingStartedAt == null
        ? null
        : DateTime.now().difference(_thinkingStartedAt!).inMilliseconds;
    _stopThinkingReveal();

    var targetIndex = responseId == null
        ? -1
        : _messages.lastIndexWhere(
            (m) => !m.isUser && m.responseId == responseId,
          );
    if (targetIndex < 0) {
      final lastUser = _messages.lastIndexWhere((m) => m.isUser);
      for (var i = _messages.length - 1; i > lastUser; i--) {
        if (!_messages[i].isUser) {
          targetIndex = i;
          break;
        }
      }
    }

    if (targetIndex >= 0) {
      final prev = _messages[targetIndex];
      if (prev.thinkingSteps.isEmpty && snap.isNotEmpty) {
        _messages[targetIndex] = AiChatMessage(
          text: prev.text,
          isUser: false,
          thinkingSteps: snap,
          thinkingDurationMs: prev.thinkingDurationMs ?? durationMs,
          showMediaUpload: prev.showMediaUpload,
          showSupportCallbackForm: prev.showSupportCallbackForm,
          supportQuestion: prev.supportQuestion,
          responseId: prev.responseId ?? responseId,
          replyPreview: prev.replyPreview,
          listings: List<MyListingProductModel>.from(prev.listings),
        );
      } else if (prev.thinkingDurationMs == null && durationMs != null) {
        _messages[targetIndex] = AiChatMessage(
          text: prev.text,
          isUser: false,
          thinkingSteps: List<String>.from(prev.thinkingSteps),
          thinkingDurationMs: durationMs,
          showMediaUpload: prev.showMediaUpload,
          showSupportCallbackForm: prev.showSupportCallbackForm,
          supportQuestion: prev.supportQuestion,
          responseId: prev.responseId ?? responseId,
          replyPreview: prev.replyPreview,
          listings: List<MyListingProductModel>.from(prev.listings),
        );
      }
      return;
    }

    if (snap.isEmpty) return;
    _messages.add(
      AiChatMessage(
        text: '',
        isUser: false,
        thinkingSteps: snap,
        thinkingDurationMs: durationMs,
        responseId: responseId,
      ),
    );
  }

  void _attachListingsToInFlightReply(List<MyListingProductModel> listings) {
    if (!mounted || listings.isEmpty) return;
    final responseId = _inFlightResponseId;
    setState(() {
      var targetIndex = responseId == null
          ? -1
          : _messages.lastIndexWhere(
              (m) => !m.isUser && m.responseId == responseId,
            );
      if (targetIndex < 0) {
        final lastUser = _messages.lastIndexWhere((m) => m.isUser);
        for (var i = _messages.length - 1; i > lastUser; i--) {
          if (!_messages[i].isUser) {
            targetIndex = i;
            break;
          }
        }
      }
      if (targetIndex < 0) {
        // Cards arrived before the assistant bubble — park them on a placeholder.
        _messages.add(
          AiChatMessage(
            text: '',
            isUser: false,
            thinkingSteps: const [],
            responseId: responseId,
            listings: List<MyListingProductModel>.from(listings),
          ),
        );
        return;
      }
      final target = _messages[targetIndex];
      if (target.listings.isNotEmpty) return;
      _messages[targetIndex] = AiChatMessage(
        text: target.text,
        isUser: false,
        thinkingSteps: List<String>.from(target.thinkingSteps),
        thinkingDurationMs: target.thinkingDurationMs,
        showMediaUpload: target.showMediaUpload,
        showSupportCallbackForm: target.showSupportCallbackForm,
        supportQuestion: target.supportQuestion,
        responseId: target.responseId ?? responseId,
        replyPreview: target.replyPreview,
        listings: List<MyListingProductModel>.from(listings),
      );
    });
    _scrollToEnd();
  }

  /// Live SignalR sometimes drops nested listing objects; the DB row still has
  /// them (history works). Re-fetch the latest assistant message for this session.
  Future<void> _hydrateListingsFromHistory({int? responseId}) async {
    final token = AuthService.instance.currentToken?.trim();
    if (token == null || token.isEmpty) return;

    // Small delay so AppendAssistantMessageAsync has committed.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    final sessionId = _realtime.sessionId;
    final listResult = await _historyRepository.listConversations(
      token: token,
      page: 1,
      pageSize: 10,
    );
    if (!mounted) return;

    await listResult.fold<Future<void>>(
      (_) async {},
      (page) async {
        AiConversationSummary? match;
        for (final item in page.items) {
          if (item.clientSessionId == sessionId) {
            match = item;
            break;
          }
        }
        match ??= page.items.isEmpty ? null : page.items.first;
        if (match == null || match.id.isEmpty) return;

        final messagesResult = await _historyRepository.getConversationMessages(
          token: token,
          conversationId: match.id,
          limit: 8,
        );
        if (!mounted) return;

        messagesResult.fold(
          (_) {},
          (messagesPage) {
            AiConversationMessageModel? lastAssistant;
            for (var i = messagesPage.messages.length - 1; i >= 0; i--) {
              final msg = messagesPage.messages[i];
              if (msg.role.toLowerCase() == 'assistant' &&
                  msg.listings.isNotEmpty) {
                lastAssistant = msg;
                break;
              }
            }
            if (lastAssistant == null) return;
            final parsed = AiProductListings.parse(lastAssistant.listings);
            if (parsed.isEmpty) return;

            setState(() {
              var targetIndex = responseId == null
                  ? -1
                  : _messages.lastIndexWhere(
                      (m) => !m.isUser && m.responseId == responseId,
                    );
              if (targetIndex < 0) {
                final lastUser = _messages.lastIndexWhere((m) => m.isUser);
                for (var i = _messages.length - 1; i > lastUser; i--) {
                  if (!_messages[i].isUser) {
                    targetIndex = i;
                    break;
                  }
                }
              }
              if (targetIndex < 0) return;
              final target = _messages[targetIndex];
              if (target.listings.isNotEmpty) return;
              _messages[targetIndex] = AiChatMessage(
                text: target.text,
                isUser: false,
                thinkingSteps: List<String>.from(target.thinkingSteps),
                thinkingDurationMs: target.thinkingDurationMs,
                showMediaUpload: target.showMediaUpload,
                showSupportCallbackForm: target.showSupportCallbackForm,
                supportQuestion: target.supportQuestion,
                responseId: target.responseId,
                replyPreview: target.replyPreview,
                listings: parsed,
              );
            });
            _scrollToEnd();
          },
        );
      },
    );
  }

  void _attachSupportFormToInFlightReply() {
    if (!mounted) return;
    final responseId = _inFlightResponseId;
    final supportQuestion = responseId == null
        ? null
        : _questionForResponse[responseId];
    setState(() {
      _isThinking = false;
      final targetIndex = responseId == null
          ? _messages.lastIndexWhere((m) => !m.isUser)
          : _messages.lastIndexWhere(
              (m) => !m.isUser && m.responseId == responseId,
            );
      if (targetIndex < 0) return;
      final target = _messages[targetIndex];
      final shouldShow = looksLikeSupportCallbackIntent(supportQuestion) ||
          looksLikeSupportCallbackCue(target.text) ||
          looksLikeTemporaryAssistantFailure(target.text) ||
          target.showSupportCallbackForm;
      if (!shouldShow) return;
      _messages[targetIndex] = AiChatMessage(
        text: target.text,
        isUser: false,
        thinkingSteps: List<String>.from(target.thinkingSteps),
        thinkingDurationMs: target.thinkingDurationMs,
        showMediaUpload: target.showMediaUpload,
        showSupportCallbackForm: true,
        supportQuestion: supportQuestion ?? target.supportQuestion,
        responseId: target.responseId,
        replyPreview: target.replyPreview,
        listings: List<MyListingProductModel>.from(target.listings),
      );
    });
    _scrollToEnd();
  }

  bool _hasSubstantiveAssistantReply({int? responseId}) {
    final index = responseId == null
        ? _messages.lastIndexWhere((m) => !m.isUser)
        : _messages.lastIndexWhere(
            (m) => !m.isUser && m.responseId == responseId,
          );
    if (index < 0) return false;
    final text = _messages[index].text.trim();
    if (text.isEmpty) return false;
    if (looksLikeTemporaryAssistantFailure(text)) return false;
    if (_isGenericHighDemandCopy(text)) return false;
    return true;
  }

  bool _shouldIgnoreAssistantError() {
    for (final step in _thinkingSteps) {
      if (_looksLikeAdCreationThinkingStep(step)) return true;
    }

    if (_hasSubstantiveAssistantReply(responseId: _inFlightResponseId)) {
      return true;
    }

    if (_inFlightResponseId == null && _hasSubstantiveAssistantReply()) {
      return true;
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

  bool _isGenericHighDemandCopy(String text) {
    final trimmed = text.trim();
    return trimmed == DioUserFacingMessage.englishHighDemand ||
        trimmed == DioUserFacingMessage.arabicHighDemand;
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

  void _showConnectionError({String? message}) {
    if (!mounted || _shouldIgnoreAssistantError()) return;
    final responseId = _inFlightResponseId;
    final raw = message?.trim() ?? '';
    final looksTechnical = raw.contains('{') ||
        raw.contains('Exception') ||
        raw.contains('http://') ||
        raw.contains('https://') ||
        raw.toLowerCase().contains('stack') ||
        raw.toLowerCase().contains('signalr');
    final display = (!looksTechnical && raw.isNotEmpty)
        ? raw
        : S.of(context).aiAgentActivityError;
    final supportQuestion = responseId == null
        ? null
        : _questionForResponse[responseId];
    final showForm = looksLikeSupportCallbackIntent(supportQuestion) ||
        looksLikeSupportCallbackCue(display) ||
        looksLikeTemporaryAssistantFailure(display);
    setState(() {
      _isThinking = false;
      _thinkingStartedAt = null;
      _inFlightResponseId = null;
      _stopThinkingReveal();
      _thinkingSteps.clear();
      _thinkingNarrative = const [];
      _backendThinkingHints.clear();
      final targetIndex = responseId == null
          ? _messages.lastIndexWhere((m) => !m.isUser)
          : _messages.lastIndexWhere(
              (m) => !m.isUser && m.responseId == responseId,
            );
      if (targetIndex >= 0 && _messages[targetIndex].text.trim().isEmpty) {
        _messages[targetIndex].text = display;
        _messages[targetIndex].showSupportCallbackForm = showForm;
        _messages[targetIndex].supportQuestion = supportQuestion;
        return;
      }
      _messages.add(
        AiChatMessage(
          text: display,
          isUser: false,
          showSupportCallbackForm: showForm,
          supportQuestion: supportQuestion,
          responseId: responseId,
        ),
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
              () {
                final mapped = <AiChatMessage>[];
                for (var i = 0; i < page.messages.length; i++) {
                  final message = page.messages[i];
                  final isUser = message.role.toLowerCase() == 'user';
                  String? priorUserQuestion;
                  for (var j = i - 1; j >= 0; j--) {
                    if (page.messages[j].role.toLowerCase() == 'user') {
                      priorUserQuestion = page.messages[j].content;
                      break;
                    }
                  }
                  final showForm = !isUser &&
                      (looksLikeSupportCallbackCue(message.content) ||
                          looksLikeTemporaryAssistantFailure(message.content) ||
                          looksLikeSupportCallbackIntent(priorUserQuestion));
                  mapped.add(
                    AiChatMessage(
                      text: message.content,
                      isUser: isUser,
                      listings: AiProductListings.parse(message.listings),
                      thinkingSteps: List<String>.from(message.thinkingSteps),
                      showSupportCallbackForm: showForm,
                      supportQuestion: priorUserQuestion,
                    ),
                  );
                }
                return mapped;
              }(),
            );
        });
        _scrollToEnd();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _planMode
        ? const AiChatColors(isDark: true, planMode: true)
        : AiChatColors.of(context);
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: Stack(
        children: [
          Column(
            children: [
              AiChatHeader(
                planMode: _planMode,
                onCancelPlan: _planMode ? _cancelAdPlan : null,
                onOpenHistory: AuthService.instance.isAuthenticated
                    ? (_historyLoading ? null : _openHistorySheet)
                    : null,
                historyLoading: _historyLoading,
                onOpenVoiceSettings: () async {
                  if (AppRoutes.shouldSkipPush(
                    context,
                    AppRoutes.kAiAssistantVoiceSettingsView,
                  )) {
                    return;
                  }
                  await context.push(AppRoutes.kAiAssistantVoiceSettingsView);
                  if (!mounted) return;
                  final male = await AiAssistantVoicePrefs.isMale();
                  final next =
                      male ? AiVoiceGender.male : AiVoiceGender.female;
                  if (next != _voiceGender) {
                    await _setVoiceGender(next);
                  }
                },
                voiceGender: _voiceGender,
                voiceConversationMode: _voiceConversationMode,
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
                  itemCount: _messages.length +
                      (_isThinking && !_voiceConversationMode ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isThinking &&
                        !_voiceConversationMode &&
                        index == _messages.length) {
                      return AiAgentActivityBubble(
                        steps: List<String>.from(_thinkingSteps),
                        narrative: List<String>.from(_thinkingNarrative),
                        startedAt: _thinkingStartedAt,
                        colors: colors,
                      );
                    }
                    final msg = _messages[index];
                    return AiSwipeToReply(
                      key: ValueKey(
                        'msg-$index-${msg.responseId}-'
                        '${msg.showSupportCallbackForm}-'
                        '${msg.listings.length}-${msg.text.length}',
                      ),
                      onReply: () => _setReply(msg),
                      child: AiMessageBubble(
                        message: msg,
                        colors: colors,
                        onPickAdMedia: _pickAdMedia,
                        uploadingAdMedia: _uploadingAdMedia,
                        sessionId: _realtime.sessionId,
                        // Keep the form mounted so the success state remains visible.
                        onSupportCallbackSubmitted: null,
                      ),
                    );
                  },
                ),
              ),
              AiComposer(
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
                onListeningChanged: (listening) {
                  if (mounted) setState(() => _micListening = listening);
                },
                onTranscribingChanged: (transcribing) {
                  if (mounted) setState(() => _micTranscribing = transcribing);
                },
              ),
            ],
          ),
          if (_voiceConversationMode)
            Positioned.fill(
              child: AiVoiceCallOverlay(
                phase: _callPhase,
                voiceConversationMode: _voiceConversationMode,
                isProcessing: _voiceCallProcessing,
                onEndCall: () => _setVoiceConversationMode(false),
                thinkingSteps: List<String>.from(_thinkingSteps),
                micMuted: _micMuted,
                micActive: _micListening,
                voiceGenderLabel: _voiceGenderLabel,
                onToggleMicMute: () => unawaited(_toggleMicMute()),
                onToggleMic: () => unawaited(_toggleOverlayMic()),
              ),
            ),
        ],
      ),
    );
  }
}
