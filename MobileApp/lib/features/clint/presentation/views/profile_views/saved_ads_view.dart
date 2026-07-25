import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/product_grid_layout.dart';
import 'package:alrasmarket/core/utils/saved_products_store.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_details_opener.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/offer_product_card.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/product%20_card.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SavedAdsView extends StatefulWidget {
  const SavedAdsView({super.key});

  @override
  State<SavedAdsView> createState() => _SavedAdsViewState();
}

class _SavedAdsViewState extends State<SavedAdsView> {
  final List<MyListingProductModel> _products = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ids = await SavedProductsStore.getIds();
      if (ids.isEmpty) {
        if (!mounted) return;
        setState(() {
          _products.clear();
          _loading = false;
        });
        return;
      }

      final loaded = <MyListingProductModel>[];
      final stale = <String>[];
      for (final id in ids) {
        final product =
            await ProductDetailsOpener.fetchPublicProductById(id);
        if (product == null) {
          stale.add(id);
          continue;
        }
        loaded.add(product);
      }

      for (final id in stale) {
        await SavedProductsStore.remove(id);
      }

      if (!mounted) return;
      setState(() {
        _products
          ..clear()
          ..addAll(loaded);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = S.of(context).failedToLoadSavedAds;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final horizontalPadding =
        ProductGridLayout.categoryHorizontalPadding(context);

    return Scaffold(
      body: Column(
        children: [
          const SearchHeader(),
          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 8.h),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20.sp,
                    color: LightColor.defaultColor,
                  ),
                ),
                Expanded(
                  child: Text(
                    s.savedAds,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _buildBody(context, horizontalPadding),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, double horizontalPadding) {
    final s = S.of(context);

    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 120.h),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        children: [
          SizedBox(height: 80.h),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.sp, color: LightColor.greyTextColor),
          ),
          SizedBox(height: 16.h),
          Center(
            child: TextButton(
              onPressed: _load,
              child: Text(s.retry),
            ),
          ),
        ],
      );
    }

    if (_products.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        children: [
          SizedBox(height: 100.h),
          Icon(
            Icons.bookmark_border_rounded,
            size: 48.sp,
            color: LightColor.greyTextColor60,
          ),
          SizedBox(height: 12.h),
          Text(
            s.noSavedAds,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            s.noSavedAdsHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: LightColor.greyTextColor,
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
          sliver: AutoSliverGrid(
            horizontalPadding: horizontalPadding,
            products: _products,
          ),
        ),
      ],
    );
  }
}

class AutoSliverGrid extends StatelessWidget {
  const AutoSliverGrid({
    super.key,
    required this.horizontalPadding,
    required this.products,
  });

  final double horizontalPadding;
  final List<MyListingProductModel> products;

  @override
  Widget build(BuildContext context) {
    final crossSpacing = 16.w;
    final mainSpacing = 16.h;
    final hasOffer = products.any((p) => p.isOfferProduct);

    return SliverGrid(
      gridDelegate: hasOffer
          ? ProductGridLayout.offerDelegate(
              context,
              horizontalPadding: horizontalPadding,
              crossAxisSpacing: crossSpacing,
              mainAxisSpacing: mainSpacing,
            )
          : ProductGridLayout.delegate(
              context,
              horizontalPadding: horizontalPadding,
              crossAxisSpacing: crossSpacing,
              mainAxisSpacing: mainSpacing,
            ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final product = products[index];
          final title = product.productName.isEmpty
              ? 'Product'
              : product.productName;
          if (product.isOfferProduct) {
            return OfferProductCard(title: title, product: product);
          }
          return ProductCard(title: title, product: product);
        },
        childCount: products.length,
      ),
    );
  }
}
