import 'package:alrasmarket/features/clint/data/models/my_order_model.dart';
import 'package:flutter/material.dart';

import 'track_order_status_helper.dart';

class OrderStatusColors {
  const OrderStatusColors({
    required this.foreground,
    required this.background,
  });

  final Color foreground;
  final Color background;
}

class OrderStatusStyle {
  OrderStatusStyle._();

  static OrderStatusColors forOrder(MyOrderModel order) {
    return forStatusId(order.statusId, fallbackName: order.statusName);
  }

  static OrderStatusColors forStatusId(
    int statusId, {
    String fallbackName = '',
  }) {
    switch (statusId) {
      case OrderStatusCodes.ordered:
        return const OrderStatusColors(
          foreground: Color(0xFF1565C0),
          background: Color(0xFFE3F2FD),
        );
      case OrderStatusCodes.approved:
        return const OrderStatusColors(
          foreground: Color(0xFF6A1B9A),
          background: Color(0xFFF3E5F5),
        );
      case OrderStatusCodes.paid:
        return const OrderStatusColors(
          foreground: Color(0xFF00796B),
          background: Color(0xFFE0F2F1),
        );
      case OrderStatusCodes.shipping:
        return const OrderStatusColors(
          foreground: Color(0xFFE65100),
          background: Color(0xFFFFF3E0),
        );
      case OrderStatusCodes.delivered:
      case OrderStatusCodes.received:
        return const OrderStatusColors(
          foreground: Color(0xFF2E7D32),
          background: Color(0xFFE8F5E9),
        );
      case OrderStatusCodes.cancelled:
        return const OrderStatusColors(
          foreground: Color(0xFFC62828),
          background: Color(0xFFFFEBEE),
        );
      case OrderStatusCodes.paidToSupplier:
        return const OrderStatusColors(
          foreground: Color(0xFF3949AB),
          background: Color(0xFFE8EAF6),
        );
      case OrderStatusCodes.returnRequested:
        return const OrderStatusColors(
          foreground: Color(0xFFEF6C00),
          background: Color(0xFFFFF8E1),
        );
      case OrderStatusCodes.returnApproved:
        return const OrderStatusColors(
          foreground: Color(0xFFAD1457),
          background: Color(0xFFFCE4EC),
        );
      case OrderStatusCodes.awaitingSellerApproval:
        return const OrderStatusColors(
          foreground: Color(0xFF6A1B9A),
          background: Color(0xFFF3E5F5),
        );
      default:
        return _fromStatusName(fallbackName);
    }
  }

  static OrderStatusColors _fromStatusName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('cancel')) {
      return forStatusId(OrderStatusCodes.cancelled);
    }
    if (lower.contains('ship')) {
      return forStatusId(OrderStatusCodes.shipping);
    }
    if (lower.contains('deliver') || lower.contains('received')) {
      return forStatusId(OrderStatusCodes.delivered);
    }
    if (lower.contains('return')) {
      return forStatusId(OrderStatusCodes.returnRequested);
    }
    if (lower.contains('paid')) {
      return forStatusId(OrderStatusCodes.paid);
    }
    if (lower.contains('approv')) {
      return forStatusId(OrderStatusCodes.approved);
    }
    return const OrderStatusColors(
      foreground: Color(0xFF3A7DC5),
      background: Color(0xFFE0F1FF),
    );
  }
}
