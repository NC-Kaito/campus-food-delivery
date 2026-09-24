// core/services/order_status_monitor.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/order_model.dart';
import 'package:flutter_app/data/services/in_app_notification_service.dart';
import 'package:flutter_app/data/services/order_service.dart';
import 'package:flutter_app/features/member/view_active_order_member.dart';
import 'package:flutter_app/features/restaurant/list_order_restaurant.dart';
import 'package:flutter_app/features/rider/view_delivery_detail.dart';
import 'package:flutter_app/global_data.dart';

class OrderStatusMonitor {
  static final OrderStatusMonitor _instance = OrderStatusMonitor._internal();
  factory OrderStatusMonitor() => _instance;
  OrderStatusMonitor._internal();

  final OrderService _orderService = OrderService();
  Timer? _timer;

  // 🎯 เก็บสถานะล่าสุดของแต่ละ orderId (ใช้สำหรับ Member และ Rider)
  final Map<int, String> _lastKnownStatuses = {};

  // 🎯 เก็บจำนวนออเดอร์รอรับล่าสุด (ใช้สำหรับ Restaurant เช็คออเดอร์ใหม่เข้า)
  int _lastKnownWaitingCount = -1;

  void startMonitoring() {
    _timer?.cancel();

    // เช็กครั้งแรกทันที ไม่ต้องรอ 5 วินาที
    _checkOrderUpdates();

    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkOrderUpdates(),
    );
  }

  void stopMonitoring() {
    _timer?.cancel();
    _lastKnownStatuses.clear();
    _lastKnownWaitingCount = -1;
  }

  // 🎯 ฟังก์ชันหลัก ตรวจสอบว่าใครกำลังล็อกอินอยู่
  Future<void> _checkOrderUpdates() async {
    final String memberUser = (GlobalData.usernameMember ?? "").trim();
    final String restUser = (GlobalData.usernameRestaurant ?? "").trim();
    final String riderUser = (GlobalData.usernameRider ?? "").trim();

    try {
      if (memberUser.isNotEmpty) {
        await _checkMemberOrders(memberUser);
      } else if (restUser.isNotEmpty) {
        await _checkRestaurantOrders(restUser);
      } else if (riderUser.isNotEmpty) {
        await _checkRiderOrders(riderUser);
      }
    } catch (_) {
      // ป้องกันแอปค้างเวลาเน็ตหลุด
    }
  }

  // ==========================================
  // 1. ระบบ Monitor สำหรับฝั่งลูกค้า (Member)
  // ==========================================
  Future<void> _checkMemberOrders(String username) async {
    // 🎯 แปลงค่า List<dynamic> เป็น List<OrderModel>
    final List<dynamic> rawOrders = await _orderService
        .getConfirmOrdersByMember(username);
    final List<OrderModel> orders = rawOrders
        .map((o) => OrderModel.fromJson(Map<String, dynamic>.from(o as Map)))
        .toList();

    for (var order in orders) {
      final int? orderId = order.orderId;
      final String currentStatus = (order.orderStatus ?? "")
          .trim()
          .toLowerCase();

      if (orderId == null) continue;

      if (_lastKnownStatuses.containsKey(orderId)) {
        final String oldStatus = _lastKnownStatuses[orderId]!;
        if (oldStatus != currentStatus) {
          _triggerMemberNotification(order, currentStatus);
        }
      }
      _lastKnownStatuses[orderId] = currentStatus;
    }
  }

  // ==========================================
  // 2. ระบบ Monitor สำหรับฝั่งร้านค้า (Restaurant)
  // ==========================================
  Future<void> _checkRestaurantOrders(String username) async {
    // 🎯 ร้านค้าจะเน้นให้แจ้งเตือนเวลา "มีออเดอร์ใหม่เข้ามา" นับแค่ความยาวของ List ก็พอครับ
    final List<dynamic> rawOrders = await _orderService
        .getWaitingOrdersByRestaurant(username);
    final int currentWaitingCount = rawOrders.length;

    if (currentWaitingCount > _lastKnownWaitingCount &&
        _lastKnownWaitingCount != -1) {
      InAppNotificationService.showTopBanner(
        title: "ออเดอร์ใหม่เข้า! 🛎️",
        message: "คุณมีคำสั่งซื้อใหม่ กรุณาตรวจสอบและกดรับออเดอร์ครับ",
        icon: Icons.storefront_rounded,
        color: Colors.orange,
        onTap: () {
          final context = InAppNotificationService.navigatorKey.currentContext;
          if (context != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ListOrderRestaurant()),
            );
          }
        },
      );
    }
    _lastKnownWaitingCount = currentWaitingCount;
  }

  // ==========================================
  // 3. ระบบ Monitor สำหรับฝั่งผู้จัดส่ง (Rider)
  // ==========================================
  Future<void> _checkRiderOrders(String username) async {
    // 🎯 แปลงค่า List<dynamic> เป็น List<OrderModel>
    final List<dynamic> rawOrders = await _orderService.getOrdersNotifyByRider(
      username,
    );
    final List<OrderModel> activeOrders = rawOrders
        .map((o) => OrderModel.fromJson(Map<String, dynamic>.from(o as Map)))
        .toList();

    for (var order in activeOrders) {
      final int? orderId = order.orderId;
      final String currentStatus = (order.orderStatus ?? "")
          .trim()
          .toLowerCase();

      if (orderId == null) continue;

      if (_lastKnownStatuses.containsKey(orderId)) {
        final String oldStatus = _lastKnownStatuses[orderId]!;

        if (oldStatus != currentStatus) {
          if (currentStatus == 'foodready') {
            InAppNotificationService.showTopBanner(
              title: "อาหารเสร็จแล้ว! 🍲",
              message:
                  "ร้าน ${order.restaurant?.restaurantName ?? 'อาหาร'} เตรียมออเดอร์เสร็จแล้ว ไปรับได้เลยครับ",
              icon: Icons.fastfood_rounded,
              color: const Color(0xFF00B300),
              onTap: () => _navigateToRiderOrder(order),
            );
          } else if (currentStatus == 'cancel' ||
              currentStatus == 'cancelled') {
            InAppNotificationService.showTopBanner(
              title: "ออเดอร์ถูกยกเลิก 🚨",
              message:
                  "คำสั่งซื้อ K${order.orderId.toString().padLeft(6, '0')} ถูกยกเลิกแล้ว",
              icon: Icons.cancel_rounded,
              color: Colors.red,
              onTap: () => _navigateToRiderOrder(order),
            );
          }
        }
      }
      _lastKnownStatuses[orderId] = currentStatus;
    }
  }

  // ==========================================
  // 🎯 ฟังก์ชันช่วยเหลือ (Helpers)
  // ==========================================

  void _navigateToRiderOrder(OrderModel order) {
    final context = InAppNotificationService.navigatorKey.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ViewDeliveryDetail(orderModel: order),
        ),
      );
    }
  }

  void _triggerMemberNotification(OrderModel order, String status) {
    String title = "อัปเดตคำสั่งซื้อ";
    String message = "ออเดอร์ #${order.orderId} มีการเปลี่ยนแปลงสถานะ";
    IconData icon = Icons.fastfood_rounded;
    Color color = const Color(0xFF00B300);

    final storeName = order.restaurant?.restaurantName ?? "ร้านอาหาร";

    switch (status) {
      case 'waitingrestaurant':
      case 'preparing':
      case 'cooking':
        title = "ร้านค้ารับออเดอร์แล้ว 🧑‍🍳";
        message = "ร้าน $storeName กำลังปรุงอาหารของคุณ";
        icon = Icons.soup_kitchen_rounded;
        color = Colors.deepOrange;
        break;
      case 'goingtorestaurant':
      case 'rideraccepted':
        title = "ไรเดอร์รับงานแล้ว 🛵";
        message = "ผู้จัดส่งกำลังเดินทางไปรับอาหารที่ร้าน $storeName";
        icon = Icons.two_wheeler_rounded;
        color = Colors.orange;
        break;
      case 'delivery':
      case 'delivering':
        title = "อาหารกำลังนำส่ง 💨";
        message =
            "ผู้จัดส่งรับอาหารจากร้าน $storeName แล้ว กำลังมุ่งหน้าไปหาคุณ";
        icon = Icons.delivery_dining_rounded;
        color = Colors.indigo;
        break;
      case 'arrived':
        title = "ไรเดอร์ถึงจุดส่งแล้ว 📍";
        message = "ผู้จัดส่งเดินทางมาถึงแล้ว กรุณาออกมารับอาหาร";
        icon = Icons.location_on_rounded;
        color = Colors.pink;
        break;
      case 'delivered':
        title = "ส่งมอบอาหารแล้ว ✅";
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
