import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/widgets/scroll_aware_bottom_nav_scaffold.dart';
import 'package:alrasmarket/features/admin/presentation/widgets/admin_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Admin shell with bottom navigation for pushed account/company pages.
class AdminHomeShell extends StatelessWidget {
  const AdminHomeShell({
    super.key,
    required this.body,
    required this.tabIndex,
  });

  final Widget body;
  final int tabIndex;

  static void navigateToTab(BuildContext context, int index) {
    context.go('${AppRoutes.kAdminHomeView}?tab=${index.clamp(0, 1)}');
  }

  @override
  Widget build(BuildContext context) {
    return ScrollAwareBottomNavScaffold(
      tabIndex: tabIndex,
      backgroundColor: AppColors.scaffold(context),
      body: body,
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: tabIndex,
        onTap: (index) => navigateToTab(context, index),
      ),
    );
  }
}
