// features/member/navbar_member.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/member_model.dart';
import 'package:flutter_app/data/services/member/member_service.dart';
import 'package:flutter_app/features/member/cart_manager_member.dart'; // ← เพิ่ม import นี้
import 'package:flutter_app/features/member/home_member.dart';
import 'package:flutter_app/features/member/list_order_member.dart';
import 'package:flutter_app/features/member/profile_member.dart';
import 'package:flutter_app/global_data.dart';
import 'package:flutter_app/core/network/dio_client.dart';

class NavbarMember extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  const NavbarMember({super.key, required this.title});

  static const Color _orange = Color(0xFFFF8C00);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<NavbarMember> createState() => _NavbarMemberState();
}

class _NavbarMemberState extends State<NavbarMember> with RouteAware {
  final MemberService memberService = MemberService();
  MemberModel? memberModel;
  String? memberImage;

  @override
  void initState() {
    super.initState();
    loadMemberData();
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;

    final String baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/') ? "$baseUrl$rawPath" : "$baseUrl/$rawPath";
  }

  Future<void> loadMemberData() async {
    try {
      final member = await memberService.getMemberByUsername(
        GlobalData.usernameMember,
      );

      if (mounted) {
        setState(() {
          if (member != null) {
            memberModel = member;
            memberImage = _getFinalImageUrl(member.profileimg);
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading member profile in Navbar: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 ดึงจำนวนรายการในตะกร้าตรงนี้ทุกครั้งที่ build ใหม่
    // (rebuild เกิดขึ้นอัตโนมัติเมื่อ Navigator.push กลับมาที่หน้านี้พอดี)
    final int cartItemCount = CartManager().items.length;

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
        ),
      ),
      centerTitle: true,

      leading: IconButton(
        icon: const Icon(
          Icons.home_outlined,
          color: NavbarMember._orange,
          size: 35,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomeMember()),
          );
        },
      ),

      actions: [
        // 🎯 ห่อไอคอนตะกร้าด้วย Stack เพื่อวาง badge ตัวเลขมุมขวาบน
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(
                Icons.shopping_cart_outlined,
                color: NavbarMember._orange,
                size: 32,
              ),
              onPressed: () async {
                // ใช้ await + then แบบง่ายด้วย setState หลังกลับมา
                // เผื่อผู้ใช้ลบของออกจากตะกร้าแล้วเลขต้องอัปเดต
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ListOrderMember(),
                  ),
                );
                if (mounted) setState(() {});
              },
            ),
            if (cartItemCount > 0)
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
                    cartItemCount > 99 ? '99+' : '$cartItemCount',
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
                MaterialPageRoute(builder: (context) => const ProfileMember()),
              );
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFFFEBCC),
              backgroundImage: (memberImage != null && memberImage!.isNotEmpty)
                  ? NetworkImage(Uri.encodeFull(memberImage!))
                  : null,
              onBackgroundImageError:
                  (memberImage != null && memberImage!.isNotEmpty)
                  ? (_, __) {}
                  : null,
              child: (memberImage == null || memberImage!.isEmpty)
                  ? const Icon(
                      Icons.person_outline_rounded,
                      color: NavbarMember._orange,
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
