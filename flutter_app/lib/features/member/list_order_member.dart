// features/member/list_order_member.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/features/member/cart_manager_member.dart';
import 'package:flutter_app/features/member/list_confirm_order_member.dart';
import 'package:flutter_app/features/member/view_order_member.dart';
import 'package:flutter_app/features/member/navbar_member.dart';
import 'package:flutter_app/features/member/profile_member.dart'; // 🌟 อิมพอร์ตเพิ่มเพื่อใช้ในลิงก์ Navbar ล่าง
import 'package:flutter_app/core/network/dio_client.dart';

class ListOrderMember extends StatefulWidget {
  const ListOrderMember({super.key});

  @override
  State<ListOrderMember> createState() => _ListOrderMemberState();
}

class _ListOrderMemberState extends State<ListOrderMember> {
  late Map<String, List<CartItem>> _groupedCart;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 🌟 แถบ Navbar บน (เหมือนหน้า Home)
      appBar: const NavbarMember(title: "รายการอาหาร"),
      body: _groupedCart.isEmpty
          ? const Center(
              child: Text(
                "ไม่มีรายการอาหารใน",
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

      // 🌟 1. เพิ่ม Bottom Navigation Bar ของหน้า Home เข้ามาประกบที่นี่
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
                ), // 🎯 ตั้งค่าให้ปุ่มตะกร้าทำงานและเป็นสีเขียว
                _buildNavItem(Icons.list_alt, "คำสั่งซื้อ", () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ListConfirmOrderMember(),
                    ),
                  );
                }),
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

  // 🌟 2. เพิ่มฟังก์ชันสำหรับสร้างปุ่มไอเทมเมนู (Copy มาจากหน้า Home เป๊ะๆ)
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
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "จำนวน $totalItemsInStore รายการ",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
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
      width: 80,
      height: 80,
      color: Colors.orange[50],
      child: const Icon(Icons.store, color: Colors.orange, size: 40),
    );
  }
}
