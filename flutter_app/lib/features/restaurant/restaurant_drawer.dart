import 'package:flutter/material.dart';
import 'package:flutter_app/features/restaurant/home_restaurant.dart';

class RestaurantDrawer extends StatelessWidget {
  const RestaurantDrawer({super.key});

  static const Color _orange = Color(0xFFFF8C00);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(height: 10),
            _buildMenuItem(
              context: context,
              icon: Icons.home_rounded,
              iconColor: _orange,
              text: "หน้าหลัก",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeRestaurant(),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            _buildMenuItem(
              context: context,
              icon: Icons.description_outlined,
              iconColor: _orange,
              text: "ข้อตกลงและเงื่อนไขการยินยอม",
              onTap: () {
                Navigator.pop(context);
                // TODO: ไปหน้าข้อตกลงและเงื่อนไข
              },
            ),
            const Divider(height: 1),
            _buildMenuItem(
              context: context,
              icon: Icons.cancel_outlined,
              iconColor: Colors.red,
              text: "ปิดบัญชีผู้ใช้",
              onTap: () {
                Navigator.pop(context);
                // TODO: จัดการปิดบัญชีผู้ใช้
              },
            ),
            const Divider(height: 1),
            _buildMenuItem(
              context: context,
              icon: Icons.logout_rounded,
              iconColor: _orange,
              text: "ออกจากระบบ",
              onTap: () {
                Navigator.pop(context);
                // TODO: จัดการออกจากระบบ (เคลียร์ session/token แล้ว push ไปหน้า login)
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 26),
      title: Text(
        text,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
      ),
      onTap: onTap,
    );
  }
}
