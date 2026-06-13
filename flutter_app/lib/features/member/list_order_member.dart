// features/member/list_order_member.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/features/member/cart_manager_member.dart';
import 'package:flutter_app/features/member/view_order_member.dart';
import 'package:flutter_app/core/network/dio_client.dart'; // 🎯 อิมพอร์ตตัวแปรกลางเพื่อดึงข้อมูลสลักไอพีล่าสุด

class ListOrderMember extends StatefulWidget {
  const ListOrderMember({super.key});

  @override
  State<ListOrderMember> createState() => _ListOrderMemberState();
}

class _ListOrderMemberState extends State<ListOrderMember> {
  late Map<String, List<CartItem>> _groupedCart;

  @override
  void initState() {
    super.initState();
    // ดึงข้อมูลรายการอาหารในตะกร้าที่จัดกลุ่มตามร้านค้า
    _groupedCart = CartManager().getGroupedByStore();
  }

  // 🎯 ฟังก์ชันช่วยต่อหัวเชื่อมต่อรูปภาพร้านค้า ป้องกันลิงก์ชิดติดกันจนพังหน้าจอ
  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http'))
      return rawPath; // รองรับข้อมูลเก่าที่เป็นลิงก์เต็มสาย

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.home_outlined, color: Colors.green, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "ตะกร้ารายการอาหาร",
          style: TextStyle(
            color: Colors.green,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.shopping_cart,
              color: Colors.green,
              size: 28,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Colors.green,
              size: 28,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
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
                // ดึง username ออกมาจากคีย์หลักของกลุ่มตะกร้า
                String storeUsername = _groupedCart.keys.elementAt(index);
                List<CartItem> storeItems = _groupedCart[storeUsername]!;

                // ดึงชื่อร้านจากโมเดลความสัมพันธ์ของรายการอาหารตัวแรก
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
    );
  }

  Widget _buildStoreCartCard(
    String storeUsername,
    String storeName,
    List<CartItem> storeItems,
  ) {
    // คำนวณจำนวนชิ้นทั้งหมดในร้านนี้
    int totalItemsInStore = 0;
    for (var item in storeItems) {
      totalItemsInStore += item.quantity;
    }

    // ดึงรูปโปรไฟล์ของร้านค้าจากไอเทมแรกในตะกร้า
    String? rawRestaurantImage =
        storeItems.first.menu.restaurant?.restaurantImage;

    // 🎯 ประกอบร่างพาร์ทรูปสั้นให้เป็น URL ตัวเต็มที่สวมไอพีปัจจุบันผ่านฟังก์ชันกลาง
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

          // เมื่อผู้ใช้กด ย้อนกลับ กลับมาจากหน้า ViewOrderMember ให้รีเฟรชตะกร้าใหม่ล่าสุด
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
                        Uri.encodeFull(
                          finalImageUrl,
                        ), // ✅ เรียกใช้งานผ่าน URL ที่สลับไอพีได้อิสระ
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
