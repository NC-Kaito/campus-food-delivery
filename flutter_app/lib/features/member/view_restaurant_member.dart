import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/features/member/list_menu_member.dart';
import 'package:flutter_app/features/user/list_menu_user.dart'; // เรียกใช้หน้าแสดงผลเมนูอาหาร

class ViewRestaurantMember extends StatefulWidget {
  final RestaurantModel
  restaurant; // 🎯 รับข้อมูลร้านค้าส่งต่อข้ามหน้าจอมาจากหน้าค้นหา
  const ViewRestaurantMember({super.key, required this.restaurant});

  @override
  State<ViewRestaurantMember> createState() => _ViewRestaurantMemberState();
}

class _ViewRestaurantMemberState extends State<ViewRestaurantMember> {
  // 🎯 ฟังก์ชันคำนวณแปลงค่าระบบ Bitwise เป็นข้อความวันเปิดให้บริการระดับเกรด A
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

  @override
  Widget build(BuildContext context) {
    // 🎯 กำหนดเลข IP ฐานประวัติโปรเจกต์คงที่ เพื่อล้างบั๊กสลับวง Wi-Fi อัตโนมัติ
    const String baseIp = "10.244.27.211";

    // เคลียร์และเข้ารหัสตัวแปร URL รูปแบนเนอร์ร้านค้าให้ปลอดภัยสูงสุด
    String safeImageUrl = "";
    if (widget.restaurant.restaurantImage != null &&
        widget.restaurant.restaurantImage!.isNotEmpty) {
      safeImageUrl = widget.restaurant.restaurantImage!
          .replaceAll("10.226.43.211", baseIp)
          .replaceAll("10.0.2.2", baseIp);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- ส่วนรูปภาพ Banner และปุ่ม Back ย้อนกลับ ---
            Stack(
              children: [
                safeImageUrl.isNotEmpty
                    ? Image.network(
                        Uri.encodeFull(
                          safeImageUrl,
                        ), // 🎯 เข้ารหัสช่องว่างแปลงรหัสอักขระพิเศษพาร์ทรูปภาพ
                        width: double.infinity,
                        height: 280,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholderBanner(),
                      )
                    : _buildPlaceholderBanner(),

                // ไล่ระดับเงา Gradient สีดำด้านล่างรูปเพื่อให้ตัวหนังสืออ่านง่ายขึ้น
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // ปุ่มลอยเด้งย้อนกลับสไตล์โมเดิร์น
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
                  // ชื่อร้านค้าตัวจริงจากฐานข้อมูล
                  Text(
                    widget.restaurant.restaurantName ??
                        "ร้านอาหารของมหาวิทยาลัย",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ป้ายแท็กสถานะร้านอาหารเปิดให้บริการแบบโมเดิร์น
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
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

                  // 🎯 ปุ่มนำทางดึงส่งข้อมูลร้านเปิดหน้าเมนูอาหารของร้านค้านั้น
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ListMenuMember(
                              restaurantModel: widget.restaurant,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.restaurant_menu,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "ดูเมนูอาหารทั้งหมด",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          Icons.phone,
                          "เบอร์โทรศัพท์",
                          widget.restaurant.phone ?? "ไม่ระบุเบอร์ติดต่อ",
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          Icons.category,
                          "ประเภทร้าน",
                          widget.restaurant.typerestaurantName ?? "อาหารทั่วไป",
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
                          "${widget.restaurant.openTime?.substring(0, 5) ?? '00:00'} - ${widget.restaurant.closeTime?.substring(0, 5) ?? '00:00'} น.",
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

  // ตัวช่วยสร้างกล่องแสดงผลข้อมูลพร้อมไอคอนวงกลมสีเขียวพาสเทล
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

  // ฟังก์ชันวาดภาพจำลองกรณีเชื่อมต่อเซิร์ฟเวอร์ดึงรูปต้นทางล้มเหลว
  Widget _buildPlaceholderBanner() {
    return Container(
      width: double.infinity,
      height: 280,
      color: Colors.grey[200],
      child: const Icon(Icons.restaurant, size: 80, color: Colors.grey),
    );
  }
}
