import 'package:alrasmarket/core/constants/country_names.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppCountrySearchField extends StatefulWidget {
  const AppCountrySearchField({
    super.key,
    this.value,
    required this.onChanged,
    this.hintText,
    this.validator,
    this.fontFamily,
    this.enabled = true,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final String? hintText;
  final String? Function(String?)? validator;
  final String? fontFamily;
  final bool enabled;

  @override
  State<AppCountrySearchField> createState() => _AppCountrySearchFieldState();
}

class _AppCountrySearchFieldState extends State<AppCountrySearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
  }

  @override
  void didUpdateWidget(AppCountrySearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextValue = widget.value ?? '';
    if (nextValue != _controller.text) {
      _controller.text = nextValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily =
        widget.fontFamily ?? AppFonts.familyFor(Localizations.localeOf(context));
    final hintText = widget.hintText ?? S.of(context).enterCountry;
    final fieldTextStyle = TextStyle(
      color: const Color(0xFF333333).withValues(alpha: 0.8),
      fontFamily: fontFamily,
      fontSize: 14.sp,
    );

    return FormField<String>(
      initialValue: widget.value,
      validator: (value) {
        final trimmed = (value ?? _controller.text).trim();
        if (widget.enabled && trimmed.isNotEmpty) {
          final match = AppCountryNames.all.firstWhere(
            (country) => country.toLowerCase() == trimmed.toLowerCase(),
            orElse: () => '',
          );
          if (match.isNotEmpty) {
            // Sync cubit/controllers before submit geo checks run.
            widget.onChanged(match);
          }
        }
        return widget.validator?.call(trimmed.isEmpty ? null : trimmed);
      },
      builder: (fieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Autocomplete<String>(
              optionsBuilder: (textEditingValue) {
                final query = textEditingValue.text.trim().toLowerCase();
                if (query.isEmpty) {
                  return AppCountryNames.all.take(12);
                }
                return AppCountryNames.all.where(
                  (country) => _matchesCountryQuery(country, query),
                );
              },
              onSelected: widget.enabled
                  ? (selection) {
                      _controller.text = selection;
                      fieldState.didChange(selection);
                      widget.onChanged(selection);
                    }
                  : null,
              displayStringForOption: (option) => option,
              fieldViewBuilder:
                  (context, textEditingController, focusNode, onFieldSubmitted) {
                if (textEditingController.text.isEmpty &&
                    _controller.text.isNotEmpty) {
                  textEditingController.text = _controller.text;
                }

                return TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  enabled: widget.enabled,
                  style: fieldTextStyle,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) {
                    _controller.text = value;
                    final trimmed = value.trim();
                    fieldState.didChange(trimmed.isEmpty ? null : trimmed);
                    if (!widget.enabled) return;
                    if (trimmed.isEmpty) {
                      widget.onChanged(null);
                      return;
                    }
                    final match = AppCountryNames.all.firstWhere(
                      (country) =>
                          country.toLowerCase() == trimmed.toLowerCase(),
                      orElse: () => '',
                    );
                    if (match.isNotEmpty) {
                      widget.onChanged(match);
                    }
                  },
                  onFieldSubmitted: (value) {
                    onFieldSubmitted();
                    final trimmed = value.trim();
                    if (trimmed.isEmpty || !widget.enabled) return;
                    final match = AppCountryNames.all.firstWhere(
                      (country) =>
                          country.toLowerCase() == trimmed.toLowerCase(),
                      orElse: () => trimmed,
                    );
                    if (AppCountryNames.all.contains(match)) {
                      textEditingController.text = match;
                      _controller.text = match;
                      fieldState.didChange(match);
                      widget.onChanged(match);
                    }
                  },
                  onTapOutside: (_) {
                    final trimmed = textEditingController.text.trim();
                    if (trimmed.isEmpty || !widget.enabled) return;
                    final match = AppCountryNames.all.firstWhere(
                      (country) =>
                          country.toLowerCase() == trimmed.toLowerCase(),
                      orElse: () => '',
                    );
                    if (match.isNotEmpty) {
                      textEditingController.text = match;
                      _controller.text = match;
                      fieldState.didChange(match);
                      widget.onChanged(match);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: fieldTextStyle.copyWith(
                      color: const Color(0xFF333333).withValues(alpha: 0.4),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 14.h,
                    ),
                    suffixIcon: Icon(
                      Icons.search_rounded,
                      size: 22.sp,
                      color: const Color(0xFF6B7280),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide:
                          const BorderSide(color: Color(0xFFEAECF0), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide:
                          const BorderSide(color: Color(0xFF3A7DC5), width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide:
                          BorderSide(color: Colors.red.shade400, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide:
                          BorderSide(color: Colors.red.shade400, width: 1.5),
                    ),
                    errorText: fieldState.errorText,
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8.r),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 220.h,
                        maxWidth: MediaQuery.sizeOf(context).width - 48.w,
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            dense: true,
                            title: Text(
                              option,
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 14.sp,
                                color: const Color(0xFF333333),
                              ),
                            ),
                            onTap: () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                onSelected(option);
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

bool _matchesCountryQuery(String country, String query) {
  final normalizedCountry = country.toLowerCase();
  if (normalizedCountry.contains(query)) return true;

  final countryTokens = normalizedCountry.split(RegExp(r'[\s,]+'));
  for (final token in countryTokens) {
    if (token.startsWith(query) || query.startsWith(token)) {
      return true;
    }
  }

  if (query.length >= 3) {
    final prefix = query.substring(0, query.length - 1);
    if (normalizedCountry.contains(prefix)) return true;
  }

  return false;
}
