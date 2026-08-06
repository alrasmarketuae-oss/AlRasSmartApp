import 'package:alrasmarket/core/utils/product_quantity_formatter.dart';
import 'package:alrasmarket/core/utils/relative_time_formatter.dart';
import 'package:alrasmarket/features/clint/data/models/my_order_model.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:intl/intl.dart';

enum TrackOrderStepState { completed, inProgress, pending }

class TrackOrderStepData {
  const TrackOrderStepData({
    required this.title,
    required this.state,
    this.date,
    this.subtitle,
  });

  final String title;
  final TrackOrderStepState state;
  final String? date;
  final String? subtitle;
}

/// Matches backend [OrderStatusCodes].
class OrderStatusCodes {
  OrderStatusCodes._();

  static const int ordered = 1;
  static const int approved = 2;
  static const int paid = 3;
  static const int shipping = 4;
  static const int delivered = 5;
  static const int cancelled = 6;
  static const int received = 7;
  static const int paidToSupplier = 8;
  static const int returnRequested = 9;
  static const int returnApproved = 10;
  static const int awaitingSellerApproval = 11;
}

class TrackOrderStatusHelper {
  TrackOrderStatusHelper._();

  static List<TrackOrderStepData> buildSteps({
    required MyOrderModel order,
    required S l10n,
    bool? isArabic,
  }) {
    if (order.statusId == OrderStatusCodes.cancelled) {
      final steps = <TrackOrderStepData>[
        TrackOrderStepData(
          title: l10n.orderCancelledStatus,
          state: TrackOrderStepState.completed,
          subtitle: l10n.orderCancelledStatus,
        ),
      ];

      if (isOnlinePayment(order)) {
        final refunded = order.isRefunded;
        steps.add(
          TrackOrderStepData(
            title: refunded ? l10n.orderRefundCompleted : l10n.orderRefundPending,
            state: refunded
                ? TrackOrderStepState.completed
                : TrackOrderStepState.inProgress,
            subtitle: refunded
                ? (_formatRelative(l10n, order.refundedAtUtc ?? '') ??
                    l10n.orderRefundCompleted)
                : l10n.orderRefundNotice,
          ),
        );
      }

      return steps;
    }

    if (order.statusId == OrderStatusCodes.returnRequested ||
        order.statusId == OrderStatusCodes.returnApproved) {
      final approved = order.statusId == OrderStatusCodes.returnApproved;
      final steps = <TrackOrderStepData>[
        TrackOrderStepData(
          title: l10n.returnOrder,
          state: approved
              ? TrackOrderStepState.completed
              : TrackOrderStepState.inProgress,
          subtitle: order.returnReason?.trim().isNotEmpty == true
              ? order.returnReason!.trim()
              : l10n.returnOrderConfirmMessage,
          date: _formatRelative(l10n, order.returnRequestedAtUtc ?? ''),
        ),
      ];
      if (approved || order.returnAdminResponse?.trim().isNotEmpty == true) {
        steps.add(
          TrackOrderStepData(
            title: l10n.orderReturnSuccess,
            state: approved
                ? TrackOrderStepState.completed
                : TrackOrderStepState.inProgress,
            subtitle: order.returnAdminResponse?.trim().isNotEmpty == true
                ? order.returnAdminResponse!.trim()
                : l10n.orderReturnSuccess,
            date: _formatRelative(l10n, order.returnRespondedAtUtc ?? ''),
          ),
        );
      }
      return steps;
    }

    // Catalog flows: awaiting admin / awaiting seller / then text statuses only.
    // Hide Paid / Shipping / Paid-to-supplier steps.
    final arabic =
        isArabic ?? Intl.getCurrentLocale().toLowerCase().startsWith('ar');
    return _buildTextStatusTimeline(order, l10n, arabic);
  }

