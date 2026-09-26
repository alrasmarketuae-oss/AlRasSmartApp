import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/string_display_format.dart';
import 'package:alrasmarket/core/widgets/cached_app_image.dart';
import 'package:alrasmarket/features/chat/presentation/controller/chat_cubit.dart';
import 'package:alrasmarket/features/chat/presentation/helpers/ask_supplier_price_payload.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_details_opener.dart';
import 'package:alrasmarket/features/company/domain/usecases/create_ad_usecases.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Product card + Yes/No for admin→supplier price confirmation in support chat.
class AskSupplierPriceChatCard extends StatefulWidget {
  const AskSupplierPriceChatCard({
    super.key,
    required this.payload,
    required this.isMe,
    this.initiallyAnswered = false,
  });

  final AskSupplierPricePayload payload;
  final bool isMe;
  final bool initiallyAnswered;

  @override
  State<AskSupplierPriceChatCard> createState() =>
      _AskSupplierPriceChatCardState();
}

class _AskSupplierPriceChatCardState extends State<AskSupplierPriceChatCard> {
  late bool _answered = widget.initiallyAnswered;
  bool _showPriceInput = false;
  bool _submitting = false;
  String? _error;
  final _priceController = TextEditingController();

  @override
  void didUpdateWidget(covariant AskSupplierPriceChatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initiallyAnswered && !_answered) {
      _answered = true;
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  bool get _isAsk => widget.payload.kind == AskSupplierPayloadKind.ask;
  bool get _canRespond =>
      _isAsk && !widget.isMe && !_answered && !_submitting;

  String? _resolveMediaUrl(String? path) {
    final raw = path?.trim() ?? '';
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    final resolved = ApiConstants.resolveMediaUrl(raw);
    return resolved.isEmpty ? null : resolved;
  }

  Future<void> _onYes() async {
    if (!_canRespond) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final content = AskSupplierPricePayload.buildYesReply(
        productId: widget.payload.productId,
        requesterUserId: widget.payload.requesterUserId,
      );
      await context.read<ChatCubit>().sendTextMessage(content);
      if (!mounted) return;
      setState(() {
        _answered = true;
        _submitting = false;
        _showPriceInput = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = S.of(context).askSupplierSendFailed;
      });
    }
  }

  Future<void> _onNo() async {
    if (!_canRespond) return;
    setState(() {
      _showPriceInput = true;
      _error = null;
    });
  }

