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
            riderImage = _getFinalImageUrl(rider.profileImage);
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading rider profile in Navbar: $e");
    }
  }

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
      backgroundColor: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.25),
      automaticallyImplyLeading: false,
      title: Text(
        widget.title,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,

      actions: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            if (_activeOrderCount > 0)
              Positioned(
                right: 4,
                top: 4,
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
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileRider()),
              ).then((_) {
                // 🎯 เมื่อผู้ใช้กดปุ่ม Home กลับมาจาก Profile ให้โหลดข้อมูล Navbar ใหม่ทันที
                loadRiderData();
              });
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFFFEBCC),
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
                      color: NavbarRider._orange,
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
