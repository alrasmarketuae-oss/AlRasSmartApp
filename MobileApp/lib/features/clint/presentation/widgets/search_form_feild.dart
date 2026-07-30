import 'package:alrasmarket/core/router/where_to_go.dart';
import 'package:alrasmarket/core/search/app_search_actions.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/serveses/product_search_index_service.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/widgets/costomtextform.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class SearchFormFiled extends StatefulWidget {
  const SearchFormFiled({
    super.key,
    this.initialQuery,
    this.controller,
    this.onSubmitted,
    this.onImageSearchTap,
    this.onFilterTap,
    this.showBackButton = true,
  });

  final String? initialQuery;
  final TextEditingController? controller;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onImageSearchTap;
  final VoidCallback? onFilterTap;

  /// Full back arrow outside the field (not chevron). Hidden on home.
  final bool showBackButton;

  @override
  State<SearchFormFiled> createState() => _SearchFormFiledState();
}

class _SearchFormFiledState extends State<SearchFormFiled> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final bool _ownsController;
  List<String> _suggestions = [];
  bool _showSuggestions = false;

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
  void didUpdateWidget(SearchFormFiled oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery &&
        widget.controller == null &&
        widget.initialQuery != null) {
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

  void _onQueryChanged() => _refreshSuggestions();

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      setState(() => _showSuggestions = false);
      return;
    }
    _refreshSuggestions();
  }

  void _refreshSuggestions() {
    final items =
        ProductSearchIndexService.instance.suggest(_controller.text).toList();
    setState(() {
      _suggestions = items;
      _showSuggestions =
          _focusNode.hasFocus &&
          _controller.text.trim().isNotEmpty &&
          items.isNotEmpty;
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
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(whereToGo());
  }

  void _pickSuggestion(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    _submit(value);
  }

  /// Amazon-style market TLD from phone / locale (not hard-coded .ae only).
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

    // App default market.
    return 'ae';
  }

  String _hintText(BuildContext context) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.showBackButton) ...[
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
                        color: const Color(0xFF333333),
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
                  hintText: _hintText(context),
                  leftIcon: AppAssets.searchIcon,
                  leftIconSize: isTablet ? 16.h : 18.h,
                  leftIconColor: const Color(0xFF0F1111),
                  onLeftIconTap: () => _submit(_controller.text.trim()),
                  height: fieldHeight,
                  borderRadius: pillRadius,
                  borderWidth: 1,
                  borderColor: const Color(0xFFD5D9D9),
                  fillColor: Colors.white,
                  showShadow: false,
                  hintStyle: TextStyle(
                    fontSize: isTablet ? 12.sp : 14.sp,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w400,
                  ),
                  onSubmitted: _submit,
                  onChanged: (_) => _refreshSuggestions(),
                  keyboardType: TextInputType.text,
                  suffixIcon: IconButton(
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
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_showSuggestions)
          Container(
            margin: EdgeInsets.only(top: 6.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFD5D9D9)),
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
                return InkWell(
                  onTap: () => _pickSuggestion(option),
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
                              color: const Color(0xFF333333),
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
