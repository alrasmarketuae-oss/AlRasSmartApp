import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/utils/product_grid_layout.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_details_opener.dart';
import 'package:alrasmarket/features/clint/presentation/models/service_product_type.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product _card.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Horizontal related-ads strip shown at the bottom of product detail pages.
///
/// - Category catalog ads → same category
/// - Retail / Booking / Offers / Requests → same product type, ranked by
///   name similarity to the current ad first
class RelatedAdsSection extends StatefulWidget {
  const RelatedAdsSection({super.key, required this.product});

  final MyListingProductModel product;

  @override
  State<RelatedAdsSection> createState() => _RelatedAdsSectionState();
}

class _RelatedAdsSectionState extends State<RelatedAdsSection> {
  bool _loading = true;
  List<MyListingProductModel> _items = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant RelatedAdsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.productId != widget.product.productId) {
      _load();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _items = const [];
    });

    try {
      final products = await _fetchCandidates(widget.product);
      if (!mounted) return;
      final ranked = widget.product.isCategoryCatalogProduct
          ? products
              .where((p) => p.productId != widget.product.productId)
              .toList()
          : ProductNameSimilarity.rank(
              currentName: widget.product.productName,
              currentProductId: widget.product.productId,
              products: products,
            );
      setState(() {
        _items = ranked.take(20).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _loading = false;
      });
    }
  }

  Future<List<MyListingProductModel>> _fetchCandidates(
    MyListingProductModel product,
  ) async {
    if (product.isCategoryCatalogProduct) {
      final categoryId = product.categoryId;
      if (categoryId == null || categoryId <= 0) return const [];
      final response = await DioHelper.getData(
        url: ApiConstants.productsByCategoryEndPoint(categoryId),
        query: {'page': 1, 'pageSize': 24},
      );
      return _parseItems(response?.data);
    }

    final typeName = _resolveTypeApiName(product);
    if (typeName == null) return const [];
    final response = await DioHelper.getData(
      url: ApiConstants.productsByTypeEndPoint(typeName),
      query: {'page': 1, 'pageSize': 40},
    );
    return _parseItems(response?.data);
  }

  String? _resolveTypeApiName(MyListingProductModel product) {
    if (product.isRetailProduct) return ServiceProductType.retail;
    if (product.productTypeId == 2 ||
        product.productTypeName.trim().toLowerCase() == 'booking') {
      return ServiceProductType.booking;
    }
    if (product.isOfferProduct) return ServiceProductType.offers;
    if (product.isRequestProduct) return ServiceProductType.requests;
    final normalized = product.productTypeName.trim().toLowerCase();
    if (ServiceProductType.all.contains(normalized)) return normalized;
    return null;
  }

  List<MyListingProductModel> _parseItems(dynamic data) {
    if (data is! Map) return const [];
    final items = data['items'] as List<dynamic>? ??
        data['Items'] as List<dynamic>? ??
        const [];
    return items
        .whereType<Map>()
        .map((e) => MyListingProductModel.fromJson(Map<String, dynamic>.from(e)))
        .where((p) => p.productId.trim().isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
        child: SizedBox(
          height: 40.h,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }
    if (_items.isEmpty) return const SizedBox.shrink();

    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final cardWidth = ProductGridLayout.cellWidth(
      context,
      horizontalPadding: 48,
      crossAxisSpacing: 12,
      columns: 2,
    );
    final cardHeight = ProductGridLayout.estimatedCardHeight(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            s.similarAds,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF333333),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: cardHeight + 8.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            itemCount: _items.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              final product = _items[index];
              return SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: ProductCard(
                  title: product.productName,
                  product: product,
                  onOrderTap: () => replaceProductDetails(context, product),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 8.h),
      ],
    );
  }
}
