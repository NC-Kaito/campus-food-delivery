// core/services/order_status_monitor.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/order_model.dart';
import 'package:flutter_app/data/services/member/in_app_notification_service.dart';
import 'package:flutter_app/data/services/order_service.dart';
import 'package:flutter_app/features/member/view_active_order_member.dart';
import 'package:flutter_app/global_data.dart';

class OrderStatusMonitor {
  static final OrderStatusMonitor _instance = OrderStatusMonitor._internal();
  factory OrderStatusMonitor() => _instance;
  OrderStatusMonitor._internal();

  final OrderService _orderService = OrderService();
  Timer? _timer;

  // เก็บสถานะล่าสุดของแต่ละ orderId: Map<orderId, status>
  final Map<int, String> _lastKnownStatuses = {};

  void startMonitoring() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkOrderUpdates(),
    );
  }

  void stopMonitoring() {
    _timer?.cancel();
    _lastKnownStatuses.clear();
  }

  Future<void> _checkOrderUpdates() async {
    final String username = GlobalData.usernameMember.trim();
    if (username.isEmpty) return;

    try {
      final List<OrderModel> orders = await _orderService
          .getConfirmOrdersByMember(username);

      for (var order in orders) {
        final int? orderId = order.orderId;
        final String currentStatus = (order.orderStatus ?? "")
            .trim()
            .toLowerCase();

        if (orderId == null) continue;

        // ถ้าเคยบันทึกสถานะไว้แล้ว และสถานะเปลี่ยนไป -> ยิง Pop-up
        if (_lastKnownStatuses.containsKey(orderId)) {
          final String oldStatus = _lastKnownStatuses[orderId]!;

          if (oldStatus != currentStatus) {
            _triggerNotification(order, currentStatus);
          }
        }

        // อัปเดตสถานะล่าสุด
        _lastKnownStatuses[orderId] = currentStatus;
      }
    } catch (_) {}
  }

  void _triggerNotification(OrderModel order, String status) {
    String title = "อัปเดตคำสั่งซื้อ";
    String message = "ออเดอร์ #${order.orderId} มีการเปลี่ยนแปลงสถานะ";
    IconData icon = Icons.fastfood_rounded;
    Color color = const Color(0xFF00B300);

    final storeName = order.restaurant?.restaurantName ?? "ร้านอาหาร";

    switch (status) {
      case 'waitingrestaurant':
      case 'preparing':
      case 'cooking':
        title = "ร้านค้ารับออเดอร์แล้ว 👨‍🍳";
        message = "ร้าน $storeName กำลังปรุงอาหารของคุณ";
        icon = Icons.soup_kitchen_rounded;
        color = Colors.deepOrange;
        break;
      case 'goingtorestaurant':
      case 'rideraccepted':
        title = "ไรเดอร์รับงานแล้ว 🏍️";
        message = "ผู้จัดส่งกำลังเดินทางไปรับอาหารที่ร้าน $storeName";
        icon = Icons.two_wheeler_rounded;
        color = Colors.orange;
        break;
      case 'delivery':
      case 'delivering':
        title = "อาหารกำลังนำส่ง 🚀";
        message =
            "ผู้จัดส่งรับอาหารจากร้าน $storeName แล้ว กำลังมุ่งหน้าไปหาคุณ";
        icon = Icons.delivery_dining_rounded;
        color = Colors.indigo;
        break;
      case 'arrived':
        title = "ไรเดอร์ถึงจุดส่งแล้ว 📍";
        message = "ผู้จัดส่งเดินทางมาถึงแล้ว กรุณาออกมารับอาหารครับ";
        icon = Icons.location_on_rounded;
        color = Colors.pink;
        break;
      case 'delivered':
        title = "ส่งมอบอาหารแล้ว 🍱";
        message = "อาหารจัดส่งถึงที่หมายแล้ว กรุณาตรวจสอบและกดยืนยันการรับ";
        icon = Icons.assignment_turned_in_rounded;
        color = Colors.purple;
        break;
      case 'cancel':
      case 'cancelled':
        title = "คำสั่งซื้อถูกยกเลิก ❌";
        message =
            "ออเดอร์ร้าน $storeName ถูกยกเลิก: ${order.cancelDetail ?? ''}";
        icon = Icons.cancel_rounded;
        color = Colors.red;
        break;
    }

    InAppNotificationService.showTopBanner(
      title: title,
      message: message,
      icon: icon,
      color: color,
      onTap: () {
        final context = InAppNotificationService.navigatorKey.currentContext;
        if (context != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ViewActiveOrderMember(order: order),
            ),
          );
        }
      },
    );
  }
}
