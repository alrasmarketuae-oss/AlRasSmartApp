import 'dart:async';

import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/app_order_listener_service.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/services/app_push_notification_service.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/features/clint/data/models/my_order_model.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_states.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/notification_navigation_helper.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/order_list_oldest_section.dart';
import 'package:alrasmarket/features/clint/presentation/models/my_orders_chip_filter.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/order_card.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/order_list_oldest_header.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/features/company/data/models/my_request_offer_model.dart';
import 'package:alrasmarket/features/company/presentation/widgets/my_ads/request_offer_card.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Orders tab layout:
/// - Supplier: Sales + Purchases + Incoming request offers
/// - Company customer (buyer only): Purchases + Incoming request offers
/// - Personal customer: Purchases only
class MyOrdersView extends StatefulWidget {
  const MyOrdersView({super.key});

  @override
  State<MyOrdersView> createState() => _MyOrdersViewState();
}

enum _OrdersSection { sales, purchases, requestOffers }

class _MyOrdersViewState extends State<MyOrdersView> {
  int _sectionIndex = 0;
  MyOrdersChipFilter _filter = MyOrdersChipFilter.all;
  final ScrollController _purchasesScrollController = ScrollController();
  final ScrollController _salesScrollController = ScrollController();
  final ScrollController _requestOffersScrollController = ScrollController();
  final Map<int, GlobalKey> _orderKeys = {};
  int? _highlightOrderId;
  int? _scrolledForOrderId;
  StreamSubscription<void>? _ordersRealtimeSub;

  /// Company customers buy only — never show "My Sales".
  List<_OrdersSection> get _availableSections {
    final auth = AuthService.instance;
    if (auth.isSupplierAccount) {
      return const [
        _OrdersSection.sales,
        _OrdersSection.purchases,
        _OrdersSection.requestOffers,
      ];
    }
    if (auth.isCompanyCustomerAccount) {
      return const [
        _OrdersSection.purchases,
        _OrdersSection.requestOffers,
      ];
    }
    return const [_OrdersSection.purchases];
  }

  bool get _showSectionTabs => _availableSections.length > 1;

  bool get _loadsIncoming =>
      AuthService.instance.isSupplierAccount ||
      AuthService.instance.isCompanyCustomerAccount;

  _OrdersSection get _currentSection {
    final sections = _availableSections;
    if (_sectionIndex < 0 || _sectionIndex >= sections.length) {
      return sections.first;
    }
    return sections[_sectionIndex];
  }

  bool get _isPurchasesSection => _currentSection == _OrdersSection.purchases;

  bool get _isRequestOffersSection =>
      _currentSection == _OrdersSection.requestOffers;

  int _indexOfSection(_OrdersSection section) {
    final index = _availableSections.indexOf(section);
    return index < 0 ? 0 : index;
  }

  List<MyRequestOfferModel> _salesOnly(List<MyRequestOfferModel> all) =>
      all.where((o) => !o.isRequestProductOffer).toList(growable: false);

  List<MyRequestOfferModel> _requestOffersOnly(List<MyRequestOfferModel> all) =>
      all.where((o) => o.isRequestProductOffer).toList(growable: false);

