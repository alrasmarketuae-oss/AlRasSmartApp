import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/features/clint/data/models/my_order_model.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Organized refund block: shows Refund ID and opens AI chat on tap.
class TrackOrderRefundIdCard extends StatelessWidget {
  const TrackOrderRefundIdCard({
    super.key,
    required this.order,
    required this.fontFamily,
  });

  final MyOrderModel order;
  final String fontFamily;

  static bool shouldShow(MyOrderModel order) {
    final id = order.stripeRefundId?.trim();
    return order.isRefunded || (id != null && id.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final refundId = order.stripeRefundId?.trim() ?? '';
    final refundedOn = _formatRefundDate(order.refundedAtUtc, isAr);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: refundId.isEmpty
            ? null
            : () => _openAiRefundLookup(context, refundId: refundId, isAr: isAr),
        borderRadius: BorderRadius.circular(14.r),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.verified_outlined,
                    color: const Color(0xFF059669),
                    size: 22.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      s.orderRefundCompleted,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF065F46),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                s.orderRefundProcessedFromOurSide,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 13.sp,
                  height: 1.45,
                  color: const Color(0xFF047857),
                ),
              ),
              if (refundedOn != null) ...[
                SizedBox(height: 8.h),
                Text(
                  '${s.orderRefundProcessedOnLabel}: $refundedOn',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF065F46),
                  ),
                ),
              ],
              if (refundId.isNotEmpty) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: const Color(0xFFD1FAE5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.orderRefundIdLabel,
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              refundId,
                              style: TextStyle(
                                fontFamily: AppFonts.familyFor(
                                  const Locale('en'),
                                ),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111827),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: refundId));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.orderRefundIdCopied)),
                          );
                        },
                        icon: Icon(
                          Icons.copy_rounded,
                          size: 18.sp,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Icon(
                      Icons.smart_toy_outlined,
                      size: 18.sp,
                      color: const Color(0xFF2563EB),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        s.orderRefundAskAiHint,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1D4ED8),
                          height: 1.35,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: const Color(0xFF2563EB),
                      size: 22.sp,
                    ),
                  ],
                ),
              ],
              SizedBox(height: 8.h),
              Text(
                s.orderRefundBankDelayHint,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 12.sp,
                  height: 1.4,
                  color: const Color(0xFF047857),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String? _formatRefundDate(String? raw, bool isAr) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return raw.trim();
    final local = parsed.toLocal();
    return DateFormat(
      isAr ? 'd MMMM yyyy، h:mm a' : 'd MMM yyyy, h:mm a',
      isAr ? 'ar' : 'en',
    ).format(local);
  }

  static void _openAiRefundLookup(
    BuildContext context, {
    required String refundId,
    required bool isAr,
  }) {
    final prompt = isAr
        ? 'عايز أستعلم عن حالة الاسترداد برقم Refund ID التالي: $refundId. '
            'قولي هل تم الاسترداد من ناحيتكم ومتى، وطمنّي إن المبلغ غالباً يظهر في البنك خلال 3 إلى 5 أيام عمل حسب البنك.'
        : 'Please check my refund status for Refund ID: $refundId. '
            'Confirm whether you already processed the refund and on which date, '
            'and reassure me that banks usually show the amount in 3–5 business days.';

    context.push(
      AppRoutes.kAiAssistantChatView,
      extra: {'initialMessage': prompt},
    );
  }
}
