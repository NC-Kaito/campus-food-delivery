// features/rider/account_menagement_rider.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/rider_model.dart';
import 'package:flutter_app/data/services/rider/rider_service.dart';
import 'package:flutter_app/data/services/order_service.dart'; // 🎯 นำเข้า OrderService
import 'package:flutter_app/features/rider/navbar_rider.dart';
import 'package:flutter_app/global_data.dart';

// TODO: ตรวจสอบและแก้ไข Path ไฟล์เหล่านี้ให้ตรงกับโปรเจกต์ของคุณ
import 'package:flutter_app/features/rider/profile_rider.dart';
import 'package:flutter_app/features/rider/login_rider.dart';
import 'package:flutter_app/features/restaurant/view_agrees.dart';
import 'package:flutter_app/features/rider/list_waiting_pickup_order.dart';

// ============================================================
// 🎨 Design tokens
// ============================================================
class _AccountTheme {
  static const Color primary = Color(0xFF2E7D32); // สีเขียวหลัก
  static const Color primarySoft = Color(0xFFE8FCD0); // เขียวอ่อน
  static const Color danger = Color(0xFFE53935);
  static const Color dangerSoft = Color(0xFFFFEBEE);
  static const Color pageBg = Colors.white;
  static const Color cardBg = Color(0xFFF6F6F7);
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF9098A3);
  static const Color divider = Color(0xFFEDEDEF);
}

class AccountManagementRider extends StatefulWidget {
  const AccountManagementRider({super.key});

  @override
  State<AccountManagementRider> createState() => _AccountManagementRiderState();
}

class _AccountManagementRiderState extends State<AccountManagementRider> {
  final RiderService riderService = RiderService();
  final OrderService _orderService = OrderService(); // 🎯 เรียกใช้ OrderService
  RiderModel? riderModel;
  String? riderImage;
  bool _isLoadingProfile = true;

  // 🎯 ตัวแปรเก็บจำนวนแจ้งเตือนรับงาน
  int _activeOrderCount = 0;

  final Color _primaryOrange = const Color(0xFFF97316);

  @override
  void initState() {
    super.initState();
    _loadRiderData();
    _fetchActiveOrderBadgeCount(); // 🎯 โหลดจำนวนออเดอร์แจ้งเตือน
  }

  Future<void> _loadRiderData() async {
    try {
      final rider = await riderService.getRiderByStudentId(
        GlobalData.usernameRider,
      );
      if (!mounted) return;
      setState(() {
        if (rider != null) {
          riderModel = rider;
        }
        _isLoadingProfile = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  // 🎯 ฟังก์ชันโหลดจำนวนแจ้งเตือน (งานใหม่ + งานที่รับมาแล้ว)
  Future<void> _fetchActiveOrderBadgeCount() async {
    try {
      String studentId = GlobalData.usernameRider;
      final waitingOrders = await _orderService.getWaitingOrders();
      final activeOrders = await _orderService.getActiveOrders(studentId);

      if (mounted) {
        setState(() {
          _activeOrderCount = waitingOrders.length + activeOrders.length;
        });
      }
    } catch (e) {
      debugPrint("เกิดข้อผิดพลาดในการนับออเดอร์แจ้งเตือน: $e");
    }
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;
    final baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/') ? "$baseUrl$rawPath" : "$baseUrl/$rawPath";
  }

  String get _displayName {
    final firstName = riderModel?.firstName ?? '';
    final lastName = riderModel?.lastName ?? '';
    final fullName = "$firstName $lastName".trim();

    if (fullName.isNotEmpty) return fullName;
    return GlobalData.usernameRider.isNotEmpty
        ? GlobalData.usernameRider
        : "ไรเดอร์";
  }

  Future<bool?> _confirmDialog({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFFDDDDDD)),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'ยกเลิก',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        confirmLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
  }

  Future<void> _handleLogout() async {
    final confirm = await _confirmDialog(
      icon: Icons.logout_rounded,
      iconColor: _AccountTheme.danger,
      iconBg: _AccountTheme.dangerSoft,
      title: 'ออกจากระบบ',
      message: 'คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?',
      confirmLabel: 'ออกจากระบบ',
      confirmColor: _AccountTheme.danger,
    );

    if (confirm == true) {
      GlobalData.usernameRider = "";

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginRider()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AccountTheme.pageBg,
      appBar: const NavbarRider(title: "ตั้งค่า"),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── การ์ดโปรไฟล์: รูป + ชื่อ ─────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _AccountTheme.primarySoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    _isLoadingProfile
                        ? const SizedBox(
                            width: 46,
                            height: 46,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _AccountTheme.primary,
                            ),
                          )
                        : Container(
                            width: 46,
                            height: 46,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _AccountTheme.primary,
                                width: 1.6,
                              ),
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  _getFinalImageUrl(riderImage).isNotEmpty
                                  ? NetworkImage(_getFinalImageUrl(riderImage))
                                  : null,
                              child: _getFinalImageUrl(riderImage).isEmpty
                                  ? const Icon(
                                      Icons.sports_motorsports_rounded,
                                      color: _AccountTheme.primary,
                                      size: 24,
                                    )
                                  : null,
                            ),
                          ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _displayName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _AccountTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "รหัสนักศึกษา: ${GlobalData.usernameRider}",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _AccountTheme.primary.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ── 1. เมนู: แก้ไขโปรไฟล์ ─────────────────────────
              _AccountMenuItem(
                icon: Icons.edit_note_rounded,
                iconColor: _AccountTheme.primary,
                label: "แก้ไขโปรไฟล์",
                onTap: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileRider(),
                      ),
                    ).then((_) {
                      _loadRiderData();
                    }),
              ),
              const _MenuDivider(),

              // ── 2. เมนู: นโยบาย ─────────────────────────
              _AccountMenuItem(
                icon: Icons.privacy_tip_outlined,
                iconColor: _AccountTheme.primary,
                label: "นโยบายและข้อตกลง",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ViewAgrees()),
                  );
                },
              ),
              const _MenuDivider(),

              // ── 3. เมนู: ออกจากระบบ ─────────────────────────
              _AccountMenuItem(
                icon: Icons.logout_rounded,
                iconColor: _AccountTheme.danger,
                label: "ออกจากระบบ",
                labelColor: _AccountTheme.danger,
                onTap: _handleLogout,
              ),
              const _MenuDivider(),
            ],
          ),
        ),
      ),

      // 🎯 แถบ Navbar ด้านล่าง
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.blueGrey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          selectedItemColor: _primaryOrange,
          unselectedItemColor: Colors.blueGrey.shade300,
          backgroundColor: Colors.white,
          currentIndex: 2, // ชี้ไปที่แท็บตั้งค่า
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (index) {
            if (index == 0) {
              Navigator.popUntil(context, (route) => route.isFirst);
            } else if (index == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ListWaitingPickupOrder(),
                ),
              );
            }
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: "หน้าหลัก",
            ),
            // 🎯 ซ้อน Stack ใส่ Badge แดงตรงปุ่มรับงาน
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.list_alt_rounded),
                  if (_activeOrderCount > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          _activeOrderCount > 99 ? '99+' : '$_activeOrderCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              label: "รับงาน",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: "ตั้งค่า",
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Divider(height: 1, thickness: 1, color: _AccountTheme.divider),
    );
  }
}

class _AccountMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color? iconBg;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;

  const _AccountMenuItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.iconBg,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg ?? Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: labelColor ?? _AccountTheme.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: _AccountTheme.textSecondary.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
