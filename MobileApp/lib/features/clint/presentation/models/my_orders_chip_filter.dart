import 'package:alrasmarket/features/clint/data/models/my_order_model.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/track_order_widgets/track_order_status_helper.dart';
import 'package:alrasmarket/generated/l10n.dart';
import 'package:flutter/material.dart';

/// Design chips for My Orders.
enum MyOrdersChipFilter {
  all,
  awaitingApproval,
  completed,
  cancelled;

  String label(S s) {
    switch (this) {
      case MyOrdersChipFilter.all:
        return s.allOrders;
      case MyOrdersChipFilter.awaitingApproval:
        return s.awaitingApproval;
      case MyOrdersChipFilter.completed:
        return s.completedOrders;
      case MyOrdersChipFilter.cancelled:
        return s.orderCancelledStatus;
    }
  }

  IconData get icon {
    switch (this) {
      case MyOrdersChipFilter.all:
        return Icons.inventory_2_outlined;
      case MyOrdersChipFilter.awaitingApproval:
        return Icons.hourglass_top_rounded;
      case MyOrdersChipFilter.completed:
        return Icons.check_circle_outline;
      case MyOrdersChipFilter.cancelled:
        return Icons.cancel_outlined;
    }
  }

  bool matches(MyOrderModel order) {
    switch (this) {
      case MyOrdersChipFilter.all:
        return true;
      case MyOrdersChipFilter.awaitingApproval:
        return (order.statusId == OrderStatusCodes.ordered &&
                !order.isApproved) ||
            order.statusId == OrderStatusCodes.awaitingSellerApproval;
      case MyOrdersChipFilter.completed:
        return order.statusId == OrderStatusCodes.delivered ||
            order.statusId == OrderStatusCodes.received;
      case MyOrdersChipFilter.cancelled:
        return order.statusId == OrderStatusCodes.cancelled;
    }
  }

  static int count(List<MyOrderModel> orders, MyOrdersChipFilter filter) =>
      orders.where(filter.matches).length;
}
