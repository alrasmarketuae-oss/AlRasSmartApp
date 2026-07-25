import 'package:alrasmarket/core/constants/country_dial_codes.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CountryCodeField extends StatelessWidget {
  const CountryCodeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.showLabel = true,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final bool showLabel;

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<CountryDialCode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: _CountryDialCodePickerSheet(
          selectedDialCode: value,
        ),
      ),
    );

    if (selected != null) {
      onChanged(selected.dialCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCountry =
        CountryDialCode.findByDialCode(value) ?? CountryDialCode.all.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF333333),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
        ],
        InkWell(
          onTap: () => _openPicker(context),
          borderRadius: BorderRadius.circular(14.r),
          child: Container(
            height: 46.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8.r,
                  offset: Offset(0, 3.h),
                ),
              ],
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedCountry.fieldLabel,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF666666),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: LightColor.defaultColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CountryDialCodePickerSheet extends StatefulWidget {
  const _CountryDialCodePickerSheet({required this.selectedDialCode});

  final String selectedDialCode;

  @override
  State<_CountryDialCodePickerSheet> createState() =>
      _CountryDialCodePickerSheetState();
}

class _CountryDialCodePickerSheetState
    extends State<_CountryDialCodePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CountryDialCode> get _filteredCountries =>
      CountryDialCode.search(_query);

  @override
  Widget build(BuildContext context) {
    final countries = _filteredCountries;
    final selected =
        CountryDialCode.findByDialCode(widget.selectedDialCode);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        child: Column(
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              S.of(context).countryCode,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: S.of(context).enterCountry,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0xFFF4F7FA),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 12.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: ListView.separated(
                itemCount: countries.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: const Color(0xFFEAECF0).withValues(alpha: 0.8),
                ),
                itemBuilder: (context, index) {
                  final country = countries[index];
                  final isSelected =
                      selected?.isoCode == country.isoCode;

                  return ListTile(
                    dense: true,
                    title: Text(
                      country.label,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? LightColor.defaultColor
                            : const Color(0xFF333333),
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: LightColor.defaultColor,
                            size: 20.sp,
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(country),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
