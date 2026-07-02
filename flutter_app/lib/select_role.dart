import 'package:flutter/material.dart';
import 'package:flutter_app/features/restaurant/login_restaurant.dart';
import 'package:flutter_app/features/rider/login_rider.dart';
import 'package:flutter_app/features/user/home_user.dart';

class SelectRolePage extends StatelessWidget {
  const SelectRolePage({super.key});

  // 🎯 สีเขียวประจำโปรเจกต์
  final Color primaryGreen = const Color(0xFF64F02D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 1),
              // --- หัวข้อ ---
              const Text(
                "ยินดีต้อนรับสู่\nCampus Delivery",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "เลือกสถานะการใช้งานของคุณ",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const Spacer(flex: 1),

              // --- กลุ่มปุ่มตัวเลือก (ใช้ Card แทนปุ่มธรรมดา) ---
              _buildRoleCard(
                context,
                "ผู้ใช้งานทั่วไป",
                Icons.person_outline,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeUser()),
                ),
              ),
              const SizedBox(height: 16),

              _buildRoleCard(
                context,
                "ร้านค้า",
                Icons.store_mall_directory_outlined,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginRestaurant()),
                ),
              ),
              const SizedBox(height: 16),

              _buildRoleCard(
                context,
                "ไรเดอร์",
                Icons.delivery_dining_outlined,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginRider()),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  // 🛠️ ปรับสไตล์ Card ให้ดูนูนและมีไอคอน เพิ่มลูกเล่นด้วย InkWell
  Widget _buildRoleCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.black87, size: 30),
                ),
                const SizedBox(width: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
