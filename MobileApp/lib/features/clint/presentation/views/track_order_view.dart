import 'dart:async';

import 'package:alrasmarket/core/serveses/app_order_listener_service.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/features/clint/data/models/my_order_model.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_states.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/track_order_widgets/track_order_customer_service_card.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/track_order_widgets/track_order_status_helper.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/track_order_widgets/track_order_summary_card.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/track_order_widgets/track_order_timeline_card.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TrackOrderView extends StatefulWidget {
  const TrackOrderView({
    super.key,
    this.order,
    this.orderId,
    this.showBuyerActions = true,
  });

  final MyOrderModel? order;
  final int? orderId;

  /// When false (seller viewing orders on their ad), hide return/cancel actions.
  final bool showBuyerActions;

  @override
  State<TrackOrderView> createState() => _TrackOrderViewState();
}

class _TrackOrderViewState extends State<TrackOrderView>
    with WidgetsBindingObserver {
  MyOrderModel? _currentOrder;
  Timer? _refreshTimer;
  StreamSubscription<int>? _orderUpdatedSub;
  static const _refreshInterval = Duration(seconds: 90);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentOrder = widget.order;
    final orderId = widget.orderId ?? widget.order?.id;
    if (orderId != null && orderId > 0) {
      // Always load live status from the API (list cache may be stale).
      unawaited(_loadOrderById(orderId));
      unawaited(_subscribeOrderRealtime(orderId));
    }
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _orderUpdatedSub?.cancel();
    unawaited(AppOrderListenerService.instance.leaveOrder());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final orderId = _trackedOrderId;
      if (orderId != null && orderId > 0) {
        unawaited(_subscribeOrderRealtime(orderId));
      }
      unawaited(_refreshCurrentOrder());
    }
  }

  Future<void> _subscribeOrderRealtime(int orderId) async {
    await AppOrderListenerService.instance.joinOrder(orderId);
    await _orderUpdatedSub?.cancel();
    _orderUpdatedSub =
        AppOrderListenerService.instance.orderUpdatedStream.listen((id) {
      if (id == (_trackedOrderId ?? orderId)) {
        unawaited(_refreshCurrentOrder());
      }
    });
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    // Fallback only — primary live path is SignalR orderUpdated.
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      unawaited(_refreshCurrentOrder());
    });
  }

  Future<void> _loadOrderById(int orderId) async {
    final order = await context.read<ClintCubit>().refreshOrderById(orderId);
    if (!mounted || order == null) return;
    setState(() => _currentOrder = order);
  }

  Future<void> _refreshCurrentOrder() async {
    final orderId = _trackedOrderId;
    if (orderId == null || orderId <= 0) return;
    final order = await context.read<ClintCubit>().refreshOrderById(orderId);
    if (!mounted || order == null) return;
    setState(() => _currentOrder = order);
  }

  int? get _trackedOrderId => _currentOrder?.id ?? widget.orderId;

  MyOrderModel get _displayOrder => _currentOrder ?? _demoOrder();

  Future<void> _handleCancelOrReturn({required bool isReturn}) async {
    final s = S.of(context);
    final order = _displayOrder;

    if (isReturn) {
      await _handleReturnRequest(order);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.cancelOrderConfirmTitle),
        content: Text(s.cancelOrderConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.cancelOrder),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final refundMessage = await context.read<ClintCubit>().cancelOrReturnOrder(
      orderId: order.id,
      isReturn: false,
    );

    if (!mounted) return;

    if (refundMessage != null || !TrackOrderStatusHelper.isOnlinePayment(order)) {
      final notice = TrackOrderStatusHelper.isOnlinePayment(order)
          ? (refundMessage?.trim().isNotEmpty == true
              ? refundMessage!.trim()
              : s.orderRefundNotice)
          : s.orderCancelledSuccess;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(notice)),
      );

      setState(() {
        _currentOrder = order.copyWithCancelled();
      });
      unawaited(_refreshCurrentOrder());
    }
  }

  Future<void> _handleReturnRequest(MyOrderModel order) async {
    final s = S.of(context);
    final reasonController = TextEditingController();
    final mediaPaths = <String>[];

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(s.returnOrderConfirmTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(s.returnOrderConfirmMessage),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: s.returnOrderConfirmMessage,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.pickFiles(
                          allowMultiple: true,
                          type: FileType.custom,
                          allowedExtensions: const [
                            'jpg',
                            'jpeg',
                            'png',
                            'mp4',
                            'mov',
                            'webm',
                          ],
                        );
                        if (result == null) return;
                        setDialogState(() {
                          for (final file in result.files) {
                            if (file.path != null &&
                                !mediaPaths.contains(file.path)) {
                              mediaPaths.add(file.path!);
                            }
                          }
                        });
                      },
                      icon: const Icon(Icons.attach_file),
                      label: Text(
                        mediaPaths.isEmpty
                            ? s.returnOrder
                            : '${mediaPaths.length}',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(s.cancel),
                ),
                TextButton(
                  onPressed: () {
                    if (reasonController.text.trim().length < 3) return;
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: Text(s.returnOrder),
                ),
              ],
            );
          },
        );
      },
    );

    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (submitted != true || !mounted) return;

    final updated = await context.read<ClintCubit>().requestOrderReturn(
      orderId: order.id,
      reason: reason,
      mediaPaths: mediaPaths,
    );

    if (!mounted) return;
    if (updated != null) {
      setState(() => _currentOrder = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.orderReturnSuccess)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final displayOrder = _displayOrder;
    final steps = TrackOrderStatusHelper.buildSteps(
      order: displayOrder,
      l10n: s,
      isArabic: isArabic,
    );
    final canReturn = widget.showBuyerActions &&
        TrackOrderStatusHelper.canReturnOrder(displayOrder);
    final showOnlineRefundNotice = widget.showBuyerActions &&
        TrackOrderStatusHelper.isOnlinePayment(displayOrder) &&
        canReturn;

    return BlocListener<ClintCubit, ClintStates>(
      listener: (context, state) {
        if (state is CancelOrderErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is RefreshOrderSuccessState &&
            state.order.id == _trackedOrderId) {
          setState(() => _currentOrder = state.order);
        } else if (state is FetchMyOrdersSuccessState) {
          final orderId = _trackedOrderId;
          if (orderId == null) return;
          final matches = state.orders.where((item) => item.id == orderId);
          if (matches.isNotEmpty) {
            setState(() => _currentOrder = matches.first);
          }
        }
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: const Color(0xFFF4F7FA),
          body: Column(
            children: [
              SearchHeader(title: s.trackOrder, isSearch: false),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
                  child: Column(
                    children: [
                      TrackOrderSummaryCard(
                        order: displayOrder,
                        fontFamily: fontFamily,
                      ),
                      SizedBox(height: 16.h),
                      TrackOrderTimelineCard(
                        steps: steps,
                        fontFamily: fontFamily,
                      ),
                      if (showOnlineRefundNotice &&
                          displayOrder.statusId !=
                              OrderStatusCodes.cancelled) ...[
                        SizedBox(height: 16.h),
                        _RefundNoticeCard(
                          message: s.orderRefundNotice,
                          fontFamily: fontFamily,
                        ),
                      ],
                      if (canReturn) ...[
                        SizedBox(height: 16.h),
                        BlocBuilder<ClintCubit, ClintStates>(
                          buildWhen: (previous, current) =>
                              current is CancelOrderLoadingState ||
                              current is CancelOrderSuccessState ||
                              current is CancelOrderErrorState,
                          builder: (context, state) {
                            final isLoading = state is CancelOrderLoadingState &&
                                state.orderId == displayOrder.id;

                            return SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: isLoading
                                    ? null
                                    : () => _handleCancelOrReturn(
                                          isReturn: true,
                                        ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFDC2626),
                                  side: const BorderSide(color: Color(0xFFDC2626)),
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                child: isLoading
                                    ? SizedBox(
                                        height: 20.h,
                                        width: 20.h,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        s.returnOrder,
                                        style: TextStyle(
                                          fontFamily: fontFamily,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15.sp,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      ],
                      SizedBox(height: 16.h),
                      TrackOrderCustomerServiceCard(
                        fontFamily: fontFamily,
                        phoneNumber: displayOrder.supplierPhone,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  MyOrderModel _demoOrder() {
    return const MyOrderModel(
      id: 2124536,
      productId: 'demo-product',
      customerName: 'Customer',
      customerEmail: 'customer@example.com',
      customerPhone: '+971500000000',
      supplierName: 'Supplier',
      supplierEmail: 'supplier@example.com',
      supplierPhone: '+971500000001',
      productName: 'Whole Black Pepper',
      productNameEn: 'Whole Black Pepper',
      productNameAr: 'فلفل أسود كامل',
      productDescription: 'Premium whole black pepper.',
      productDescriptionEn: 'Premium whole black pepper.',
      productDescriptionAr: 'فلفل أسود كامل فاخر.',
      productTypeName: 'Booking',
      productTypeNameEn: 'Booking',
      productTypeNameAr: 'حجز',
      categoryName: 'Spices',
      categoryNameEn: 'Spices',
      categoryNameAr: 'بهارات',
      categoryId: 1,
      primaryImagePath: null,
      unitName: 'tons',
      unitNameEn: 'Ton',
      unitNameAr: 'طن',
      statusId: 1,
      statusName: 'Ordered',
      statusLabelAr: 'تم الطلب',
      unitPrice: 0,
      totalPrice: 0,
      customerTotalPrice: 0,
      amountFormatted: '',
      currency: 'AED',
      customerTotalPriceFormatted: '',
      chargedGrandTotalAed: 0,
      chargedGrandTotalFormatted: '',
      quantity: 1,
      paymentMethod: 1,
      paymentMethodName: 'CashOnDelivery',
      createdAt: '',
      isApproved: false,
      notes: null,
      videoPaths: [],
      images: [],
      portId: null,
      portName: null,
    );
  }
}

class _RefundNoticeCard extends StatelessWidget {
  const _RefundNoticeCard({
    required this.message,
    required this.fontFamily,
  });

  final String message;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: const Color(0xFF2563EB), size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 13.sp,
                color: const Color(0xFF1E3A8A),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on MyOrderModel {
  MyOrderModel copyWithCancelled() {
    return MyOrderModel(
      id: id,
      productId: productId,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      supplierName: supplierName,
      supplierEmail: supplierEmail,
      supplierPhone: supplierPhone,
      productName: productName,
      productNameEn: productNameEn,
      productNameAr: productNameAr,
      productDescription: productDescription,
      productDescriptionEn: productDescriptionEn,
      productDescriptionAr: productDescriptionAr,
      productTypeName: productTypeName,
      productTypeNameEn: productTypeNameEn,
      productTypeNameAr: productTypeNameAr,
      categoryName: categoryName,
      categoryNameEn: categoryNameEn,
      categoryNameAr: categoryNameAr,
      categoryId: categoryId,
      primaryImagePath: primaryImagePath,
      unitName: unitName,
      unitNameEn: unitNameEn,
      unitNameAr: unitNameAr,
      statusId: OrderStatusCodes.cancelled,
      statusName: 'Cancelled',
      statusLabelAr: 'ملغي',
      unitPrice: unitPrice,
      totalPrice: totalPrice,
      customerTotalPrice: customerTotalPrice,
      amountFormatted: amountFormatted,
      currency: currency,
      customerTotalPriceFormatted: customerTotalPriceFormatted,
      chargedGrandTotalAed: chargedGrandTotalAed,
      chargedGrandTotalFormatted: chargedGrandTotalFormatted,
      quantity: quantity,
      paymentMethod: paymentMethod,
      paymentMethodName: paymentMethodName,
      createdAt: createdAt,
      isApproved: isApproved,
      notes: notes,
      videoPaths: videoPaths,
      images: images,
      portId: portId,
      portName: portName,
      refundedAtUtc: refundedAtUtc,
      isRefunded: isRefunded,
      returnReason: returnReason,
      returnMediaPaths: returnMediaPaths,
      returnRequestedAtUtc: returnRequestedAtUtc,
      returnAdminResponse: returnAdminResponse,
      returnRespondedAtUtc: returnRespondedAtUtc,
    );
  }
}
