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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ClintCubit>().initProduct(
        widget.product,
        toUserId: widget.toUserId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const _SubmitOfferPage();
  }
}

class _SubmitOfferPage extends StatelessWidget {
  const _SubmitOfferPage();

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
                  child: const SubmitOfferFormWidget(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
