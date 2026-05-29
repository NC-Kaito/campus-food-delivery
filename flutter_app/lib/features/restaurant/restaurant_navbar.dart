import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/features/restaurant/home_restaurant.dart';
import 'package:flutter_app/features/restaurant/profile_restaurant.dart';
import 'package:flutter_app/global_data.dart';

class RestaurantNavbar extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  const RestaurantNavbar({super.key, required this.title});

  static const Color _orange = Color(0xFFFF8C00);

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

          // ✅ แก้ไขจุดตาย: ดึง URL รูปโปรไฟล์ตรงๆ จากไอพีเครื่องจริง (.211) ไม่ต้องใช้ .replaceAll ขัดขาตัวเองแล้ว
          restaurantimage = rest.restaurantImage;
        }
      });
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

      // ── ไอคอนบ้าน ด้านซ้าย ───────────────────────────
      leading: IconButton(
        icon: const Icon(
          Icons.home_rounded,
          color: RestaurantNavbar._orange,
          size: 35,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomeRestaurant()),
          );
        },
      ),

      // ── ไอคอนด้านขวา ──────────────────────────────────
      actions: [
        // ตะกร้า / ร้านค้า
        IconButton(
          icon: const Icon(
            Icons.shopping_bag_outlined,
            color: RestaurantNavbar._orange,
            size: 35,
          ),
          onPressed: () {
            // TODO: จัดการระบบตะกร้า
          },
        ),
        const SizedBox(width: 20),

        // กระดิ่ง
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: RestaurantNavbar._orange,
            size: 35,
          ),
          onPressed: () {
            // TODO: ไปหน้าแจ้งเตือน
          },
        ),
        const SizedBox(width: 20),

        // รูปโปรไฟล์หน้าร้าน (CircleAvatar)
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
                  ? NetworkImage(Uri.encodeFull(restaurantimage!))
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
                      color: RestaurantNavbar._orange,
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
