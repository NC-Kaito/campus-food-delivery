// features/restaurant/list_order_restaurant.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/order_model.dart';
import 'package:flutter_app/data/services/order_service.dart';
import 'package:flutter_app/features/restaurant/restaurant_navbar.dart';
import 'package:flutter_app/features/restaurant/view_order_restaurant.dart';
import 'package:flutter_app/global_data.dart';
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

  List<OrderModel> _allOrders = [];
  Timer? _autoRefreshTimer;

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

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  OrderModel _toOrderModel(dynamic item) {
    if (item is OrderModel) return item;
    if (item is Map<String, dynamic>) return OrderModel.fromJson(item);
    if (item is Map)
      return OrderModel.fromJson(Map<String, dynamic>.from(item));
    return OrderModel.fromJson({});
  }

  // 🎯 ดึงข้อมูลออเดอร์ของร้าน
  Future<void> _fetchOrders() async {
    setState(() => _isLoadingOrders = true);
    await _loadOrderData();
    if (mounted) setState(() => _isLoadingOrders = false);
  }

  Future<void> _fetchOrdersBackground() async {
    await _loadOrderData();
  }

  Future<void> _loadOrderData() async {
    try {
      String username = GlobalData.usernameRestaurant.trim();
      if (username.isEmpty) return;

      final rawWaiting = await _orderService.getWaitingOrdersByRestaurant(
        username,
      );
      final rawActive = await _orderService.getActiveOrdersByRestaurant(
        username,
      );

      List<dynamic> rawCancel = [];
      try {
        rawCancel = await _orderService.getcancelOrdersByRestaurant(username);
      } catch (_) {}

      List<dynamic> rawReview = [];
      try {
        rawReview = await _orderService.getReviewSuccessOrdersByRestaurant(
          username,
        );
      } catch (_) {}

      final Set<int> addedIds = {};
      final List<OrderModel> combinedList = [];

      for (var list in [rawWaiting, rawActive, rawCancel, rawReview]) {
        for (var item in list) {
          final model = _toOrderModel(item);
          if (model.orderId != null && !addedIds.contains(model.orderId)) {
            addedIds.add(model.orderId!);
            combinedList.add(model);
          }
        }
      }

      if (mounted) {
        setState(() {
          _allOrders = combinedList;
        });
      }
    } catch (e) {
      debugPrint("🚨 โหลดออเดอร์ร้านค้าล้มเหลว: $e");
    }
  }

  // 🎯 กรองสถานะเหมือนฟังก์ชัน _filterOrders ของ Member 100%
  List<OrderModel> _filterOrders(String type) {
    return _allOrders.where((order) {
      final status = (order.orderStatus ?? '').trim().toLowerCase();

      if (type == 'new') {
        // ออเดอร์ใหม่: รอร้านกดรับ
        return status == 'waitingrestaurant' || status == 'pending';
      } else if (type == 'preparing') {
        // ต้องเตรียม: กำลังทำ / รอไรเดอร์มารับ / กำลังส่ง
        return status == 'goingtorestaurant' ||
            status == 'going' ||
            status == 'rideraccepted' ||
            status == 'riderarrived' ||
            status == 'preparing' ||
            status == 'cooking' ||
            status == 'foodready' ||
            status == 'delivery' ||
            status == 'delivering' ||
            status == 'ontheway' ||
            status == 'pickedup' ||
            status == 'arrived' ||
            status == 'reached';
      } else if (type == 'success') {
        // จัดส่งสำเร็จ
        return status == 'delivered' ||
            status == 'success' ||
            status == 'completed';
      } else if (type == 'review') {
        // มีการรีวิวแล้ว
        return status == 'reviewsuccess';
      } else if (type == 'cancel') {
        // ยกเลิก หรือ แจ้งปัญหา
        return status == 'cancel' ||
            status == 'cancelled' ||
            status == 'issue_reported';
      }
      return true;
    }).toList();
  }

  List<OrderModel> get _currentOrders {
    if (_selectedTabIndex == 0) return _filterOrders('new');
    if (_selectedTabIndex == 1) return _filterOrders('preparing');
    if (_selectedTabIndex == 2) return _filterOrders('success');
    if (_selectedTabIndex == 3) return _filterOrders('review');
    if (_selectedTabIndex == 4) return _filterOrders('cancel');
    return [];
  }

  Future<void> _openOrderDetail(
    OrderModel orderModel, {
    bool isReviewTab = false,
  }) async {
    Widget targetPage;

    if (isReviewTab) {
      targetPage = review.ViewReviewRestaurant(orderModel: orderModel);
    } else {
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
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
                  fontSize: 11.5,
                ),
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                right: 2,
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
    final newCount = _filterOrders('new').length;
    final preparingCount = _filterOrders('preparing').length;
    final cancelCount = _filterOrders('cancel').length;
    final currentOrdersList = _currentOrders;

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
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildTab("ออเดอร์ใหม่", 0, badgeCount: newCount),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildTab("ต้องเตรียม", 1, badgeCount: preparingCount),
                ),
                const SizedBox(width: 6),
                Expanded(child: _buildTab("สำเร็จ", 2)),
                const SizedBox(width: 6),
                Expanded(child: _buildTab("รีวิว", 3)),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildTab("ยกเลิก", 4, badgeCount: cancelCount),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              "ทั้งหมด ${currentOrdersList.length} รายการ",
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
                : currentOrdersList.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _fetchOrders,
                    color: _primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: currentOrdersList.length,
                      itemBuilder: (context, index) {
                        return _buildOrderCard(currentOrdersList[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel orderModel) {
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
    for (var item in orderModel.items) {
      totalItems += item.qty;
    }

    String orderTimeText = "--:--";
    if (orderModel.orderdate != null) {
      final DateTime dateTime = orderModel.orderdate!;
      orderTimeText =
          "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} น.";
    }

    bool isReviewTab = _selectedTabIndex == 3;
    bool isCancelTab = _selectedTabIndex == 4;

    String buttonText = "ดูรายละเอียด";
    if (_selectedTabIndex == 0) {
      buttonText = "ดูรายละเอียด / รับออเดอร์";
    } else if (_selectedTabIndex == 1) {
      buttonText = "ดูสถานะออเดอร์";
    } else if (_selectedTabIndex == 2) {
      buttonText = "ดูรายละเอียด";
    } else if (isReviewTab) {
      buttonText = "ดูรีวิวจากลูกค้า";
    } else if (isCancelTab) {
      buttonText = "ดูเหตุผลการยกเลิก";
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openOrderDetail(orderModel, isReviewTab: isReviewTab),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isCancelTab
              ? const Color(0xFFFFEBEE)
              : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCancelTab ? Colors.red.shade200 : Colors.grey.shade300,
          ),
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
                          backgroundColor: isCancelTab
                              ? Colors.red.withOpacity(0.15)
                              : _primary.withOpacity(0.15),
                          backgroundImage: finalImgUrl.isNotEmpty
                              ? NetworkImage(finalImgUrl)
                              : null,
                          child: finalImgUrl.isEmpty
                              ? Icon(
                                  Icons.person,
                                  size: 20,
                                  color: isCancelTab ? Colors.red : _primary,
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
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isCancelTab ? Colors.red : _accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (isCancelTab &&
                orderModel.cancelDetail != null &&
                orderModel.cancelDetail!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "สาเหตุ: ${orderModel.cancelDetail}",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
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
                    backgroundColor: isCancelTab
                        ? Colors.red.shade600
                        : _primary,
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
        : _selectedTabIndex == 3
        ? "ยังไม่มีรายการที่ได้รับการรีวิว"
        : "ไม่มีรายการคำสั่งซื้อที่ถูกยกเลิก";

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
            color: _selectedTabIndex == 4
                ? Colors.red.withOpacity(0.4)
                : _primary.withOpacity(0.4),
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
