import 'package:alrasmarket/core/widgets/primary_button.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SubmitOfferButtonWidget extends StatelessWidget {
  const SubmitOfferButtonWidget({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClintCubit, ClintStates>(
      buildWhen: (previous, current) {
        final prev = previous is SubmitOfferFormState ? previous.isSubmitting : false;
        final curr = current is SubmitOfferFormState ? current.isSubmitting : false;
        return prev != curr;
      },
      builder: (context, state) {
        final isSubmitting =
            state is SubmitOfferFormState && state.isSubmitting;
        return PrimaryButton(
          text: 'Submit Offer',
          isLoading: isSubmitting,
          backgroundColor: const Color(0xFF3A7DC5),
          onPressed: isSubmitting
              ? null
              : (onPressed ?? () => context.read<ClintCubit>().submitOfferForm()),
        );
      },
    );
  }
}