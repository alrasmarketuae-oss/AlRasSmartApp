import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/services/api_constants.dart';
import 'package:alrasmarket/core/services/dio_helper.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_navigation_helper.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Opens marketplace product details by product id (fetches public listing first).
class ProductDetailsOpener {
  ProductDetailsOpener._();

  /// Instant open from a card (no blocking spinner). Details use list data;
  /// optional silent refresh can still use [openByProductId] without [seed].
  static void openProduct(
    BuildContext context,
    MyListingProductModel product, {
    bool preferRetailChannel = false,
    bool? isOffer,
  }) {
    ProductNavigationHelper.openDetails(
      context,
      product,
      preferRetailChannel: preferRetailChannel,
      isOffer: isOffer,
    );
  }

  static Future<void> openByProductId(
    BuildContext context, {
    required String productId,
    bool preferRetailChannel = false,
    MyListingProductModel? seed,
  }) async {
    final id = productId.trim();
    if (id.isEmpty) {
      if (context.mounted) {
        AppToast.showError(context, S.of(context).productUnavailable);
      }
      return;
    }

    // Have list/card data → open immediately (no circular progress dialog).
    if (seed != null) {
      openProduct(
        context,
        seed,
        preferRetailChannel: preferRetailChannel,
      );
      return;
    }

    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ProductDetailsLoadingPage(
          productId: id,
          preferRetailChannel: preferRetailChannel,
        ),
      ),
    );
  }

  static Future<MyListingProductModel?> fetchPublicProductById(
    String productId, {
    bool asRetail = false,
  }) async {
    final response = await DioHelper.getData(
      url: ApiConstants.productByIdEndPoint(
        productId.trim(),
        asRetail: asRetail,
      ),
    );
    final status = response?.statusCode ?? 0;
    if (status < 200 || status >= 300) return null;

    final data = response?.data;
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    final item = map['item'] ?? map['Item'];
    if (item is! Map) return null;
    return MyListingProductModel.fromJson(Map<String, dynamic>.from(item));
  }
}

/// Skeleton page shown only when opening by id without seed data.
class _ProductDetailsLoadingPage extends StatefulWidget {
  const _ProductDetailsLoadingPage({
    required this.productId,
    required this.preferRetailChannel,
  });

  final String productId;
  final bool preferRetailChannel;

  @override
  State<_ProductDetailsLoadingPage> createState() =>
      _ProductDetailsLoadingPageState();
}

class _ProductDetailsLoadingPageState extends State<_ProductDetailsLoadingPage> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final product = await ProductDetailsOpener.fetchPublicProductById(
        widget.productId,
        asRetail: widget.preferRetailChannel,
      );
      if (!mounted) return;
      if (product == null) {
        Navigator.of(context).pop();
        AppToast.showError(context, S.of(context).productUnavailable);
        return;
      }
      Navigator.of(context).pop();
      if (!mounted) return;
      ProductNavigationHelper.openDetails(
        context,
        product,
        preferRetailChannel: widget.preferRetailChannel,
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      AppToast.showError(context, S.of(context).productUnavailable);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FA),
        body: Column(
          children: [
            SearchHeader(
              title: S.of(context).productDetails,
              isSearch: false,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(height: 220.h, radius: 16.r),
                    SizedBox(height: 16.h),
                    _SkeletonBox(height: 22.h, width: 180.w),
                    SizedBox(height: 10.h),
                    _SkeletonBox(height: 14.h, width: double.infinity),
                    SizedBox(height: 8.h),
                    _SkeletonBox(height: 14.h, width: 220.w),
                    SizedBox(height: 20.h),
                    _SkeletonBox(height: 16.h, width: 120.w),
                    SizedBox(height: 10.h),
                    _SkeletonBox(height: 80.h, radius: 12.r),
                    SizedBox(height: 20.h),
                    Text(
                      S.of(context).loadingEllipsis,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 13.sp,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.height,
    this.width,
    this.radius,
  });

  final double height;
  final double? width;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(radius ?? 8.r),
      ),
    );
  }
}

/// Ranks products by how closely [candidateName] matches [currentName].
class ProductNameSimilarity {
  ProductNameSimilarity._();

  static int score(String currentName, String candidateName) {
    final current = _normalize(currentName);
    final candidate = _normalize(candidateName);
    if (current.isEmpty || candidate.isEmpty) return 0;
    if (current == candidate) return 1000;
    if (candidate.startsWith(current) || current.startsWith(candidate)) {
      return 800;
    }
    if (candidate.contains(current) || current.contains(candidate)) {
      return 600;
    }

    final currentTokens = current
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 2)
        .toList();
    final candidateTokens = candidate
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 2)
        .toList();
    if (currentTokens.isEmpty || candidateTokens.isEmpty) return 0;

    var overlap = 0;
    for (final token in currentTokens) {
      if (candidateTokens.any(
        (other) =>
            other == token || other.contains(token) || token.contains(other),
      )) {
        overlap++;
      }
    }
    return overlap * 120;
  }

  static List<MyListingProductModel> rank({
    required String currentName,
    required String currentProductId,
    required List<MyListingProductModel> products,
  }) {
    final filtered = products
        .where((p) => p.productId.trim() != currentProductId.trim())
        .toList();
    filtered.sort((a, b) {
      final scoreA = score(currentName, a.productName);
      final scoreB = score(currentName, b.productName);
      if (scoreA != scoreB) return scoreB.compareTo(scoreA);
      return a.productName.toLowerCase().compareTo(b.productName.toLowerCase());
    });
    return filtered;
  }

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

/// Convenience for go_router callers that already have a product model.
void openProductDetails(
  BuildContext context,
  MyListingProductModel product, {
  bool preferRetailChannel = false,
}) {
  ProductNavigationHelper.openDetails(
    context,
    product,
    preferRetailChannel: preferRetailChannel,
  );
}

/// Used when replacing the current details route with another product.
void replaceProductDetails(
  BuildContext context,
  MyListingProductModel product, {
  bool preferRetailChannel = false,
}) {
  final useRetailChannel =
      ProductNavigationHelper.resolvePreferRetailChannel(preferRetailChannel);

  if (product.isRequestProduct) {
    context.pushReplacement(
      AppRoutes.kRequestDetailsView,
      extra: {'product': product},
    );
    return;
  }
  if (useRetailChannel && product.isRetailFeedProduct) {
    context.pushReplacement(
      AppRoutes.kRetailProductDetailsView,
      extra: {
        'product': product,
        'isOffer': false,
        'preferRetailChannel': true,
      },
    );
    return;
  }
  if (product.isCategoryCatalogProduct) {
    context.pushReplacement(
      AppRoutes.kBookingDetailsView,
      extra: {'product': product},
    );
    return;
  }
  if (product.isPureRetailProduct) {
    context.pushReplacement(
      AppRoutes.kRetailProductDetailsView,
      extra: {
        'product': product,
        'isOffer': false,
        'preferRetailChannel': true,
      },
    );
    return;
  }
  if (product.productTypeName.trim().toLowerCase() == 'booking' ||
      product.productTypeId == 2) {
    context.pushReplacement(
      AppRoutes.kBookingDetailsView,
      extra: {'product': product},
    );
    return;
  }
  if (product.isOfferProduct) {
    context.pushReplacement(
      AppRoutes.kRetailProductDetailsView,
      extra: {'product': product, 'isOffer': true},
    );
    return;
  }
  context.pushReplacement(
    AppRoutes.kRetailProductDetailsView,
    extra: {
      'product': product,
      'isOffer': false,
      'preferRetailChannel': useRetailChannel,
    },
  );
}
