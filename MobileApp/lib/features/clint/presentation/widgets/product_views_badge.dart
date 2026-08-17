import 'package:alrasmarket/core/services/product_view_service.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProductViewsBadge extends StatefulWidget {
  const ProductViewsBadge({
    super.key,
    required this.productId,
    required this.initialViewsCount,
    required this.fontFamily,
    this.trackOnOpen = true,
    this.compact = false,
  });

  final String productId;
  final int initialViewsCount;
  final String fontFamily;
  final bool trackOnOpen;
  final bool compact;

  @override
  State<ProductViewsBadge> createState() => _ProductViewsBadgeState();
}

class _ProductViewsBadgeState extends State<ProductViewsBadge> {
  late int _viewsCount;

  @override
  void initState() {
    super.initState();
    _viewsCount = widget.initialViewsCount;
    if (widget.trackOnOpen) {
      _registerView();
    }
  }

  @override
  void didUpdateWidget(covariant ProductViewsBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialViewsCount != widget.initialViewsCount) {
      _viewsCount = widget.initialViewsCount;
    }
  }

  Future<void> _registerView() async {
    final updated = await ProductViewService.trackProductView(widget.productId);
    if (!mounted || updated == null) return;
    setState(() => _viewsCount = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.visibility_outlined,
          size: widget.compact ? 13.sp : 18.sp,
          color: const Color(0xFF6B7280),
        ),
        SizedBox(width: widget.compact ? 3.w : 6.w),
        Text(
          S.of(context).adViewsCount(_viewsCount),
          style: TextStyle(
            color: const Color(0xFF6B7280),
            fontFamily: widget.fontFamily,
            fontSize: widget.compact ? 11.sp : 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
