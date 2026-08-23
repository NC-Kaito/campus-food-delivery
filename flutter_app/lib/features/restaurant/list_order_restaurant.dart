// features/restaurant/list_order_restaurant.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/order_model.dart';
import 'package:flutter_app/data/services/order_service.dart';
import 'package:flutter_app/features/restaurant/restaurant_navbar.dart';
import 'package:flutter_app/features/restaurant/view_order_restaurant.dart';
import 'package:flutter_app/global_data.dart';

// 🎯 1. เพิ่มการอิมพอร์ตหน้า ViewReviewRestaurant เข้ามาเชื่อมโยงกันครับคุณนารีย์
// (ตรวจสอบ Path โฟลเดอร์ในเครื่องอีกครั้งให้ตรงกันเป๊ะๆ นะครับ)
import 'package:flutter_app/features/restaurant/view_review_restaurant.dart'
    as review;

class ListOrderRestaurant extends StatefulWidget {
  const ListOrderRestaurant({super.key});

  @override
  State<ListOrderRestaurant> createState() => _ListOrderRestaurantState();
}

class _ListOrderRestaurantState extends State<ListOrderRestaurant> {
  final OrderService _orderService = OrderService();

  bool _isLoadingOrders = false;
  int _selectedTabIndex = 0;

  List<dynamic> _realOrders = [];
  Timer? _autoRefreshTimer;

  int _waitingCount = 0;
  int _activeCount = 0;

