import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/product_price_formatter.dart';
import 'package:alrasmarket/core/utils/string_display_format.dart';
import 'package:alrasmarket/core/widgets/cached_app_image.dart';
import 'package:alrasmarket/features/chat/presentation/helpers/ask_for_price_payload.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_details_opener.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Compact product card for Ask-for-price support chat (matches dashboard layout).
/// Shows customer-facing prices after commissions.
class AskForPriceChatProductCard extends StatefulWidget {
  const AskForPriceChatProductCard({
    super.key,
    required this.payload,
    required this.isMe,
  });

  final AskForPricePayload payload;
  final bool isMe;

  @override
  State<AskForPriceChatProductCard> createState() =>
      _AskForPriceChatProductCardState();
}

class _AskForPriceChatProductCardState extends State<AskForPriceChatProductCard> {
  MyListingProductModel? _product;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AskForPriceChatProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.payload.productId != widget.payload.productId) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final product = await ProductDetailsOpener.fetchPublicProductById(
      widget.payload.productId,
    );
    if (!mounted) return;
    setState(() {
      _product = product;
      _loading = false;
    });
  }

  String get _title {
    final fromApi = _product?.localeDisplayName.trim() ?? '';
    if (fromApi.isNotEmpty) return fromApi.capitalizeFirst();
    final fromPayload = widget.payload.productName?.trim() ?? '';
    if (fromPayload.isNotEmpty) return fromPayload.capitalizeFirst();
    return S.of(context).askForPrice;
  }

  String? get _code {
    final fromApi = _product?.productCode.trim() ?? '';
    if (fromApi.isNotEmpty) return fromApi;
    final fromPayload = widget.payload.productCode?.trim() ?? '';
    return fromPayload.isEmpty ? null : fromPayload;
  }

  String? get _quantityLabel {
    final fromPayload = widget.payload.quantityLabel?.trim() ?? '';
    if (fromPayload.isNotEmpty) return fromPayload;
    final product = _product;
    if (product == null) return null;
    final qty = product.quantity.trim();
    final unit = product.unitName.trim();
    if (qty.isEmpty && unit.isEmpty) return null;
    return '$qty $unit'.trim();
  }

  /// Always use customer-facing (post-commission) price for this support card.
  String? get _customerPriceLabel {
    final product = _product;
    if (product != null) {
      final label = ProductPriceFormatter.unitPriceLabel(
        product,
        preferRetail: product.preferRetailFromSearchListing,
        s: S.of(context),
      ).trim();
      if (label.isNotEmpty) return label;
      final fallback = ProductPriceFormatter.priceWithCurrency(
        product,
        preferRetail: product.preferRetailFromSearchListing,
      ).trim();
      if (fallback.isNotEmpty) return fallback;
    }
    final fromPayload = widget.payload.customerPriceLabel?.trim() ?? '';
    return fromPayload.isEmpty ? null : fromPayload;
  }

  String? get _imageUrl {
    final fromApi = _product?.primaryImageUrl?.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    final path = widget.payload.imagePath?.trim() ?? '';
    if (path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final resolved = ApiConstants.resolveMediaUrl(path);
    return resolved.isEmpty ? null : resolved;
  }

  Future<void> _openAd() async {
    await ProductDetailsOpener.openByProductId(
      context,
      productId: widget.payload.productId,
      seed: _product,
      preferRetailChannel: _product?.preferRetailFromSearchListing ?? false,
    );
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
    final priceColor = isMe ? const Color(0xFF7DFFA8) : const Color(0xFF619D51);
    final imageUrl = _imageUrl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openAd,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: 0.72.sw,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: borderColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.all(10.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: SizedBox(
                        width: 88.w,
                        height: 88.w,
                        child: imageUrl == null
                            ? ColoredBox(
                                color: isMe
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : const Color(0xFFF2F4F7),
                                child: Center(
                                  child: _loading
                                      ? SizedBox(
                                          width: 18.w,
                                          height: 18.w,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: isMe
                                                ? Colors.white
                                                : LightColor.defaultColor,
                                          ),
                                        )
                                      : Icon(
                                          Icons.image_not_supported_outlined,
                                          color: mutedColor,
                                          size: 22.sp,
                                        ),
                                ),
                              )
                            : CachedAppImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                width: 88.w,
                                height: 88.w,
                              ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.askForPriceCardTitle,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: isMe
                                  ? Colors.white.withValues(alpha: 0.75)
                                  : LightColor.defaultColor,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            _loading &&
                                    (widget.payload.productName
                                            ?.trim()
                                            .isEmpty ??
                                        true)
                                ? s.askForPriceCardLoading
                                : _title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                              color: titleColor,
                            ),
                          ),
                          if (_quantityLabel != null) ...[
                            SizedBox(height: 2.h),
                            Text(
                              _quantityLabel!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 11.sp,
                                color: mutedColor,
                              ),
                            ),
                          ],
                          if (_code != null) ...[
                            SizedBox(height: 2.h),
                            Text(
                              _code!,
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
                          if (_customerPriceLabel != null)
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${s.askForPriceCustomerPrice} ',
                                    style: TextStyle(
                                      fontFamily: fontFamily,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                      color: mutedColor,
                                    ),
                                  ),
                                  TextSpan(
                                    text: _customerPriceLabel!,
                                    style: TextStyle(
                                      fontFamily: fontFamily,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w800,
                                      color: priceColor,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (_loading)
                            Text(
                              s.askForPriceCardLoading,
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 11.sp,
                                color: mutedColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: borderColor)),
                ),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
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
            ],
          ),
        ),
      ),
    );
  }
}
