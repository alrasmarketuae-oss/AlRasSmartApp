import 'dart:async';

import 'package:alrasmarket/core/serveses/catalog_sync_service.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/core/utils/product_price_formatter.dart';
import 'package:alrasmarket/core/utils/thousands_separator_input_formatter.dart';
import 'package:alrasmarket/core/widgets/cached_app_image.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/company_cubit.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/company_states.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_currency_label.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChangePricesView extends StatefulWidget {
  const ChangePricesView({super.key, this.highlightProductId});

  final String? highlightProductId;

  @override
  State<ChangePricesView> createState() => _ChangePricesViewState();
}

class _ChangePricesViewState extends State<ChangePricesView> {
  final _searchController = TextEditingController();
  final _listController = ScrollController();
  final _rowKeys = <String, GlobalKey>{};
  final _editors = <String, _PriceEditors>{};
  bool _savingAll = false;
  String? _scrolledToId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<CompanyCubit>();
      cubit.restoreListingsState();
      cubit.loadMyListings(context);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listController.dispose();
    for (final editor in _editors.values) {
      editor.dispose();
    }
    super.dispose();
  }

  void _scrollToHighlightIfNeeded(List<MyListingProductModel> products) {
    final target = widget.highlightProductId?.trim() ?? '';
    if (target.isEmpty || products.isEmpty) return;
    if (_scrolledToId != null &&
        _scrolledToId!.toLowerCase() == target.toLowerCase()) {
      return;
    }
    _scrolledToId = target;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _rowKeys[target];
      final ctx = key?.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        alignment: 0.15,
      );
    });
  }

  void _ensureEditors(List<MyListingProductModel> products) {
    final ids = <String>{};
    for (final product in products) {
      ids.add(product.productId);
      _editors.putIfAbsent(
        product.productId,
        () => _PriceEditors.fromProduct(product),
      );
    }
    final stale = _editors.keys.where((id) => !ids.contains(id)).toList();
    for (final id in stale) {
      _editors.remove(id)?.dispose();
    }
  }

  List<MyListingProductModel> _visible(List<MyListingProductModel> products) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return products;
    return products.where((product) {
      return product.editDisplayName.toLowerCase().contains(query) ||
          product.productName.toLowerCase().contains(query) ||
          product.productCode.toLowerCase().contains(query);
    }).toList();
  }

  Future<String?> _saveProduct(
    MyListingProductModel product, {
    required bool syncCatalog,
  }) async {
    final editor = _editors[product.productId];
    if (editor == null) return null;

    final wholesale = ThousandsNumberInput.parseDouble(editor.wholesale.text);
    if (wholesale == null || wholesale <= 0) {
      return S.of(context).invalidPrice;
    }

    double? retail;
    if (editor.hasRetail) {
      final parsedRetail = ThousandsNumberInput.parseDouble(editor.retail.text);
      final hadRetail = (editor.originalRetail ?? 0) > 0;
      if (hadRetail) {
        if (parsedRetail == null || parsedRetail <= 0) {
          return S.of(context).invalidPrice;
        }
        retail = parsedRetail;
      } else if (parsedRetail != null && parsedRetail > 0) {
        retail = parsedRetail;
      }
    }

    editor.saving = true;
    setState(() {});

    final error = await context.read<CompanyCubit>().updateProductPrice(
          productId: product.productId,
          usdPrice: wholesale,
          retailPrice: retail,
          context: context,
        );

    editor.saving = false;
    if (error == null) {
      editor.markSaved(wholesale: wholesale, retail: retail);
    }
    if (mounted) setState(() {});
    if (error == null && syncCatalog) {
      unawaited(CatalogSyncService.instance.afterAdMutation());
    }
    return error;
  }

  Future<void> _saveAll(List<MyListingProductModel> products) async {
    final dirty = products
        .where((product) => _editors[product.productId]?.isDirty == true)
        .toList();
    if (dirty.isEmpty || _savingAll) return;

    setState(() => _savingAll = true);
    var saved = 0;
    String? lastError;
    for (final product in dirty) {
      final error = await _saveProduct(product, syncCatalog: false);
      if (!mounted) return;
      if (error == null) {
        saved++;
      } else {
        lastError = error;
      }
    }

    unawaited(CatalogSyncService.instance.afterAdMutation());
    if (!mounted) return;
    setState(() => _savingAll = false);

    if (lastError != null && saved == 0) {
      AppToast.showError(context, lastError);
    } else if (lastError != null) {
      AppToast.showError(context, lastError);
    } else {
      AppToast.showSuccess(context, S.of(context).pricesUpdated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FE),
      body: Column(
        children: [
          SearchHeader(title: s.changePrices, isSearch: false),
          Expanded(
            child: BlocBuilder<CompanyCubit, CompanyStates>(
              buildWhen: (previous, current) =>
                  current is CompanyMyListingsState,
              builder: (context, state) {
                if (state is! CompanyMyListingsState) {
                  return const Center(child: CircularProgressIndicator());
                }

                _ensureEditors(state.products);
                final products = _visible(state.products);
                final dirtyCount = state.products
                    .where(
                      (product) => _editors[product.productId]?.isDirty == true,
                    )
                    .length;

                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: s.changePricesSearchHint,
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 12.h,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildList(state, products, s),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                        child: PrimaryButton(
                          text: dirtyCount > 0
                              ? '${s.saveChanges} ($dirtyCount)'
                              : s.saveChanges,
                          isLoading: _savingAll,
                          onPressed: dirtyCount == 0 || _savingAll
                              ? null
                              : () => _saveAll(state.products),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    CompanyMyListingsState state,
    List<MyListingProductModel> products,
    S s,
  ) {
    if (state.isLoading && state.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.products.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Text(
            state.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: LightColor.greyTextColor, fontSize: 14.sp),
          ),
        ),
      );
    }

    if (state.products.isEmpty) {
      return Center(
        child: Text(
          s.noAdsToChangePrices,
          style: TextStyle(color: LightColor.greyTextColor, fontSize: 14.sp),
        ),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Text(
          s.noAdsMatchFilter,
          style: TextStyle(color: LightColor.greyTextColor, fontSize: 14.sp),
        ),
      );
    }

    _scrollToHighlightIfNeeded(products);

    return RefreshIndicator(
      onRefresh: () => context.read<CompanyCubit>().reloadMyListings(),
      child: ListView.separated(
        controller: _listController,
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
        itemCount: products.length,
        separatorBuilder: (_, __) => SizedBox(height: 10.h),
        itemBuilder: (context, index) {
          final product = products[index];
          final editor = _editors[product.productId]!;
          final key = _rowKeys.putIfAbsent(product.productId, GlobalKey.new);
          final highlighted = (widget.highlightProductId ?? '')
              .trim()
              .toLowerCase() ==
              product.productId.trim().toLowerCase();
          return KeyedSubtree(
            key: key,
            child: DecoratedBox(
              decoration: highlighted
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: LightColor.defaultColor,
                        width: 1.5,
                      ),
                    )
                  : const BoxDecoration(),
              child: _PriceRow(
                product: product,
                editor: editor,
                onChanged: () => setState(() {}),
                onSave: () async {
                  final error = await _saveProduct(product, syncCatalog: true);
                  if (!mounted) return;
                  if (error != null) {
                    AppToast.showError(context, error);
                  } else {
                    AppToast.showSuccess(context, s.pricesUpdated);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PriceEditors {
  _PriceEditors({
    required this.wholesale,
    required this.retail,
    required this.hasRetail,
    required this.originalWholesale,
    required this.originalRetail,
  });

  factory _PriceEditors.fromProduct(MyListingProductModel product) {
    final wholesale =
        ThousandsNumberInput.parseDouble(product.ownerListingPrice) ?? 0;
    final hasRetail = product.hasRetailPricing || product.isHybridCategoryRetail;
    final retail = hasRetail
        ? (ThousandsNumberInput.parseDouble(product.retailPrice) ?? 0)
        : null;
    return _PriceEditors(
      wholesale: TextEditingController(
        text: ThousandsNumberInput.format(wholesale),
      ),
      retail: TextEditingController(
        text: retail == null ? '' : ThousandsNumberInput.format(retail),
      ),
      hasRetail: hasRetail,
      originalWholesale: wholesale,
      originalRetail: retail,
    );
  }

  final TextEditingController wholesale;
  final TextEditingController retail;
  final bool hasRetail;
  double originalWholesale;
  double? originalRetail;
  bool saving = false;

  bool get isDirty {
    final nextWholesale = ThousandsNumberInput.parseDouble(wholesale.text);
    if (!_same(nextWholesale, originalWholesale)) return true;
    if (hasRetail) {
      final nextRetail = ThousandsNumberInput.parseDouble(retail.text);
      if (!_same(nextRetail, originalRetail)) return true;
    }
    return false;
  }

  void markSaved({required double wholesale, double? retail}) {
    originalWholesale = wholesale;
    originalRetail = retail;
  }

  void dispose() {
    wholesale.dispose();
    retail.dispose();
  }

  static bool _same(double? a, double? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return (a - b).abs() < 0.0001;
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.product,
    required this.editor,
    required this.onChanged,
    required this.onSave,
  });

  final MyListingProductModel product;
  final _PriceEditors editor;
  final VoidCallback onChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final imageUrl = product.primaryImageUrl ?? product.categoryImageUrl;
    final wholesaleCurrency =
        ProductPriceFormatter.wholesaleCurrencyCode(product);
    final retailCurrency = ProductPriceFormatter.retailCurrencyCode(product);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16233A).withValues(alpha: 0.05),
            blurRadius: 12.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: CachedAppImage(
              imageUrl: imageUrl,
              width: 52.w,
              height: 52.w,
              borderRadius: BorderRadius.circular(10.r),
              errorWidget: Container(
                width: 52.w,
                height: 52.w,
                color: const Color(0xFFF3F4F6),
                alignment: Alignment.center,
                child: Icon(
                  Icons.image_outlined,
                  color: const Color(0xFF9CA3AF),
                  size: 22.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.editDisplayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF16233A),
                    height: 1.3,
                  ),
                ),
                if (product.productTypeName.trim().isNotEmpty) ...[
                  SizedBox(height: 3.h),
                  Text(
                    product.productTypeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF7B8794),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _PriceField(
                controller: editor.wholesale,
                currency: wholesaleCurrency,
                hint: editor.hasRetail ? s.wholesalePrice : s.enterPrice,
                onChanged: (_) => onChanged(),
              ),
              if (editor.hasRetail) ...[
                SizedBox(height: 8.h),
                _PriceField(
                  controller: editor.retail,
                  currency: retailCurrency,
                  hint: s.retailPriceLabel,
                  onChanged: (_) => onChanged(),
                ),
              ],
            ],
          ),
          if (editor.isDirty) ...[
            SizedBox(width: 4.w),
            editor.saving
                ? SizedBox(
                    width: 22.w,
                    height: 22.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    onPressed: onSave,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(
                      width: 32.w,
                      height: 32.w,
                    ),
                    icon: Icon(
                      Icons.check_circle_rounded,
                      color: LightColor.defaultColor,
                      size: 24.sp,
                    ),
                  ),
          ],
        ],
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  const _PriceField({
    required this.controller,
    required this.currency,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String currency;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118.w,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [ThousandsSeparatorInputFormatter.price()],
        textAlign: TextAlign.end,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF16233A),
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          suffixIcon: Padding(
            padding: EdgeInsets.only(right: 10.w),
            child: CreateAdCurrencyLabel(
              currency: currency,
              iconHeight: 13.sp,
            ),
          ),
          suffixIconConstraints: BoxConstraints(minWidth: 28.w, minHeight: 28.h),
          filled: true,
          fillColor: const Color(0xFFF6F9FE),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 10.w,
            vertical: 10.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: Color(0xFFE6EEF8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: Color(0xFFE6EEF8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(color: LightColor.defaultColor),
          ),
        ),
      ),
    );
  }
}
