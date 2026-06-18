// features/member/navbar_member.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/member_model.dart';
import 'package:flutter_app/data/services/member/member_service.dart';
import 'package:flutter_app/features/member/home_member.dart';
import 'package:flutter_app/features/member/list_order_member.dart';
import 'package:flutter_app/features/member/profile_member.dart';
import 'package:flutter_app/global_data.dart';
import 'package:flutter_app/core/network/dio_client.dart'; // 🎯 เรียกใช้ไอพีตัวกลางเซิร์ฟเวอร์หลัก

class NavbarMember extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  const NavbarMember({super.key, required this.title});

  static const Color _orange = Color(0xFFFF8C00);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<NavbarMember> createState() => _NavbarMemberState();
}

class _NavbarMemberState extends State<NavbarMember> {
  final MemberService memberService = MemberService();
  MemberModel? memberModel;
  String? memberImage;

  @override
  void initState() {
    super.initState();
    loadMemberData();
  }

  // ฟังก์ชันเชื่อมพาร์ทสั้นเข้าไอพีเซิร์ฟเวอร์ส่วนกลางหลัก
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
            // 🎯 ปรับให้แมตช์เข้าสายแปลงพาร์ทผ่าน Base URL ไอพีกลาง ปลอดภัยรูปไม่หลุด
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
        IconButton(
          icon: const Icon(
            Icons.shopping_cart_outlined,
            color: NavbarMember._orange,
            size: 32,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ListOrderMember()),
            );
          },
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
