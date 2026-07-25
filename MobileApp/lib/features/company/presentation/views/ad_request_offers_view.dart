import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/company_cubit.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/company_states.dart';
import 'package:alrasmarket/features/company/presentation/widgets/my_ads/ad_request_order_info_card.dart';
import 'package:alrasmarket/features/company/presentation/widgets/my_ads/request_offer_card.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class AdRequestOffersView extends StatefulWidget {
  const AdRequestOffersView({
    super.key,
    required this.product,
    this.preferRetailPricing = false,
    this.preferCategoryLabel = false,
    this.showBothPricingChannels = false,
  });

  final MyListingProductModel product;
  final bool preferRetailPricing;
  final bool preferCategoryLabel;
  final bool showBothPricingChannels;

  @override
  State<AdRequestOffersView> createState() => _AdRequestOffersViewState();
}

class _AdRequestOffersViewState extends State<AdRequestOffersView> {
  late final ScrollController _scrollController;
  late final CompanyCubit _cubit;

  bool get _isRequestAd =>
      widget.product.productTypeName.trim().toLowerCase() == 'requests';

  @override
  void initState() {
    super.initState();
    _cubit = sl<CompanyCubit>();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _cubit.loadMyRequestOffers(
        productId: widget.product.productId,
        productName: widget.product.productName,
      );
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _cubit.restoreListingsState();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _cubit.loadMoreMyRequestOffers();
    }
  }

  Future<void> _onAccept(int orderId) async {
    final error = await _cubit.acceptRequestOffer(orderId);
    if (!mounted || error == null) return;
    AppToast.showError(context, error);
  }

  Future<void> _onReject(int orderId) async {
    final error = await _cubit.rejectRequestOffer(orderId);
    if (!mounted || error == null) return;
    AppToast.showError(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final isAr = Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final pageTitle = _isRequestAd
        ? s.offersInfo
        : (isAr ? 'الطلبات على الإعلان' : 'Orders on ad');
    final sectionTitle = _isRequestAd
        ? s.receivedOffers
        : (isAr ? 'الطلبات الواردة' : 'Received orders');
    final countLabel = _isRequestAd
        ? (int count) => s.offersAvailable(count)
        : (int count) => s.ordersAvailable(count);
    final emptyLabel = _isRequestAd
        ? s.noOffersOnAd
        : (isAr ? 'لا توجد طلبات على هذا الإعلان حالياً.' : 'No orders on this ad yet.');
    final pendingAdminEmptyLabel = isAr
        ? 'لا توجد طلبات ظاهرة حالياً. الطلبات والعروض تظهر هنا بعد موافقة الإدارة، ثم يمكنك قبولها أو رفضها.'
        : 'No visible orders yet. Orders and offers appear here after admin approval; you can then accept or reject them.';

    return BlocProvider.value(
      value: _cubit,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: const Color(0xFFF4F7FA),
          body: Column(
            children: [
              SearchHeader(title: pageTitle, isSearch: false),
              Expanded(
                child: BlocBuilder<CompanyCubit, CompanyStates>(
                  buildWhen: (_, current) =>
                      current is CompanyAdRequestOffersState,
                  builder: (context, state) {
                    if (state is! CompanyAdRequestOffersState) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final isInitialLoading =
                        state.isLoading && state.offers.isEmpty;

                    return RefreshIndicator(
                      onRefresh: () => _cubit.loadMyRequestOffers(
                        productId: state.productId,
                        productName: state.productName,
                      ),
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: AdRequestOrderInfoCard(
                              product: widget.product,
                              fontFamily: fontFamily,
                              preferRetailPricing: widget.preferRetailPricing,
                              preferCategoryLabel: widget.preferCategoryLabel,
                              showBothPricingChannels:
                                  widget.showBothPricingChannels,
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                24.w,
                                6.h,
                                24.w,
                                12.h,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    sectionTitle,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontFamily: fontFamily,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      height: 1.5,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    countLabel(state.totalCount),
                                    style: TextStyle(
                                      color: const Color(0xFF3A7DC5),
                                      fontFamily: fontFamily,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14.sp,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isInitialLoading)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (state.errorMessage != null &&
                              state.offers.isEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24.w,
                                  vertical: 32.h,
                                ),
                                child: Text(
                                  state.errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: fontFamily,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                            )
                          else if (state.offers.isEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24.w,
                                  vertical: 32.h,
                                ),
                                child: Text(
                                  widget.product.requiresAdminOrderModeration
                                      ? pendingAdminEmptyLabel
                                      : emptyLabel,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: fontFamily,
                                    fontSize: 14.sp,
                                    color: const Color(
                                      0xFF333333,
                                    ).withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                24.w,
                                0,
                                24.w,
                                24.h,
                              ),
                              sliver: SliverList.separated(
                                itemCount: state.offers.length +
                                    (state.isLoadingMore ? 1 : 0),
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: 12.h),
                                itemBuilder: (context, index) {
                                  if (index >= state.offers.length) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(12),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  final offer = state.offers[index];
                                  final isUpdating =
                                      state.isUpdatingStatus &&
                                      state.updatingOrderId == offer.orderId;

                                  return RequestOfferCard(
                                    offer: offer,
                                    fontFamily: fontFamily,
                                    isUpdating: isUpdating,
                                    acceptLabel: _isRequestAd
                                        ? s.acceptOfferAction
                                        : s.acceptOrderAction,
                                    rejectLabel: _isRequestAd
                                        ? s.rejectOfferAction
                                        : s.rejectOrderAction,
                                    onTrack: offer.orderId > 0
                                        ? () => context.push(
                                              AppRoutes.kTrackOrderView,
                                              extra: {
                                                'orderId': offer.orderId,
                                                'showBuyerActions': false,
                                              },
                                            )
                                        : null,
                                    onAccept: offer.canAccept
                                        ? () => _onAccept(offer.orderId)
                                        : null,
                                    onReject: offer.canReject
                                        ? () => _onReject(offer.orderId)
                                        : null,
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
