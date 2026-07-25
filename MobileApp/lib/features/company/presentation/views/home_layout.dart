import 'package:alrasmarket/core/serveses/notifications_service.dart';
import 'package:alrasmarket/core/widgets/scroll_aware_bottom_nav_scaffold.dart';
import 'package:alrasmarket/features/clint/presentation/views/home_view.dart';

import 'package:alrasmarket/features/clint/presentation/views/my_orders_view.dart';
import 'package:alrasmarket/features/clint/presentation/views/profile_view.dart';
import 'package:alrasmarket/features/company/presentation/views/create_ad.dart';
import 'package:alrasmarket/features/company/presentation/views/my_ads_view.dart';
import 'package:alrasmarket/features/company/presentation/widgets/company_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../controller/cubit/company_cubit.dart';
import '../controller/cubit/company_states.dart';

class CompanyHomeLayout extends StatefulWidget {
  const CompanyHomeLayout({super.key});

  @override
  State<CompanyHomeLayout> createState() => _CompanyHomeLayoutState();
}

class _CompanyHomeLayoutState extends State<CompanyHomeLayout> {
  @override
  void initState() {
    super.initState();
    NotificationsService.instance.refreshUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompanyCubit, CompanyStates>(
      buildWhen: (prev, curr) {
        if (curr is! CompanyTabState) return false;
        if (prev is! CompanyTabState) return true;
        return prev.index != curr.index;
      },
      builder: (context, state) {
        final cubit = CompanyCubit.get(context);
        const showMyAds = true;
        final screens = [
          HomeView(key: ValueKey('company_supplier_home'), isCompany: true),
          CreateAdView(),
          MyOrdersView(),
          const MyAdsView(isTabView: true),
          ProfileView(),
        ];
        final currentIndex = cubit.currentIndex >= screens.length
            ? screens.length - 1
            : cubit.currentIndex;
        return SafeArea(
          child: ScrollAwareBottomNavScaffold(
            tabIndex: currentIndex,
            body: IndexedStack(index: currentIndex, children: screens),
            bottomNavigationBar: ListenableBuilder(
              listenable: NotificationsService.instance,
              builder: (context, _) {
                return CompanyBottomNavBar(
                  currentIndex: currentIndex,
                  onTap: (index) =>
                      context.read<CompanyCubit>().setTab(index),
                  context: context,
                  showMyAds: showMyAds,
                  unreadBadgeCount:
                      NotificationsService.instance.unreadCount,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