  static List<TrackOrderStepData> _buildTextStatusTimeline(
    MyOrderModel order,
    S l10n,
    bool isArabic,
  ) {
    final createdDate = _formatRelative(l10n, order.createdAt);
    final history = order.statusHistory;

    if (history.isNotEmpty) {
      final steps = <TrackOrderStepData>[
        TrackOrderStepData(
          title: l10n.ordered,
          state: TrackOrderStepState.completed,
          date: createdDate,
        ),
      ];

      for (var i = 0; i < history.length; i++) {
        final entry = history[i];
        final isLast = i == history.length - 1;
        final isReceived = order.statusId == OrderStatusCodes.delivered ||
            order.statusId == OrderStatusCodes.received;
        steps.add(
          TrackOrderStepData(
            title: entry.label(isArabic: isArabic),
            state: isLast
                ? (isReceived
                    ? TrackOrderStepState.completed
                    : TrackOrderStepState.inProgress)
                : TrackOrderStepState.completed,
            date: _formatRelative(l10n, entry.createdAtUtc),
          ),
        );
      }
      return steps;
    }

    final currentLabel = displayStatusLabel(order, isArabic: isArabic);

    final steps = <TrackOrderStepData>[
      TrackOrderStepData(
        title: l10n.ordered,
        state: TrackOrderStepState.completed,
        date: createdDate,
      ),
    ];

    if (order.statusId == OrderStatusCodes.ordered && !order.isApproved) {
      steps.add(
        TrackOrderStepData(
          title: isArabic ? 'بانتظار موافقة التطبيق' : 'Awaiting app approval',
          state: TrackOrderStepState.inProgress,
          subtitle: currentLabel,
        ),
      );
      return steps;
    }

    if (order.statusId == OrderStatusCodes.awaitingSellerApproval) {
      steps.add(
        TrackOrderStepData(
          title: isArabic ? 'بانتظار موافقة البائع' : 'Awaiting seller approval',
          state: TrackOrderStepState.inProgress,
          subtitle: currentLabel,
        ),
      );
      return steps;
    }

    if (order.isApproved) {
      steps.add(
        TrackOrderStepData(
          title: l10n.approved,
          state: TrackOrderStepState.completed,
        ),
      );
      final isReceived = order.statusId == OrderStatusCodes.delivered ||
          order.statusId == OrderStatusCodes.received;
      steps.add(
        TrackOrderStepData(
          title: currentLabel,
          state: isReceived
              ? TrackOrderStepState.completed
              : TrackOrderStepState.inProgress,
        ),
      );
      return steps;
    }

    steps.add(
      TrackOrderStepData(
        title: currentLabel,
        state: TrackOrderStepState.inProgress,
      ),
    );
    return steps;
  }

  /// Prefer API/custom bilingual labels (no Paid-to-Merge-Spice override).
  static String displayStatusLabel(MyOrderModel order, {required bool isArabic}) {
    final fromApi = order.statusLabel(isArabic: isArabic).trim();
    if (fromApi.isNotEmpty) {
      return fromApi;
    }

    if (order.statusId == OrderStatusCodes.received) {
      return isArabic ? 'تم التسليم' : 'Delivered';
    }

    if (order.statusId == OrderStatusCodes.awaitingSellerApproval) {
      return isArabic ? 'بانتظار موافقة البائع' : 'Awaiting seller approval';
    }

    if (order.statusId == OrderStatusCodes.ordered && !order.isApproved) {
      return isArabic ? 'بانتظار موافقة التطبيق' : 'Awaiting app approval';
    }

    return isArabic ? 'غير معروف' : 'Unknown';
  }

  static String? _formatRelative(S l10n, String raw) {
    final text = RelativeTimeFormatter.format(l10n, raw);
    return text.isEmpty ? null : text;
  }

  static String destinationLabel(MyOrderModel order, {bool isArabic = false}) {
    final port = order.portName?.trim();
    if (port != null && port.isNotEmpty) return port;
    final category = order.localizedCategoryName(isArabic: isArabic).trim();
    if (category.isNotEmpty && category != '—') return category;
    return '—';
  }

  static String quantityLabel(MyOrderModel order, S l10n, {bool isArabic = false}) {
    final qtyText = _formatQuantity(order.quantity);
    final withUnit = ProductQuantityFormatter.quantityWithUnit(
      quantityText: qtyText,
      unitName: order.localizedUnitName(isArabic: isArabic),
      s: l10n,
    );
    if (withUnit.isEmpty) {
      return '${l10n.quantity}: $qtyText';
    }
    return '${l10n.quantity}: $withUnit';
  }

  static String _formatQuantity(double quantity) {
    if (quantity <= 0) return '0';
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }
    return quantity.toString();
  }

  static String orderNumberLabel(MyOrderModel order, S l10n) {
    return '${l10n.orderNumber}: #${order.id}';
  }

  static bool isRetailOrder(MyOrderModel order) {
    return order.isRetail;
  }

  static bool canCancelOrder(MyOrderModel order) {
    return order.statusId == OrderStatusCodes.ordered ||
        order.statusId == OrderStatusCodes.awaitingSellerApproval ||
        order.statusId == OrderStatusCodes.approved ||
        order.statusId == OrderStatusCodes.paid;
  }

  static bool canReturnOrder(MyOrderModel order) {
    return order.canRequestReturn;
  }

  static bool isOnlinePayment(MyOrderModel order) {
    final method = order.paymentMethodName.trim().toLowerCase();
    return method == 'online' || order.paymentMethod == 1;
  }

  static bool isRetailCashOnDelivery(MyOrderModel order) {
    return isRetailOrder(order) && !isOnlinePayment(order);
  }
}
