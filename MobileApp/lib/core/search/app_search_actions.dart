import 'package:alrasmarket/core/media/image_source_picker.dart';
import 'package:alrasmarket/core/router/app_router.dart';
import 'package:alrasmarket/core/search/search_history_entry.dart';
import 'package:alrasmarket/core/search/user_search_history_service.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Shared search navigation used by every screen in the app.
class AppSearchActions {
  AppSearchActions._();

  static void _openSearchResults(
    BuildContext context,
    Map<String, dynamic> extra,
  ) {
    final isOnSearchResults =
        GoRouterState.of(context).matchedLocation ==
        AppRoutes.kProductSearchResultsView;

    if (isOnSearchResults) {
      context.replace(AppRoutes.kProductSearchResultsView, extra: extra);
    } else {
      context.push(AppRoutes.kProductSearchResultsView, extra: extra);
    }
  }

  static void submit(BuildContext context, String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    FocusManager.instance.primaryFocus?.unfocus();
    _openSearchResults(context, {'query': trimmed});
  }

  static Future<void> searchByImage(BuildContext context) async {
    final source = await showImageSourceSheet(
      context,
      title: S.of(context).searchByImage,
    );
    if (!context.mounted || source == null) return;

    final cubit = context.read<ClintCubit>();
    final imagePath = await cubit.pickImageForSearch(source: source);
    if (!context.mounted || imagePath == null) return;

    FocusManager.instance.primaryFocus?.unfocus();
    await openImagePath(context, imagePath);
  }

  static void openHistoryEntry(BuildContext context, SearchHistoryEntry entry) {
    FocusManager.instance.primaryFocus?.unfocus();

    if (entry.type == SearchHistoryType.image && entry.canReplayWithoutApi) {
      _openSearchResults(context, {
        'historyId': entry.id,
        'replayCached': true,
      });
      return;
    }

    if (entry.query != null && entry.query!.trim().isNotEmpty) {
      _openSearchResults(context, {'query': entry.query!.trim()});
      return;
    }

    if (entry.imagePath != null && entry.imagePath!.isNotEmpty) {
      _openSearchResults(context, {
        'imagePath': entry.imagePath,
        'replayCached': entry.canReplayWithoutApi,
        if (entry.canReplayWithoutApi) 'historyId': entry.id,
      });
      return;
    }
  }

  static Future<void> openImagePath(
    BuildContext context,
    String imagePath,
  ) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final cached = await UserSearchHistoryService.instance.getEntryByImagePath(
      imagePath,
    );
    if (!context.mounted) return;

    if (cached != null && cached.canReplayWithoutApi) {
      _openSearchResults(context, {
        'historyId': cached.id,
        'replayCached': true,
      });
      return;
    }

    _openSearchResults(context, {'imagePath': imagePath});
  }
}
