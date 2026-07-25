import 'package:alrasmarket/core/utils/saved_products_store.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Bookmark control for product details (not shown on list cards).
class ProductBookmarkButton extends StatefulWidget {
  const ProductBookmarkButton({
    super.key,
    required this.productId,
    this.color = const Color(0xFF3A7DC5),
  });

  final String productId;
  final Color color;

  @override
  State<ProductBookmarkButton> createState() => _ProductBookmarkButtonState();
}

class _ProductBookmarkButtonState extends State<ProductBookmarkButton> {
  bool _bookmarked = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ProductBookmarkButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) {
      _ready = false;
      _load();
    }
  }

  Future<void> _load() async {
    final saved = await SavedProductsStore.isSaved(widget.productId);
    if (!mounted) return;
    setState(() {
      _bookmarked = saved;
      _ready = true;
    });
  }

  Future<void> _toggle() async {
    final next = await SavedProductsStore.toggle(widget.productId);
    if (!mounted) return;
    setState(() => _bookmarked = next);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return IconButton(
      onPressed: !_ready || widget.productId.trim().isEmpty ? null : _toggle,
      tooltip: s.savedAds,
      icon: Icon(
        _bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
        size: 24.sp,
        color: widget.color,
      ),
    );
  }
}
