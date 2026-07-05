import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/features/restaurant/profile_restaurant.dart';
import 'package:flutter_app/global_data.dart';

class RestaurantNavbar extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  const RestaurantNavbar({super.key, required this.title});

  static const Color orange = Color(
    0xFFFF8C00,
  ); // 🎯 ลบ underscore ให้เป็น public เพราะจะถูกเรียกใช้ข้ามไฟล์

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<RestaurantNavbar> createState() => _RestaurantNavbarState();
}

class _RestaurantNavbarState extends State<RestaurantNavbar> {
  final RestaurantService restaurantService = RestaurantService();
  RestaurantModel? restaurantModel;
  String? restaurantimage;

  Future<void> loadRestaurantData() async {
    final rest = await restaurantService.getRestaurantByUsername(
      GlobalData.usernameRestaurant,
    );

    if (mounted) {
      setState(() {
        if (rest != null) {
          restaurantModel = rest;
          restaurantimage = rest.restaurantImage;
        }
      });
    }
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;

    final String baseUrl = DioClient.dio.options.baseUrl;
    if (rawPath.startsWith('/')) {
      return "$baseUrl$rawPath";
    } else {
      return "$baseUrl/$rawPath";
    }
  }

  @override
  void initState() {
    super.initState();
    loadRestaurantData();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 3,
      automaticallyImplyLeading: false,

      // ── ไอคอนสามขีด ด้านซ้าย (เปิด Drawer) ─────────────
      leading: IconButton(
        icon: const Icon(
          Icons.menu_rounded,
          color: RestaurantNavbar.orange,
          size: 35,
        ),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),

      // ── ไอคอนด้านขวา ──────────────────────────────────
      actions: [
        IconButton(
          icon: const Icon(
            Icons.shopping_bag_outlined,
            color: RestaurantNavbar.orange,
            size: 35,
          ),
          onPressed: () {
            // TODO: จัดการระบบตะกร้า
          },
        ),
        const SizedBox(width: 20),

        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: RestaurantNavbar.orange,
            size: 35,
          ),
          onPressed: () {
            // TODO: ไปหน้าแจ้งเตือน
          },
        ),
        const SizedBox(width: 20),

        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileRestaurant(),
                ),
              );
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFFFEBCC),
              backgroundImage:
                  (restaurantimage != null && restaurantimage!.isNotEmpty)
                  ? NetworkImage(_getFinalImageUrl(restaurantimage!))
                  : null,
              onBackgroundImageError:
                  (restaurantimage != null && restaurantimage!.isNotEmpty)
                  ? (_, __) {
                      print("โหลดรูปโปรไฟล์บน Navbar จากเซิร์ฟเวอร์ไม่สำเร็จ");
                    }
                  : null,
              child: (restaurantimage == null || restaurantimage!.isEmpty)
                  ? const Icon(
                      Icons.person_outline_rounded,
                      color: RestaurantNavbar.orange,
                      size: 20,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
