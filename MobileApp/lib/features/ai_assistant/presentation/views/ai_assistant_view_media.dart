part of 'ai_assistant_view.dart';

mixin _AiAssistantMediaMixin on _AiAssistantViewStateBase {
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
        AiChatMessage(
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
}
