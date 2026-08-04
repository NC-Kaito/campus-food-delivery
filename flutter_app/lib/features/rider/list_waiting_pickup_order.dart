// features/rider/list_waiting_pickup_order.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/services/rider/rider_service.dart';
import 'package:flutter_app/data/services/order_service.dart';
import 'package:flutter_app/data/models/order_model.dart';
import 'package:flutter_app/global_data.dart';

import 'package:flutter_app/features/rider/view_waiting_pickup_order.dart';
import 'package:flutter_app/features/rider/view_delivery_detail.dart'; // 🎯 1. นำเข้าหน้า ViewDeliveryDetail ที่คุณสร้างขึ้น

import 'package:flutter_app/features/rider/view_waiting_pickup_order.dart'
    as waiting;
import 'package:flutter_app/features/rider/view_delivery_detail.dart'
    as delivery;

class ListWaitingPickupOrder extends StatefulWidget {
  const ListWaitingPickupOrder({super.key});

  @override
  State<ListWaitingPickupOrder> createState() => _ListWaitingPickupOrderState();
}

class _ListWaitingPickupOrderState extends State<ListWaitingPickupOrder>
    with SingleTickerProviderStateMixin {
  final RiderService _riderService = RiderService();
  final OrderService _orderService = OrderService();

  bool _isReady = false;
  bool _isUpdating = false;
  bool _isLoadingOrders = false;
  bool _isLoadingStatus = true;
  int _selectedTabIndex = 0;

  // 🎯 ใช้ TabController จริงแทนปุ่ม chip เดิม เพื่อให้ UX/UI ของแถบแท็บ
  // เหมือนกับฝั่ง member (list_confirm_order_member.dart) เป๊ะๆ
  late final TabController _tabController;

  List<dynamic> _realOrders = [];

  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchRiderStatus();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();

    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isReady && !_isLoadingOrders && !_isUpdating) {
        _fetchOrdersBackground();
      }
    });
  }

  // 🎯 ดึงข้อมูลเบื้องหลังตามแท็บที่เลือก
  Future<void> _fetchOrdersBackground() async {
    if (!_isReady) return;
    try {
      List<dynamic> orders = [];
      if (_selectedTabIndex == 0) {
        orders = await _orderService.getWaitingOrders();
      } else if (_selectedTabIndex == 1) {
        String studentId = GlobalData.usernameRider;
        orders = await _orderService.getActiveOrders(studentId);
      }

      if (mounted) {
        setState(() {
          _realOrders = orders;
        });
      }
    } catch (e) {
      debugPrint("Auto-refresh orders failure: $e");
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchRiderStatus() async {
    try {
      String studentId = GlobalData.usernameRider;
      final riderData = await _riderService.getRiderByStudentId(studentId);

      if (mounted) {
        setState(() {
          _isReady = riderData.isActive ?? false;
          _isLoadingStatus = false;
        });

        if (_isReady) {
          _fetchOrders();
          _startAutoRefresh();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStatus = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🚨 โหลดสถานะไรเดอร์ล้มเหลว: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🎯 ดึงข้อมูลออเดอร์แยกตามแท็บแบบแสดง Loading
  Future<void> _fetchOrders() async {
    if (!_isReady) return;

    setState(() {
      _isLoadingOrders = true;
    });

    try {
      List<dynamic> orders = [];
      if (_selectedTabIndex == 0) {
        // แท็บ 0: งานใหม่ที่ยังไม่มีใครรับ
        orders = await _orderService.getWaitingOrders();
      } else if (_selectedTabIndex == 1) {
        // แท็บ 1: งานที่ไรเดอร์คนนี้รับมาแล้วกำลังดำเนินการ
        String studentId = GlobalData.usernameRider;
        orders = await _orderService.getActiveOrders(studentId);
      } else {
        // แท็บ 2: จัดส่งสำเร็จ
        orders = [];
      }

      if (mounted) {
        setState(() {
          _realOrders = orders;
          _isLoadingOrders = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingOrders = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🚨 โหลดรายการออเดอร์ล้มเหลว: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleActiveStatus(bool newStatus) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      String studentId = GlobalData.usernameRider;
      await _riderService.updateIsActive(studentId, newStatus);

      if (mounted) {
        setState(() {
          _isReady = newStatus;
          _isUpdating = false;

          if (!newStatus) {
            _realOrders.clear();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? "เปิดระบบพร้อมรับงานแล้ว 🏍️"
                  : "ปิดระบบพักการทำงานแล้ว 💤",
            ),
            duration: const Duration(seconds: 1),
          ),
        );

        if (newStatus) {
          _fetchOrders();
          _startAutoRefresh();
        } else {
          _autoRefreshTimer?.cancel();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🚨 เปลี่ยนสถานะไม่สำเร็จ: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🎯 2. ปรับฟังก์ชันเปิดหน้ารายละเอียด ให้แยกตามแท็บ (Tab 0 ไปหน้า ViewWaitingPickupOrder, Tab 1 ไปหน้า ViewDeliveryDetail)
  Future<void> _openOrderDetail(OrderModel orderModel) async {
    Widget targetPage;

    if (_selectedTabIndex == 0) {
      targetPage = waiting.ViewWaitingPickupOrder(orderModel: orderModel);
    } else {
      targetPage = delivery.ViewDeliveryDetail(orderModel: orderModel);
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    );

    // รีเฟรชลิสต์เมื่อกลับมาจากหน้ารายละเอียด
    if (result == true || _selectedTabIndex == 1) {
      _fetchOrders();
    }
  }

  String _getFinalProfileImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;

    final String baseUrl = DioClient.dio.options.baseUrl;

    if (rawPath.startsWith('/')) {
      return "$baseUrl$rawPath";
    } else {
      return "$baseUrl/$rawPath";
    }
  }

  // 🎯 แถบแท็บสไตล์เดียวกับฝั่ง member: พื้นขาว ตัวหนังสือหนา + เส้นขีดใต้
  // แท็บที่กำลังเลือกอยู่ (แทนปุ่ม chip สีเหลืองแบบเดิม)
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF64FF20),
        indicatorWeight: 3,
        labelColor: const Color(0xFF2E7D32),
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        onTap: (index) {
          if (_selectedTabIndex == index) return;
          setState(() => _selectedTabIndex = index);
          _fetchOrders(); // 🎯 โหลดข้อมูลใหม่เมื่อเปลี่ยนแท็บ
        },
        tabs: const [
          Tab(text: "งานใหม่"),
          Tab(text: "รายการจัดส่ง"),
          Tab(text: "จัดส่งสำเร็จ"),
        ],
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final orderModel = OrderModel.fromJson(order);

    final int rawOrderId = orderModel.orderId ?? 0;
    final String orderId = rawOrderId.toString().padLeft(6, '0');
    final String restaurantName =
        orderModel.restaurant?.restaurantName ?? "ไม่ระบุชื่อร้าน";

    String memberFullName = "ไม่ระบุชื่อผู้รับ";
    String finalImgUrl = "";

    if (orderModel.member != null) {
      final String firstName = orderModel.member?.firstname ?? "";
      final String lastName = orderModel.member?.lastname ?? "";
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        memberFullName = "$firstName $lastName".trim();
      }

      final String? rawImgPath = orderModel.member?.profileimg ?? "";
      finalImgUrl = _getFinalProfileImageUrl(rawImgPath);
    } else if (order["customerName"] != null) {
      memberFullName = order["customerName"];
    }

    int totalItems = 0;
    if (order["orderDetails"] != null && order["orderDetails"] is List) {
      totalItems = (order["orderDetails"] as List).length;
    } else if (order["items"] != null && order["items"] is List) {
      totalItems = (order["items"] as List).length;
    }

    String orderTimeText = "--:--";
    if (orderModel.orderdate != null) {
      final DateTime dateTime = orderModel.orderdate!;
      final String hour = dateTime.hour.toString().padLeft(2, '0');
      final String minute = dateTime.minute.toString().padLeft(2, '0');
      orderTimeText = "$hour:$minute น.";
    }

    // 🎯 กำหนดคำที่ปุ่มให้ตรงกับบริบทของแท็บ
    String buttonText = _selectedTabIndex == 0
        ? "ดูรายละเอียดเพื่อรับงาน"
        : "ดูเส้นทาง / สถานะจัดส่ง";

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openOrderDetail(orderModel),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.orange.withOpacity(0.2),
                          backgroundImage: finalImgUrl.isNotEmpty
                              ? NetworkImage(finalImgUrl)
                              : null,
                          child: finalImgUrl.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Colors.orange,
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            memberFullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "เลขที่ออเดอร์",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        "K$orderId",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 4),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "รับที่ (ร้านค้า)",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          restaurantName,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "ทั้งหมด $totalItems รายการ",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "เวลาสั่งซื้อ: $orderTimeText",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1, color: Colors.black12),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _openOrderDetail(orderModel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF64FF20),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey.shade200,
        leading: IconButton(
          icon: const Icon(Icons.home_outlined, color: Colors.orange, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delivery_dining,
              color: Colors.orange,
              size: 30,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: Colors.orange,
              size: 30,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Colors.orange,
              size: 30,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoadingStatus
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "งานของฉัน",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          shadows: [
                            Shadow(
                              color: Colors.orange.withOpacity(0.3),
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _isReady ? "พร้อมรับงาน" : "พักการทำงาน",
                            style: TextStyle(
                              color: _isReady
                                  ? const Color(0xFF64FF20)
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _isUpdating
                                ? null
                                : () => _toggleActiveStatus(!_isReady),
                            child: Opacity(
                              opacity: _isUpdating ? 0.5 : 1.0,
                              child: Container(
                                width: 54,
                                height: 28,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _isReady
                                        ? const Color(0xFF64FF20)
                                        : Colors.grey,
                                    width: 2,
                                  ),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  mainAxisAlignment: _isReady
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  children: [
                                    if (_isReady)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 6),
                                        child: Text(
                                          "ON",
                                          style: TextStyle(
                                            color: Color(0xFF64FF20),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    Container(
                                      margin: const EdgeInsets.all(2),
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _isReady
                                            ? const Color(0xFF64FF20)
                                            : Colors.grey,
                                      ),
                                    ),
                                    if (!_isReady)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 4),
                                        child: Text(
                                          "OFF",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildTabBar(),
                if (_isReady && !_isLoadingStatus)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Text(
                      "ทั้งหมด ${_realOrders.length} รายการ",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: !_isReady
                      ? _buildDisabledState()
                      : _isLoadingOrders
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.orange,
                          ),
                        )
                      : _realOrders.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _fetchOrders,
                          color: Colors.orange,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            itemCount: _realOrders.length,
                            itemBuilder: (context, index) {
                              return _buildOrderCard(_realOrders[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDisabledState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.power_settings_new, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "เปิดสถานะพร้อมรับงาน เพื่อเริ่มดูออเดอร์ใหม่",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String emptyMessage = _selectedTabIndex == 0
        ? "ยังไม่มีออเดอร์ใหม่ในระบบขณะนี้"
        : _selectedTabIndex == 1
        ? "ยังไม่มีรายการที่กำลังจัดส่ง"
        : "ยังไม่มีรายการที่จัดส่งสำเร็จ";

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      color: Colors.orange,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          Icon(
            Icons.layers_clear_outlined,
            size: 80,
            color: Colors.orange.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              emptyMessage,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
