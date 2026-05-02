import 'package:flutter/material.dart';
import 'package:flutter_app/features/restaurant/agrees_restaurant.dart';

class LoginRestaurant extends StatefulWidget {
  const LoginRestaurant({super.key});

  @override
  State<LoginRestaurant> createState() => _LoginRestaurantState();
}

class _LoginRestaurantState extends State<LoginRestaurant> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // เพิ่มสีพื้นหลังให้อ่อนๆ ดูสะอาดตา
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        // กันหน้าจอค้างเวลามีคีย์บอร์ดเด้งขึ้นมา
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 80),
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ส่วนของ Logo หรือ Icon จำลอง
                const Icon(
                  Icons.restaurant_menu,
                  size: 80,
                  color: Colors.green,
                ),
                const SizedBox(height: 10),
                const Text(
                  'ยินดีต้อนรับ',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Text(
                  'เข้าสู่ระบบร้านค้า MJU Delivery',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // ช่องกรอกชื่อผู้ใช้
                TextFormField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "กรุณากรอกชื่อผู้ใช้",
                    labelText: "ชื่อผู้ใช้ (Username)",
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none, // ซ่อนเส้นขอบปกติ
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ช่องกรอกรหัสผ่าน
                TextFormField(
                  obscureText: true, // ปิดบังรหัสผ่าน
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline),
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "กรุณากรอกรหัสผ่าน",
                    labelText: "รหัสผ่าน (Password)",
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // ปุ่มเข้าสู่ระบบ (เด่นสุด)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () {},
                    child: const Text(
                      "เข้าสู่ระบบ",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // ปุ่มสมัครสมาชิก (รองลงมา)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext buildContext) {
                            return AgreesRestaurant();
                          },
                        ),
                      );
                    },
                    child: const Text(
                      "สมัครสมาชิก",
                      style: TextStyle(fontSize: 18, color: Colors.green),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
