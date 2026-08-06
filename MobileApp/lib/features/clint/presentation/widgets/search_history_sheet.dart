import 'dart:io';

import 'package:alrasmarket/core/search/app_search_actions.dart';
import 'package:alrasmarket/core/search/search_history_entry.dart';
import 'package:alrasmarket/core/search/user_search_history_service.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:alrasmarket/core/utils/relative_time_formatter.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<void> showSearchHistorySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
    ),
    builder: (context) => const _SearchHistorySheet(),
  );
}

class _SearchHistorySheet extends StatefulWidget {
  const _SearchHistorySheet();

  @override
  State<_SearchHistorySheet> createState() => _SearchHistorySheetState();
}

class _SearchHistorySheetState extends State<_SearchHistorySheet> {
  List<SearchHistoryEntry> _entries = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await UserSearchHistoryService.instance.loadEntries();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _remove(String id) async {
    await UserSearchHistoryService.instance.removeEntry(id);
    await _load();
  }

  Future<void> _clearAll() async {
    await UserSearchHistoryService.instance.clearAll();
    await _load();
  }

  String _timeAgo(BuildContext context, int createdAtMs) {
    return RelativeTimeFormatter.formatFromLocalMs(
      S.of(context),
      createdAtMs,
    );
  }

  IconData _iconFor(SearchHistoryType type) {
    switch (type) {
      case SearchHistoryType.image:
        return Icons.image_search_rounded;
      case SearchHistoryType.code:
        return Icons.tag_rounded;
      case SearchHistoryType.text:
        return Icons.search_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return SafeArea(
      child: SizedBox(
        height: maxHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 12.w, 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.searchHistory,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ),
                  if (_entries.isNotEmpty)
                    TextButton(
                      onPressed: _clearAll,
                      child: Text(s.clearAll),
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _entries.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.w),
                            child: Text(
                              s.searchHistoryEmpty,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: LightColor.greyTextColor,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                          itemCount: _entries.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: LightColor.greyTextColor.withValues(alpha: 0.15),
                          ),
                          itemBuilder: (context, index) {
                            final entry = _entries[index];
                            final imagePath = entry.imagePath;
                            final hasThumb = imagePath != null &&
                                imagePath.isNotEmpty &&
                                File(imagePath).existsSync();

                            return ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 4.w,
                                vertical: 4.h,
                              ),
                              leading: hasThumb
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8.r),
                                      child: Image.file(
                                        File(imagePath),
                                        width: 44.w,
                                        height: 44.w,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : CircleAvatar(
                                      radius: 22.r,
                                      backgroundColor: const Color(0xFFE8F1FB),
                                      child: Icon(
                                        _iconFor(entry.type),
                                        color: LightColor.defaultColor,
                                        size: 22.sp,
                                      ),
                                    ),
                              title: Text(
                                entry.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                entry.type == SearchHistoryType.image &&
                                        entry.suggestedNames.isNotEmpty
                                    ? entry.suggestedNames.take(3).join(', ')
                                    : _timeAgo(context, entry.createdAtMs),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: LightColor.greyTextColor,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.close,
                                  size: 18.sp,
                                  color: LightColor.greyTextColor,
                                ),
                                onPressed: () => _remove(entry.id),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                AppSearchActions.openHistoryEntry(context, entry);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
