import 'dart:async';

import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/router/where_to_go.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/features/clint/data/models/my_order_model.dart';
import 'package:alrasmarket/features/clint/domain/usecases/payment_usecases.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

class PaymentSuccessView extends StatefulWidget {
  const PaymentSuccessView({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  State<PaymentSuccessView> createState() => _PaymentSuccessViewState();
}

class _PaymentSuccessViewState extends State<PaymentSuccessView> {
  static const _maxPolls = 40;
  static const _pollInterval = Duration(seconds: 2);

  final _getCheckoutStatusUseCase = sl<GetCheckoutStatusUseCase>();

  _PaymentPageState _pageState = _PaymentPageState.loading;
  String? _orderGroupId;
  String? _errorMessage;
  int _pollCount = 0;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    if (widget.sessionId.isEmpty) {
      setState(() {
        _pageState = _PaymentPageState.error;
        _errorMessage = 'Missing payment session.';
      });
      return;
    }

    unawaited(_pollOnce());
    _pollTimer = Timer.periodic(_pollInterval, (_) => unawaited(_pollOnce()));
  }

  Future<void> _pollOnce() async {
    if (!mounted || _pageState == _PaymentPageState.completed) return;

    final token = AuthService.instance.currentToken;
    if (token == null) {
      setState(() {
        _pageState = _PaymentPageState.error;
        _errorMessage = 'Please sign in again to confirm your payment.';
      });
      _pollTimer?.cancel();
      return;
    }

    _pollCount++;
    final result = await _getCheckoutStatusUseCase(
      GetCheckoutStatusParams(token: token, sessionId: widget.sessionId),
    );

    if (!mounted) return;

    await result.fold(
      (failure) async {
        setState(() {
          _pageState = _PaymentPageState.error;
          _errorMessage = failure.message;
        });
        _pollTimer?.cancel();
      },
      (status) async {
        if (status.isCompleted) {
          _pollTimer?.cancel();
          setState(() {
            _pageState = _PaymentPageState.completed;
            _orderGroupId = status.orderGroupId;
          });
          final cubit = context.read<ClintCubit>();
          await Future.wait([
            cubit.loadCart(),
            cubit.fetchMyOrders(),
          ]);
          if (!mounted) return;
          final latestOrder = _latestOrder(cubit.myOrders);
          if (latestOrder != null) {
            context.pushReplacement(
              AppRoutes.kTrackOrderView,
              extra: {'order': latestOrder},
            );
          }
          return;
        }

        if (status.isProcessing) {
          setState(() => _pageState = _PaymentPageState.processing);
          return;
        }

        if (_pollCount >= _maxPolls) {
          _pollTimer?.cancel();
          setState(() {
            _pageState = _PaymentPageState.error;
            _errorMessage =
                'Payment received but order confirmation is taking longer than expected. Please check My Orders.';
          });
        } else {
          setState(() => _pageState = _PaymentPageState.loading);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppFonts.familyFor(Localizations.localeOf(context));
    final l10n = S.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 48.h),
                      if (_pageState == _PaymentPageState.completed)
                        SvgPicture.asset(
                          AppAssets.checkCircleIcon,
                          width: 88.r,
                          height: 88.r,
                        )
                      else if (_pageState == _PaymentPageState.error)
                        Icon(
                          Icons.error_outline_rounded,
                          size: 88.r,
                          color: Colors.red.shade400,
                        )
                      else
                        SizedBox(
                          width: 56.r,
                          height: 56.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFF3A7DC5),
                          ),
                        ),
                      SizedBox(height: 28.h),
                      Text(
                        _titleForState(l10n),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF333333),
                          fontFamily: fontFamily,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        _subtitleForState(l10n),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF333333).withValues(alpha: 0.65),
                          fontFamily: fontFamily,
                          fontSize: 14.sp,
                          height: 1.5,
                        ),
                      ),
                      if (_orderGroupId != null && _orderGroupId!.isNotEmpty) ...[
                        SizedBox(height: 28.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 18.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9F5EA),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Column(
                            children: [
                              Text(
                                l10n.orderNumber,
                                style: TextStyle(
                                  color: const Color(0xFF333333)
                                      .withValues(alpha: 0.55),
                                  fontFamily: fontFamily,
                                  fontSize: 13.sp,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                '#${_orderGroupId!.substring(0, 8).toUpperCase()}',
                                style: TextStyle(
                                  color: const Color(0xFF333333),
                                  fontFamily: fontFamily,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_errorMessage != null) ...[
                        SizedBox(height: 20.h),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontFamily: fontFamily,
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_pageState == _PaymentPageState.completed) ...[
                PrimaryButton(
                  text: l10n.trackOrder,
                  backgroundColor: const Color(0xFF3A7DC5),
                  onPressed: () {
                    final latestOrder = _latestOrder(
                      context.read<ClintCubit>().myOrders,
                    );
                    if (latestOrder != null) {
                      context.push(
                        AppRoutes.kTrackOrderView,
                        extra: {'order': latestOrder},
                      );
                      return;
                    }
                    context.go(whereToGo());
                  },
                  height: 48.h,
                  borderRadius: 8.r,
                ),
                SizedBox(height: 12.h),
              ],
              OutlinedButton(
                onPressed: () => context.go(whereToGo()),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF3A7DC5), width: 1.5),
                  minimumSize: Size(double.infinity, 48.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  l10n.backToHome,
                  style: TextStyle(
                    color: const Color(0xFF3A7DC5),
                    fontFamily: fontFamily,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  String _titleForState(S l10n) {
    switch (_pageState) {
      case _PaymentPageState.completed:
        return l10n.orderSentSuccessfullyTitle;
      case _PaymentPageState.processing:
        return 'Payment received';
      case _PaymentPageState.error:
        return 'Payment issue';
      case _PaymentPageState.loading:
        return 'Confirming payment...';
    }
  }

  String _subtitleForState(S l10n) {
    switch (_pageState) {
      case _PaymentPageState.completed:
        return l10n.orderSentSuccessfullySubtitle;
      case _PaymentPageState.processing:
        return 'Your payment was received. Creating your order now...';
      case _PaymentPageState.error:
        return 'We could not confirm your payment yet.';
      case _PaymentPageState.loading:
        return 'Please wait while we verify your payment with Stripe.';
    }
  }
}

enum _PaymentPageState { loading, processing, completed, error }

MyOrderModel? _latestOrder(List<MyOrderModel> orders) {
  if (orders.isEmpty) return null;
  return orders.reduce((a, b) {
    final aDate =
        DateTime.tryParse(a.createdAt) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final bDate =
        DateTime.tryParse(b.createdAt) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.isAfter(aDate) ? b : a;
  });
}
