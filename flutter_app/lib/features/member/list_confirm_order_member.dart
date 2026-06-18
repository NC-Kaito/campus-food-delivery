// features/member/list_confirm_order_member.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/order_model.dart';
import 'package:flutter_app/data/services/order_service.dart';
import 'package:flutter_app/features/member/list_order_member.dart';
import 'package:flutter_app/features/member/view_confirm_order_member.dart';
import 'package:flutter_app/features/member/view_order_member.dart';
import 'package:flutter_app/features/member/navbar_member.dart';
import 'package:flutter_app/features/member/profile_member.dart';
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
      String username = GlobalData.usernameMember;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const NavbarMember(title: "ประวัติคำสั่งซื้อ"),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _orderHistoryList.isEmpty
          ? const Center(
              child: Text(
                "ไม่มีรายการคำสั่งซื้อในฐานข้อมูล",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 15.0,
              ),
              itemCount: _orderHistoryList.length,
              itemBuilder: (context, index) {
                return _buildOrderHistoryCard(_orderHistoryList[index]);
              },
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
                }),
                _buildNavItem(Icons.list_alt, "คำสั่งซื้อ", () {
                  _fetchOrderHistory();
                }, isActive: true),
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
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? Colors.green : Colors.grey),
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

    // 🎯 ดึงชื่อร้านค้าและรูปภาพทะลุผ่าน RestaurantModel ตัวใหม่
    String storeName =
        order.restaurant?.restaurantName ?? order.restaurantUsername;
    String finalImageUrl = _getFinalImageUrl(order.restaurant?.restaurantImage);

    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FCD0),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
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
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
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
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      storeName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                            fontSize: 15,
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
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.green,
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
