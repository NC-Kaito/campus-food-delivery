// features/member/list_order_member.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/features/member/cart_manager_member.dart';
import 'package:flutter_app/features/member/list_active_order_member.dart';
import 'package:flutter_app/features/member/view_order_member.dart';
import 'package:flutter_app/features/member/navbar_member.dart';
import 'package:flutter_app/features/member/profile_member.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/services/order_service.dart'; // 🎯 นำเข้า OrderService
import 'package:flutter_app/global_data.dart'; // 🎯 นำเข้า GlobalData เพื่อใช้ดึงชื่อผู้ใช้

class ListOrderMember extends StatefulWidget {
  const ListOrderMember({super.key});

  @override
  State<ListOrderMember> createState() => _ListOrderMemberState();
}

class _ListOrderMemberState extends State<ListOrderMember> {
  late Map<String, List<CartItem>> _groupedCart;
  final OrderService _orderService =
      OrderService(); // 🎯 สร้าง Instance ของ OrderService
  int _activeOrderCount = 0; // 🎯 ตัวแปรเก็บจำนวนออเดอร์ที่กำลังดำเนินการ

  // สไตล์ข้อความของเมนูด้านล่าง (เหมือนกับหน้า Home)
  final menuTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Colors.green[700],
  );

  @override
  void initState() {
    super.initState();
    // ดึงข้อมูลรายการอาหารในตะกร้าที่จัดกลุ่มตามร้านค้า
    _groupedCart = CartManager().getGroupedByStore();
    _fetchActiveOrderCount(); // 🎯 เรียกดึงข้อมูลจำนวนคำสั่งซื้อเมื่อเปิดหน้า
  }

  // 🎯 ฟังก์ชันช่วยต่อหัวเชื่อมต่อรูปภาพร้านค้า ป้องกันลิงก์ชิดติดกันจนพังหน้าจอ
  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;

    final String baseUrl = DioClient.dio.options.baseUrl;
    if (rawPath.startsWith('/')) {
      return "$baseUrl$rawPath";
    } else {
      return "$baseUrl/$rawPath";
    }
  }

  // 🎯 ฟังก์ชันดึงจำนวน "คำสั่งซื้อที่กำลังดำเนินการ"
  Future<void> _fetchActiveOrderCount() async {
    try {
      String username = GlobalData.usernameMember.trim();
      if (username.isEmpty) return;

      final history = await _orderService.getConfirmOrdersByMember(username);

      int count = 0;
      for (var order in history) {
        final status = (order.orderStatus ?? '').toLowerCase();
        // คัดกรองเฉพาะออเดอร์ที่ยังไม่เสร็จสิ้น หรือ ยังไม่ถูกยกเลิก
        if (status != 'success' &&
            status != 'completed' &&
            status != 'cancel' &&
            status != 'cancelled') {
          count++;
        }
      }

      if (mounted) {
        setState(() {
          _activeOrderCount = count;
        });
      }
    } catch (e) {
      debugPrint("เกิดข้อผิดพลาดในการโหลดจำนวนออเดอร์หน้าตะกร้า: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final int cartItemCount =
        CartManager().items.length; // 🎯 จำนวนตะกร้าปัจจุบัน

    return Scaffold(
      backgroundColor: Colors.white,
      // 🌟 แถบ Navbar บน (เหมือนหน้า Home)
      appBar: const NavbarMember(title: "รายการอาหาร"),
      body: _groupedCart.isEmpty
          ? const Center(
              child: Text(
                "ไม่มีรายการอาหารในตะกร้า",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 15.0,
              ),
              itemCount: _groupedCart.keys.length,
              itemBuilder: (context, index) {
                String storeUsername = _groupedCart.keys.elementAt(index);
                List<CartItem> storeItems = _groupedCart[storeUsername]!;

                String storeName =
                    storeItems.first.menu.restaurant?.restaurantName ??
                    storeUsername;

                return _buildStoreCartCard(
                  storeUsername,
                  storeName,
                  storeItems,
                );
              },
            ),

      // 🌟 Bottom Navigation Bar
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
                  // กดย้อนกลับไปหน้าหลัก (เพื่อป้องกันการเปิดหน้าซ้อนกันเรื่อยๆ)
                  Navigator.popUntil(context, (route) => route.isFirst);
                }),
                _buildNavItem(
                  Icons.shopping_basket,
                  "ตะกร้าอาหาร",
                  () {
                    // อยู่หน้านี้อยู่แล้ว รีเฟรชข้อมูลตะกร้าล่าสุด
                    setState(() {
                      _groupedCart = CartManager().getGroupedByStore();
                    });
                  },
                  isActive: true,
                  badgeCount: cartItemCount, // 🎯 เพิ่ม Badge ตะกร้า
                ),
                _buildNavItem(
                  Icons.list_alt,
                  "คำสั่งซื้อ",
                  () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ListConfirmOrderMember(),
                      ),
                    );
                  },
                  badgeCount:
                      _activeOrderCount, // 🎯 เพิ่ม Badge ออเดอร์ที่กำลังดำเนินการ
                ),
                _buildNavItem(Icons.person, "โปรไฟล์", () {
                  // กดเปิดหน้า Profile สมาชิก
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

  // 🌟 ฟังก์ชันสำหรับสร้างปุ่มไอเทมเมนู (อัปเดตให้รองรับ badgeCount เหมือนหน้า Home)
  Widget _buildNavItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isActive = false,
    int badgeCount = 0, // 🎯 รับค่า badgeCount
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

  Widget _buildStoreCartCard(
    String storeUsername,
    String storeName,
    List<CartItem> storeItems,
  ) {
    int totalItemsInStore = 0;
    for (var item in storeItems) {
      totalItemsInStore += item.quantity;
    }

    String? rawRestaurantImage =
        storeItems.first.menu.restaurant?.restaurantImage;

    final String finalImageUrl = _getFinalImageUrl(rawRestaurantImage);

    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FCD0), // สีพื้นหลังการ์ด
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
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewOrderMember(
                storeUsername: storeUsername,
                storeName: storeName,
                storeItems: storeItems,
              ),
            ),
          );

          setState(() {
            _groupedCart = CartManager().getGroupedByStore();
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // 1. รูปภาพร้านค้า
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: finalImageUrl.isNotEmpty
                    ? Image.network(
                        Uri.encodeFull(finalImageUrl),
                        width: 75,
                        height: 75,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholderIcon(),
                      )
                    : _buildPlaceholderIcon(),
              ),
              const SizedBox(width: 16),

              // 2. ข้อมูลชื่อร้านและจำนวนรายการ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    const SizedBox(height: 6),
                    Text(
                      "จำนวน $totalItemsInStore รายการ",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 🌟 3. ปุ่ม/ไอคอน นำทางบอกให้รู้ว่ากดสั่งอาหารได้
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "สั่งอาหาร",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 14,
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

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 75,
      height: 75,
      color: Colors.orange[50],
      child: const Icon(Icons.store, color: Colors.orange, size: 36),
    );
  }
}
