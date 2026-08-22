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
import 'package:alrasmarket/features/clint/presentation/models/my_orders_chip_filter.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/order_card.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/features/company/presentation/widgets/my_ads/request_offer_card.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Orders tab layout varies by account:
/// - Supplier: Incoming + Purchases
/// - Company customer: Requests + Orders
/// - Personal customer: Purchases only
class MyOrdersView extends StatefulWidget {
  const MyOrdersView({super.key});

  @override
  State<MyOrdersView> createState() => _MyOrdersViewState();
}

class _MyOrdersViewState extends State<MyOrdersView> {
  int _sectionIndex = 0;
  MyOrdersChipFilter _filter = MyOrdersChipFilter.all;
  final ScrollController _purchasesScrollController = ScrollController();
  final ScrollController _incomingScrollController = ScrollController();
  final Map<int, GlobalKey> _orderKeys = {};
  int? _highlightOrderId;
  int? _scrolledForOrderId;
  StreamSubscription<void>? _ordersRealtimeSub;

  bool get _showIncomingTab =>
      !AuthService.instance.isPersonalCustomerAccount;

  bool get _isCompanyCustomerAccount =>
      AuthService.instance.isCompanyCustomerAccount;

  bool get _isPurchasesSection =>
      !_showIncomingTab || _sectionIndex != 0;

  Future<void> _onOrdersRealtimeUpdate() async {
    if (!mounted) return;
    final cubit = context.read<ClintCubit>();
    final previousIncomingIds =
        cubit.incomingOrders.map((order) => order.orderId).toSet();

    if (_isPurchasesSection) {
      await cubit.fetchMyOrders(silent: true);
      if (_showIncomingTab) {
        await cubit.fetchIncomingOrders(silent: true);
      }
    } else if (_isCompanyCustomerAccount) {
      await cubit.fetchIncomingOrders(silent: true);
    } else {
      await cubit.fetchIncomingOrders(silent: true);
    }

    if (!mounted) return;
    final newcomers = cubit.incomingOrders
        .where((order) => !previousIncomingIds.contains(order.orderId))
        .toList();
    if (newcomers.isEmpty) return;

    if (_showIncomingTab && _sectionIndex != 0) {
      setState(() => _sectionIndex = 0);
    }

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final productName = newcomers.first.productName.trim();
    unawaited(
      AppPushNotificationService.instance.showForegroundAlert(
        title: isAr ? 'طلب جديد متاح' : 'New Order available',
        body: productName.isEmpty
            ? (isAr
                ? 'وصلك طلب جديد على أحد إعلاناتك.'
                : 'You received a new order on one of your listings.')
            : (isAr
                ? 'لديك طلب جديد على منتج "$productName".'
                : 'You have a new order for "$productName".'),
        data: {
          'type': 'new_order',
          'orderId': '${newcomers.first.orderId}',
          'referenceId': '${newcomers.first.orderId}',
        },
      ),
    );
  }

