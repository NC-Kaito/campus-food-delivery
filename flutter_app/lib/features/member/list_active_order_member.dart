// features/member/list_confirm_order_member.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/order_model.dart';
import 'package:flutter_app/data/services/order_service.dart';
import 'package:flutter_app/features/member/account_management_member.dart';
import 'package:flutter_app/features/member/list_order_member.dart';
import 'package:flutter_app/features/member/member_review.dart';
import 'package:flutter_app/features/member/view_active_order_member.dart';
import 'package:flutter_app/features/member/cancel_order_member.dart';
import 'package:flutter_app/features/member/navbar_member.dart';
import 'package:flutter_app/features/member/profile_member.dart';
import 'package:flutter_app/features/member/cart_manager_member.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/features/member/view_review.dart';
import 'package:flutter_app/global_data.dart';

import 'dart:async';

class ListActiveOrderMember extends StatefulWidget {
  const ListActiveOrderMember({super.key});

  @override
  State<ListActiveOrderMember> createState() => _ListConfirmOrderMemberState();
}

class _ListConfirmOrderMemberState extends State<ListActiveOrderMember>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  List<OrderModel> _orderHistoryList = [];
  bool _isLoading = true;

  Timer? _timer;
  late TabController _tabController;

  final menuTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Colors.green[700],
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _fetchOrderHistory();

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchOrderHistorySilently();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrderHistory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      String username = GlobalData.usernameMember.trim();
      if (username.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final history = await _orderService.getConfirmOrdersByMember(username);

      if (mounted) {
        setState(() {
          _orderHistoryList = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("เกิดข้อผิดพลาดในการโหลดประวัติคำสั่งซื้อหน้า UI: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchOrderHistorySilently() async {
    if (!mounted) return;

    try {
      String username = GlobalData.usernameMember.trim();
      if (username.isEmpty) return;

      final history = await _orderService.getConfirmOrdersByMember(username);

      if (mounted) {
        setState(() {
          _orderHistoryList = history;
        });
      }
    } catch (e) {
      debugPrint("เกิดข้อผิดพลาดในการดึงข้อมูลแบบ Background: $e");
    }
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;

    final String baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/') ? "$baseUrl$rawPath" : "$baseUrl/$rawPath";
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

  Map<String, dynamic> _getDetailedStatusInfo(String? rawStatus) {
    final status = (rawStatus ?? '').trim().toLowerCase();

    switch (status) {
      case 'waitingrestaurant':
      case 'pending':
        return {
          'text': 'รอร้านค้ายืนยัน',
          'color': Colors.blue[800]!,
          'bgColor': Colors.blue[50]!,
          'icon': Icons.storefront_rounded,
        };
      case 'preparing':
      case 'cooking':
      case 'foodready':
      case 'waitingrider':
        return {
          'text': 'ร้านรับออเดอร์แล้ว',
          'color': Colors.deepOrange[800]!,
          'bgColor': Colors.deepOrange[50]!,
          'icon': Icons.soup_kitchen_rounded,
        };
      case 'goingtorestaurant':
      case 'going':
      case 'riderarrived':
        return {
          'text': 'ผู้จัดส่งกำลังไปรับ',
          'color': Colors.orange[800]!,
          'bgColor': Colors.orange[50]!,
          'icon': Icons.directions_bike_rounded,
        };
      case 'delivery':
      case 'delivering':
      case 'ontheway':
      case 'pickedup':
        return {
          'text': 'กำลังจัดส่ง',
          'color': Colors.indigo[800]!,
          'bgColor': Colors.indigo[50]!,
          'icon': Icons.local_shipping_rounded,
        };
      case 'arrived':
      case 'reached':
        return {
          'text': 'ถึงที่หมายแล้ว',
          'color': Colors.pink[800]!,
          'bgColor': Colors.pink[50]!,
          'icon': Icons.location_on_rounded,
        };
      case 'delivered':
        return {
          'text': 'รอยืนยันรับอาหาร',
          'color': Colors.purple[800]!,
          'bgColor': Colors.purple[50]!,
          'icon': Icons.assignment_turned_in_rounded,
        };
      case 'success':
      case 'completed':
        return {
          'text': 'จัดส่งสำเร็จ (รอรีวิว)',
          'color': Colors.green[800]!,
          'bgColor': Colors.green[50]!,
          'icon': Icons.check_circle_rounded,
        };
      case 'reviewsuccess':
        return {
          'text': 'รีวิวเสร็จสิ้น',
          'color': Colors.teal[800]!,
          'bgColor': Colors.teal[50]!,
          'icon': Icons.stars_rounded,
        };
      case 'cancel':
      case 'cancelled':
        return {
          'text': 'ยกเลิกคำสั่งซื้อแล้ว',
          'color': Colors.red[800]!,
          'bgColor': Colors.red[50]!,
          'icon': Icons.cancel_rounded,
        };
      case 'issue_reported':
        return {
          'text': 'มีการแจ้งปัญหาคำสั่งซื้อ',
          'color': Colors.red[800]!,
          'bgColor': Colors.red[50]!,
          'icon': Icons.support_agent_rounded,
        };
      default:
        return {
          'text': status.isEmpty ? 'ไม่ระบุสถานะ' : status,
          'color': Colors.grey[800]!,
          'bgColor': Colors.grey[100]!,
          'icon': Icons.info_outline_rounded,
        };
    }
  }

  List<OrderModel> _filterOrders(String type) {
    return _orderHistoryList.where((order) {
      final status = (order.orderStatus ?? '').toLowerCase();

      if (type == 'pending') {
        return status != 'delivered' &&
            status != 'success' &&
            status != 'completed' &&
            status != 'reviewsuccess' &&
            status != 'cancel' &&
            status != 'cancelled' &&
            status != 'issue_reported';
      } else if (type == 'success') {
        return status == 'delivered' ||
            status == 'success' ||
            status == 'completed';
      } else if (type == 'history') {
        return status == 'reviewsuccess';
      } else if (type == 'cancel') {
        return status == 'cancel' ||
            status == 'cancelled' ||
            status == 'issue_reported';
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final int cartItemCount = CartManager().items.length;
    final int activeOrderCount = _filterOrders('pending').length;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: const NavbarMember(title: "รายการคำสั่งซื้อ"),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF64F02D),
                indicatorWeight: 3,
                labelColor: const Color(0xFF2E7D32),
                unselectedLabelColor: Colors.grey[600],
                labelPadding: EdgeInsets.zero,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                tabs: [
                  _buildTabWithBadge(
                    "กำลังดำเนินการ",
                    _filterOrders('pending').length,
                  ),
                  _buildTabWithBadge(
                    "สำเร็จ/รอรีวิว",
                    _filterOrders('success').length,
                  ),
                  _buildTabWithBadge(
                    "ประวัติคำสั่งซื้อ",
                    _filterOrders('history').length,
                  ),
                  _buildTabWithBadge("ยกเลิก", _filterOrders('cancel').length),
                ],
              ),
            ),
            // 🎯 แก้ไขโครงสร้างตรงนี้ ไม่ให้โดนถอด TabBarView ออกตอนกำลังโหลด
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.green),
                        )
                      : _buildOrderListView(
                          _filterOrders('pending'),
                          "ไม่มีคำสั่งซื้อที่กำลังดำเนินการ",
                        ),
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.green),
                        )
                      : _buildOrderListView(
                          _filterOrders('success'),
                          "ไม่มีคำสั่งซื้อรอรีวิว",
                        ),
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.green),
                        )
                      : _buildOrderListView(
                          _filterOrders('history'),
                          "ยังไม่มีประวัติคำสั่งซื้อ",
                        ),
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.green),
                        )
                      : _buildOrderListView(
                          _filterOrders('cancel'),
                          "ไม่มีคำสั่งซื้อที่ถูกยกเลิก",
                        ),
                ],
              ),
            ),
          ],
        ),

        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.home, "หน้าหลัก", () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }),
                  _buildNavItem(Icons.shopping_basket, "ตะกร้าอาหาร", () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ListOrderMember(),
                      ),
                    );
                  }, badgeCount: cartItemCount),
                  _buildNavItem(
                    Icons.list_alt,
                    "คำสั่งซื้อ",
                    () {
                      _fetchOrderHistory();
                    },
                    isActive: true,
                    badgeCount: activeOrderCount,
                  ),
                  _buildNavItem(Icons.settings, "ตั้งค่า", () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AccountManagementMember(),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderListView(List<OrderModel> orders, String emptyText) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(
              emptyText,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildOrderHistoryCard(orders[index]);
      },
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isActive = false,
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: isActive ? Colors.green : Colors.grey),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              label,
              style: menuTextStyle.copyWith(
                color: isActive ? Colors.green[700] : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHistoryCard(OrderModel order) {
    int totalItems = 0;
    for (var item in order.items) {
      totalItems += item.qty;
    }

    String storeName =
        order.restaurant?.restaurantName ?? order.restaurantUsername;
    String finalImageUrl = _getFinalImageUrl(order.restaurant?.restaurantImage);

    final statusInfo = _getDetailedStatusInfo(order.orderStatus);

    final String statusLower = (order.orderStatus ?? '').toLowerCase();

    final bool isCompleted =
        statusLower == 'success' ||
        statusLower == 'completed' ||
        statusLower == 'reviewsuccess';

    final bool isReviewed = statusLower == 'reviewsuccess';

    String formattedDate = _formatDateTime(order.orderdate);

    bool isWithinOneHour = true;
    try {
      final dynamic rawSuccessTime =
          (order as dynamic).successtime ?? (order as dynamic).successTime;

      final dynamic rawOrderDate = order.orderdate;

      if (rawSuccessTime != null && rawOrderDate != null) {
        DateTime orderDate;
        if (rawOrderDate is DateTime) {
          orderDate = rawOrderDate.toLocal();
        } else {
          orderDate = DateTime.parse(rawOrderDate.toString()).toLocal();
        }

        int hour = 0;
        int minute = 0;

        if (rawSuccessTime is List) {
          hour = int.tryParse(rawSuccessTime[0].toString()) ?? 0;
          if (rawSuccessTime.length > 1) {
            minute = int.tryParse(rawSuccessTime[1].toString()) ?? 0;
          }
        } else {
          String timeStr = rawSuccessTime
              .toString()
              .replaceAll(RegExp(r'[\[\]]'), '')
              .trim();
          List<String> timeParts = timeStr.contains(':')
              ? timeStr.split(':')
              : timeStr.split(',');
          if (timeParts.isNotEmpty)
            hour = int.tryParse(timeParts[0].trim()) ?? 0;
          if (timeParts.length > 1)
            minute = int.tryParse(timeParts[1].trim()) ?? 0;
        }

        DateTime successDateTime = DateTime(
          orderDate.year,
          orderDate.month,
          orderDate.day,
          hour,
          minute,
        );

        if (successDateTime.isBefore(orderDate)) {
          successDateTime = successDateTime.add(const Duration(days: 1));
        }

        if (DateTime.now().difference(successDateTime).inMinutes >= 60) {
          isWithinOneHour = false;
        }
      } else if (isCompleted) {
        isWithinOneHour = false;
      }
    } catch (e) {
      debugPrint("Error parsing success time: $e");
      isWithinOneHour = false;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FCD0),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        // 🎯 แก้ไขการ Navigate แบบ Async/Await เพื่อให้เปลี่ยนแท็บก่อนโหลด
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewActiveOrderMember(order: order),
            ),
          );

          if (result == true) {
            _tabController.animateTo(3); // 🎯 สไลด์ไปแท็บยกเลิกทันที!
          }
          _fetchOrderHistory(); // 🎯 ค่อยอัปเดตข้อมูลตามหลัง
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: finalImageUrl.isNotEmpty
                    ? Image.network(
                        Uri.encodeFull(finalImageUrl),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholderIcon(),
                      )
                    : _buildPlaceholderIcon(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusInfo['bgColor'],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (statusInfo['color'] as Color).withOpacity(
                            0.3,
                          ),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusInfo['icon'] as IconData,
                            size: 13,
                            color: statusInfo['color'],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusInfo['text'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusInfo['color'],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "รหัสบิล: #${order.orderId ?? '-'}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "จำนวน $totalItems รายการ",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "฿${order.totalPrice.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    if (isCompleted) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isWithinOneHour) ...[
                            Expanded(
                              child: OutlinedButton.icon(
                                // 🎯 แก้ไขปุ่มให้ทำงานแบบ Async / Await เหมือนกัน
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CancelOrderMember(
                                        orderId: order.orderId ?? 0,
                                      ),
                                    ),
                                  );

                                  if (result == true) {
                                    _tabController.animateTo(
                                      3,
                                    ); // 🎯 สไลด์แท็บทันที
                                  }
                                  _fetchOrderHistory(); // 🎯 รีเฟรชข้อมูลตามทีหลัง
                                },
                                icon: Icon(
                                  Icons.warning_amber_rounded,
                                  size: 16,
                                  color: Colors.red[600],
                                ),
                                label: Text(
                                  "แจ้งปัญหา",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[700],
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.red[400]!,
                                    width: 1.2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor: Colors.red.shade50,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  if (isReviewed) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ViewReview(order: order),
                                      ),
                                    );
                                  } else {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MemberReview(order: order),
                                      ),
                                    );
                                    if (result == true) _fetchOrderHistory();
                                  }
                                },
                                icon: Icon(
                                  isReviewed
                                      ? Icons.rate_review_rounded
                                      : Icons.star_rounded,
                                  size: 16,
                                  color: isReviewed
                                      ? Colors.blue
                                      : Colors.orange,
                                ),
                                label: Text(
                                  isReviewed ? "ดูรีวิว" : "รีวิวออเดอร์",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isReviewed
                                        ? Colors.blue[700]
                                        : Colors.green[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: isReviewed
                                        ? Colors.blue[400]!
                                        : Colors.green[400]!,
                                    width: 1.2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            OutlinedButton.icon(
                              onPressed: () async {
                                if (isReviewed) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ViewReview(order: order),
                                    ),
                                  );
                                } else {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          MemberReview(order: order),
                                    ),
                                  );
                                  if (result == true) _fetchOrderHistory();
                                }
                              },
                              icon: Icon(
                                isReviewed
                                    ? Icons.rate_review_rounded
                                    : Icons.star_rounded,
                                size: 16,
                                color: isReviewed ? Colors.blue : Colors.orange,
                              ),
                              label: Text(
                                isReviewed ? "ดูรีวิว" : "รีวิวออเดอร์",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isReviewed
                                      ? Colors.blue[700]
                                      : Colors.green[700],
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isReviewed
                                      ? Colors.blue[400]!
                                      : Colors.green[400]!,
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Align(
                alignment: Alignment.center,
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.orange[50],
      child: const Icon(Icons.store, color: Colors.orange, size: 40),
    );
  }

  Widget _buildTabWithBadge(String text, int count) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
