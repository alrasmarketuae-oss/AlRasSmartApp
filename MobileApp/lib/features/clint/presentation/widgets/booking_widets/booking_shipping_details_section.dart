import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_card.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_design.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/booking_widets/booking_details_section_title.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

/// Labeled shipping & route block for booking ads (matches admin detail fields).
class BookingShippingDetailsSection extends StatelessWidget {
  const BookingShippingDetailsSection({
    super.key,
    required this.product,
    required this.fontFamily,
  });

  final MyListingProductModel product;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final shipping = product.shipping;
    final route = _fallbackRoute(isAr);

    final rows = <({IconData icon, String label, String value})>[];

    void addRow(IconData icon, String label, String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return;
      rows.add((icon: icon, label: label, value: trimmed));
    }

    addRow(
      Icons.route_outlined,
      isAr ? 'مسار الشحن (من → إلى)' : 'Shipping route (from → to)',
      route,
    );
    addRow(Icons.public_outlined, s.countryOfOrigin, product.originCountryName);
    addRow(Icons.anchor_outlined, s.loadingPort, product.loadingPortName);
    addRow(
      Icons.flag_outlined,
      s.destinationCountry,
      product.destinationCountryName,
    );
    addRow(
      Icons.directions_boat_outlined,
      s.destinationPort,
      product.arrivalPortName,
    );
    addRow(
      Icons.schedule_outlined,
      s.shippingDurationDays,
      product.shippingDuration,
    );
    addRow(
      Icons.notes_outlined,
      isAr ? 'ملاحظات الشحن الإضافية' : 'Additional shipping notes',
      shipping.additionalShippingNotes,
    );

    if (rows.isEmpty) return const SizedBox.shrink();

    final tiles = rows
        .map(
          (row) => BookingDetailsFactTile(
            icon: row.icon,
            label: row.label,
            fontFamily: fontFamily,
            value: row.value,
          ),
        )
        .toList();

    return BookingDetailsSectionCard(
      title: s.shippingInformation,
      icon: Icons.directions_boat_filled_outlined,
      fontFamily: fontFamily,
      child: BookingDetailsFactsGrid(tiles: tiles),
    );
  }

  String _fallbackRoute(bool isAr) {
    final fromCountry = product.originCountryName.trim();
    final fromPort = product.loadingPortName.trim();
    final toCountry = product.destinationCountryName.trim();
    final toPort = product.arrivalPortName.trim();
    if (fromCountry.isEmpty && toCountry.isEmpty) return '';

    final from = fromPort.isEmpty ? fromCountry : '$fromCountry ($fromPort)';
    final to = toPort.isEmpty ? toCountry : '$toCountry ($toPort)';
    if (from.isEmpty) return to;
    if (to.isEmpty) return from;
    return isAr ? 'من $from → إلى $to' : 'From $from → to $to';
  }
}

class ProductDocumentsSection extends StatelessWidget {
  const ProductDocumentsSection({
    super.key,
    required this.documents,
    required this.fontFamily,
  });

  final List<String> documents;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    final paths = documents
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (paths.isEmpty) return const SizedBox.shrink();

    final s = S.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BookingDetailsSectionTitle(
          title: s.productDocuments,
          fontFamily: fontFamily,
        ),
        SizedBox(height: 8.h),
        BookingDetailsCard(
          children: [
            for (var i = 0; i < paths.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  color: const Color(0xFFEAECF0).withValues(alpha: 0.9),
                ),
              _DocumentTile(
                path: paths[i],
                index: i + 1,
                fontFamily: fontFamily,
                openLabel: isAr ? 'فتح المستند' : 'Open document',
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.path,
    required this.index,
    required this.fontFamily,
    required this.openLabel,
  });

  final String path;
  final int index;
  final String fontFamily;
  final String openLabel;

  String get _fileName {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.isNotEmpty ? parts.last : path;
  }

  String? get _url {
    final url = ApiConstants.resolveMediaUrl(path);
    return url.isEmpty ? null : url;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final url = _url;
        if (url == null) return;
        final uri = Uri.tryParse(url);
        if (uri == null) return;
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
        child: Row(
          children: [
            Icon(
              Icons.description_outlined,
              color: const Color(0xFF3A7DC5),
              size: 22.sp,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF333333),
                      fontFamily: fontFamily,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '$openLabel #$index',
                    style: TextStyle(
                      color: const Color(0xFF3A7DC5),
                      fontFamily: fontFamily,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              size: 18.sp,
              color: const Color(0xFF3A7DC5),
            ),
          ],
        ),
      ),
    );
  }
}