  static const Color _primary = Color(0xFF16A34A);
  static const Color _accent = Color(0xFFEA7C1E);

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isLoadingOrders) {
        _fetchOrdersBackground();
      }
    });
  }

  Future<void> _fetchOrdersBackground() async {
    try {
      String username = GlobalData.usernameRestaurant;

      final waitingOrders = await _orderService.getWaitingOrdersByRestaurant(
        username,
      );
      final activeOrders = await _orderService.getActiveOrdersByRestaurant(
        username,
      );

      if (mounted) {
        setState(() {
          _waitingCount = waitingOrders.length;
          _activeCount = activeOrders.length;

          if (_selectedTabIndex == 0) {
            _realOrders = waitingOrders;
          } else if (_selectedTabIndex == 1) {
            _realOrders = activeOrders;
          } else if (_selectedTabIndex == 2) {
            _realOrders = []; // ประวัติสำเร็จ
          } else if (_selectedTabIndex == 3) {
            _fetchReviewOrdersSilent(username);
          }
        });
      }
    } catch (e) {
      debugPrint("Auto-refresh restaurant orders failure: $e");
    }
  }

  Future<void> _fetchReviewOrdersSilent(String username) async {
    try {
      final reviewOrders = await _orderService
          .getReviewSuccessOrdersByRestaurant(username);
      if (mounted && _selectedTabIndex == 3) {
        setState(() {
          _realOrders = reviewOrders;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoadingOrders = true);

    try {
      String username = GlobalData.usernameRestaurant;

      final waitingOrders = await _orderService.getWaitingOrdersByRestaurant(
        username,
      );
      final activeOrders = await _orderService.getActiveOrdersByRestaurant(
        username,
      );

      List<dynamic> targetOrders = [];
      if (_selectedTabIndex == 0) {
        targetOrders = waitingOrders;
      } else if (_selectedTabIndex == 1) {
        targetOrders = activeOrders;
      } else if (_selectedTabIndex == 2) {
        targetOrders = []; // ประวัติสำเร็จ
      } else if (_selectedTabIndex == 3) {
        targetOrders = await _orderService.getReviewSuccessOrdersByRestaurant(
          username,
        );
      }

      if (mounted) {
        setState(() {
          _waitingCount = waitingOrders.length;
          _activeCount = activeOrders.length;
          _realOrders = targetOrders;
          _isLoadingOrders = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingOrders = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🚨 โหลดรายการออเดอร์ล้มเหลว: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🎯 2. แก้ไขฟังก์ชันการกดเปิดหน้าจอรายละเอียด ให้สลับแยกพาร์ทตามแท็บอย่างถูกต้อง
  Future<void> _openOrderDetail(
    OrderModel orderModel, {
    bool isReviewTab = false,
  }) async {
    Widget targetPage;

    if (isReviewTab) {
      // ✨ ถ้ากดจากแท็บที่ 4 (ดูรีวิว) ให้เดินทางไปยังหน้า ViewReviewRestaurant ที่เพิ่งดีไซน์ไว้ครับ
      targetPage = review.ViewReviewRestaurant(orderModel: orderModel);
    } else {
      // ✨ ถ้ากดจากแท็บงานปกติ ให้เปิดหน้าแสดงรายละเอียดออเดอร์ของร้านค้าตัวเดิมครับ
      targetPage = ViewOrderRestaurant(orderModel: orderModel);
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    );

    if (result == true) {
      _fetchOrders();
    }
  }

  String _getFinalProfileImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;
    final String baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/') ? "$baseUrl$rawPath" : "$baseUrl/$rawPath";
  }

  Widget _buildTab(String title, int index, {int badgeCount = 0}) {
    bool isActive = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        if (_selectedTabIndex == index) return;
        setState(() {
          _selectedTabIndex = index;
        });
        _fetchOrders();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? _primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _primary.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.only(right: badgeCount > 0 ? 10.0 : 0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : Colors.black87,
                  fontSize: 12,
                ),
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                right: 4,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
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
      appBar: const RestaurantNavbar(title: ""),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              "คำสั่งซื้อของร้าน",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _primary,
                shadows: [
                  Shadow(
                    color: _primary.withOpacity(0.2),
                    offset: const Offset(1, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildTab(
                    "คำสั่งซื้อใหม่",
                    0,
                    badgeCount: _waitingCount,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTab(
                    "ที่ต้องเตรียม",
                    1,
                    badgeCount: _activeCount,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildTab("สำเร็จ", 2)),
                const SizedBox(width: 8),
                Expanded(child: _buildTab("ดูรีวิว", 3)),
              ],
            ),
          ),
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
          const SizedBox(height: 12),
          Expanded(
            child: _isLoadingOrders
                ? const Center(
                    child: CircularProgressIndicator(color: _primary),
                  )
                : _realOrders.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _fetchOrders,
                    color: _primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
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

  Widget _buildOrderCard(dynamic order) {
    final orderModel = OrderModel.fromJson(order);
    final int rawOrderId = orderModel.orderId ?? 0;
    final String orderId = rawOrderId.toString().padLeft(6, '0');

    String customerName = "ไม่ระบุชื่อลูกค้า";
    String finalImgUrl = "";

    if (orderModel.member != null) {
      final String firstName = orderModel.member?.firstname ?? "";
      final String lastName = orderModel.member?.lastname ?? "";
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        customerName = "$firstName $lastName".trim();
      }
      final String? rawImgPath = orderModel.member?.profileimg ?? "";
      finalImgUrl = _getFinalProfileImageUrl(rawImgPath);
    }

    int totalItems = 0;
    if (orderModel.items.isNotEmpty) {
      for (var item in orderModel.items) {
        totalItems += item.qty;
      }
    } else if (order["orderDetails"] != null && order["orderDetails"] is List) {
      for (var item in (order["orderDetails"] as List)) {
        totalItems += (item["qty"] as num?)?.toInt() ?? 1;
      }
    }

    String orderTimeText = "--:--";
    if (orderModel.orderdate != null) {
      final DateTime dateTime = orderModel.orderdate!;
      orderTimeText =
          "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} น.";
    }

    bool isReviewTab = _selectedTabIndex == 3;

    String buttonText = "ดูรายละเอียด";
    if (_selectedTabIndex == 0) {
      buttonText = "ดูรายละเอียด / รับออเดอร์";
    } else if (_selectedTabIndex == 1) {
      buttonText = "ดูสถานะออเดอร์";
    } else if (_selectedTabIndex == 2) {
      buttonText = "ดูรายละเอียด";
    } else if (isReviewTab) {
      buttonText = "ดูรีวิวจากลูกค้า";
    }

    final double cardRating =
        double.tryParse((order['reviewRating'] ?? 5.0).toString()) ?? 5.0;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openOrderDetail(orderModel, isReviewTab: isReviewTab),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: _primary.withOpacity(0.15),
                          backgroundImage: finalImgUrl.isNotEmpty
                              ? NetworkImage(finalImgUrl)
                              : null,
                          child: finalImgUrl.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 20,
                                  color: _primary,
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            customerName,
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
                          color: _accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (isReviewTab) ...[
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
              const SizedBox(height: 12),
            ],

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
                        "รายการอาหาร $totalItems รายการ",
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
                        "$orderTimeText",
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
                  onPressed: () =>
                      _openOrderDetail(orderModel, isReviewTab: isReviewTab),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
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

  Widget _buildEmptyState() {
    String emptyMessage = _selectedTabIndex == 0
        ? "ยังไม่มีคำสั่งซื้อใหม่เข้ามา"
        : _selectedTabIndex == 1
        ? "ไม่มีออเดอร์ที่ต้องเตรียม"
        : _selectedTabIndex == 2
        ? "ยังไม่มีประวัติคำสั่งซื้อสำเร็จ"
        : "ยังไม่มีรายการที่ได้รับการรีวิว";

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      color: _primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: _primary.withOpacity(0.4),
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
