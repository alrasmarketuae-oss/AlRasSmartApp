import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_states.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/requst_widets/submit_offer_form.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../controller/cubit/clint_cubit.dart';
import '../../../widgets/search_header.dart';

class SubmitOfferView extends StatefulWidget {
  const SubmitOfferView({
    super.key,
    required this.product,
    this.toUserId = '',
  });

  final MyListingProductModel product;
  final String toUserId;

  @override
  State<SubmitOfferView> createState() => _SubmitOfferViewState();
}

class _SubmitOfferViewState extends State<SubmitOfferView> {
  ClintCubit? _cubit;

  void _bindProduct({bool emitState = true}) {
    final cubit = _cubit ??= context.read<ClintCubit>();
    if (emitState) {
      cubit.initProduct(widget.product, toUserId: widget.toUserId);
    } else {
      cubit.prepareSubmitOfferProduct(
        widget.product,
        toUserId: widget.toUserId,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Clear shared controllers + bind product before first paint (no emit),
    // then emit after the frame so app-wide BlocBuilders are not notified mid-build.
    _cubit = context.read<ClintCubit>();
    _cubit!.prepareSubmitOfferProduct(
      widget.product,
      toUserId: widget.toUserId,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bindProduct();
    });
  }

  @override
  void didUpdateWidget(covariant SubmitOfferView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.productId == widget.product.productId &&
        oldWidget.toUserId == widget.toUserId) {
      return;
    }
    _bindProduct();
  }

  @override
  void dispose() {
    _cubit?.resetSubmitOfferForm(onlyForProductId: widget.product.productId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SubmitOfferPage(product: widget.product);
  }
}

class _SubmitOfferPage extends StatelessWidget {
  const _SubmitOfferPage({required this.product});

  final MyListingProductModel product;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClintCubit, ClintStates>(
      listenWhen: (_, current) =>
          current is SubmitOfferSuccessState ||
          current is SubmitOfferErrorState,
      listener: (context, state) {
        if (state is SubmitOfferSuccessState) {
          context.pushReplacement(AppRoutes.kSubmitOfferSuccessView);
        } else if (state is SubmitOfferErrorState) {
          AppToast.showError(context, state.error);
        }
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.scaffold(context),
          body: Column(
            children: [
              SearchHeader(title: S.of(context).submitOffer, isSearch: false),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                  child: SubmitOfferFormWidget(
                    key: ValueKey('submit-offer-form-${product.productId}'),
                    product: product,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
