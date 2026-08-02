import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/features/restaurant/account_management.dart';
import 'package:flutter_app/features/restaurant/profile_restaurant.dart';
// TODO: แก้ path นี้ให้ตรงกับตำแหน่งไฟล์ LoginRestaurant จริงในโปรเจกต์ของคุณ
import 'package:flutter_app/features/restaurant/login_restaurant.dart';
import 'package:flutter_app/global_data.dart';

class RestaurantNavbar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final int cartCount;
  final int notificationCount;

  const RestaurantNavbar({
    super.key,
    required this.title,
    this.cartCount = 0,
    this.notificationCount = 0,
  });

  static const Color orange = Color(0xFFFF8C00);
  static const Color orangeSoft = Color(0xFFFFF1DE);

  // ระยะห่างมาตรฐานเดียวกันทุกจุดในแถบเมนู เพื่อความสม่ำเสมอ
  static const double gap = 10;
  static const double radius = 12;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  State<RestaurantNavbar> createState() => _RestaurantNavbarState();
}

class _RestaurantNavbarState extends State<RestaurantNavbar> {
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

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFE53935),
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'ออกจากระบบ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'คุณต้องการออกจากระบบใช่หรือไม่?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF555555),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'ยกเลิก',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'ออกจากระบบ',
                        style: TextStyle(fontWeight: FontWeight.w600),
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
      // TODO: ใส่โค้ดเคลียร์ Session (เช่น ลบ token, ล้าง GlobalData) ก่อนเปลี่ยนหน้า
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginRestaurant()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = RestaurantNavbar.gap;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight + 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _HomeButton(
                  onTap: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                ),
                const SizedBox(width: gap + 4),
                Expanded(
                  child: Text(
                    widget.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F1F1F),
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                const SizedBox(width: gap),
                _IconAction(
                  icon: Icons.shopping_bag_outlined,
                  badgeCount: widget.cartCount,
                  tooltip: 'ตะกร้า',
                  onTap: () {},
                ),
                const SizedBox(width: gap),
                _IconAction(
                  icon: Icons.notifications_outlined,
                  badgeCount: widget.notificationCount,
                  tooltip: 'การแจ้งเตือน',
                  onTap: () {},
                ),
                const SizedBox(width: gap),
                _IconAction(
                  icon: Icons.logout_rounded,
                  color: const Color(0xFFE53935),
                  background: const Color(0xFFFFEBEE),
                  tooltip: 'ออกจากระบบ',
                  onTap: () => _handleLogout(context),
                ),
                const SizedBox(width: gap),
                Container(height: 26, width: 1, color: const Color(0xFFEDEDED)),
                const SizedBox(width: gap),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountManagement(),
                    ),
                  ),
                  child: _ProfileAvatar(
                    isLoading: _isLoadingProfile,
                    imageUrl: _getFinalImageUrl(restaurantImage),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final VoidCallback onTap;
  const _HomeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RestaurantNavbar.orangeSoft,
      borderRadius: BorderRadius.circular(RestaurantNavbar.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(RestaurantNavbar.radius),
        splashColor: RestaurantNavbar.orange.withOpacity(0.18),
        highlightColor: RestaurantNavbar.orange.withOpacity(0.08),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(RestaurantNavbar.radius),
            border: Border.all(
              color: RestaurantNavbar.orange.withOpacity(0.22),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.home_rounded,
            color: RestaurantNavbar.orange,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final int badgeCount;
  final VoidCallback onTap;
  final Color? color;
  final Color? background;
  final String? tooltip;

  const _IconAction({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
    this.color,
    this.background,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: background ?? const Color(0xFFF6F6F6),
      borderRadius: BorderRadius.circular(RestaurantNavbar.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(RestaurantNavbar.radius),
        splashColor: RestaurantNavbar.orange.withOpacity(0.18),
        highlightColor: RestaurantNavbar.orange.withOpacity(0.08),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(icon, color: color ?? const Color(0xFF555555), size: 21),
              if (badgeCount > 0)
                Positioned(
                  right: 2,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    constraints: const BoxConstraints(minWidth: 16),
                    decoration: BoxDecoration(
                      color: RestaurantNavbar.orange,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: RestaurantNavbar.orange.withOpacity(0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class _ProfileAvatar extends StatelessWidget {
  final bool isLoading;
  final String imageUrl;
  const _ProfileAvatar({required this.isLoading, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 38,
        height: 38,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: RestaurantNavbar.orange,
            ),
          ),
        ),
      );
    }
    return Container(
      width: 38,
      height: 38,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            RestaurantNavbar.orange,
            RestaurantNavbar.orange.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: RestaurantNavbar.orange.withOpacity(0.28),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          color: RestaurantNavbar.orangeSoft,
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.person_outline_rounded,
                    color: RestaurantNavbar.orange,
                    size: 18,
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: RestaurantNavbar.orange,
                        ),
                      ),
                    );
                  },
                )
              : const Icon(
                  Icons.person_outline_rounded,
                  color: RestaurantNavbar.orange,
                  size: 18,
                ),
        ),
      ),
    );
  }
}