  void _loadCompanyRequestsData() {
    unawaited(context.read<ClintCubit>().fetchIncomingOrders());
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
      if (_showIncomingTab) {
        if (_isCompanyCustomerAccount) {
          _loadCompanyRequestsData();
        } else {
          cubit.fetchIncomingOrders();
        }
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
    _incomingScrollController.dispose();
    super.dispose();
  }

  void _onSectionSelected(int index) {
    setState(() => _sectionIndex = index);
    final cubit = context.read<ClintCubit>();
    if (index == 0) {
      if (_isCompanyCustomerAccount) {
        _loadCompanyRequestsData();
      } else {
        cubit.fetchIncomingOrders();
      }
    } else {
      cubit.fetchMyOrders();
    }
  }

  void _onPendingHighlight() {
    if (!mounted) return;
    _consumePendingHighlight();
  }

  void _consumePendingHighlight() {
    final id = NotificationNavigationHelper.pendingHighlightOrderId.value;
    final openIncoming = NotificationNavigationHelper.pendingOpenIncomingTab;
    if ((id == null || id <= 0) && !openIncoming) return;
    NotificationNavigationHelper.pendingHighlightOrderId.value = null;
    NotificationNavigationHelper.pendingOpenIncomingTab = false;
    final cubit = context.read<ClintCubit>();
    final isIncoming = openIncoming ||
        cubit.incomingOrders.any((order) => order.orderId == id);
    setState(() {
      if (_showIncomingTab && isIncoming) {
        _sectionIndex = 0;
      } else if (_showIncomingTab && id != null && id > 0) {
        _sectionIndex = 1;
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
                if (_showIncomingTab) ...[
                  _OrdersSectionTabs(
                    selectedIndex: _sectionIndex,
                    onSelected: _onSectionSelected,
                    isCompanyCustomer: _isCompanyCustomerAccount,
                  ),
                ],
                Expanded(
                  child: _isPurchasesSection
                      ? _buildPurchasesSection(context, s, fontFamily)
                      : _buildIncomingSection(
                          context,
                          s,
                          fontFamily,
                          subtitle: _isCompanyCustomerAccount
                              ? s.companyCustomerRequestsSubtitle
                              : null,
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
    String? subtitle,
  }) {
    final cubit = ClintCubit.get(context);
    final offers = cubit.incomingOrders;

    if (cubit.isLoadingIncomingOrders && offers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (cubit.incomingOrdersError != null && offers.isEmpty) {
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
        controller: _incomingScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 8.h),
              child: Text(
                subtitle ?? s.incomingOrdersSubtitle,
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
                  s.noIncomingOrdersYet,
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
              sliver: SliverList.separated(
                itemCount: offers.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final offer = offers[index];
                  final isUpdating =
                      cubit.updatingIncomingOrderId == offer.orderId;
                  return RequestOfferCard(
                    offer: offer,
                    fontFamily: fontFamily,
                    isUpdating: isUpdating,
                    acceptLabel: s.acceptOrderAction,
                    rejectLabel: s.rejectOrderAction,
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
                        ? () => _onAcceptIncoming(offer.orderId)
                        : null,
                    onReject: offer.canReject
                        ? () => _onRejectIncoming(offer.orderId)
                        : null,
                  );
                },
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
              sliver: SliverList.separated(
                itemCount: visible.length,
                separatorBuilder: (_, __) => SizedBox(height: 14.h),
                itemBuilder: (context, index) {
                  final order = visible[index];
                  return OrderCard(
                    key: _keyFor(order.id),
                    order: order,
                    highlighted: _highlightOrderId == order.id,
                    onTrackTap: () => context.push(
                      AppRoutes.kTrackOrderView,
                      extra: {'order': order},
                    ),
                  );
                },
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
}

class _OrdersSectionTabs extends StatelessWidget {
  const _OrdersSectionTabs({
    required this.selectedIndex,
    required this.onSelected,
    required this.isCompanyCustomer,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool isCompanyCustomer;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final firstTabLabel = isCompanyCustomer
        ? s.companyCustomerRequestsTab
        : s.incomingOrders;
    final secondTabLabel = isCompanyCustomer
        ? s.companyCustomerOrdersTab
        : s.purchases;
    final items = [
      (label: firstTabLabel, icon: Icons.inbox_outlined),
      (label: secondTabLabel, icon: Icons.shopping_bag_outlined),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 4.h),
      child: Row(
        children: List.generate(items.length, (index) {
          final isSelected = selectedIndex == index;
          final item = items[index];
          final fg = isSelected ? Colors.white : LightColor.defaultColor;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == 0 ? 6.w : 0,
                left: index == 1 ? 6.w : 0,
              ),
              child: GestureDetector(
                onTap: () => onSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 9.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.r),
                    color: isSelected ? LightColor.defaultColor : AppColors.card(context),
                    border: Border.all(
                      color: LightColor.defaultColor,
                      width: 1.4,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(item.icon, size: 16.sp, color: fg),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: fg,
                            fontFamily: fontFamily,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18.sp,
                        color: fg,
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
