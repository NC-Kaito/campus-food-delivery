import 'package:flutter/material.dart';
import 'package:flutter_app/features/admin/home_admin.dart';
import 'package:flutter_app/features/admin/list_restaurant.dart';

class AdminNavbar extends StatelessWidget implements PreferredSizeWidget {
  const AdminNavbar({super.key});

  static const Color _orange = Color(0xFFFF8C00);

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 233, 233, 233),
      elevation: 1,
      shadowColor: const Color(0xFFEEEEEE),
      automaticallyImplyLeading: false,
      titleSpacing: 24,
      title: Row(
        children: [
          // หน้าหลัก
          _NavItem(
            icon: Icons.home,
            label: 'หน้าหลัก',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeAdmin()),
              );
            },
          ),
          const Spacer(),
          // สมัครร้านค้า
          _NavItem(
            icon: Icons.store,
            label: 'สมัครร้านค้า',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ListRestaurant(),
                ), // เปลี่ยนชื่อ Class ตามหน้าจริงของคุณ
              );
            },
          ),
          const SizedBox(width: 32),
          // สมัครผู้จัดส่ง
          _NavItem(
            icon: Icons.delivery_dining,
            label: 'สมัครผู้จัดส่ง',
            onTap: () {
              // TODO: navigate to rider registration
            },
          ),
          const SizedBox(width: 32),
          // ออกจากระบบ
          _NavItem(
            icon: Icons.logout,
            label: 'ออกจากระบบ',
            onTap: () {
              // TODO: handle logout
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFFF8C00), size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFFF8C00),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
