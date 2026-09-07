// features/member/notify_member.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/order_model.dart';
import 'package:flutter_app/data/services/order_service.dart';
import 'package:flutter_app/features/member/navbar_member.dart';
import 'package:flutter_app/features/member/view_active_order_member.dart';
import 'package:flutter_app/global_data.dart';

class NotifyMember extends StatefulWidget {
  const NotifyMember({super.key});

  @override
  State<NotifyMember> createState() => _NotifyMemberState();
}

class _NotifyMemberState extends State<NotifyMember> {
  final OrderService _orderService = OrderService();
  final Color primaryGreen = const Color(0xFF00B300);

  List<OrderModel> _notifications = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchNotificationsSilently();
    });
  }

  Future<void> _fetchNotifications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      String username = GlobalData.usernameMember.trim();
      if (username.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final orders = await _orderService.getConfirmOrdersByMember(username);

      if (mounted) {
        setState(() {
          _notifications = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchNotificationsSilently() async {
    try {
      String username = GlobalData.usernameMember.trim();
      if (username.isEmpty) return;

      final orders = await _orderService.getConfirmOrdersByMember(username);
      if (mounted) {
        setState(() {
          _notifications = orders;
        });
      }
    } catch (_) {}
  }

  String _formatDateTime(dynamic rawDate) {
    if (rawDate == null || rawDate.toString().isEmpty) return "ไม่ระบุเวลา";
    try {
      DateTime dt;
      if (rawDate is DateTime) {
        dt = rawDate.toLocal();
      } else {
        dt = DateTime.parse(rawDate.toString()).toLocal();
      }
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year + 543;
      final hr = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return "$d/$m/$y $hr:$min น.";
    } catch (e) {
      return rawDate.toString();
    }
  }

  Map<String, dynamic> _getNotificationContent(OrderModel order) {
    final status = (order.orderStatus ?? "").trim().toLowerCase();
    final storeName =
        order.restaurant?.restaurantName ?? order.restaurantUsername;

    switch (status) {
      case 'waitingrider':
        return {
          'title': 'กำลังค้นหาผู้จัดส่ง',
          'message': 'ออเดอร์ร้าน $storeName อยู่ในระหว่างการค้นหาไรเดอร์',
          'icon': Icons.person_search_rounded,
          'color': Colors.blue,
          'bgColor': Colors.blue.shade50,
        };
      case 'waitingrestaurant':
      case 'pending':
      case 'preparing':
      case 'cooking':
      case 'foodready':
        return {
          'title': 'ร้านค้ารับออเดอร์แล้ว',
          'message': 'ร้าน $storeName กำลังเริ่มเตรียมอาหารของคุณ',
          'icon': Icons.soup_kitchen_rounded,
          'color': Colors.deepOrange,
          'bgColor': Colors.deepOrange.shade50,
        };
      case 'rideraccepted':
      case 'goingtorestaurant':
      case 'going':
      case 'riderarrived':
        return {
          'title': 'ผู้จัดส่งกำลังเดินทางไปรับอาหาร',
          'message': 'ผู้จัดส่งรับงานแล้ว และกำลังเดินทางไปที่ร้าน $storeName',
          'icon': Icons.two_wheeler_rounded,
          'color': Colors.orange,
          'bgColor': Colors.orange.shade50,
        };
      case 'delivery':
      case 'delivering':
      case 'ontheway':
      case 'pickedup':
        return {
          'title': 'กำลังนำส่งอาหารให้คุณ',
          'message': 'ผู้จัดส่งได้รับอาหารจากร้าน $storeName และกำลังนำส่ง',
          'icon': Icons.delivery_dining_rounded,
          'color': Colors.indigo,
          'bgColor': Colors.indigo.shade50,
        };
      case 'arrived':
      case 'reached':
        return {
          'title': 'ผู้จัดส่งถึงจุดส่งแล้ว',
          'message': 'ผู้จัดส่งเดินทางมาถึงจุดหมายแล้ว กรุณาเตรียมรับอาหาร',
          'icon': Icons.location_on_rounded,
          'color': Colors.pink,
          'bgColor': Colors.pink.shade50,
        };
      case 'delivered':
        return {
          'title': 'รอยืนยันการรับอาหาร',
          'message': 'อาหารจัดส่งถึงที่หมายแล้ว กรุณาตรวจสอบและกดยืนยัน',
          'icon': Icons.assignment_turned_in_rounded,
          'color': Colors.purple,
          'bgColor': Colors.purple.shade50,
        };
      case 'success':
      case 'completed':
        return {
          'title': 'จัดส่งอาหารสำเร็จแล้ว',
          'message':
              'ออเดอร์ร้าน $storeName เสร็จสมบูรณ์ อย่าลืมให้คะแนนรีวิวนะครับ',
          'icon': Icons.check_circle_rounded,
          'color': primaryGreen,
          'bgColor': const Color(0xFFE8FCD0),
        };
      case 'reviewsuccess':
        return {
          'title': 'รีวิวออเดอร์สำเร็จ',
          'message': 'ขอบคุณสำหรับรีวิวร้าน $storeName',
          'icon': Icons.stars_rounded,
          'color': Colors.teal,
          'bgColor': Colors.teal.shade50,
        };
      case 'issue_reported':
        return {
          'title': 'มีการแจ้งปัญหาคำสั่งซื้อ',
          'message': 'บันทึกหลักฐานการแจ้งปัญหาออเดอร์ร้าน $storeName แล้ว',
          'icon': Icons.support_agent_rounded,
          'color': Colors.red,
          'bgColor': Colors.red.shade50,
        };
      case 'cancel':
      case 'cancelled':
        return {
          'title': 'คำสั่งซื้อถูกยกเลิก',
          'message':
              'ออเดอร์ร้าน $storeName ถูกยกเลิก: ${order.cancelDetail ?? "ไม่ระบุสาเหตุ"}',
          'icon': Icons.cancel_rounded,
          'color': Colors.red,
          'bgColor': Colors.red.shade50,
        };
      default:
        return {
          'title': 'อัปเดตสถานะคำสั่งซื้อ',
          'message': 'ออเดอร์ร้าน $storeName: $status',
          'icon': Icons.notifications_rounded,
          'color': Colors.grey,
          'bgColor': Colors.grey.shade100,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const NavbarMember(title: "การแจ้งเตือน"),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : _notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              color: primaryGreen,
              onRefresh: _fetchNotifications,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 14.0,
                ),
                itemCount: _notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _buildNotificationCard(_notifications[index]);
                },
              ),
            ),
    );
  }

  Widget _buildNotificationCard(OrderModel order) {
    final info = _getNotificationContent(order);
    final String dateText = _formatDateTime(order.orderdate);
    final String orderId = (order.orderId ?? 0).toString().padLeft(6, '0');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewActiveOrderMember(order: order),
            ),
          ).then((_) => _fetchNotificationsSilently());
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: info['bgColor'] as Color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  info['icon'] as IconData,
                  color: info['color'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            info['title'] as String,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "K$orderId",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info['message'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateText,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            "ยังไม่มีการแจ้งเตือนในขณะนี้",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
