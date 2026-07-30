import 'package:alrasmarket/core/widgets/scroll_aware_bottom_nav_scaffold.dart';
import 'package:alrasmarket/features/shipping_company/presentation/controller/cubit/shipping_company_cubit.dart';
import 'package:alrasmarket/features/shipping_company/presentation/controller/cubit/shipping_company_states.dart';
import 'package:alrasmarket/features/shipping_company/presentation/views/shipping_home_view.dart';
import 'package:alrasmarket/features/shipping_company/presentation/views/shipping_profile_view.dart';
import 'package:alrasmarket/features/shipping_company/presentation/widgets/shipping_bottom_nav_bar.dart';
import 'package:alrasmarket/features/shipping_company/presentation/widgets/shipping_company_widgets.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShippingHomeLayout extends StatelessWidget {
  const ShippingHomeLayout({super.key});

  static const _screens = [
    ShippingHomeView(),
    ShippingProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShippingCompanyCubit, ShippingCompanyStates>(
      buildWhen: (prev, curr) {
        if (curr is ShippingCompanyTabState) return true;
        if (curr is ShippingCompanyLoadedState &&
            prev is ShippingCompanyLoadedState) {
          return prev.tabIndex != curr.tabIndex;
        }
        if (curr is ShippingCompanyLoadedState) return true;
        return false;
      },
      builder: (context, state) {
        final cubit = ShippingCompanyCubit.get(context);
        final companyName = cubit.dashboard?.companyName ?? S.of(context).shippingCompany;
        return ScrollAwareBottomNavScaffold(
          tabIndex: cubit.currentIndex,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ShippingMainHeader(companyName: companyName),
              Expanded(
                child: IndexedStack(
                  index: cubit.currentIndex,
                  children: _screens,
                ),
              ),
            ],
          ),
          bottomNavigationBar: ShippingBottomNavBar(
            currentIndex: cubit.currentIndex,
            onTap: (index) =>
                context.read<ShippingCompanyCubit>().setTab(index),
            context: context,
          ),
        );
      },
    );
  }
}
