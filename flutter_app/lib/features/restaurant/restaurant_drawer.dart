// features/restaurant/restaurant_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/features/restaurant/close_account.dart';
import 'package:flutter_app/features/restaurant/home_restaurant.dart';
import 'package:flutter_app/features/restaurant/login_restaurant.dart';
import 'package:flutter_app/features/restaurant/view_agrees.dart';
import 'package:flutter_app/global_data.dart';
// 🎯 ยังไม่มีไฟล์นี้ในโค้ดที่ให้มา — สร้าง placeholder ไว้ก่อน
// ถ้ามีหน้าจริงอยู่แล้ว เปลี่ยน path/ชื่อคลาสให้ตรงกับของจริงได้เลย
import 'package:flutter_app/features/restaurant/sales_restaurant.dart';
import 'package:flutter_app/features/restaurant/review_restaurant.dart';

class RestaurantDrawer extends StatefulWidget {
  const RestaurantDrawer({super.key});

  @override
  State<RestaurantDrawer> createState() => _RestaurantDrawerState();
}

class _RestaurantDrawerState extends State<RestaurantDrawer> {
  static const Color _orange = Color(0xFFFF8C00);
  static const Color _yellow = Color(0xFFFFD400);
  static const Color _green = Color(0xFF3DD16B);
  static const Color _primary = Color(0xFF16A34A);
  static const Color _danger = Color(0xFFE53935);
  static const Color _textDark = Color(0xFF1E1E24);

  final RestaurantService _restaurantService = RestaurantService();
  RestaurantModel? _restaurantModel;

  // 🎯 สถานะเปิด/ปิดร้าน — ย้ายมาจากหน้า ProfileRestaurant เพื่อให้สลับ
  // สถานะร้านได้เร็วจากเมนู Drawer โดยไม่ต้องเข้าไปหน้าโปรไฟล์
  bool _isStoreOpen = true;
  bool _isTogglingStatus = false;

  @override
  void initState() {
    super.initState();
    _loadRestaurant();
  }

  // 🎯 โหลดข้อมูลร้านเองตอนเปิด Drawer เพราะ "ปิดบัญชีผู้ใช้" ต้องใช้
  // RestaurantModel ส่งต่อไปหน้า CloseAccount (Drawer เป็น widget กลาง
  // ที่ถูกใช้ร่วมทุกหน้า เลยดึงข้อมูลเองแทนที่จะรับผ่าน constructor)
  Future<void> _loadRestaurant() async {
    try {
      final result = await _restaurantService.getRestaurantByUsername(
        GlobalData.usernameRestaurant,
      );
      if (mounted) {
        setState(() {
          _restaurantModel = result;
          _isStoreOpen = result.statusOpen ?? true;
        });
      }
    } catch (e) {
      debugPrint("โหลดข้อมูลร้านสำหรับ Drawer ไม่สำเร็จ: $e");
    }
  }

  Future<void> _toggleStoreStatus() async {
    if (_restaurantModel == null || _isTogglingStatus) return;

    final bool previousStatus = _isStoreOpen;
    final bool newStatus = !_isStoreOpen;

    setState(() {
      _isStoreOpen = newStatus;
      _isTogglingStatus = true;
    });

    try {
      _restaurantModel!.statusOpen = newStatus;
      await _restaurantService.updateStatusOpen(_restaurantModel!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? 'เปิดร้านสำเร็จ' : 'ปิดร้านสำเร็จ',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: _primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint("Update Status Error: $e");
      if (mounted) {
        setState(() => _isStoreOpen = previousStatus);
        _restaurantModel!.statusOpen = previousStatus;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เปลี่ยนสถานะไม่สำเร็จ: $e'),
            backgroundColor: _danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTogglingStatus = false);
    }
  }

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6),

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
            Divider(
              height: 1,
              color: Colors.grey.shade300,
              indent: 16,
              endIndent: 16,
            ),

            // ── การ์ดสถานะเปิด/ปิดร้าน (อยู่ใต้ปุ่มหน้าแรก) ────────────
            _buildStatusCard(),

            Divider(
              height: 1,
              color: Colors.grey.shade300,
              indent: 16,
              endIndent: 16,
            ),

            // ── การ์ดลัด: ยอดขาย / รีวิว ──────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F9),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      color: _yellow,
                      icon: Icons.attach_money_rounded,
                      iconColor: Colors.black87,
                      label: "ยอดขาย",
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SalesRestaurant(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildStatCard(
                      color: _green,
                      icon: Icons.star_rounded,
                      iconColor: Colors.white,
                      label: "รีวิว",
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReviewRestaurant(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),
            Divider(
              height: 1,
              color: Colors.grey.shade300,
              indent: 16,
              endIndent: 16,
            ),

            // ── 3 เมนูล่าง เหมือนหน้า ProfileRestaurant เป๊ะๆ ─────────
            _buildMenuItem(
              context: context,
              icon: Icons.article_outlined,
              iconColor: _orange,
              text: "ข้อตกลงและเงื่อนไขการยินยอม",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ViewAgrees()),
                );
              },
            ),
            Divider(
              height: 1,
              color: Colors.grey.shade300,
              indent: 16,
              endIndent: 16,
            ),

            _buildMenuItem(
              context: context,
              icon: Icons.cancel_outlined,
              iconColor: Colors.red,
              text: "ปิดบัญชีผู้ใช้",
              onTap: () {
                if (_restaurantModel == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("กำลังโหลดข้อมูลร้าน กรุณาลองใหม่อีกครั้ง"),
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CloseAccount(restaurant: _restaurantModel!),
                  ),
                );
              },
            ),
            Divider(
              height: 1,
              color: Colors.grey.shade300,
              indent: 16,
              endIndent: 16,
            ),

            _buildMenuItem(
              context: context,
              icon: Icons.logout_rounded,
              iconColor: _orange,
              text: "ออกจากระบบ",
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  barrierColor: Colors.black.withOpacity(0.4),
                  builder: (context) => Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                          const Text(
                            'ออกจากระบบ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 10),
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
                          Row(
                            children: [
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

                if (confirm == true && context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginRestaurant(),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── การ์ดสถานะเปิด/ปิดร้าน (ย้ายมาจาก ProfileRestaurant) ────────────
  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 12, 18, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  color: _primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "สถานะเปิด-ปิดร้าน",
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: _toggleStoreStatus,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 70,
              height: 34,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: _isStoreOpen ? _primary : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: _isStoreOpen
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: _isTogglingStatus
                      ? Padding(
                          padding: const EdgeInsets.all(6),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _isStoreOpen ? _primary : Colors.grey[500],
                          ),
                        )
                      : Icon(
                          _isStoreOpen ? Icons.check : Icons.close,
                          size: 15,
                          color: _isStoreOpen ? _primary : Colors.grey[500],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── การ์ดสถิติสีสัน (ยอดขาย / รีวิว) ────────────────────────────────
  Widget _buildStatCard({
    required Color color,
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 30),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
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
