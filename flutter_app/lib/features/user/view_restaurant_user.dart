// features/user/view_restaurant_user.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/features/user/list_menu_user.dart';

class ViewRestaurantUser extends StatefulWidget {
  final RestaurantModel restaurant; // รับข้อมูลร้านค้า
  const ViewRestaurantUser({super.key, required this.restaurant});

  @override
  State<ViewRestaurantUser> createState() => _ViewRestaurantUserState();
}

class _ViewRestaurantUserState extends State<ViewRestaurantUser> {
  // 🎯 ปรับปรุงฟังก์ชันแปลงค่าระบบ Bitwise ให้ตรงล็อกมาตรฐานชุดเดียวกัน
  String _parseOpenDays(int? dayMask) {
    if (dayMask == null) return "จันทร์ - เสาร์";
    if (dayMask == 127) return "เปิดทุกวัน";
    if (dayMask == 126) return "จันทร์ - เสาร์";
    if (dayMask == 62) return "จันทร์ - ศุกร์";
    return "จันทร์ - เสาร์";
  }

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
    final String finalImageUrl = _getFinalImageUrl(
      widget.restaurant.restaurantImage,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar:
          true, // 🎯 ดึงให้รูปแบนเนอร์ทะลุขึ้นไปด้านบนสุดเหมือนหน้า Member 100%
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ─── ส่วนหัวรูปภาพ (Stack โดนแกะโครงสร้างมาจาก Member 100%) ───
            Stack(
              children: [
                Container(
                  height: 290,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(0),
                      bottomRight: Radius.circular(0),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(0),
                      bottomRight: Radius.circular(0),
                    ),
                    child: finalImageUrl.isNotEmpty
                        ? Image.network(
                            Uri.encodeFull(finalImageUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholderBackground(),
                          )
                        : _buildPlaceholderBackground(),
                  ),
                ),

                // ปุ่มย้อนกลับลอยตัวสไตล์โมเดิร์นคุมโทนพรีเมียม
                Positioned(
                  top: 45,
                  left: 15,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.85),
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.black87,
                        size: 18,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),

            // ─── ส่วนเนื้อหาข้อมูล (ใช้โครงสร้าง Transform.translate ดันขึ้นไปทับแบนเนอร์เหมือน Member) ───
            Transform.translate(
              offset: const Offset(0, -25),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),

                    // ชื่อร้านค้าขนาดเต็มตา 32px สมมาตร
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            widget.restaurant.restaurantName ?? "-",
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // หัวข้อเมนูแนะนำ
                    const Text(
                      "เมนูแนะนำ",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // การ์ดเมนูแนะนำพร้อมเงาละมุนตา
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              'https://images.unsplash.com/photo-1617093727343-374698b1b08d?q=80&w=200',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.fastfood,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "คะน้าหมูกรอบ",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                "ราคา 40 บาท",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    // ตัวจุดนำทางสามจุดล่างการ์ดแนะนำ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // 🎯 ปุ่มแถบสีเขียวสปอร์ตตัวแรงตัวใหม่ ปลดล็อกเปิดหน้าเมนูอาหาร
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFF64F02D,
                                ), // 🎯 พ่นสีเขียวใหม่สปอร์ตเข้าเซ็ตระบบคราบบบ
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ListMenuUser(
                                      restaurantModel: widget.restaurant,
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                "ดูเมนูอาหารทั้งหมด",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // ─── ตารางข้อมูลรายละเอียดร้านแบบแบ่งฝั่งเส้นคั่นตรงกลาง ถอดพิมพ์เขียวมาจาก Member ───
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _buildInfoRow(
                                Icons.storefront,
                                "ชื่อร้านค้า",
                                widget.restaurant.restaurantName ?? "-",
                              ),
                              const SizedBox(height: 20),
                              _buildInfoRow(
                                Icons.shopping_cart_outlined,
                                "วันทำการ",
                                _parseOpenDays(widget.restaurant.openDay),
                              ),
                              const SizedBox(height: 20),
                              _buildInfoRow(
                                Icons.phone_in_talk_outlined,
                                "เบอร์โทรศัพท์",
                                widget.restaurant.phone ?? "-",
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 2,
                          height: 190,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            children: [
                              _buildInfoRow(
                                Icons.restaurant_menu,
                                "ประเภทร้านค้า",
                                widget.restaurant.typerestaurantName ??
                                    "อาหารตามสั่ง",
                              ),
                              const SizedBox(height: 20),
                              _buildInfoRow(
                                Icons.access_time,
                                "เวลาเปิด - ปิด",
                                "${widget.restaurant.openTime?.substring(0, 5) ?? '00:00'} - ${widget.restaurant.closeTime?.substring(0, 5) ?? '00:00'} น.",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 28, color: Colors.black),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderBackground() {
    return Container(
      color: const Color(0xFFD92D2D),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 80, color: Colors.white),
      ),
    );
  }
}
