import 'package:alrasmarket/core/serveses/notifications_service.dart';
import 'package:alrasmarket/core/widgets/scroll_aware_bottom_nav_scaffold.dart';
import 'package:alrasmarket/features/clint/presentation/views/home_view.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/user_bottom_nav_bar.dart';
import 'package:alrasmarket/features/company/presentation/views/my_ads_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../controller/cubit/clint_cubit.dart';
import '../controller/cubit/clint_states.dart';
import 'add_order_view.dart';
import 'my_orders_view.dart';
import 'profile_view.dart';

class HomeLayout extends StatefulWidget {
  const HomeLayout({super.key});

  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> {
  @override
  void initState() {
    super.initState();
    NotificationsService.instance.refreshUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClintCubit, ClintStates>(
      buildWhen: (prev, curr) {
        if (curr is! ClintTabState) return false;
        if (prev is! ClintTabState) return true;
        return prev.index != curr.index;
      },
      builder: (context, state) {
        final cubit = ClintCubit.get(context);
        const showMyAds = true;
        final screens = [
          HomeView(key: ValueKey('client_home')),
          AddOrderView(),
          MyOrdersView(),
          const MyAdsView(isTabView: true),
          ProfileView(),
        ];
        // Keeps the status bar the same colour as the tab shown behind it.
        const tabBackgrounds = [
          Colors.white,
          Color(0xffF2F7FF),
          Color(0xFFF4F7FA),
          Colors.white,
          Color(0xffF2F7FF),
        ];
        final currentIndex = cubit.currentIndex >= screens.length
            ? screens.length - 1
            : cubit.currentIndex;
        return ScrollAwareBottomNavScaffold(
          tabIndex: currentIndex,
          backgroundColor: tabBackgrounds[currentIndex],
          body: IndexedStack(index: currentIndex, children: screens),
          bottomNavigationBar: ListenableBuilder(
            listenable: NotificationsService.instance,
            builder: (context, _) {
              return UserBottomNavBar(
                currentIndex: currentIndex,
                onTap: (index) => context.read<ClintCubit>().setTab(index),
                context: context,
                showMyAds: showMyAds,
                unreadBadgeCount:
                    NotificationsService.instance.unreadCount,
              );
            },
          ),
        );
      },
    );
  }
}
