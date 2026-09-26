import 'dart:async';

import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/serveses/chat_unread_service.dart';
import 'package:alrasmarket/core/widgets/login_required_sheet.dart';
import 'package:alrasmarket/core/widgets/scroll_aware_bottom_nav_scaffold.dart';
import 'package:alrasmarket/core/theme/colors.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<ClintCubit>();
      unawaited(cubit.ensureOrdersRealtimeListener());
      if (!AuthService.instance.isPersonalCustomerAccount) {
        unawaited(cubit.fetchIncomingOrders());
      }
      if (AuthService.instance.isAuthenticated) {
        unawaited(ChatUnreadService.instance.refreshUnreadCount());
      }
    });
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
        final sessionKey = AuthService.instance.currentUserID ?? 'guest';
        final screens = [
          HomeView(key: ValueKey('client_home_$sessionKey')),
          AddOrderView(key: ValueKey('client_add_$sessionKey')),
          MyOrdersView(key: ValueKey('client_orders_$sessionKey')),
          MyAdsView(
            key: ValueKey('client_ads_$sessionKey'),
            isTabView: true,
          ),
          ProfileView(
            key: ValueKey('client_profile_$sessionKey'),
            isTabView: true,
          ),
        ];
        // Keeps the status bar the same colour as the tab shown behind it.
        final tabBackgrounds = [
          AppColors.scaffold(context),
          AppColors.scaffold(context),
          AppColors.scaffold(context),
          AppColors.scaffold(context),
          AppColors.scaffold(context),
        ];
        final currentIndex = cubit.currentIndex >= screens.length
            ? screens.length - 1
            : cubit.currentIndex;
        return ScrollAwareBottomNavScaffold(
          tabIndex: currentIndex,
          backgroundColor: tabBackgrounds[currentIndex],
          body: IndexedStack(index: currentIndex, children: screens),
          bottomNavigationBar: ListenableBuilder(
            listenable: ChatUnreadService.instance,
            builder: (context, _) {
              return BlocSelector<ClintCubit, ClintStates, int>(
                selector: (state) =>
                    context.read<ClintCubit>().pendingIncomingApprovalCount,
                builder: (context, pendingOrdersBadgeCount) {
                  return UserBottomNavBar(
                    currentIndex: currentIndex,
                    onTap: (index) {
                      // Home + Profile stay open for guests (AI lives on Profile).
                      const profileTabIndex = 4;
                      if (index != 0 &&
                          index != profileTabIndex &&
                          !ensureLoggedIn(context)) {
                        return;
                      }
                      context.read<ClintCubit>().setTab(index);
                    },
                    context: context,
                    showMyAds: showMyAds,
                    unreadBadgeCount: ChatUnreadService.instance.unreadCount,
                    pendingOrdersBadgeCount: pendingOrdersBadgeCount,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
