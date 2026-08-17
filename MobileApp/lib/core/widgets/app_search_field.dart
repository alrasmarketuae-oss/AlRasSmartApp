import 'dart:async';

import 'package:alrasmarket/core/router/where_to_go.dart';
import 'package:alrasmarket/core/search/app_search_actions.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/serveses/product_search_index_service.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/widgets/costomtextform.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/company_cubit.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

enum AppSearchMode {
  /// Product catalog search — suggestions + image search.
  /// Suggestions update on each keystroke; products load only on submit.
  catalog,

  /// Inline list filter — no API, no image lens.
  local,
}

/// Unified search bar used across the app (home, results, local filters).
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    this.mode = AppSearchMode.catalog,
    this.initialQuery,
    this.controller,
    this.hintText,
    this.onSubmitted,
    this.onChanged,
    this.onImageSearchTap,
    this.onFilterTap,
    this.showBackButton = true,
    this.showImageSearch = true,
    this.enableSuggestions = true,
  });

  final AppSearchMode mode;
  final String? initialQuery;
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onImageSearchTap;
  final VoidCallback? onFilterTap;
  final bool showBackButton;
  final bool showImageSearch;

  /// Remote autocomplete dropdown (catalog mode) — updates while typing.
  final bool enableSuggestions;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

/// Backward-compatible alias.
typedef SearchFormFiled = AppSearchField;

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final bool _ownsController;
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  bool _pickingSuggestion = false;

  bool get _isCatalog => widget.mode == AppSearchMode.catalog;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = TextEditingController(text: widget.initialQuery ?? '');
      _ownsController = true;
    }

    _controller.addListener(_onQueryChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery &&
        widget.controller == null &&
        widget.initialQuery != null &&
        widget.initialQuery != _controller.text) {
      _controller.text = widget.initialQuery!;
      _refreshSuggestions();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onQueryChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onQueryChanged() {
    widget.onChanged?.call(_controller.text);
    if (_isCatalog && widget.enableSuggestions) {
      _applyPreviewSuggestions();
      unawaited(_refreshSuggestions());
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      Future<void>.delayed(const Duration(milliseconds: 160), () {
        if (!mounted || _pickingSuggestion || _focusNode.hasFocus) return;
        setState(() => _showSuggestions = false);
      });
      return;
    }
    if (_isCatalog && widget.enableSuggestions) {
      unawaited(_refreshSuggestions());
    }
  }

  void _applyPreviewSuggestions() {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      if (_showSuggestions || _suggestions.isNotEmpty) {
        setState(() {
          _suggestions = const [];
          _showSuggestions = false;
        });
      }
      return;
    }

    final items =
        ProductSearchIndexService.instance.preview(query).toList();
    if (!mounted) return;
    if (items.isEmpty) return;
    setState(() {
      _suggestions = items;
      _showSuggestions = _focusNode.hasFocus;
    });
  }

  Future<void> _refreshSuggestions() async {
    if (!_isCatalog || !widget.enableSuggestions) return;

    final query = _controller.text;
    if (query.trim().isEmpty) {
      if (_showSuggestions || _suggestions.isNotEmpty) {
        setState(() {
          _suggestions = const [];
          _showSuggestions = false;
        });
      }
      return;
    }

    final items =
        await ProductSearchIndexService.instance.suggestRemote(query);
    if (!mounted || _controller.text != query) return;
    setState(() {
      _suggestions = items;
      _showSuggestions = _focusNode.hasFocus && items.isNotEmpty;
    });
  }

  void _submit(String value) {
    setState(() => _showSuggestions = false);
    FocusScope.of(context).unfocus();
    if (widget.onSubmitted != null) {
      widget.onSubmitted!(value);
      return;
    }
    AppSearchActions.submit(context, value);
  }

  Future<void> _searchByImage() async {
    setState(() => _showSuggestions = false);
    if (widget.onImageSearchTap != null) {
      widget.onImageSearchTap!();
      return;
    }
    await AppSearchActions.searchByImage(context);
  }

  void _goBack() {
    FocusScope.of(context).unfocus();

    final clint = _maybeReadClintCubit(context);
    if (clint != null && clint.currentIndex != 0) {
      clint.setTab(0);
      return;
    }
    final company = _maybeReadCompanyCubit(context);
    if (company != null && company.currentIndex != 0) {
      company.setTab(0);
      return;
    }

    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(whereToGo());
  }

  static ClintCubit? _maybeReadClintCubit(BuildContext context) {
    try {
      return context.read<ClintCubit>();
    } catch (_) {
      return null;
    }
  }

  static CompanyCubit? _maybeReadCompanyCubit(BuildContext context) {
    try {
      return context.read<CompanyCubit>();
    } catch (_) {
      return null;
    }
  }

  void _pickSuggestion(String value) {
    _pickingSuggestion = true;
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    _submit(value);
    _pickingSuggestion = false;
  }

  static String marketTld() {
    final phone = (AuthService.instance.currentUserPhone ?? '')
        .replaceAll(RegExp(r'[\s\-]'), '');
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');

    if (digits.startsWith('+971') ||
        digits.startsWith('971') ||
        AuthService.instance.isUaePhoneNumber) {
      return 'ae';
    }
    if (digits.startsWith('+966') || digits.startsWith('966')) return 'sa';
    if (digits.startsWith('+974') || digits.startsWith('974')) return 'qa';
    if (digits.startsWith('+973') || digits.startsWith('973')) return 'bh';
    if (digits.startsWith('+968') || digits.startsWith('968')) return 'om';
    if (digits.startsWith('+965') || digits.startsWith('965')) return 'kw';
    if (digits.startsWith('+20') || digits.startsWith('20')) return 'eg';
    if (digits.startsWith('+962') || digits.startsWith('962')) return 'jo';

    return 'ae';
  }

  String _resolveHint(BuildContext context) {
    if (widget.hintText != null && widget.hintText!.trim().isNotEmpty) {
      return widget.hintText!.trim();
    }
    final tld = marketTld();
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return isAr ? 'ابحث في Alras.$tld' : 'Search Alras.$tld';
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final fieldHeight = isTablet ? 36.h : 44.h;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final lensSize = isTablet ? 22.h : 26.h;
    final backWidth = isTablet ? 28.h : 32.h;
    final backIconSize = isTablet ? 16.sp : 18.sp;
    final pillRadius = fieldHeight / 2;
    final showBack = widget.showBackButton && _isCatalog;
    final showLens = _isCatalog && widget.showImageSearch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showBack) ...[
              Tooltip(
                message: MaterialLocalizations.of(context).backButtonTooltip,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _goBack,
                    borderRadius: BorderRadius.circular(8.r),
                    child: SizedBox(
                      width: backWidth,
                      height: fieldHeight,
                      child: Icon(
                        isRtl ? Icons.arrow_forward : Icons.arrow_back,
                        size: backIconSize,
                        color: AppColors.title(context),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 6.w),
            ],
            Expanded(
              child: SizedBox(
                height: fieldHeight,
                child: CustomTextFormField(
                  controller: _controller,
                  focusNode: _focusNode,
                  hintText: _resolveHint(context),
                  leftIcon: AppAssets.searchIcon,
                  leftIconSize: isTablet ? 16.h : 18.h,
                  leftIconColor: AppColors.subtitle(context),
                  onLeftIconTap: _isCatalog
                      ? () => _submit(_controller.text.trim())
                      : null,
                  height: fieldHeight,
                  borderRadius: pillRadius,
                  borderWidth: 1,
                  borderColor: AppColors.inputBorder(context),
                  fillColor: AppColors.inputFill(context),
                  unfocusOnTapOutside: false,
                  textStyle: TextStyle(
                    fontSize: isTablet ? 12.sp : 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.title(context),
                  ),
                  showShadow: false,
                  hintStyle: TextStyle(
                    fontSize: isTablet ? 12.sp : 14.sp,
                    color: AppColors.subtitle(context),
                    fontWeight: FontWeight.w400,
                  ),
                  onSubmitted: _isCatalog ? _submit : null,
                  keyboardType: TextInputType.text,
                  suffixIcon: showLens
                      ? IconButton(
                          padding: EdgeInsets.only(right: 8.w, left: 4.w),
                          constraints: BoxConstraints(
                            minWidth: lensSize + 10,
                            minHeight: fieldHeight,
                          ),
                          tooltip: S.of(context).searchByImage,
                          onPressed: _searchByImage,
                          icon: Image.asset(
                            AppAssets.aiLensSearchIcon,
                            width: lensSize,
                            height: lensSize,
                            fit: BoxFit.contain,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
        if (_isCatalog && _showSuggestions)
          Container(
            margin: EdgeInsets.only(top: 6.h),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.inputBorder(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: BoxConstraints(maxHeight: 220.h),
            child: ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              shrinkWrap: true,
              itemCount: _suggestions.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: LightColor.greyTextColor.withValues(alpha: 0.15),
              ),
              itemBuilder: (context, index) {
                final option = _suggestions[index];
                return Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (_) {
                    _pickingSuggestion = true;
                    _pickSuggestion(option);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          size: 16.sp,
                          color: LightColor.defaultColor,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            option,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.title(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
