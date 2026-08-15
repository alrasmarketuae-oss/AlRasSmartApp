import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/features/clint/data/models/international_shipping_post_model.dart';
import 'package:alrasmarket/features/clint/presentation/views/services_views/shipping_price_service_view.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_design.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class ShippingPostDetailsView extends StatefulWidget {
  const ShippingPostDetailsView({super.key, required this.post});

  final InternationalShippingPostModel post;

  @override
  State<ShippingPostDetailsView> createState() =>
      _ShippingPostDetailsViewState();
}

class _ShippingPostDetailsViewState extends State<ShippingPostDetailsView> {
  bool _showPhone = false;

  Future<void> _callPhone() async {
    final phone = widget.post.phoneNumber.trim();
    if (phone.isEmpty) return;
    setState(() => _showPhone = true);
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final post = widget.post;
    final carrierName = post.publisherName.trim().isNotEmpty
        ? post.publisherName
        : s.todayShipping;
    final details = post.details.trim();
    final price20 = ShippingCardHelpers.formatUsdPrice(post.container20ftPriceUsd);
    final price40 = ShippingCardHelpers.formatUsdPrice(post.container40ftPriceUsd);
    final daysMin = post.minDurationDays?.toString() ?? '—';
    final daysMax = post.maxDurationDays?.toString() ?? '—';
    final phoneDisplay = _showPhone
        ? (post.phoneNumber.trim().isEmpty ? '—' : post.phoneNumber)
        : ShippingCardHelpers.maskPhone(post.phoneNumber);

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: Column(
        children: [
          SearchHeader(
            title: carrierName,
            isSearch: false,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
              children: [
                BookingDetailsSectionCard(
                  title: carrierName,
                  icon: Icons.local_shipping_outlined,
                  fontFamily: fontFamily,
                  child: Column(
                    children: [
                      BookingDetailsFactTile(
                        icon: Icons.flag_outlined,
                        label: s.fromLabel,
                        fontFamily: fontFamily,
                        value: '${post.fromCountry}\n${post.fromPort}',
                        valueBold: true,
                      ),
                      BookingDetailsFactTile(
                        icon: Icons.place_outlined,
                        label: s.toLabel,
                        fontFamily: fontFamily,
                        value: '${post.toCountry}\n${post.toPort}',
                        valueBold: true,
                      ),
                      if (post.minDurationDays != null ||
                          post.maxDurationDays != null)
                        BookingDetailsFactTile(
                          icon: Icons.schedule_outlined,
                          label: s.shippingDurationDays,
                          fontFamily: fontFamily,
                          value: s.shippingTimeRange(daysMin, daysMax),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                BookingDetailsSectionCard(
                  title: s.details,
                  icon: Icons.notes_outlined,
                  fontFamily: fontFamily,
                  child: Text(
                    details.isEmpty ? s.noDetailsAvailable : details,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 14.sp,
                      height: 1.5,
                      color: AppColors.title(context),
                    ),
                  ),
                ),
                if (price20.isNotEmpty || price40.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  BookingDetailsSectionCard(
                    title: [
                      if (price20.isNotEmpty) s.price20ftLabel,
                      if (price40.isNotEmpty) s.price40ftLabel,
                    ].join(' · '),
                    icon: Icons.attach_money,
                    fontFamily: fontFamily,
                    child: Column(
                      children: [
                        if (price20.isNotEmpty)
                          BookingDetailsFactTile(
                            icon: Icons.inventory_2_outlined,
                            label: s.container20f,
                            fontFamily: fontFamily,
                            value: price20,
                            valueBold: true,
                            valueColor: const Color(0xFF0066CC),
                          ),
                        if (price40.isNotEmpty)
                          BookingDetailsFactTile(
                            icon: Icons.inventory_2_outlined,
                            label: s.container40f,
                            fontFamily: fontFamily,
                            value: price40,
                            valueBold: true,
                            valueColor: const Color(0xFF0066CC),
                          ),
                      ],
                    ),
                  ),
                ],
                if (post.phoneNumber.trim().isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  BookingDetailsSectionCard(
                    title: s.phoneCall,
                    icon: Icons.phone_outlined,
                    fontFamily: fontFamily,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            phoneDisplay,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: LightColor.defaultColor,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        ElevatedButton(
                          onPressed: _callPhone,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LightColor.defaultColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(s.showNumber),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