  Future<void> _submitNewPrice() async {
    if (!_canRespond) return;
    final raw = _priceController.text.trim().replaceAll(',', '.');
    final price = double.tryParse(raw);
    if (price == null || price <= 0) {
      setState(() => _error = S.of(context).askSupplierInvalidPrice);
      return;
    }

    final token = AuthService.instance.currentToken;
    if (token == null || token.isEmpty) {
      setState(() => _error = S.of(context).pleaseLoginToContinue);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final updateResult = await sl<UpdateProductPriceUseCase>()(
      productId: widget.payload.productId,
      usdPrice: price,
      token: token,
    );

    final updateError = updateResult.fold((f) => f.message, (_) => null);
    if (updateError != null) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = updateError;
      });
      return;
    }

    try {
      final content = AskSupplierPricePayload.buildNoReply(
        productId: widget.payload.productId,
        newSupplierPrice: price,
        unitName: widget.payload.unitName,
        requesterUserId: widget.payload.requesterUserId,
      );
      await context.read<ChatCubit>().sendTextMessage(content);
      if (!mounted) return;
      setState(() {
        _answered = true;
        _submitting = false;
        _showPriceInput = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = S.of(context).askSupplierSendFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final isMe = widget.isMe;
    final borderColor = isMe
        ? Colors.white.withValues(alpha: 0.35)
        : AppColors.border(context);
    final cardBg = isMe
        ? Colors.white.withValues(alpha: 0.15)
        : AppColors.scaffold(context);
    final titleColor = isMe ? Colors.white : AppColors.title(context);
    final mutedColor = isMe
        ? Colors.white.withValues(alpha: 0.7)
        : LightColor.greyTextColor;

    if (widget.payload.kind == AskSupplierPayloadKind.reply) {
      return _buildReplyCard(
        s: s,
        fontFamily: fontFamily,
        isMe: isMe,
        borderColor: borderColor,
        cardBg: cardBg,
        titleColor: titleColor,
        mutedColor: mutedColor,
      );
    }

    final title = (widget.payload.productName?.trim().isNotEmpty ?? false)
        ? widget.payload.productName!.trim().capitalizeFirst()
        : s.askSupplierTitle;
    final unit = widget.payload.unitName?.trim();
    final supplierPrice = widget.payload.supplierPriceLabel?.trim();
    final imageUrl = _resolveMediaUrl(widget.payload.imagePath);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 280.w,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: SizedBox(
                      width: 64.w,
                      height: 64.w,
                      child: imageUrl != null
                          ? CachedAppImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              width: 64.w,
                              height: 64.w,
                            )
                          : ColoredBox(
                              color: mutedColor.withValues(alpha: 0.15),
                              child: Icon(
                                Icons.image_outlined,
                                color: mutedColor,
                                size: 22.sp,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.askSupplierTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: mutedColor,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                            height: 1.25,
                          ),
                        ),
                        if (widget.payload.quantityLabel?.trim().isNotEmpty ??
                            false) ...[
                          SizedBox(height: 4.h),
                          Text(
                            widget.payload.quantityLabel!.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 11.sp,
                              color: mutedColor,
                            ),
                          ),
                        ],
                        SizedBox(height: 6.h),
                        Text(
                          (unit != null && unit.isNotEmpty)
                              ? s.askSupplierQuestionWithUnit(unit)
                              : s.askSupplierQuestion,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 12.sp,
                            height: 1.3,
                            color: titleColor,
                          ),
                        ),
                        if (supplierPrice != null &&
                            supplierPrice.isNotEmpty) ...[
                          SizedBox(height: 6.h),
                          Text(
                            unit != null && unit.isNotEmpty
                                ? '$supplierPrice / $unit'
                                : supplierPrice,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: isMe
                                  ? Colors.white
                                  : LightColor.defaultColor,
                            ),
                          ),
                          Text(
                            s.askSupplierPriceBeforeCommission,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 10.sp,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_canRespond || _showPriceInput || _answered) ...[
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: borderColor)),
                ),
                padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_answered)
                      Text(
                        s.askSupplierThanks,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      )
                    else if (_showPriceInput) ...[
                      Text(
                        (unit != null && unit.isNotEmpty)
                            ? s.askSupplierEnterNewPricePerUnit(unit)
                            : s.askSupplierEnterNewPrice,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextField(
                        controller: _priceController,
                        enabled: !_submitting,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,]'),
                          ),
                        ],
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 14.sp,
                          color: AppColors.title(context),
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: s.askSupplierPriceHint,
                          filled: true,
                          fillColor: AppColors.scaffold(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 10.h,
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _submitting
                                  ? null
                                  : () => setState(() {
                                        _showPriceInput = false;
                                        _error = null;
                                      }),
                              child: Text(s.cancel),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: FilledButton(
                              onPressed: _submitting ? null : _submitNewPrice,
                              style: FilledButton.styleFrom(
                                backgroundColor: LightColor.defaultColor,
                              ),
                              child: _submitting
                                  ? SizedBox(
                                      width: 16.w,
                                      height: 16.w,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(s.askSupplierSubmitPrice),
                            ),
                          ),
                        ],
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _submitting ? null : _onNo,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                side: BorderSide(color: Colors.red.shade300),
                              ),
                              child: Text(s.askSupplierNo),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: FilledButton(
                              onPressed: _submitting ? null : _onYes,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF619d51),
                              ),
                              child: _submitting
                                  ? SizedBox(
                                      width: 16.w,
                                      height: 16.w,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(s.askSupplierYes),
                            ),
                          ),
                        ],
                      ),
                    if (_error != null) ...[
                      SizedBox(height: 6.h),
                      Text(
                        _error!,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 11.sp,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 8.h),
                child: TextButton(
                  onPressed: () {
                    ProductDetailsOpener.openByProductId(
                      context,
                      productId: widget.payload.productId,
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    s.askForPriceOpenAd,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: isMe ? Colors.white : LightColor.defaultColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyCard({
    required S s,
    required String fontFamily,
    required bool isMe,
    required Color borderColor,
    required Color cardBg,
    required Color titleColor,
    required Color mutedColor,
  }) {
    final confirmed = widget.payload.confirmed == true;
    final unit = widget.payload.unitName?.trim();
    final newPrice = widget.payload.newSupplierPriceLabel?.trim();

    return Container(
      width: 260.w,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.askSupplierTitle,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: mutedColor,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            confirmed ? s.askSupplierConfirmed : s.askSupplierUpdated,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: confirmed
                  ? (isMe ? Colors.white : const Color(0xFF619d51))
                  : (isMe ? Colors.white : Colors.amber.shade800),
            ),
          ),
          if (!confirmed && newPrice != null && newPrice.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              unit != null && unit.isNotEmpty ? '$newPrice / $unit' : newPrice,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
