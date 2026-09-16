import 'package:alrasmarket/features/clint/presentation/widgets/track_order_widgets/track_order_status_helper.dart';
import 'package:alrasmarket/generated/l10n.dart';

/// Remaps third-person seller/advertiser decision labels to first-person
/// ownership wording when the current user is the decision maker
/// (Sales / Incoming tabs on My Orders).
class DecisionMakerOrderStatusLabels {
  DecisionMakerOrderStatusLabels._();

  static String remap({
    required String apiLabel,
    required int statusId,
    required S s,
  }) {
    final label = apiLabel.trim();
    if (label.isEmpty || label == '—') return label;
    final lower = label.toLowerCase();

    if (statusId == OrderStatusCodes.awaitingSellerApproval ||
        lower.contains('awaiting seller approval') ||
        label.contains('بانتظار موافقة البائع') ||
        lower.contains('awaiting advertiser approval') ||
        label.contains('بانتظار موافقة المعلن')) {
      return s.awaitingYourApproval;
    }

    if (lower.contains('accepted by the seller') ||
        lower.contains('accepted by seller') ||
        label.contains('تم قبول الطلب من البائع')) {
      return s.youAcceptedTheOrder;
    }

    if (lower == 'order rejected' ||
        lower.contains('order rejected') ||
        label == 'تم رفض الطلب') {
      return s.youRejectedTheOrder;
    }

    if (lower.contains('accepted by the requester') ||
        lower.contains('accepted by requester') ||
        label.contains('تم القبول من قبل الطالب') ||
        label.contains('قبول من قبل الطالب')) {
      return s.youAcceptedTheOffer;
    }

    if (lower.contains('rejected by the advertiser') ||
        lower.contains('rejected by advertiser') ||
        label.contains('تم الرفض من قبل المعلن') ||
        label.contains('رفض من قبل المعلن')) {
      return s.youRejectedTheOffer;
    }

    return label;
  }

  /// Tries the active locale label first, then the other language field.
  static String remapOffer({
    required String statusName,
    required String statusAr,
    required int statusId,
    required bool isArabic,
    required S s,
  }) {
    final primary = (isArabic ? statusAr : statusName).trim();
    final secondary = (isArabic ? statusName : statusAr).trim();
    final candidates = <String>[
      if (primary.isNotEmpty) primary,
      if (secondary.isNotEmpty && secondary != primary) secondary,
    ];
    if (candidates.isEmpty) {
      return remap(apiLabel: '', statusId: statusId, s: s);
    }

    for (final candidate in candidates) {
      final remapped = remap(
        apiLabel: candidate,
        statusId: statusId,
        s: s,
      );
      if (remapped != candidate) return remapped;
    }
    return candidates.first;
  }
}
