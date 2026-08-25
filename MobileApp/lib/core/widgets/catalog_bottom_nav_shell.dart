import 'dart:async';

import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/serveses/cached_constants.dart';
import 'package:alrasmarket/core/serveses/notifications_service.dart';
import 'package:alrasmarket/core/services_locator/services_locator.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/widgets/login_required_sheet.dart';
import 'package:alrasmarket/core/widgets/scroll_aware_bottom_nav_scaffold.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_states.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/user_bottom_nav_bar.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/company_cubit.dart';
import 'package:alrasmarket/features/company/presentation/widgets/company_bottom_nav_bar.dart';
import 'package:alrasmarket/features/person/presentation/controller/cubit/person_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Bottom nav shell for pushed catalog pages (e.g. search results) so the
/// main tab bar stays visible outside the home layouts.
class CatalogBottomNavShell extends StatelessWidget {
  const CatalogBottomNavShell({
    super.key,
    required this.body,
    this.tabIndex = 0,
  });

  final Widget body;
  final int tabIndex;

  static Widget wrap(Widget child, {int tabIndex = 0}) {
    final auth = AuthService.instance;
    if (auth.isAdminAccount || isShippingCompanyAccount == true) {
      return child;
    }
    return CatalogBottomNavShell(tabIndex: tabIndex, body: child);
  }

  void _onTap(BuildContext context, int index) {
    if (index != 0 && !ensureLoggedIn(context)) return;

    final auth = AuthService.instance;
    if (auth.isPersonalCustomerAccount) {
      final person = sl<PersonCubit>();
      if (!person.isClosed) person.setTab(index);
      if (index == 1) {
        unawaited(sl<ClintCubit>().loadCart());
      }
      context.go(AppRoutes.kPersonHomeView);
      return;
    }

    // Guests browse company home; suppliers use the same shell.
    if (auth.isSupplierAccount || !auth.isAuthenticated) {
      final company = sl<CompanyCubit>();
      if (!company.isClosed) company.setTab(index);
      context.go(AppRoutes.kCompanyHomeView);
      return;
    }

    final clint = sl<ClintCubit>();
    if (!clint.isClosed) clint.setTab(index);
    context.go(AppRoutes.kClientHomeView);
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final isPerson = auth.isPersonalCustomerAccount;
    final useCompanyNav = auth.isSupplierAccount || !auth.isAuthenticated;

    return ScrollAwareBottomNavScaffold(
      tabIndex: tabIndex,
      backgroundColor: AppColors.scaffold(context),
      body: body,
      bottomNavigationBar: ListenableBuilder(
        listenable: NotificationsService.instance,
        builder: (context, _) {
          return BlocSelector<ClintCubit, ClintStates, int>(
            selector: (_) =>
                context.read<ClintCubit>().pendingIncomingApprovalCount,
            builder: (context, pendingOrdersBadgeCount) {
              if (useCompanyNav) {
                return CompanyBottomNavBar(
                  currentIndex: tabIndex,
                  onTap: (index) => _onTap(context, index),
                  context: context,
                  unreadBadgeCount: NotificationsService.instance.unreadCount,
                  pendingOrdersBadgeCount: pendingOrdersBadgeCount,
                );
              }

              return UserBottomNavBar(
                currentIndex: tabIndex,
                onTap: (index) => _onTap(context, index),
                context: context,
                isPerson: isPerson,
                showMyAds: !isPerson,
                unreadBadgeCount: NotificationsService.instance.unreadCount,
                pendingOrdersBadgeCount: pendingOrdersBadgeCount,
              );
            },
          );
        },
      ),
    );
  }
}