  Future<void> _onOrdersRealtimeUpdate() async {
    if (!mounted) return;
    final cubit = context.read<ClintCubit>();
    final previousIncomingIds =
        cubit.incomingOrders.map((order) => order.orderId).toSet();

    if (_isPurchasesSection) {
      await cubit.fetchMyOrders(silent: true);
      if (_loadsIncoming) {
        await cubit.fetchIncomingOrders(silent: true);
      }
    } else {
      await cubit.fetchIncomingOrders(silent: true);
    }

    if (!mounted) return;
    final newcomers = cubit.incomingOrders
        .where((order) => !previousIncomingIds.contains(order.orderId))
        .toList();
    if (newcomers.isEmpty) return;

    if (_showSectionTabs) {
      final first = newcomers.first;
      setState(() {
        if (first.isRequestProductOffer) {
          _sectionIndex = _indexOfSection(_OrdersSection.requestOffers);
        } else if (AuthService.instance.isSupplierAccount) {
          _sectionIndex = _indexOfSection(_OrdersSection.sales);
        } else {
          _sectionIndex = _indexOfSection(_OrdersSection.purchases);
        }
      });
    }

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final productName =
        newcomers.first.localizedProductName(isArabic: isAr).trim();
    final isRequest = newcomers.first.isRequestProductOffer;
    unawaited(
      AppPushNotificationService.instance.showForegroundAlert(
        title: isRequest
            ? (isAr ? 'عرض جديد متاح' : 'New offer available')
            : (isAr ? 'طلب جديد متاح' : 'New Order available'),
        body: productName.isEmpty
            ? (isRequest
                ? (isAr
                    ? 'وصلك عرض جديد على أحد طلباتك.'
                    : 'You received a new offer on one of your requests.')
                : (isAr
                    ? 'وصلك طلب جديد على أحد إعلاناتك.'
                    : 'You received a new order on one of your listings.'))
            : (isRequest
                ? (isAr
                    ? 'لديك عرض جديد على طلب "$productName".'
                    : 'You have a new offer on "$productName".')
                : (isAr
                    ? 'لديك طلب جديد على منتج "$productName".'
                    : 'You have a new order for "$productName".')),
        data: {
          'type': isRequest ? 'request_offer' : 'new_order',
          'orderId': '${newcomers.first.orderId}',
          'referenceId': '${newcomers.first.orderId}',
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    NotificationNavigationHelper.pendingHighlightOrderId
        .addListener(_onPendingHighlight);
    _ordersRealtimeSub =
        AppOrderListenerService.instance.userOrdersUpdatedStream.listen((_) {
      unawaited(_onOrdersRealtimeUpdate());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<ClintCubit>();
      if (_loadsIncoming) {
        unawaited(cubit.fetchIncomingOrders());
        unawaited(cubit.fetchMyOrders());
      } else {
        cubit.fetchMyOrders();
      }
      _consumePendingHighlight();
    });
  }

  @override
  void dispose() {
    NotificationNavigationHelper.pendingHighlightOrderId
        .removeListener(_onPendingHighlight);
    _ordersRealtimeSub?.cancel();
    _purchasesScrollController.dispose();
    _salesScrollController.dispose();
    _requestOffersScrollController.dispose();
    super.dispose();
  }

  void _onSectionSelected(int index) {
    setState(() => _sectionIndex = index);
    final cubit = context.read<ClintCubit>();
    final section = _availableSections[index];
    if (section == _OrdersSection.purchases) {
      cubit.fetchMyOrders();
    } else {
      cubit.fetchIncomingOrders();
    }
  }

  void _onPendingHighlight() {
    if (!mounted) return;
    _consumePendingHighlight();
  }

  void _consumePendingHighlight() {
    final id = NotificationNavigationHelper.pendingHighlightOrderId.value;
    final openIncoming = NotificationNavigationHelper.pendingOpenIncomingTab;
    final openRequestOffers =
        NotificationNavigationHelper.pendingOpenRequestOffersTab;
    if ((id == null || id <= 0) && !openIncoming && !openRequestOffers) {
      return;
    }
    NotificationNavigationHelper.pendingHighlightOrderId.value = null;
    NotificationNavigationHelper.pendingOpenIncomingTab = false;
    NotificationNavigationHelper.pendingOpenRequestOffersTab = false;

    final cubit = context.read<ClintCubit>();
    final matchedIncoming = id != null && id > 0
        ? cubit.incomingOrders
            .where((order) => order.orderId == id)
            .firstOrNull
        : null;
    final isIncoming = openIncoming ||
        openRequestOffers ||
        matchedIncoming != null;

    setState(() {
      if (_showSectionTabs && isIncoming) {
        if (openRequestOffers ||
            (matchedIncoming?.isRequestProductOffer ?? false)) {
          _sectionIndex = _indexOfSection(_OrdersSection.requestOffers);
        } else if (AuthService.instance.isSupplierAccount) {
          _sectionIndex = _indexOfSection(_OrdersSection.sales);
        } else {
          _sectionIndex = _indexOfSection(_OrdersSection.purchases);
        }
      } else if (_showSectionTabs && id != null && id > 0) {
        _sectionIndex = _indexOfSection(_OrdersSection.purchases);
      }
      _filter = MyOrdersChipFilter.all;
      _highlightOrderId = isIncoming ? null : id;
      _scrolledForOrderId = null;
    });
    if (isIncoming) {
      cubit.fetchIncomingOrders(silent: cubit.incomingOrders.isNotEmpty);
    } else {
      cubit.fetchMyOrders();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollToHighlightIfNeeded(context.read<ClintCubit>().myOrders);
      });
    }
  }

  GlobalKey _keyFor(int orderId) =>
      _orderKeys.putIfAbsent(orderId, GlobalKey.new);

  void _scrollToHighlightIfNeeded(List<MyOrderModel> orders) {
    final targetId = _highlightOrderId;
    if (targetId == null || targetId <= 0 || orders.isEmpty) return;
    if (_scrolledForOrderId == targetId) return;

    final index = orders.indexWhere((o) => o.id == targetId);
    if (index < 0) return;

    _scrolledForOrderId = targetId;

    void attemptScroll([int tries = 0]) {
      if (!mounted) return;
      final ctx = _keyFor(targetId).currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          alignment: 0.15,
        );
        Future<void>.delayed(const Duration(milliseconds: 2800), () {
          if (!mounted) return;
          if (_highlightOrderId == targetId) {
            setState(() => _highlightOrderId = null);
          }
        });
        return;
      }
      if (tries >= 12) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        attemptScroll(tries + 1);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => attemptScroll());
  }

  List<MyOrderModel> _filtered(List<MyOrderModel> orders) =>
      orders.where(_filter.matches).toList(growable: false);

  Future<void> _onAcceptIncoming(int orderId) async {
    final error = await context.read<ClintCubit>().acceptIncomingOrder(orderId);
    if (!mounted || error == null) return;
    AppToast.showError(context, error);
  }

  Future<void> _onRejectIncoming(int orderId) async {
    final error = await context.read<ClintCubit>().rejectIncomingOrder(orderId);
    if (!mounted || error == null) return;
    AppToast.showError(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final s = S.of(context);

    return BlocConsumer<ClintCubit, ClintStates>(
      listenWhen: (previous, current) =>
          current is FetchMyOrdersSuccessState ||
          current is RefreshOrderSuccessState,
      listener: (context, state) {
        if (!_isPurchasesSection) return;
        final orders = context.read<ClintCubit>().myOrders;
        _scrollToHighlightIfNeeded(orders);
      },
      buildWhen: (previous, current) =>
          current is FetchMyOrdersLoadingState ||
          current is FetchMyOrdersSuccessState ||
          current is FetchMyOrdersErrorState ||
          current is RefreshOrderSuccessState ||
          current is FetchIncomingOrdersLoadingState ||
          current is FetchIncomingOrdersSuccessState ||
          current is FetchIncomingOrdersErrorState ||
          current is IncomingOrderStatusUpdatingState ||
          current is IncomingOrderStatusUpdatedState,
      builder: (context, state) {
        return SafeArea(
          child: Scaffold(
            backgroundColor: AppColors.scaffold(context),
            body: Column(
              children: [
                const SearchHeader(
                  title: null,
                  isBackButton: false,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 4.h, 24.w, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.myOrders,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.title(context),
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        s.myOrdersSubtitle,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 13.sp,
                          color: AppColors.subtitle(context),
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: 12.h),
                    ],
                  ),
                ),
                if (_showSectionTabs) ...[
                  _OrdersSectionTabs(
                    sections: _availableSections,
                    selectedIndex: _sectionIndex,
                    onSelected: _onSectionSelected,
                  ),
                ],
                Expanded(
                  child: _isPurchasesSection
                      ? _buildPurchasesSection(context, s, fontFamily)
                      : _isRequestOffersSection
                          ? _buildIncomingSection(
                              context,
                              s,
                              fontFamily,
                              scrollController: _requestOffersScrollController,
                              offers: _requestOffersOnly(
                                ClintCubit.get(context).incomingOrders,
                              ),
                              subtitle: s.incomingRequestOffersSubtitle,
                              emptyLabel: s.noIncomingRequestOffersYet,
                              useOfferLabels: true,
                            )
                          : _buildIncomingSection(
                              context,
                              s,
                              fontFamily,
                              scrollController: _salesScrollController,
                              offers: _salesOnly(
                                ClintCubit.get(context).incomingOrders,
                              ),
                              subtitle: s.incomingOrdersSubtitle,
                              emptyLabel: s.noIncomingOrdersYet,
                              useOfferLabels: false,
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIncomingSection(
    BuildContext context,
    S s,
    String fontFamily, {
    required ScrollController scrollController,
    required List<MyRequestOfferModel> offers,
    required String subtitle,
    required String emptyLabel,
    required bool useOfferLabels,
  }) {
    final cubit = ClintCubit.get(context);
    final allIncoming = cubit.incomingOrders;

    if (cubit.isLoadingIncomingOrders && allIncoming.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (cubit.incomingOrdersError != null && allIncoming.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            cubit.incomingOrdersError!,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: fontFamily, fontSize: 14.sp),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => cubit.fetchIncomingOrders(),
      child: CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 8.h),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 13.sp,
                  color: const Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
            ),
          ),
          if (offers.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  emptyLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 14.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
              sliver: _buildIncomingOrdersSliver(
                offers: offers,
                cubit: cubit,
                s: s,
                fontFamily: fontFamily,
                useOfferLabels: useOfferLabels,
                onAcceptIncoming: _onAcceptIncoming,
                onRejectIncoming: _onRejectIncoming,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPurchasesSection(
    BuildContext context,
    S s,
    String fontFamily,
  ) {
    final cubit = ClintCubit.get(context);
    final orders = cubit.myOrders;
    final visible = _filtered(orders);

    if (cubit.isLoadingMyOrders && orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (cubit.myOrdersError != null && orders.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            cubit.myOrdersError!,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: fontFamily, fontSize: 14.sp),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => cubit.fetchMyOrders(),
      child: CustomScrollView(
        controller: _purchasesScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (orders.isNotEmpty) _sliverFilterChips(orders, s, fontFamily),
          if (orders.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  s.noPurchasesYet,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 14.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            )
          else if (visible.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  s.noOrdersMatchFilter,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 14.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
              sliver: _buildPurchasesOrdersSliver(
                orders: visible,
                oldestLabel: s.oldestOrdersSection,
                fontFamily: fontFamily,
                highlightOrderId: _highlightOrderId,
                keyFor: _keyFor,
                onTrackTap: (order) => context.push(
                  AppRoutes.kTrackOrderView,
                  extra: {'order': order},
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sliverFilterChips(
    List<MyOrderModel> orders,
    S s,
    String fontFamily,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
        child: Wrap(
          spacing: 6.w,
          runSpacing: 6.h,
          children: [
            for (final chip in MyOrdersChipFilter.values)
              ChoiceChip(
                selected: _filter == chip,
                showCheckmark: false,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 0),
                labelPadding: EdgeInsets.only(right: 4.w),
                avatar: Icon(
                  chip.icon,
                  size: 13.sp,
                  color: _filter == chip
                      ? Colors.white
                      : LightColor.defaultColor,
                ),
                label: Text(
                  '${chip.label(s)} (${MyOrdersChipFilter.count(orders, chip)})',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w600,
                    color: _filter == chip
                        ? Colors.white
                        : AppColors.title(context),
                  ),
                ),
                selectedColor: LightColor.defaultColor,
                backgroundColor: AppColors.card(context),
                side: BorderSide(
                  color: _filter == chip
                      ? LightColor.defaultColor
                      : AppColors.border(context),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                onSelected: (_) => setState(() => _filter = chip),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchasesOrdersSliver({
    required List<MyOrderModel> orders,
    required String oldestLabel,
    required String fontFamily,
    required int? highlightOrderId,
    required GlobalKey Function(int orderId) keyFor,
    required void Function(MyOrderModel order) onTrackTap,
  }) {
    final entries = OrderListOldestSection.buildEntries(
      items: orders,
      createdAtOf: (order) => order.createdAt,
      oldestSectionLabel: oldestLabel,
    );

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = entries[index];
          final bottomGap = index < entries.length - 1 ? 14.h : 0.0;

          if (entry.isHeader) {
            return Padding(
              padding: EdgeInsets.only(bottom: bottomGap),
              child: OrderListOldestHeader(
                label: entry.sectionLabel!,
                fontFamily: fontFamily,
              ),
            );
          }

          final order = entry.item!;
          return Padding(
            padding: EdgeInsets.only(bottom: bottomGap),
            child: OrderCard(
              key: keyFor(order.id),
              order: order,
              highlighted: highlightOrderId == order.id,
              onTrackTap: () => onTrackTap(order),
            ),
          );
        },
        childCount: entries.length,
      ),
    );
  }

  Widget _buildIncomingOrdersSliver({
    required List<MyRequestOfferModel> offers,
    required ClintCubit cubit,
    required S s,
    required String fontFamily,
    required bool useOfferLabels,
    required Future<void> Function(int orderId) onAcceptIncoming,
    required Future<void> Function(int orderId) onRejectIncoming,
  }) {
    final entries = OrderListOldestSection.buildEntries(
      items: offers,
      createdAtOf: (offer) => offer.createdAt,
      oldestSectionLabel: s.oldestOrdersSection,
    );

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = entries[index];
          final bottomGap = index < entries.length - 1 ? 12.h : 0.0;

          if (entry.isHeader) {
            return Padding(
              padding: EdgeInsets.only(bottom: bottomGap),
              child: OrderListOldestHeader(
                label: entry.sectionLabel!,
                fontFamily: fontFamily,
              ),
            );
          }

          final offer = entry.item!;
          final isUpdating = cubit.updatingIncomingOrderId == offer.orderId;
          final isRequestOffer =
              offer.isRequestProductOffer || useOfferLabels;
          return Padding(
            padding: EdgeInsets.only(bottom: bottomGap),
            child: RequestOfferCard(
              offer: offer,
              fontFamily: fontFamily,
              isUpdating: isUpdating,
              acceptLabel: isRequestOffer
                  ? s.acceptOfferAction
                  : s.acceptOrderAction,
              rejectLabel: isRequestOffer
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
                  ? () => onAcceptIncoming(offer.orderId)
                  : null,
              onReject: offer.canReject
                  ? () => onRejectIncoming(offer.orderId)
                  : null,
            ),
          );
        },
        childCount: entries.length,
      ),
    );
  }
}

class _OrdersSectionTabs extends StatelessWidget {
  const _OrdersSectionTabs({
    required this.sections,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_OrdersSection> sections;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final items = sections.map((section) {
      switch (section) {
        case _OrdersSection.sales:
          return (label: s.incomingOrders, icon: Icons.storefront_outlined);
        case _OrdersSection.purchases:
          return (label: s.purchases, icon: Icons.shopping_bag_outlined);
        case _OrdersSection.requestOffers:
          return (
            label: s.incomingRequestOffersTab,
            icon: Icons.inbox_outlined,
          );
      }
    }).toList(growable: false);

    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 4.h),
      child: Row(
        children: List.generate(items.length, (index) {
          final isSelected = selectedIndex == index;
          final item = items[index];
          final fg = isSelected ? Colors.white : LightColor.defaultColor;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              child: GestureDetector(
                onTap: () => onSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 9.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.r),
                    color: isSelected
                        ? LightColor.defaultColor
                        : AppColors.card(context),
                    border: Border.all(
                      color: LightColor.defaultColor,
                      width: 1.4,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(item.icon, size: 14.sp, color: fg),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: fg,
                            fontFamily: fontFamily,
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
