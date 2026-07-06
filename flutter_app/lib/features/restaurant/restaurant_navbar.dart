import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/features/restaurant/profile_restaurant.dart';
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
  // 🎯 สถานะเปิด/ปิดร้าน ย้ายมาแสดงที่ Navbar แทนหน้า Profile
  bool _isStoreOpen = true;

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
          _isStoreOpen = rest.statusOpen ?? true;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight + 8,
          child: Row(
            children: [
              const SizedBox(width: 4),
              _MenuButton(onTap: () => Scaffold.of(context).openDrawer()),
              const SizedBox(width: 8),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1F1F),
                    letterSpacing: 0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _IconAction(
                icon: Icons.shopping_bag_outlined,
                badgeCount: widget.cartCount,
                onTap: () {
                  // TODO: จัดการระบบตะกร้า
                },
              ),
              const SizedBox(width: 6),
              _IconAction(
                icon: Icons.notifications_outlined,
                badgeCount: widget.notificationCount,
                onTap: () {
                  // TODO: ไปหน้าแจ้งเตือน
                },
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileRestaurant(),
                      ),
                    );
                  },
                  child: _ProfileAvatar(
                    isLoading: _isLoadingProfile,
                    imageUrl: _getFinalImageUrl(restaurantImage),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded, tinted menu button — matches the icon-in-a-pill pattern
/// used across most modern delivery/e-commerce apps.
class _MenuButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MenuButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RestaurantNavbar.orangeSoft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(
            Icons.menu_rounded,
            color: RestaurantNavbar.orange,
            size: 24,
          ),
        ),
      ),
    );
  }
}

/// Icon button with an optional unread-count badge, the way cart /
/// notification icons are usually treated in production apps.
class _IconAction extends StatelessWidget {
  final IconData icon;
  final int badgeCount;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: const Color(0xFF3A3A3A), size: 25),
              if (badgeCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: RestaurantNavbar.orange,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 16),
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
  }
}

class _ProfileAvatar extends StatelessWidget {
  final bool isLoading;
  final String imageUrl;

  const _ProfileAvatar({required this.isLoading, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFF0F0F0),
        ),
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
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
        border: Border.all(color: RestaurantNavbar.orange, width: 1.5),
      ),
      child: CircleAvatar(
        backgroundColor: RestaurantNavbar.orangeSoft,
        backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
        onBackgroundImageError: imageUrl.isNotEmpty
            ? (_, __) {
                debugPrint("โหลดรูปโปรไฟล์บน Navbar จากเซิร์ฟเวอร์ไม่สำเร็จ");
              }
            : null,
        child: imageUrl.isEmpty
            ? const Icon(
                Icons.person_outline_rounded,
                color: RestaurantNavbar.orange,
                size: 18,
              )
            : null,
      ),
    );
  }
}
