import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/widgets/app_country_search_field.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateAdLocationDetailsSection extends StatelessWidget {
  const CreateAdLocationDetailsSection({
    super.key,
    required this.countryLabel,
    required this.portLabel,
    required this.selectedCountry,
    required this.ports,
    required this.selectedPort,
    required this.isPortsLoading,
    required this.onCountryChanged,
    required this.onPortChanged,
  });

  final String countryLabel;
  final String portLabel;
  final String? selectedCountry;
  final List<String> ports;
  final String? selectedPort;
  final bool isPortsLoading;
  final ValueChanged<String?> onCountryChanged;
  final ValueChanged<String?> onPortChanged;

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final labelStyle = TextStyle(
      color: const Color(0xFF333333),
      fontFamily: fontFamily,
      fontSize: 14.sp,
      fontWeight: FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(countryLabel, style: labelStyle),
                  SizedBox(height: 8.h),
                  AppCountrySearchField(
                    value: selectedCountry,
                    fontFamily: fontFamily,
                    hintText: S.of(context).enterCountry,
                    onChanged: onCountryChanged,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return S.of(context).thisFieldIsRequired;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (portLabel.isNotEmpty) Text(portLabel, style: labelStyle),
                  if (portLabel.isNotEmpty) SizedBox(height: 8.h),
                  _geoDropdownField(
                    fontFamily: fontFamily,
                    hint: isPortsLoading
                        ? S.of(context).loadingEllipsis
                        : S.of(context).selectPort,
                    value: selectedPort,
                    items: ports,
                    isLoading: isPortsLoading,
                    enabled:
                        selectedCountry != null && ports.isNotEmpty,
                    onChanged: onPortChanged,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return S.of(context).thisFieldIsRequired;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _geoDropdownField({
    required String fontFamily,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
    bool isLoading = false,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      isExpanded: true,
      hint: Text(
        hint,
        style: TextStyle(
          color: const Color(0xFF333333).withValues(alpha: 0.4),
          fontFamily: fontFamily,
          fontSize: 14.sp,
        ),
      ),
      icon: isLoading
          ? SizedBox(
              width: 18.w,
              height: 18.h,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.keyboard_arrow_down_rounded,
              color: const Color(0xFF6B7280),
              size: 20.sp,
            ),
      dropdownColor: Colors.white,
      menuMaxHeight: 320.h,
      style: TextStyle(
        color: const Color(0xFF333333),
        fontFamily: fontFamily,
        fontSize: 14.sp,
      ),
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFFEAECF0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFF3A7DC5), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: enabled && !isLoading ? onChanged : null,
    );
  }
}
