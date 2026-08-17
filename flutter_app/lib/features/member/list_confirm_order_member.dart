// features/member/list_confirm_order_member.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/order_model.dart';
import 'package:flutter_app/data/services/order_service.dart';
import 'package:flutter_app/features/member/list_order_member.dart';
import 'package:flutter_app/features/member/member_review.dart';
import 'package:flutter_app/features/member/view_confirm_order_member.dart';
import 'package:flutter_app/features/member/navbar_member.dart';
import 'package:flutter_app/features/member/profile_member.dart';
import 'package:flutter_app/features/member/cart_manager_member.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/global_data.dart';

class ListConfirmOrderMember extends StatefulWidget {
  const ListConfirmOrderMember({super.key});

  @override
  State<ListConfirmOrderMember> createState() => _ListConfirmOrderMemberState();
}

class _ListConfirmOrderMemberState extends State<ListConfirmOrderMember> {
  final OrderService _orderService = OrderService();
  List<OrderModel> _orderHistoryList = [];
  bool _isLoading = true;

  final menuTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Colors.green[700],
  );

  @override
  void initState() {
    super.initState();
    _fetchOrderHistory();
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

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;

    final String baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/') ? "$baseUrl$rawPath" : "$baseUrl/$rawPath";
  }

  Map<String, dynamic> _getDetailedStatusInfo(String? rawStatus) {
    final status = (rawStatus ?? '').trim();

    switch (status) {
      case 'WaitingRider':
        return {
          'text': 'รอผู้จัดส่งรับงาน',
          'color': Colors.orange[800]!,
          'bgColor': Colors.orange[50]!,
          'icon': Icons.directions_bike_rounded,
        };
      case 'WaitingRestaurant':
        return {
          'text': 'รอร้านค้ายืนยัน',
          'color': Colors.blue[800]!,
          'bgColor': Colors.blue[50]!,
          'icon': Icons.storefront_rounded,
        };
      case 'Cooking':
      case 'Preparing':
        return {
          'text': 'ร้านกำลังปรุงอาหาร',
          'color': Colors.deepOrange[800]!,
          'bgColor': Colors.deepOrange[50]!,
          'icon': Icons.soup_kitchen_rounded,
        };
      case 'delivery':
      case 'OnTheWay':
        return {
          'text': 'กำลังจัดส่ง',
          'color': Colors.indigo[800]!,
          'bgColor': Colors.indigo[50]!,
          'icon': Icons.local_shipping_rounded,
        };
      case 'Success':
      case 'Completed':
        return {
          'text': 'จัดส่งสำเร็จแล้ว',
          'color': Colors.green[800]!,
          'bgColor': Colors.green[50]!,
          'icon': Icons.check_circle_rounded,
        };
      case 'Cancel':
      case 'Cancelled':
        return {
          'text': 'ยกเลิกคำสั่งซื้อแล้ว',
          'color': Colors.red[800]!,
          'bgColor': Colors.red[50]!,
          'icon': Icons.cancel_rounded,
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

      bool isReviewed = false;

      if (type == 'pending') {
        return status != 'success' &&
            status != 'completed' &&
            status != 'cancel' &&
            status != 'cancelled';
      } else if (type == 'success') {
        return (status == 'success' || status == 'completed') && !isReviewed;
      } else if (type == 'history') {
        return (status == 'success' || status == 'completed') && isReviewed;
      } else if (type == 'cancel') {
        return status == 'cancel' || status == 'cancelled';
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
                // 🎯 เอา isScrollable: true ออก เพื่อให้มันแบ่งพื้นที่เท่าๆ กัน 4 ส่วน
                indicatorColor: const Color(0xFF64F02D),
                indicatorWeight: 3,
                labelColor: const Color(0xFF2E7D32),
                unselectedLabelColor: Colors.grey[600],
                // 🎯 ลด Padding ภายในลง เพื่อให้คำยาวๆ แสดงได้ครบโดยไม่ตกบรรทัด
                labelPadding: EdgeInsets.zero,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13, // 🎯 ปรับขนาดอักษรลงนิดนึงให้ดูลงตัวและพอดีกรอบ
                ),
                tabs: const [
                  Tab(text: "กำลังดำเนินการ"),
                  Tab(text: "สำเร็จแล้ว"),
                  Tab(text: "ประวัติคำสั่งซื้อ"),
                  Tab(text: "ยกเลิก"),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    )
                  : TabBarView(
                      children: [
                        _buildOrderListView(
                          _filterOrders('pending'),
                          "ไม่มีคำสั่งซื้อที่กำลังดำเนินการ",
                        ),
                        _buildOrderListView(
                          _filterOrders('success'),
                          "ไม่มีคำสั่งซื้อรอรีวิว",
                        ),
                        _buildOrderListView(
                          _filterOrders('history'),
                          "ยังไม่มีประวัติคำสั่งซื้อ",
                        ),
                        _buildOrderListView(
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
                  _buildNavItem(Icons.person, "โปรไฟล์", () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileMember(),
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

    final bool isCompleted =
        order.orderStatus?.toLowerCase() == 'success' ||
        order.orderStatus?.toLowerCase() == 'completed';

    bool isReviewed = false;

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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewConfirmOrderMember(order: order),
            ),
          ).then((_) {
            _fetchOrderHistory();
          });
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
                    Text(
                      "รหัสบิล: #${order.orderId ?? '-'}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (isReviewed) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'กำลังพัฒนาหน้าแสดงผลการรีวิว...',
                                  ),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MemberReview(order: order),
                                ),
                              ).then((_) {
                                _fetchOrderHistory();
                              });
                            }
                          },
                          icon: Icon(
                            isReviewed
                                ? Icons.rate_review_rounded
                                : Icons.star_rounded,
                            size: 18,
                            color: isReviewed ? Colors.blue : Colors.orange,
                          ),
                          label: Text(
                            isReviewed ? "ดูการรีวิว" : "รีวิวคำสั่งซื้อ",
                            style: TextStyle(
                              fontSize: 13,
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
                          ),
                        ),
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
}
