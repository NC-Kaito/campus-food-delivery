import 'package:flutter/material.dart';
import 'package:flutter_app/features/restaurant/login_restaurant.dart';
import 'package:flutter_app/features/rider/login_rider.dart';
import 'package:flutter_app/features/user/home_user.dart';

class SelectRolePage extends StatelessWidget {
  const SelectRolePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // พื้นหลังแอปสีขาวสะอาดตา
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- ข้อความหัวข้อ ---
                const Text(
                  "เลือกดู",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 35),

                // --- กลุ่มปุ่มตัวเลือกผู้ใช้งาน ---
                _buildRoleButton(context, "User", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeUser()),
                  );
                }),
                const SizedBox(height: 25), // ระยะห่างระหว่างปุ่มตามแบบ Figma

                _buildRoleButton(context, "Restaurant", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginRestaurant()),
                  );
                }),
                const SizedBox(height: 25),

                _buildRoleButton(context, "Rider", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginRider()),
                  );
                }),
                // const SizedBox(height: 25),

                // _buildRoleButton(context, "Admin", () {
                //   // TODO: Navigator.push ไปหน้าของ Admin
                // }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🛠️ ฟังก์ชันสำหรับสร้างปุ่มตัวเลือกแบบกำหนดสไตล์ครั้งเดียวใช้ร่วมกันได้ทุกปุ่ม
  Widget _buildRoleButton(
    BuildContext context,
    String title,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity, // ขยายให้กว้างเต็มพื้นที่ตาม Padding ที่กำหนดไว้
      height: 85, // ความสูงปุ่มสี่เหลี่ยมผืนผ้าตามสัดส่วนภาพต้นแบบ
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDC0000).withOpacity(
            0.12,
          ), // สีเทาอมอ่อนพาสเทลตาม Layout (ดีฟอลต์ใช้สเปกสีใกล้เคียง #E0E0E0 หรือเทาอ่อนพื้นฐาน)
          // หมายเหตุ: หากต้องการสีเทาแบบในภาพเป๊ะๆ สามารถเปลี่ยนใช้: const Color(0xFFD9D9D9) ได้ครับ
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4), // ปรับขอบมนเล็กน้อยตามภาพ
          ),
        ),
        onPressed: onTap,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w500, // ความหนาตัวอักษรกำลังดีอ่านง่าย
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
