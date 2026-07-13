import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/features/restaurant/close_account.dart';
import 'package:flutter_app/features/restaurant/profile_restaurant.dart';
// TODO: แก้ path นี้ให้ตรงกับตำแหน่งไฟล์ LoginRestaurant จริงในโปรเจกต์ของคุณ
import 'package:flutter_app/features/restaurant/login_restaurant.dart';
import 'package:flutter_app/features/restaurant/restaurant_navbar.dart';
import 'package:flutter_app/features/restaurant/view_agrees.dart';
import 'package:flutter_app/global_data.dart';

// ============================================================
// 🎨 Design tokens — โทนเดียวกับ RestaurantNavbar เพื่อความสอดคล้องทั้งแอป
// ============================================================
class _AccountTheme {
  static const Color primary = Color(0xFFFF8C00); // ส้ม — โทนหลักของแบรนด์
  static const Color primarySoft = Color(0xFFFFF1DE);
  static const Color danger = Color(0xFFE53935);
  static const Color dangerSoft = Color(0xFFFFEBEE);
  static const Color pageBg = Colors.white;
  static const Color cardBg = Color(0xFFF6F6F7);
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF9098A3);
  static const Color divider = Color(0xFFEDEDEF);
}

class AccountManagement extends StatefulWidget {
  const AccountManagement({super.key});

  @override
  State<AccountManagement> createState() => _AccountManagementState();
}

class _AccountManagementState extends State<AccountManagement> {
  final RestaurantService restaurantService = RestaurantService();
  RestaurantModel? restaurantModel;
  String? restaurantImage;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurantData();
  }

  Future<void> _loadRestaurantData() async {
    try {
      final rest = await restaurantService.getRestaurantByUsername(
        GlobalData.usernameRestaurant,
      );
      if (!mounted) return;
      setState(() {
        if (rest != null) {
          restaurantModel = rest;
          restaurantImage = rest.restaurantImage;
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
    final name = restaurantModel?.restaurantName;
    if (name != null && name.trim().isNotEmpty) return name;
    return GlobalData.usernameRestaurant;
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
                      child: const Text('ยกเลิก'),
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
                        style: const TextStyle(color: Colors.white),
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

  Future<void> _handleCloseAccount() async {
    final confirm = await _confirmDialog(
      icon: Icons.warning_rounded,
      iconColor: _AccountTheme.danger,
      iconBg: _AccountTheme.dangerSoft,
      title: 'ปิดบัญชีผู้ใช้',
      message:
          'การปิดบัญชีจะทำให้คุณไม่สามารถใช้งานบัญชีนี้ได้อีก คุณแน่ใจหรือไม่?',
      confirmLabel: 'ปิดบัญชี',
      confirmColor: _AccountTheme.danger,
    );

    if (confirm == true) {
      // TODO: เรียก service สำหรับปิดบัญชีผู้ใช้จริงตรงนี้
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginRestaurant()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RestaurantNavbar(title: ""),
      backgroundColor:
          _AccountTheme.pageBg, // แก้ไขให้เรียกใช้จากคลาสสีที่ถูกต้อง
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                  color: const Color.fromARGB(255, 3, 220, 65),
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
                              backgroundColor: _AccountTheme.primarySoft,
                              backgroundImage:
                                  _getFinalImageUrl(restaurantImage).isNotEmpty
                                  ? NetworkImage(
                                      _getFinalImageUrl(restaurantImage),
                                    )
                                  : null,
                              child: _getFinalImageUrl(restaurantImage).isEmpty
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

              // ── รายการเมนูจัดการบัญชี ─────────────────────────
              _AccountMenuItem(
                icon: Icons.edit_note_rounded,
                iconColor: _AccountTheme.primary,
                label: "แก้ไขโปรไฟล์",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileRestaurant(),
                  ),
                ),
              ),
              const _MenuDivider(),

              // ── แก้ไขเมนู ข้อตกลงและเงื่อนไขการยินยอม ──
              _AccountMenuItem(
                icon: Icons.description_outlined,
                iconColor: _AccountTheme.primary,
                label: "ข้อตกลงและเงื่อนไขการยินยอม",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ViewAgrees()),
                  );
                },
              ),
              const _MenuDivider(),

              // ── แก้ไขเมนู ปิดบัญชีผู้ใช้ ──
              _AccountMenuItem(
                icon: Icons.cancel_outlined,
                iconColor: _AccountTheme.danger,
                label: "ปิดบัญชีผู้ใช้",
                labelColor: _AccountTheme.danger,
                onTap: () {
                  // ตรวจสอบว่า restaurantModel มีค่าก่อนส่ง เพื่อป้องกัน error
                  if (restaurantModel != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CloseAccount(
                          restaurant: restaurantModel!,
                        ), // ส่งค่า restaurant เข้าไปที่นี่
                      ),
                    );
                  }
                },
              ),
              const _MenuDivider(),
            ],
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
                    fontSize: 14.5,
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
