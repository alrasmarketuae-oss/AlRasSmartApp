import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/features/clint/data/models/my_order_model.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_states.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/notification_navigation_helper.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/product_details_opener.dart';
import 'package:alrasmarket/features/clint/presentation/models/my_orders_chip_filter.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/order_card.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class MyOrdersView extends StatefulWidget {
  const MyOrdersView({super.key});

  @override
  State<MyOrdersView> createState() => _MyOrdersViewState();
}

class _MyOrdersViewState extends State<MyOrdersView> {
  MyOrdersChipFilter _filter = MyOrdersChipFilter.all;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _orderKeys = {};
  int? _highlightOrderId;
  int? _scrolledForOrderId;

  @override
  void initState() {
    super.initState();
    NotificationNavigationHelper.pendingHighlightOrderId
        .addListener(_onPendingHighlight);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ClintCubit>().fetchMyOrders();
      _consumePendingHighlight();
    });
  }

  @override
  void dispose() {
    NotificationNavigationHelper.pendingHighlightOrderId
        .removeListener(_onPendingHighlight);
    _scrollController.dispose();
    super.dispose();
  }

  void _onPendingHighlight() {
    if (!mounted) return;
    _consumePendingHighlight();
  }

  void _consumePendingHighlight() {
    final id = NotificationNavigationHelper.pendingHighlightOrderId.value;
    if (id == null || id <= 0) return;
    NotificationNavigationHelper.pendingHighlightOrderId.value = null;
    setState(() {
      _filter = MyOrdersChipFilter.all;
      _highlightOrderId = id;
      _scrolledForOrderId = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToHighlightIfNeeded(context.read<ClintCubit>().myOrders);
    });
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

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final s = S.of(context);

    return BlocConsumer<ClintCubit, ClintStates>(
      listenWhen: (previous, current) =>
          current is FetchMyOrdersSuccessState ||
          current is RefreshOrderSuccessState,
      listener: (context, state) {
        final orders = context.read<ClintCubit>().myOrders;
        _scrollToHighlightIfNeeded(orders);
      },
      buildWhen: (previous, current) =>
          current is FetchMyOrdersLoadingState ||
          current is FetchMyOrdersSuccessState ||
          current is FetchMyOrdersErrorState ||
          current is RefreshOrderSuccessState,
      builder: (context, state) {
        final cubit = ClintCubit.get(context);
        final orders = cubit.myOrders;
        final visible = _filtered(orders);

        return SafeArea(
          child: Scaffold(
            backgroundColor: const Color(0xFFF4F7FA),
            body: Column(
              children: [
                SearchHeader(
                  title: null,
                  isBackButton: false,
                ),
                Expanded(
                  child: cubit.isLoadingMyOrders && orders.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : cubit.myOrdersError != null && orders.isEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24.w),
                                child: Text(
                                  cubit.myOrdersError!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: fontFamily,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => cubit.fetchMyOrders(),
                              child: CustomScrollView(
                                controller: _scrollController,
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                slivers: [
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        24.w,
                                        4.h,
                                        24.w,
                                        0,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s.myOrders,
                                            style: TextStyle(
                                              fontFamily: fontFamily,
                                              fontSize: 26.sp,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF0F172A),
                                              height: 1.2,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            s.myOrdersSubtitle,
                                            style: TextStyle(
                                              fontFamily: fontFamily,
                                              fontSize: 13.sp,
                                              color: const Color(0xFF64748B),
                                              height: 1.35,
                                            ),
                                          ),
                                          SizedBox(height: 14.h),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (orders.isNotEmpty)
                                    sliverFilterChips(orders, s, fontFamily),
                                  if (orders.isEmpty)
                                    SliverFillRemaining(
                                      hasScrollBody: false,
                                      child: Center(
                                        child: Text(
                                          s.orders,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: fontFamily,
                                            fontSize: 14.sp,
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
                                      padding: EdgeInsets.fromLTRB(
                                        16.w,
                                        8.h,
                                        16.w,
                                        24.h,
                                      ),
                                      sliver: SliverList.separated(
                                        itemCount: visible.length,
                                        separatorBuilder: (_, __) =>
                                            SizedBox(height: 14.h),
                                        itemBuilder: (context, index) {
                                          final order = visible[index];
                                          return OrderCard(
                                            key: _keyFor(order.id),
                                            order: order,
                                            highlighted:
                                                _highlightOrderId == order.id,
                                            onAdTap: () => ProductDetailsOpener
                                                .openByProductId(
                                              context,
                                              productId: order.productId,
                                            ),
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
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget sliverFilterChips(
    List<MyOrderModel> orders,
    S s,
    String fontFamily,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 4.h),
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
                        : const Color(0xFF1E293B),
                  ),
                ),
                selectedColor: LightColor.defaultColor,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: _filter == chip
                      ? LightColor.defaultColor
                      : const Color(0xFFE2E8F0),
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
