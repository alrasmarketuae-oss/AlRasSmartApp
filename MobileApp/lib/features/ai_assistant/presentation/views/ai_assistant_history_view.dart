import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/features/ai_assistant/data/ai_assistant_repository.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const _aiGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [LightColor.defaultColor, LightColor.lightBlue],
);

class AiAssistantHistoryView extends StatefulWidget {
  const AiAssistantHistoryView({
    super.key,
    this.activeSessionId,
  });

  final String? activeSessionId;

  @override
  State<AiAssistantHistoryView> createState() => _AiAssistantHistoryViewState();
}

class _AiAssistantHistoryViewState extends State<AiAssistantHistoryView> {
  final _repository = AiAssistantRepository();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  List<AiConversationSummary> _items = [];
  bool _loading = true;
  String? _error;
  bool _searchOpen = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = AuthService.instance.currentToken;
    if (token == null) {
      setState(() {
        _loading = false;
        _error = S.of(context).aiAssistantHistoryLoadError;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _repository.listConversations(
      token: token,
      page: 1,
      pageSize: 50,
    );
    if (!mounted) return;

    result.fold(
      (_) {
        setState(() {
          _loading = false;
          _error = S.of(context).aiAssistantHistoryLoadError;
        });
      },
      (page) {
        setState(() {
          _loading = false;
          _items = page.items;
        });
      },
    );
  }

  List<AiConversationSummary> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((item) {
      final title = (item.titlePreview ?? '').toLowerCase();
      return title.contains(q);
    }).toList();
  }

  String _titleFor(AiConversationSummary item) {
    final preview = item.titlePreview?.trim();
    if (preview != null && preview.isNotEmpty) return preview;
    return S.of(context).aiAssistantHistoryUntitled;
  }

  String _whenFor(AiConversationSummary item) {
    final raw = item.lastMessageAtUtc.trim();
    if (raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final local = parsed.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    if (sameDay) return '$hh:$mm';
    return '${local.day}/${local.month}/${local.year}  $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(8.w, topInset + 8.h, 12.w, 16.h),
            decoration: BoxDecoration(
              gradient: _aiGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
              boxShadow: [
                BoxShadow(
                  color: LightColor.defaultColor.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18.sp,
                      ),
                    ),
                    Icon(
                      Icons.forum_rounded,
                      color: Colors.white,
                      size: 22.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        s.aiAssistantHistoryTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _searchOpen = !_searchOpen;
                          if (!_searchOpen) {
                            _searchController.clear();
                            _query = '';
                          }
                        });
                        if (_searchOpen) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _searchFocus.requestFocus();
                          });
                        }
                      },
                      icon: Icon(
                        _searchOpen ? Icons.close_rounded : Icons.search_rounded,
                        color: Colors.white,
                        size: 22.sp,
                      ),
                    ),
                  ],
                ),
                if (_searchOpen) ...[
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    onChanged: (value) => setState(() => _query = value),
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: s.aiAssistantHistorySearchHint,
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13.sp,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.16),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _error != null
                    ? _EmptyState(
                        icon: Icons.wifi_off_rounded,
                        title: _error!,
                        actionLabel: s.aiAssistantHistoryRetry,
                        onAction: _load,
                      )
                    : filtered.isEmpty
                        ? _EmptyState(
                            icon: _query.isEmpty
                                ? Icons.chat_bubble_outline_rounded
                                : Icons.search_off_rounded,
                            title: _query.isEmpty
                                ? s.aiAssistantHistoryEmpty
                                : s.aiAssistantHistoryNoResults,
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => SizedBox(height: 10.h),
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                final active = widget.activeSessionId != null &&
                                    widget.activeSessionId == item.clientSessionId;
                                return _HistoryTile(
                                  title: _titleFor(item),
                                  subtitle:
                                      '${item.messageCount} ${s.aiAssistantHistoryMessages}',
                                  when: _whenFor(item),
                                  active: active,
                                  onTap: () => Navigator.of(context).pop(item),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.title,
    required this.subtitle,
    required this.when,
    required this.active,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String when;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0xFF15233A) : const Color(0xFF111827),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: active
                  ? LightColor.lightBlue.withValues(alpha: 0.7)
                  : const Color(0xFF1F2937),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  gradient: _aiGradient,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFFE5E7EB),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 13.sp,
                          color: const Color(0xFF9CA3AF),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF9CA3AF),
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (when.isNotEmpty)
                    Text(
                      when,
                      style: TextStyle(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 11.sp,
                      ),
                    ),
                  SizedBox(height: 8.h),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    color: Colors.white70,
                    size: 22.sp,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 42.sp),
            SizedBox(height: 12.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
                height: 1.4,
              ),
            ),
            if (onAction != null && actionLabel != null) ...[
              SizedBox(height: 16.h),
              TextButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
