// features/restaurant/account_management.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/services/order_status_monitor.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/features/restaurant/close_account.dart';
import 'package:flutter_app/features/restaurant/openday_rest.dart';
import 'package:flutter_app/features/restaurant/profile_restaurant.dart';
import 'package:flutter_app/features/restaurant/login_restaurant.dart';
import 'package:flutter_app/features/restaurant/restaurant_navbar.dart';
import 'package:flutter_app/features/restaurant/view_agrees.dart';
import 'package:flutter_app/global_data.dart';
import 'package:flutter_app/main_login.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

// ============================================================
//  Design tokens — โทนสีเขียวเดียวกับ RestaurantNavbar
// ============================================================
class _AccountTheme {
  static const Color primary = Color(0xFF00B300); // สีเขียวหลัก
  static const Color primarySoft = Color(0xFFE8F5E9); // สีเขียวอ่อน
  static const Color danger = Color(0xFFE53935);
  static const Color dangerSoft = Color(0xFFFFEBEE);
  static const Color pageBg = Colors.white;
  static const Color cardBg = Color(0xFFF6F6F7);
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF9098A3);
  static const Color divider = Color(0xFFEDEDEF);
}

class AccountManagement extends StatefulWidget {
  final bool showTutorial; // 🎯 รับค่าว่าต้องทำ Tutorial หรือไม่
  const AccountManagement({
    super.key,
    this.showTutorial = false,
  }); // 🎯 ค่าตั้งต้นเป็น false

  @override
  State createState() => _AccountManagementState(); // 🎯 แก้จุดที่ 1
}

// 🎯 แก้จุดที่ 2: ระบุ type เป็น  เพื่อให้เรียก widget.showTutorial ได้
class _AccountManagementState extends State<AccountManagement> {
  final RestaurantService restaurantService = RestaurantService();
  RestaurantModel? restaurantModel;
  String? restaurantImage;
  bool _isLoadingProfile = true;

  // 🎯 สร้าง Key ผูกกับปุ่ม "ตั้งค่าวันเวลาเปิด-ปิดร้าน"
  final GlobalKey opendayMenuKey = GlobalKey();
  TutorialCoachMark? tutorialCoachMark;

  final menuTextStyle = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: _AccountTheme.primary,
  );

  @override
  void initState() {
    super.initState();
    _loadRestaurantData();

    // 🎯 ตรวจสอบว่าต้องเล่น Tutorial ต่อหรือไม่
    if (widget.showTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _showTutorial();
        });
      });
    }
  }

  // 🎯 ฟังก์ชันแสดง Tutorial ชี้ไปที่ปุ่มตั้งค่าเวลา
  void _showTutorial() {
    if (tutorialCoachMark != null) return;
    tutorialCoachMark = TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: "opendayTarget",
          keyTarget: opendayMenuKey,
          alignSkip: Alignment.topRight,
          shape: ShapeLightFocus.RRect,
          radius: 14,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ขั้นตอนสุดท้าย! 🕒",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "แตะที่เมนูนี้เพื่อตั้งเวลาเปิด-ปิดร้าน\nเมื่อตั้งเสร็จ ร้านของคุณจะพร้อมรับออเดอร์ทันที",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        controller.skip();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OpendayRest(),
                          ),
                        ).then((_) => _loadRestaurantData());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _AccountTheme.primary,
                      ),
                      child: const Text(
                        "ไปตั้งเวลาเปิด-ปิดร้าน",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
      colorShadow: Colors.black,
      opacityShadow: 0.8,
      textSkip: "ข้าม",
      onSkip: () => true,
    )..show(context: context);
  }

  Future _loadRestaurantData() async {
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
    return rawPath.startsWith('/')
        ? baseUrl + rawPath
        : baseUrl + '/' + rawPath;
  }

  String get _displayName {
    final name = restaurantModel?.restaurantName;
    if (name != null && name.trim().isNotEmpty) return name;
    return GlobalData.usernameRestaurant;
  }

  Future _confirmDialog({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog(
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

  Future _handleLogout() async {
    final confirm = await _confirmDialog(
      icon: Icons.logout_rounded,
      iconColor: _AccountTheme.danger,
      iconBg: _AccountTheme.dangerSoft,
      title: 'ออกจากระบบ',
      message: 'คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบร้านค้า?',
      confirmLabel: 'ออกจากระบบ',
      confirmColor: _AccountTheme.danger,
    );

    if (confirm == true) {
      GlobalData.usernameRestaurant = "";
      OrderStatusMonitor().stopMonitoring();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainLogin()),
        (route) => false,
      );
    }
  }

  Future _handleCloseAccount() async {
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
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainLogin()),
        (route) => false,
      );
    }
  }

  // 🎯 สร้างวิดเจ็ตปุ่มนำทาง (เหมือน Member)
  Widget _buildNavItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? _AccountTheme.primary : Colors.grey.shade400,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: menuTextStyle.copyWith(
                color: isActive ? _AccountTheme.primary : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RestaurantNavbar(title: "ตั้งค่าบัญชี"),
      backgroundColor: _AccountTheme.pageBg,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                                  _getFinalImageUrl(restaurantImage).isNotEmpty
                                  ? NetworkImage(
                                      _getFinalImageUrl(restaurantImage),
                                    )
                                  : null,
                              child: _getFinalImageUrl(restaurantImage).isEmpty
                                  ? const Icon(
                                      Icons.storefront_rounded,
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

              _AccountMenuItem(
                icon: Icons.edit_note_rounded,
                iconColor: _AccountTheme.primary,
                label: "แก้ไขโปรไฟล์",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileRestaurant(),
                  ),
                ).then((_) => _loadRestaurantData()),
              ),
              const _MenuDivider(),

              // 🎯 หุ้ม Key ไว้ที่เมนูเปิด-ปิดร้าน เพื่อให้ Tutorial ชี้มาที่นี่
              Container(
                key: opendayMenuKey,
                child: _AccountMenuItem(
                  icon: Icons.schedule_rounded,
                  iconColor: _AccountTheme.primary,
                  label: "ตั้งค่าวันเวลาเปิด-ปิดร้าน",
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OpendayRest(),
                      ),
                    );
                    await _loadRestaurantData();
                  },
                ),
              ),
              const _MenuDivider(),

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

              _AccountMenuItem(
                icon: Icons.cancel_outlined,
                iconColor: _AccountTheme.danger,
                label: "ปิดบัญชีผู้ใช้",
                labelColor: _AccountTheme.danger,
                onTap: () {
                  if (restaurantModel != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CloseAccount(restaurant: restaurantModel!),
                      ),
                    );
                  }
                },
              ),
              const _MenuDivider(),

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

      // 🎯 แถบนำทางด้านล่าง (Bottom Navigation Bar)
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
