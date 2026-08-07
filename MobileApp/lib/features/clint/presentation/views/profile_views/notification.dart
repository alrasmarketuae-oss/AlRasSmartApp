import 'package:alrasmarket/core/utils/assets.dart';
import 'package:alrasmarket/core/serveses/notifications_service.dart';
import 'package:alrasmarket/core/utils/relative_time_formatter.dart';
import 'package:alrasmarket/features/clint/data/models/app_notification_model.dart';
import 'package:alrasmarket/features/clint/presentation/helpers/notification_navigation_helper.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/notification_card.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/notification_section_header.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/notifications_list_skeleton.dart';
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
  static const _pageSize = 20;
  /// Load the next page when the user is within this distance of the bottom.
  static const _loadMoreThreshold = 320.0;

  final ScrollController _scrollController = ScrollController();
  List<AppNotificationModel> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;
  bool _markedAllRead = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final cached = NotificationsService.instance.peekSessionPage1();
    if (cached != null) {
      _items = List<AppNotificationModel>.from(cached.items);
      _page = 1;
      _hasMore = _items.length < cached.totalCount;
      _loading = false;
      _markedAllRead = true;
      _error = null;
    } else {
      _loadNotifications(reset: true);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || !_hasMore || _loadingMore || _loading) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      _loadMore();
    }
  }

  Future<void> _loadNotifications({
    required bool reset,
    bool forceRefresh = false,
  }) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
        _hasMore = true;
        _markedAllRead = false;
      });
    }

    try {
      final page = await NotificationsService.instance.fetchMine(
        page: 1,
        pageSize: _pageSize,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;

      var items = page.items;
      if (!_markedAllRead &&
          (page.unreadCount > 0 || items.any((item) => !item.isRead))) {
        try {
          await NotificationsService.instance.markAllRead();
          _markedAllRead = true;
          items = items.map(_asRead).toList();
          NotificationsService.instance.updateSessionItems(items);
        } catch (_) {
          // Keep fetched list even if mark-all fails.
        }
      } else if (_markedAllRead) {
        items = items.map(_asRead).toList();
        NotificationsService.instance.updateSessionItems(items);
      }

      if (!mounted) return;
      setState(() {
        _items = items;
        _page = 1;
        _hasMore = items.length < page.totalCount;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (reset) {
          _items = [];
        }
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;

    setState(() => _loadingMore = true);
    final nextPage = _page + 1;

    try {
      final page = await NotificationsService.instance.fetchMine(
        page: nextPage,
        pageSize: _pageSize,
        forceRefresh: true,
      );
      if (!mounted) return;

      final incoming = _markedAllRead
          ? page.items.map(_asRead).toList()
          : page.items;
      final existingIds = _items.map((e) => e.id).toSet();
      final appended = incoming
          .where((item) => !existingIds.contains(item.id))
          .toList();

      setState(() {
        _items = [..._items, ...appended];
        _page = nextPage;
        _hasMore = _items.length < page.totalCount && appended.isNotEmpty;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  AppNotificationModel _asRead(AppNotificationModel current) =>
      AppNotificationModel(
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
    if (!mounted) return;
    await NotificationNavigationHelper.open(context, item);
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
              onRefresh: () =>
                  _loadNotifications(reset: true, forceRefresh: true),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const NotificationsListSkeleton();
    }

    if (_error != null && _items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(24.w),
        children: [
          Text(_error!, textAlign: TextAlign.center),
          SizedBox(height: 16.h),
          Center(
            child: TextButton(
              onPressed: () =>
                  _loadNotifications(reset: true, forceRefresh: true),
              child: Text(S.of(context).retry),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      itemCount: _items.isEmpty
          ? 1
          : _items.length + 2, // header + optional loader
      itemBuilder: (context, index) {
        if (_items.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 48.h),
            child: Text(
              'No notifications yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.grey,
              ),
            ),
          );
        }

        if (index == 0) {
          return NotificationSectionHeader(
            title: S.of(context).notifications,
          );
        }

        final itemIndex = index - 1;
        if (itemIndex < _items.length) {
          final item = _items[itemIndex];
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: NotificationsCard(
              title: item.title,
              subtitle: item.body,
              time: item.createdAt == null
                  ? ''
                  : RelativeTimeFormatter.formatFromUtc(
                      S.of(context),
                      item.createdAt!.toUtc(),
                    ),
              icon: _iconFor(item),
              showUnreadDot: !item.isRead,
              onTap: () => _onTap(item),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Center(
            child: _loadingMore
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const SizedBox(height: 8),
          ),
        );
      },
    );
  }
}
