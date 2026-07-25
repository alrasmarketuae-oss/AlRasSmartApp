import 'package:alrasmarket/core/router/where_to_go.dart';
import 'package:alrasmarket/core/search/app_search_actions.dart';
import 'package:alrasmarket/core/serveses/product_search_index_service.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/widgets/costomtextform.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

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

class _SearchFormFiledState extends State<SearchFormFiled>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final bool _ownsController;
  late final AnimationController _borderController;
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
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
    _borderController.dispose();
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
    // No stack entry (e.g. replace) — go to the account home.
    context.go(whereToGo());
  }

  void _pickSuggestion(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    _submit(value);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final fieldHeight = isTablet ? 30.h : 46.h;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final lensSize = isTablet ? 22.h : 28.h;
    final backWidth = isTablet ? 28.h : 32.h;
    final backIconSize = isTablet ? 16.sp : 18.sp;

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
              child: AnimatedBuilder(
                animation: _borderController,
                builder: (context, _) => SizedBox(
                  height: fieldHeight,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _SearchNeuralBorderPainter(
                              progress: _borderController.value,
                              borderRadius: 8.r,
                            ),
                          ),
                        ),
                      ),
                      CustomTextFormField(
                        controller: _controller,
                        focusNode: _focusNode,
                        hintText: S.of(context).searchForProducts,
                        leftIcon: AppAssets.searchIcon,
                        leftIconSize: isTablet ? 16.h : 20.h,
                        leftIconColor: const Color(0xff919191),
                        onLeftIconTap: () => _submit(_controller.text.trim()),
                        height: fieldHeight,
                        borderRadius: 8,
                        borderWidth: 1,
                        hintStyle: isTablet
                            ? TextStyle(fontSize: 10.sp, color: LightColor.hintColor)
                            : null,
                        onSubmitted: _submit,
                        onChanged: (_) => _refreshSuggestions(),
                        keyboardType: TextInputType.text,
                        suffixIcon: IconButton(
                          padding: EdgeInsets.only(right: 6.w, left: 4.w),
                          constraints: BoxConstraints(
                            minWidth: lensSize + 8,
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
                    ],
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
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
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

class _SearchNeuralBorderPainter extends CustomPainter {
  _SearchNeuralBorderPainter({
    required this.progress,
    required this.borderRadius,
  });

  final double progress;
  final double borderRadius;

  static const _nodeColors = [
    Color(0xFF59E390),
    Color(0xFF42D4FF),
    Color(0xFF8A7DFF),
    Color(0xFFFF3D81),
    Color(0xFFFF8C42),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.75),
      Radius.circular(borderRadius),
    );

    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF42D4FF).withValues(alpha: 0.22);
    canvas.drawRRect(rrect, orbitPaint);

    const nodeCount = 8;
    final perimeter = _rRectPerimeter(rrect);
    final points = List.generate(nodeCount, (i) {
      final t = (progress + i / nodeCount) % 1.0;
      final wobble = math.sin(progress * 2 * math.pi + i * 0.9) * 6.0;
      final d = (t * perimeter + wobble + perimeter) % perimeter;
      return _pointOnRRect(rrect, d);
    });

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (var i = 0; i < points.length; i++) {
      final next = (i + 1) % points.length;
      final pulse = (math.sin(progress * 2 * math.pi + i) + 1) / 2;
      linePaint.color = _nodeColors[i % _nodeColors.length]
          .withValues(alpha: 0.18 + pulse * 0.35);
      canvas.drawLine(points[i], points[next], linePaint);
    }

    for (var i = 0; i < points.length; i++) {
      final pulse = (math.sin(progress * 2 * math.pi + i * 0.8) + 1) / 2;
      final color = _nodeColors[i % _nodeColors.length];
      final nodeRadius = 1.2 + pulse * 1.2;
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.28 + pulse * 0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);
      canvas.drawCircle(points[i], nodeRadius + 1.3, glowPaint);
      canvas.drawCircle(
        points[i],
        nodeRadius,
        Paint()..color = color.withValues(alpha: 0.75 + pulse * 0.25),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SearchNeuralBorderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.borderRadius != borderRadius;
  }

  double _rRectPerimeter(RRect rrect) {
    final w = rrect.width;
    final h = rrect.height;
    final r = rrect.tlRadiusX.clamp(0, math.min(w, h) / 2);
    final straight = 2 * ((w - 2 * r) + (h - 2 * r));
    final arcs = 2 * math.pi * r;
    return straight + arcs;
  }

  Offset _pointOnRRect(RRect r, double d) {
    final left = r.left;
    final top = r.top;
    final right = r.right;
    final bottom = r.bottom;
    final radius = r.tlRadiusX.clamp(0, math.min(r.width, r.height) / 2);
    final topLen = r.width - 2 * radius;
    final sideLen = r.height - 2 * radius;
    final quarterArc = math.pi * radius / 2;
    final segments = [
      topLen,
      quarterArc,
      sideLen,
      quarterArc,
      topLen,
      quarterArc,
      sideLen,
      quarterArc,
    ];
    var remain = d;
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      if (remain <= seg) {
        switch (i) {
          case 0:
            return Offset(left + radius + remain, top);
          case 1:
            final a = -math.pi / 2 + remain / radius;
            return Offset(
              right - radius + math.cos(a) * radius,
              top + radius + math.sin(a) * radius,
            );
          case 2:
            return Offset(right, top + radius + remain);
          case 3:
            final a = remain / radius;
            return Offset(
              right - radius + math.cos(a) * radius,
              bottom - radius + math.sin(a) * radius,
            );
          case 4:
            return Offset(right - radius - remain, bottom);
          case 5:
            final a = math.pi / 2 + remain / radius;
            return Offset(
              left + radius + math.cos(a) * radius,
              bottom - radius + math.sin(a) * radius,
            );
          case 6:
            return Offset(left, bottom - radius - remain);
          default:
            final a = math.pi + remain / radius;
            return Offset(
              left + radius + math.cos(a) * radius,
              top + radius + math.sin(a) * radius,
            );
        }
      }
      remain -= seg;
    }
    return Offset(left + radius, top);
  }
}
