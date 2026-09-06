// features/rider/navbar_rider.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/rider_model.dart';
import 'package:flutter_app/data/services/rider/rider_service.dart';
import 'package:flutter_app/data/services/order_service.dart';
import 'package:flutter_app/features/rider/home_rider.dart';
import 'package:flutter_app/features/rider/list_waiting_pickup_order.dart';
import 'package:flutter_app/features/rider/profile_rider.dart';
import 'package:flutter_app/global_data.dart';
import 'package:flutter_app/core/network/dio_client.dart';

class NavbarRider extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  const NavbarRider({super.key, required this.title});

  // 🎯 ปรับให้ใช้โทนสีเดียวกับ Member
  static const Color _orange = Color(0xFFFF8C00);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<NavbarRider> createState() => _NavbarRiderState();
}

class _NavbarRiderState extends State<NavbarRider> {
  final RiderService riderService = RiderService();
  final OrderService _orderService = OrderService();
  RiderModel? riderModel;
  String? riderImage;

  // 🎯 ตัวแปรเก็บจำนวนออเดอร์แจ้งเตือน
  int _activeOrderCount = 0;

  @override
  void initState() {
    super.initState();
    loadRiderData();
    _fetchActiveOrderBadgeCount();
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;

    final String baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/') ? "$baseUrl$rawPath" : "$baseUrl/$rawPath";
  }

  Future<void> loadRiderData() async {
    try {
      final rider = await riderService.getRiderByStudentId(
        GlobalData.usernameRider,
      );

      if (mounted) {
        setState(() {
          if (rider != null) {
            riderModel = rider;
            riderImage = _getFinalImageUrl(rider.studentCardImage);
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading rider profile in Navbar: $e");
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

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white, // 🎯 เปลี่ยนพื้นหลังเป็นสีขาวแบบ Member
      elevation: 4, // 🎯 เพิ่มเงาแบบ Member
      shadowColor: Colors.black.withOpacity(0.25),
      automaticallyImplyLeading: false,
      title: Text(
        widget.title,
        style: const TextStyle(
          color: Colors.black87, // 🎯 ข้อความสีดำ/เทาเข้มแบบ Member
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,

      // ─── ปุ่ม Home (ด้านซ้าย) ───
      leading: IconButton(
        icon: const Icon(
          Icons.home_outlined,
          color: NavbarRider._orange, // 🎯 เปลี่ยนไอคอนเป็นสีส้มแบบ Member
          size: 35, // 🎯 ขนาดไอคอนเท่ากับ Member
        ),
        onPressed: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      ),

      actions: [
        // ─── 🎯 ปุ่มการแจ้งเตือนพร้อม Badge สีแดง ───
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_active_outlined,
                color:
                    NavbarRider._orange, // 🎯 เปลี่ยนไอคอนเป็นสีส้มแบบ Member
                size: 32, // 🎯 ขนาดไอคอนใกล้เคียงกับตะกร้าของ Member
              ),
              onPressed: () {
                // 🎯 เมื่อคลิกให้เปิดหน้า ListWaitingPickupOrder
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ListWaitingPickupOrder(),
                  ),
                ).then((_) {
                  // รีเฟรชแจ้งเตือนเมื่อกลับมาที่หน้าเดิม
                  _fetchActiveOrderBadgeCount();
                });
              },
            ),
            if (_activeOrderCount > 0)
              Positioned(
                right: 4, // 🎯 ปรับตำแหน่งให้เหมือน Member
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18, // 🎯 ขนาด badge แบบ Member
                    minHeight: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white, // 🎯 ขอบสีขาวให้เหมือน Member
                      width: 1.5,
                    ),
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
        const SizedBox(width: 12),

        // ─── รูปโปรไฟล์ (มุมขวาบน) ───
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileRider()),
              ).then((_) {
                loadRiderData();
              });
            },
            child: CircleAvatar(
              radius: 18, // 🎯 ขนาดวงกลมโปรไฟล์เท่า Member
              backgroundColor: const Color(
                0xFFFFEBCC,
              ), // 🎯 พื้นหลังสีส้มอ่อนแบบ Member
              backgroundImage: (riderImage != null && riderImage!.isNotEmpty)
                  ? NetworkImage(Uri.encodeFull(riderImage!))
                  : null,
              onBackgroundImageError:
                  (riderImage != null && riderImage!.isNotEmpty)
                  ? (_, __) {}
                  : null,
              child: (riderImage == null || riderImage!.isEmpty)
                  ? const Icon(
                      Icons.sports_motorsports_rounded,
                      color: NavbarRider._orange, // 🎯 ไอคอนข้างในสีส้ม
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
