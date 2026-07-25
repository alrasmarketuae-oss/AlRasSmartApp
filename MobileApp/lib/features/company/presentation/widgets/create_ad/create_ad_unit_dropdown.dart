import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_form_field_styles.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_unit_options.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateAdUnitDropdown extends StatelessWidget {
  const CreateAdUnitDropdown({
    super.key,
    required this.selectedUnit,
    required this.onChanged,
    this.isLocked = false,
    this.matchRowHeight = false,
  });

  final String selectedUnit;
  final ValueChanged<String> onChanged;
  final bool isLocked;
  final bool matchRowHeight;

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final s = S.of(context);

    final fieldTextStyle = TextStyle(
      color: const Color(0xFF333333),
      fontFamily: fontFamily,
      fontSize: 14.sp,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );

    final canonicalSelected = CreateAdUnitOptions.canonical(selectedUnit);
    final displayLabel = CreateAdUnitOptions.localizedLabel(canonicalSelected, s);

    if (isLocked) {
      final locked = InputDecorator(
        decoration: CreateAdFormFieldStyles.dropdownDecorator().copyWith(
          fillColor: const Color(0xFFF3F4F6),
        ),
        child: Text(
          displayLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: fieldTextStyle,
        ),
      );
      if (matchRowHeight) {
        return CreateAdFormFieldStyles.buildRowDropdown(locked);
      }
      return locked;
    }

    final options = CreateAdUnitOptions.values.contains(canonicalSelected)
        ? CreateAdUnitOptions.values
        : <String>[canonicalSelected, ...CreateAdUnitOptions.values];

    // Key forces FormField to follow parent selectedUnit (initialValue alone does not).
    final dropdown = DropdownButtonFormField<String>(
      key: ValueKey('unit-dropdown-$canonicalSelected'),
      initialValue: canonicalSelected,
      isExpanded: true,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 22.sp,
        color: const Color(0xFF6B7280),
      ),
      decoration: CreateAdFormFieldStyles.dropdownDecorator(),
      style: fieldTextStyle,
      selectedItemBuilder: (context) => options
          .map(
            (unit) => SizedBox(
              width: double.infinity,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  CreateAdUnitOptions.localizedLabel(unit, s),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: fieldTextStyle,
                ),
              ),
            ),
          )
          .toList(),
      items: options
          .map(
            (unit) => DropdownMenuItem<String>(
              value: unit,
              child: Text(
                CreateAdUnitOptions.localizedLabel(unit, s),
                style: fieldTextStyle,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null || value == canonicalSelected) return;
        onChanged(value);
      },
    );

    if (matchRowHeight) {
      return CreateAdFormFieldStyles.buildRowDropdown(dropdown);
    }

    return dropdown;
  }
}
