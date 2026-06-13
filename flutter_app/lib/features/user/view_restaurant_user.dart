import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/features/user/list_menu_user.dart';
// import 'package:flutter_app/features/menu/list_menu_restaurant.dart'; // แก้ Path ตามจริง

class ViewRestaurantUser extends StatefulWidget {
  final RestaurantModel restaurant; // รับข้อมูลร้านค้า
  const ViewRestaurantUser({super.key, required this.restaurant});

  @override
  State<ViewRestaurantUser> createState() => _ViewRestaurantUserState();
}

class _ViewRestaurantUserState extends State<ViewRestaurantUser> {
  // ฟังก์ชันแปลงเลข Bitwise เป็นชื่อวัน (เหมือนหน้า Search)
  String _getOpenDayText(int? bitwiseValue) {
    if (bitwiseValue == null || bitwiseValue == 0) return "ไม่ระบุวันเปิด";
    if (bitwiseValue == 127) return "เปิดทุกวัน";
    List<String> days = [];
    final dayMap = {
      1: "อา.",
      2: "จ.",
      4: "อ.",
      8: "พ.",
      16: "พฤ.",
      32: "ศ.",
      64: "ส.",
    };
    dayMap.forEach((key, value) {
      if ((bitwiseValue & key) != 0) days.add(value);
    });
    return days.join(', ');
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath; // ดักรองรับกรณีข้อมูลเก่า

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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- ส่วนรูปภาพ Banner และปุ่ม Back ---
            Stack(
              children: [
                Image.network(
                  Uri.encodeFull(finalImageUrl),
                  width: double.infinity,
                  height: 280,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 280,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.restaurant,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
                ),
                // ไล่เฉดสีดำด้านล่างรูปเพื่อให้ชื่อร้านสีขาวอ่านง่ายขึ้น (ถ้าต้องการ)
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 45,
                  left: 15,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.9),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.green),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ชื่อร้านค้า
                  Text(
                    widget.restaurant.restaurantName ?? "ชื่อร้านค้า",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // แสดงสถานะเปิด-ปิด แบบเก๋ๆ
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "● กำลังเปิดให้บริการ",
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ปุ่มดูเมนู
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
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
                      icon: const Icon(
                        Icons.restaurant_menu,
                        color: Colors.white,
                      ),
                      label: const Text("ดูเมนูอาหารทั้งหมด"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Divider(thickness: 1),
                  const SizedBox(height: 15),

                  // --- ส่วนข้อมูลรายละเอียดร้านค้า ---
                  const Text(
                    "รายละเอียดร้านค้า",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          Icons.phone,
                          "เบอร์โทรศัพท์",
                          widget.restaurant.phone ?? "ไม่ระบุ",
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          Icons.category,
                          "ประเภทร้าน",
                          widget.restaurant.typerestaurantName ?? "ไม่ระบุ",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          Icons.calendar_month,
                          "วันทำการ",
                          _getOpenDayText(widget.restaurant.openDay),
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          Icons.access_time_filled,
                          "เวลาเปิด - ปิด",
                          "${widget.restaurant.openTime?.substring(0, 5)} - ${widget.restaurant.closeTime?.substring(0, 5)} น.",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[50],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Colors.green[700]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
