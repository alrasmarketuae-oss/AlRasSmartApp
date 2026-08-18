import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/features/admin/presentation/widgets/admin_home_shell.dart';
import 'package:flutter/material.dart';

/// Wraps profile/company pages with the admin bottom bar when the user is admin.
class AdminAccountPage {
  static Widget wrap(
    Widget child, {
    int tabIndex = 1,
  }) {
    if (!AuthService.instance.isAdminAccount) return child;
    return AdminHomeShell(tabIndex: tabIndex, body: child);
  }
}
