// features/rider/list_waiting_pickup_order.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/services/rider/rider_service.dart';
import 'package:flutter_app/data/services/order_service.dart';
import 'package:flutter_app/data/models/order_model.dart';
import 'package:flutter_app/global_data.dart';

import 'package:flutter_app/features/rider/view_waiting_pickup_order.dart'
    as waiting;
import 'package:flutter_app/features/rider/view_delivery_detail.dart'
    as delivery;
import 'package:flutter_app/features/rider/view_review_rider.dart' as review;

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

  late final TabController _tabController;
  List<dynamic> _realOrders = [];
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

  Future<void> _fetchOrdersBackground() async {
    if (!_isReady) return;
    try {
      List<dynamic> orders = [];
      String studentId = GlobalData.usernameRider;

      if (_selectedTabIndex == 0) {
        orders = await _orderService.getWaitingOrders();
      } else if (_selectedTabIndex == 1) {
        orders = await _orderService.getActiveOrders(studentId);
      } else if (_selectedTabIndex == 2) {
        orders = await _orderService.getSuccessOrdersByRider(studentId);
      } else if (_selectedTabIndex == 3) {
        orders = await _orderService.getReviewSuccessOrders(studentId);
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

  Future<void> _fetchOrders() async {
    if (!_isReady) return;

    setState(() {
      _isLoadingOrders = true;
    });

    try {
      List<dynamic> orders = [];
      String studentId = GlobalData.usernameRider;

      if (_selectedTabIndex == 0) {
        orders = await _orderService.getWaitingOrders();
      } else if (_selectedTabIndex == 1) {
        orders = await _orderService.getActiveOrders(studentId);
      } else if (_selectedTabIndex == 2) {
        orders = await _orderService.getSuccessOrdersByRider(studentId);
      } else if (_selectedTabIndex == 3) {
        orders = await _orderService.getReviewSuccessOrders(studentId);
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

  Future<void> _openOrderDetail(
    OrderModel orderModel,
    dynamic rawOrder, {
    bool isReviewTab = false,
  }) async {
    Widget targetPage;

    if (_selectedTabIndex == 0) {
      targetPage = waiting.ViewWaitingPickupOrder(orderModel: orderModel);
    } else if (isReviewTab) {
      targetPage = review.ViewReviewRider(orderModel: orderModel);
    } else {
      targetPage = delivery.ViewDeliveryDetail(orderModel: orderModel);
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    );

    if (result == true || _selectedTabIndex == 1) {
      _fetchOrders();
    }
  }

  String _getFinalProfileImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;

    final String baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/') ? "$baseUrl$rawPath" : "$baseUrl/$rawPath";
  }

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
        labelPadding: const EdgeInsets.symmetric(horizontal: 2.0),
        onTap: (index) {
          if (_selectedTabIndex == index) return;
          setState(() => _selectedTabIndex = index);
          _fetchOrders();
        },
        tabs: const [
          Tab(text: "งานใหม่"),
          Tab(text: "รายการจัดส่ง"),
          Tab(text: "จัดส่งสำเร็จ"),
          Tab(text: "ดูรีวิว"),
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
      orderTimeText =
          "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} น.";
    }

    String buttonText = "ดูรายละเอียด";
    bool isReviewTab = _selectedTabIndex == 3;

    if (_selectedTabIndex == 0) {
      buttonText = "ดูรายละเอียดเพื่อรับงาน";
    } else if (_selectedTabIndex == 1) {
      buttonText = "ดูเส้นทาง / Status จัดส่ง";
    } else if (_selectedTabIndex == 2) {
      buttonText = "ดูรายละเอียดการจัดส่ง";
    } else if (isReviewTab) {
      buttonText = "ดูรีวิวการจัดส่ง";
    }

    final double cardRating =
        double.tryParse((order['reviewRating'] ?? 5.0).toString()) ?? 5.0;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () =>
          _openOrderDetail(orderModel, order, isReviewTab: isReviewTab),
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
            if (isReviewTab) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$cardRating คะแนน",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                  onPressed: () => _openOrderDetail(
                    orderModel,
                    order,
                    isReviewTab: isReviewTab,
                  ),
                  style: ElevatedButton.styleFrom(
                    // 🎯 ปรับแก้: ให้ใช้สีเขียว #64FF20 เป็นหลักในทุกแท็บ เพื่อความสบายตาและเข้าคู่กันครับ
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
                      // 🎯 ปรับแก้: ตัวอักษรบนปุ่มเป็นสีดำ เพื่อให้ตัดกับสีพื้นหลังสีเขียวอย่างเด่นชัดและอ่านง่ายครับ
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
        : _selectedTabIndex == 2
        ? "ยังไม่มีรายการที่จัดส่งสำเร็จ"
        : "ยังไม่มีรายการที่ได้รับการรีวิว";

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
