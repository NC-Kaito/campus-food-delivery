import 'package:flutter/material.dart';
import 'package:flutter_app/features/admin/home_admin.dart';
import 'package:flutter_app/features/admin/list_restaurant.dart';
import 'package:flutter_app/features/admin/list_rider.dart';
import 'package:flutter_app/features/admin/login_admin.dart';

class AdminNavbar extends StatelessWidget implements PreferredSizeWidget {
  const AdminNavbar({super.key});

  // โทนสีส้มของ Navbar และแถบเส้นสีเหลืองสดด้านล่าง
  static const Color _primaryOrange = Color(0xFFFDB054);
  static const Color _bottomYellow = Color(0xFFFFF128);

  // เพิ่มความสูงให้รวมความหนาของเส้นเหลือง (80 + 5 = 85)
  @override
  Size get preferredSize => const Size.fromHeight(85);

  // ── กล่องยืนยันการออกจากระบบ (Modern Minimal Dialog) ──
  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        elevation: 8,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFCDD2),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFE53935),
                    size: 26,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ออกจากระบบ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'คุณต้องการออกจากระบบใช่หรือไม่?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'ยกเลิก',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFFE53935),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'ออกจากระบบ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirm == true && context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginAdmin()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: _primaryOrange,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 70,
      toolbarHeight: 80,

      // ── แถบเส้นสีเหลืองที่ขอบล่างของ Navbar ─────────────────────
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(5),
        child: Container(color: _bottomYellow, height: 5),
      ),

      title: Row(
        children: [
          // ── ฝั่งซ้าย: โลโก้ (logo_admin.png) และ ชื่อระบบ MJU CFD ──
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/campusFoodDelivery_logo.png', // เปลี่ยนเป็น path โฟลเดอร์ asset ของคุณได้ตามต้องการ
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.delivery_dining,
                      color: Color(0xFF2E7D32),
                      size: 34,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Maejo Campus Food Delivery',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1.5),
                      blurRadius: 3.0,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Spacer(),

          // ── เมนูนำทาง (ไอคอนและข้อความสีขาว) ──
          _NavItem(
            icon: Icons.home_rounded,
            label: 'หน้าหลัก',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeAdmin()),
              );
            },
          ),

          const SizedBox(width: 28),

          _NavItem(
            icon: Icons.storefront_rounded,
            label: 'สมัครร้านค้า',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ListRestaurant()),
              );
            },
          ),

          const SizedBox(width: 28),

          _NavItem(
            icon: Icons.moped_rounded,
            label: 'สมัครผู้จัดส่ง',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ListRider()),
              );
            },
          ),

          const SizedBox(width: 32),

          // ── ฝั่งขวา: แคปซูลโปรไฟล์ Admin พร้อมเมนูกดเพื่อแสดงปุ่มออกจากระบบ ──
          PopupMenuButton<String>(
            tooltip: 'บัญชีผู้ใช้',
            offset: const Offset(0, 52),
            color: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                height: 44,
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFE53935),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'ออกจากระบบ',
                      style: TextStyle(
                        color: Color(0xFFE53935),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.manage_accounts, color: Colors.white, size: 26),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Widget เมนูไอเทม พร้อมลูกเล่น Hover ──
class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHover = true),
      onExit: (_) => setState(() => isHover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 180),
                scale: isHover ? 1.1 : 1.0,
                child: Icon(
                  widget.icon,
                  color: isHover ? Colors.white70 : Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  color: isHover ? Colors.white70 : Colors.white,
                  fontSize: 12,
                  fontWeight: isHover ? FontWeight.bold : FontWeight.w500,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
