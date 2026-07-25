import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_cubit.dart';
import 'package:alrasmarket/features/auth/presentation/controller/cubit/auth_states.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/privacy.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthStates>(
      buildWhen: (_, current) => current is ChangeLocaleState,
      builder: (context, state) {
        final authCubit = AuthCubit.get(context);
        final selectedCode = authCubit.locale.languageCode;

        return Scaffold(
          body: Column(
            children: [
              SearchHeader(title: S.of(context).PolicyandPrivacy),
              SizedBox(height: 12.h),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [TermsAndConditionsWidget()],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
