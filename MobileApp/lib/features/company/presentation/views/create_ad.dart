import 'dart:async';

import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/services/publish_success_sound.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/core/ui/widgets/feedback/app_toast.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_cubit.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_states.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_design.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_form_widget.dart';
import 'package:alrasmarket/features/company/presentation/widgets/create_ad/create_ad_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class CreateAdView extends StatelessWidget {
  const CreateAdView({super.key, this.cubit});

  final CreateAdCubit? cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: const _CreateAdPage(),
      );
    }

    return BlocProvider(
      create: (_) => sl<CreateAdCubit>(),
      child: const _CreateAdPage(),
    );
  }
}

class _CreateAdPage extends StatelessWidget {
  const _CreateAdPage();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreateAdCubit, CreateAdFormState>(
      listenWhen: (previous, current) =>
          previous.submitErrorMessage != current.submitErrorMessage ||
          previous.submitSuccessMessage != current.submitSuccessMessage,
      listener: (context, state) {
        final cubit = context.read<CreateAdCubit>();
        if (state.submitSuccessMessage != null) {
          // Backend create/update flow finished successfully.
          unawaited(PublishSuccessSound.instance.playOnce());
          AppToast.showSuccess(context, state.submitSuccessMessage!);
          final navigateProductId = state.submitNavigateProductId;
          final wasEdit = state.isEditMode;
          cubit.clearSubmitFeedback();
          if (wasEdit) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            return;
          }
          if (navigateProductId != null && navigateProductId.isNotEmpty) {
            context.go(
              AppRoutes.kMyAdsView,
              extra: {'highlightProductId': navigateProductId},
            );
          }
        } else if (state.submitErrorMessage != null) {
          AppToast.showError(context, state.submitErrorMessage!);
          cubit.clearSubmitFeedback();
        }
      },
      builder: (context, state) {
        return PopScope(
          canPop: !state.isSubmitting,
          child: SafeArea(
            child: Scaffold(
              backgroundColor: CreateAdDesign.pageBg,
              body: Column(
                children: [
                  const CreateAdHeaderWidget(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                      child: const CreateAdFormWidget(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
