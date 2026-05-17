import 'package:flutter/material.dart';
import 'package:flutter_app/features/admin/home_admin.dart';
import 'package:flutter_app/features/admin/list_restaurant.dart';
import 'package:flutter_app/features/admin/list_rider.dart';
import 'package:flutter_app/features/admin/login_admin.dart';

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

      // ── ขยับ navbar ลงมา ─────────────────────────────
      title: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
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
                  ),
                );
              },
            ),

            const SizedBox(width: 32),

            // สมัครผู้จัดส่ง
            _NavItem(
              icon: Icons.delivery_dining,
              label: 'สมัครผู้จัดส่ง',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ListRider()),
                );
              },
            ),

            const SizedBox(width: 32),

            // ออกจากระบบ
            _NavItem(
              icon: Icons.logout,
              label: 'ออกจากระบบ',
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  barrierColor: Colors.black.withOpacity(0.4),
                  builder: (context) => Dialog(
                    insetPadding: const EdgeInsets.symmetric(
                      horizontal: 300,
                      vertical: 100,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    backgroundColor: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Icon ─────────────────────────────────
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFEBEE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFE53935),
                              size: 32,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Title ────────────────────────────────
                          const Text(
                            'ออกจากระบบ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ── Subtitle ─────────────────────────────
                          const Text(
                            'คุณต้องการออกจากระบบใช่หรือไม่?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── Buttons ──────────────────────────────
                          Row(
                            children: [
                              // ยกเลิก
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    'ยกเลิก',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // ออกจากระบบ
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE53935),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'ออกจากระบบ',
                                    style: TextStyle(
                                      fontSize: 16,
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
                );

                if (confirm == true) {
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginAdmin(),
                      ),
                      (route) => false,
                    );
                  }
                }
              },
            ),

            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

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

      onEnter: (_) {
        setState(() {
          isHover = true;
        });
      },

      onExit: (_) {
        setState(() {
          isHover = false;
        });
      },

      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 180),
                scale: isHover ? 1.08 : 1,
                child: Icon(
                  widget.icon,
                  color: isHover
                      ? const Color.fromARGB(255, 216, 119, 0)
                      : const Color(0xFFFF8C00),
                  size: 32,
                ),
              ),

              const SizedBox(height: 4),

              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  color: isHover
                      ? const Color.fromARGB(255, 216, 119, 0)
                      : const Color(0xFFFF8C00),
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
