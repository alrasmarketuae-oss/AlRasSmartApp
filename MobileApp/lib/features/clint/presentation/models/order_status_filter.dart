import 'package:alrasmarket/features/clint/data/models/my_order_model.dart';
import 'package:alrasmarket/features/clint/presentation/widgets/track_order_widgets/track_order_status_helper.dart';
import 'package:alrasmarket/generated/l10n.dart';

/// Status chips for My Orders — aligned with the new admin/seller workflow
/// (awaiting admin → awaiting seller → in progress → delivered), not the old
/// retail-only Paid/Shipping pipeline.
enum OrderStatusFilter {
  all,
  awaitingAdmin,
  awaitingSeller,
  inProgress,
  delivered,
  cancelled,
  returns;

  String label(S s) {
    switch (this) {
      case OrderStatusFilter.all:
        return s.filterAll;
      case OrderStatusFilter.awaitingAdmin:
        return s.awaitingAdminApproval;
      case OrderStatusFilter.awaitingSeller:
        return s.awaitingSellerApproval;
      case OrderStatusFilter.inProgress:
        return s.inProgress;
      case OrderStatusFilter.delivered:
        return s.delivered;
      case OrderStatusFilter.cancelled:
        return s.orderCancelledStatus;
      case OrderStatusFilter.returns:
        return s.returnsFilter;
    }
  }

  bool matches(MyOrderModel order) {
    switch (this) {
      case OrderStatusFilter.all:
        return true;
      case OrderStatusFilter.awaitingAdmin:
        return order.statusId == OrderStatusCodes.ordered && !order.isApproved;
      case OrderStatusFilter.awaitingSeller:
        return order.statusId == OrderStatusCodes.awaitingSellerApproval;
      case OrderStatusFilter.inProgress:
        // Accepted / paid / shipping / paid-to-supplier (incl. custom text on Approved).
        return order.statusId == OrderStatusCodes.approved ||
            order.statusId == OrderStatusCodes.paid ||
            order.statusId == OrderStatusCodes.shipping ||
            order.statusId == OrderStatusCodes.paidToSupplier ||
            (order.statusId == OrderStatusCodes.ordered && order.isApproved);
      case OrderStatusFilter.delivered:
        return order.statusId == OrderStatusCodes.delivered ||
            order.statusId == OrderStatusCodes.received;
      case OrderStatusFilter.cancelled:
        return order.statusId == OrderStatusCodes.cancelled;
      case OrderStatusFilter.returns:
        return order.statusId == OrderStatusCodes.returnRequested ||
            order.statusId == OrderStatusCodes.returnApproved;
    }
  }
}
