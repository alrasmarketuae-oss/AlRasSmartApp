import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/serveses/notifications_service.dart';
import 'package:alrasmarket/core/utils/utc_date_time.dart';
import 'package:alrasmarket/features/clint/data/models/app_notification_model.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/notification_navigation_helper.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/notification_card.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/notification_section_header.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/search_header.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  List<AppNotificationModel> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final page = await NotificationsService.instance.fetchMine();
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _iconFor(AppNotificationModel item) {
    final route = item.navigationRoute.toLowerCase();
    if (route.contains('order')) {
      return AppAssets.profile3dBoxFillIcon;
    }
    if (route.contains('offer')) {
      return AppAssets.profileBadgePercentIcon;
    }
    return AppAssets.profileMessageCircleIcon;
  }

  Future<void> _onTap(AppNotificationModel item) async {
    if (!item.isRead) {
      try {
        await NotificationsService.instance.markRead(item.id);
        if (mounted) {
          setState(() {
            final index = _items.indexWhere((e) => e.id == item.id);
            if (index >= 0) {
              final current = _items[index];
              _items[index] = AppNotificationModel(
                id: current.id,
                title: current.title,
                body: current.body,
                referenceId: current.referenceId,
                routeId: current.routeId,
                routeName: current.routeName,
                typeName: current.typeName,
                isRead: true,
                createdAt: current.createdAt,
              );
            }
          });
        }
      } catch (_) {}
    }

    if (!mounted) return;
    await NotificationNavigationHelper.open(context, item);
  }

  Future<void> _markAllRead() async {
    try {
      await NotificationsService.instance.markAllRead();
      if (!mounted) return;
      setState(() {
        _items = _items
            .map(
              (current) => AppNotificationModel(
                id: current.id,
                title: current.title,
                body: current.body,
                referenceId: current.referenceId,
                routeId: current.routeId,
                routeName: current.routeName,
                typeName: current.typeName,
                isRead: true,
                createdAt: current.createdAt,
              ),
            )
            .toList();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SearchHeader(title: S.of(context).notifications),
          SizedBox(height: 12.h),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 120.h),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(24.w),
        children: [
          Text(_error!, textAlign: TextAlign.center),
          SizedBox(height: 16.h),
          Center(
            child: TextButton(
              onPressed: _loadNotifications,
              child: Text(S.of(context).retry),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      children: [
        if (_items.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 48.h),
            child: Text(
              'No notifications yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.grey,
              ),
            ),
          )
        else ...[
          NotificationSectionHeader(
            title: S.of(context).notifications,
            showMarkAllAsRead: _items.any((e) => !e.isRead) ||
                NotificationsService.instance.unreadCount > 0,
            onMarkAllAsRead: _markAllRead,
          ),
          ..._items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: NotificationsCard(
                title: item.title,
                subtitle: item.body,
                time: item.createdAt == null
                    ? ''
                    : UtcDateTime.formatDateTimeLocal(
                        item.createdAt!.toIso8601String(),
                      ),
                icon: _iconFor(item),
                showUnreadDot: !item.isRead,
                onTap: () => _onTap(item),
              ),
            ),
          ),
          SizedBox(height: 24.h),
        ],
      ],
    );
  }
}
