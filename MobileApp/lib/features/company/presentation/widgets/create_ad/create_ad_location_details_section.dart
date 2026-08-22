import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/widgets/app_country_search_field.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_geo_dropdown_field.dart';
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
    this.showPorts = true,
  });

  final String countryLabel;
  final String portLabel;
  final String? selectedCountry;
  final List<String> ports;
  final String? selectedPort;
  final bool isPortsLoading;
  final ValueChanged<String?> onCountryChanged;
  final ValueChanged<String?> onPortChanged;
  final bool showPorts;

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));

    final countryField = AppCountrySearchField(
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
    );

    if (!showPorts) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            countryLabel,
            style: TextStyle(
              color: const Color(0xFF333333),
              fontFamily: fontFamily,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          countryField,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                countryLabel,
                style: TextStyle(
                  color: const Color(0xFF333333),
                  fontFamily: fontFamily,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              countryField,
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: CreateAdGeoDropdownField(
            label: portLabel,
            hint: isPortsLoading
                ? S.of(context).loadingEllipsis
                : S.of(context).selectPort,
            items: ports,
            selectedValue: selectedPort,
            isLoading: isPortsLoading,
            enabled: selectedCountry != null && ports.isNotEmpty,
            onChanged: onPortChanged,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return S.of(context).thisFieldIsRequired;
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}
