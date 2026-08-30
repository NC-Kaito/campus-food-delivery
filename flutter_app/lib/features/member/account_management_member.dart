import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/member_model.dart';
import 'package:flutter_app/data/services/member/member_service.dart';
import 'package:flutter_app/features/member/list_active_order_member.dart';
import 'package:flutter_app/global_data.dart';
import 'package:flutter_app/features/member/cart_manager_member.dart';
import 'package:flutter_app/features/member/list_order_member.dart';

import 'package:flutter_app/features/member/navbar_member.dart';
import 'package:flutter_app/features/member/profile_member.dart';
import 'package:flutter_app/features/member/login_member.dart';
import 'package:flutter_app/features/restaurant/view_agrees.dart';

// ============================================================
// 🎨 Design tokens — โทนสีเขียวสำหรับฝั่งลูกคัา (Member)
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

class AccountManagementMember extends StatefulWidget {
  const AccountManagementMember({super.key});

  @override
  State<AccountManagementMember> createState() =>
      _AccountManagementMemberState();
}

class _AccountManagementMemberState extends State<AccountManagementMember> {
  final MemberService memberService = MemberService();
  MemberModel? memberModel;
  String? memberImage;
  bool _isLoadingProfile = true;

  // 🎯 กำหนด TextStyle สำหรับเมนูด้านล่าง
  final menuTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Colors.green[700],
  );

  @override
  void initState() {
    super.initState();
    _loadMemberData();
  }

  Future<void> _loadMemberData() async {
    try {
      final mem = await memberService.getMemberByUsername(
        GlobalData.usernameMember,
      );
      if (!mounted) return;
      setState(() {
        if (mem != null) {
          memberModel = mem;

          memberImage = mem.profileimg;
        }
        _isLoadingProfile = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;
    final baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/') ? "$baseUrl$rawPath" : "$baseUrl/$rawPath";
  }

  String get _displayName {
    final firstName = memberModel?.firstname ?? '';
    final lastName = memberModel?.lastname ?? '';
    final fullName = "$firstName $lastName".trim();

    if (fullName.isNotEmpty) return fullName;
    return GlobalData.usernameMember.isNotEmpty
        ? GlobalData.usernameMember
        : "ผู้ใช้งาน";
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
      GlobalData.usernameMember = "";

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginMember()),
        (route) => false,
      );
    }
  }

  // 🎯 เพิ่มฟังก์ชันสำหรับปุ่ม Navbar
  Widget _buildNavItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isActive = false,
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: isActive ? Colors.green : Colors.grey),
                if (badgeCount > 0)
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
                        badgeCount > 99 ? '99+' : '$badgeCount',
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
            Text(
              label,
              style: menuTextStyle.copyWith(
                color: isActive ? Colors.green[700] : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ดึงจำนวนของในตะกร้ามาโชว์ที่ปุ่มตะกร้าอาหาร
    final int cartItemCount = CartManager().items.length;

    return Scaffold(
      appBar: const NavbarMember(title: "ตั้งค่าบัญชี"),
      backgroundColor: _AccountTheme.pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                              // 🎯 แสดงรูปโปรไฟล์ ถ้าดึงมาแล้วไม่ว่างเปล่า
                              backgroundImage:
                                  _getFinalImageUrl(memberImage).isNotEmpty
                                  ? NetworkImage(_getFinalImageUrl(memberImage))
                                  : null,
                              child: _getFinalImageUrl(memberImage).isEmpty
                                  ? const Icon(
                                      Icons.person_outline_rounded,
                                      color: _AccountTheme.primary,
                                      size: 22,
                                    )
                                  : null,
                            ),
                          ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _AccountTheme.textPrimary,
                        ),
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
                        builder: (context) => const ProfileMember(),
                      ),
                    ).then((_) {
                      // รีเฟรชข้อมูลเผื่อมีการเปลี่ยนชื่อหรือเปลี่ยนรูปภาพ
                      _loadMemberData();
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

      // 🎯 เพิ่มแถบเมนูด้านล่าง (Navbar)
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.home, "หน้าหลัก", () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                }),
                _buildNavItem(Icons.shopping_basket, "ตะกร้าอาหาร", () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ListOrderMember(),
                    ),
                  );
                }, badgeCount: cartItemCount),
                _buildNavItem(Icons.list_alt, "คำสั่งซื้อ", () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ListActiveOrderMember(),
                    ),
                  );
                }),
                // 🎯 ให้ไอคอน "โปรไฟล์" ทำงานเป็นโหมด Active (สีเขียว)
                _buildNavItem(Icons.settings, "ตั้งค่า", () {}, isActive: true),
              ],
            ),
          ),
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
