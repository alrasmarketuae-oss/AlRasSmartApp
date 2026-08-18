import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/widgets/scroll_aware_bottom_nav_scaffold.dart';
import 'package:alrasmarket/features/admin/presentation/views/admin_companies_view.dart';
import 'package:alrasmarket/features/admin/presentation/widgets/admin_bottom_nav_bar.dart';
import 'package:alrasmarket/features/clint/presentation/views/profile_view.dart';
import 'package:flutter/material.dart';

class AdminHomeLayout extends StatefulWidget {
  const AdminHomeLayout({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<AdminHomeLayout> createState() => _AdminHomeLayoutState();
}

class _AdminHomeLayoutState extends State<AdminHomeLayout> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialTab.clamp(0, 1);
  }

  @override
  void didUpdateWidget(covariant AdminHomeLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _index = widget.initialTab.clamp(0, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const AdminCompaniesView(),
      const ProfileView(isTabView: true),
    ];

    return ScrollAwareBottomNavScaffold(
      tabIndex: _index,
      backgroundColor: AppColors.scaffold(context),
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
      ),
    );
  }
}
