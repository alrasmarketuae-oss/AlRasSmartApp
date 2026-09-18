import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/widgets.dart';

/// High-level agent activity for live status UI (never raw tools / CoT).
enum AiAgentActivityKind {
  processing,
  searching,
  checkingPrice,
  checkingAvailability,
  processingOrder,
  preparingResponse,
  uploadingMedia,
  stillWorking,
  completed,
  error,
}

/// Maps backend thinking / tool text into a single user-facing activity kind.
class AiAgentActivityMapper {
  AiAgentActivityMapper._();

  static final RegExp _jsonLike = RegExp(r'[\{\}\[\]]|"ok"\s*:|function_call|tool_calls');
  static final RegExp _toolNameLike = RegExp(
    r'^(Running|بنفّذ|بنفذ)\s+\w+|^(get_|find_|search_|create_|update_|list_|delete_|mark_|set_|lookup_|explain_|add_|remove_)',
    caseSensitive: false,
  );

  /// Returns null when [raw] should be ignored (CoT / JSON / technical noise).
  static AiAgentActivityKind? classify(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) return null;
    if (_looksTechnical(text)) return AiAgentActivityKind.processing;

    final lower = text.toLowerCase();

    if (_containsAny(lower, const [
      'upload',
      'رفع',
      'وسائط',
      'media',
    ])) {
      return AiAgentActivityKind.uploadingMedia;
    }

    if (_containsAny(lower, const [
      'search',
      'listing',
      'listings',
      'بدوّر',
      'بدور',
      'إعلان',
      'اعلان',
      'منتج',
      'products',
      'catalog',
    ])) {
      return AiAgentActivityKind.searching;
    }

    if (_containsAny(lower, const [
      'price',
      'cheapest',
      'expensive',
      'سعر',
      'اسعار',
      'أسعار',
      'أرخص',
      'ارخص',
      'أغلى',
      'اغلى',
    ])) {
      return AiAgentActivityKind.checkingPrice;
    }

    if (_containsAny(lower, const [
      'availab',
      'stock',
      'quantity',
      'sold out',
      'كمية',
      'الكميه',
      'الكمية',
      'متاح',
      'توفر',
      'نافد',
    ])) {
      return AiAgentActivityKind.checkingAvailability;
    }

    if (_containsAny(lower, const [
      'order',
      'cart',
      'purchase',
      'طلب',
      'طلبات',
      'سلّة',
      'سله',
      'شراء',
      'مشتريات',
    ])) {
      return AiAgentActivityKind.processingOrder;
    }

    if (_containsAny(lower, const [
      'prepar',
      'gather',
      'checking',
      'hand off',
      'handoff',
      'براجع',
      'بجهّز',
      'بجهز',
      'بلمّ',
      'بلم',
      'تمام',
      'got it',
    ])) {
      return AiAgentActivityKind.preparingResponse;
    }

    if (_containsAny(lower, const [
      '✓',
      'done',
      'found what',
      'لقينا',
      'تمام',
      'completed',
    ])) {
      return AiAgentActivityKind.completed;
    }

    if (_containsAny(lower, const [
      'error',
      'فشل',
      'failed',
      'unavailable',
    ])) {
      return AiAgentActivityKind.error;
    }

    return AiAgentActivityKind.processing;
  }

  static String labelFor(
    BuildContext context,
    AiAgentActivityKind kind,
  ) {
    final s = S.of(context);
    switch (kind) {
      case AiAgentActivityKind.searching:
        return s.aiAgentActivitySearching;
      case AiAgentActivityKind.checkingPrice:
        return s.aiAgentActivityCheckingPrice;
      case AiAgentActivityKind.checkingAvailability:
        return s.aiAgentActivityCheckingAvailability;
      case AiAgentActivityKind.processingOrder:
        return s.aiAgentActivityProcessingOrder;
      case AiAgentActivityKind.preparingResponse:
        return s.aiAgentActivityPreparing;
      case AiAgentActivityKind.uploadingMedia:
        return s.aiAgentActivityUploadingMedia;
      case AiAgentActivityKind.stillWorking:
        return s.aiAgentActivityStillWorking;
      case AiAgentActivityKind.completed:
        return s.aiAgentActivityCompleted;
      case AiAgentActivityKind.error:
        return s.aiAgentActivityError;
      case AiAgentActivityKind.processing:
        return s.aiAgentActivityWorking;
    }
  }

  /// Friendly history line for a stored step (sanitized).
  static String friendlyStep(BuildContext context, String raw) {
    final kind = classify(raw) ?? AiAgentActivityKind.processing;
    return labelFor(context, kind);
  }

  /// Deduped friendly history for expand/collapse panel.
  static List<String> friendlyHistory(
    BuildContext context,
    Iterable<String> rawSteps,
  ) {
    final out = <String>[];
    for (final raw in rawSteps) {
      final label = friendlyStep(context, raw);
      if (out.isEmpty || out.last != label) {
        out.add(label);
      }
    }
    return out;
  }

  static bool _looksTechnical(String text) {
    if (_jsonLike.hasMatch(text)) return true;
    if (_toolNameLike.hasMatch(text)) return true;
    if (text.contains('http://') || text.contains('https://')) return true;
    if (text.contains('Exception') || text.contains('StackTrace')) return true;
    if (RegExp(r'Tool\s+\w+', caseSensitive: false).hasMatch(text)) return true;
    if (text.contains('الأداة ')) return true;
    return false;
  }

  static bool _containsAny(String haystack, List<String> needles) {
    for (final n in needles) {
      if (haystack.contains(n.toLowerCase())) return true;
    }
    return false;
  }
}
