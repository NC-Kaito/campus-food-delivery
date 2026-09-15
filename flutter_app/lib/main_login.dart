// features/user/main_login.dart
import 'package:flutter/material.dart';

// 🎯 Models
import 'package:flutter_app/data/models/member_model.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/rider_model.dart';

// 🎯 Services
import 'package:flutter_app/data/services/member/member_service.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/data/services/rider/rider_service.dart';

// 🎯 Home Pages
import 'package:flutter_app/features/user/home_user.dart';
import 'package:flutter_app/features/member/home_member.dart';
import 'package:flutter_app/features/restaurant/home_restaurant.dart';
import 'package:flutter_app/features/rider/home_rider.dart';

// 🎯 Register Pages
import 'package:flutter_app/features/user/register_member.dart';
import 'package:flutter_app/features/restaurant/agrees_restaurant.dart';
import 'package:flutter_app/features/rider/agrees_rider.dart';

import 'package:flutter_app/global_data.dart';

class MainLogin extends StatefulWidget {
  const MainLogin({super.key});

  @override
  State<MainLogin> createState() => _MainLoginState();
}

class _MainLoginState extends State<MainLogin> {
  // 🎯 0 = ลูกค้า (Member), 1 = ร้านค้า (Restaurant), 2 = ไรเดอร์ (Rider)
  int _selectedRole = 0;

  final MemberService memberService = MemberService();
  final RestaurantService restaurantService = RestaurantService();
  final RiderService riderService = RiderService();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late final TextEditingController usernameController;
  late final TextEditingController passwordController;
  late final FocusNode usernameFocus;
  late final FocusNode passwordFocus;

  bool _isLoading = false;
  bool _obscurePassword = true;

  final Color primaryGreen = const Color(0xFF00B300);

  final menuTextStyle = const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: Color(0xFF00B300),
  );

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    passwordController = TextEditingController();
    usernameFocus = FocusNode();
    passwordFocus = FocusNode();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    usernameFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  // 🎯 ฟังก์ชันจัดการสถานะ (สำหรับร้านค้าและไรเดอร์)
  void _handleVerificationStatus(
    String? status,
    Widget homePage,
    String roleName,
  ) {
    if (status == 'close') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade700,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text(
                "บัญชีถูกปิดใช้งาน",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          content: Text(
            "คุณได้ทำการปิดบัญชี$roleNameในระบบเรียบร้อยแล้ว หากต้องการความช่วยเหลือหรือมีข้อสงสัยเพิ่มเติมให้ทำการติดต่อผู้ดูแลระบบเพื่อสอบถามเพิ่มเติม",
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "ตกลง",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (status == 'true') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => homePage),
        (route) => false,
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.mark_email_unread_rounded,
                color: Colors.orange.shade700,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text(
                "รอการอนุมัติ",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          content: Text(
            "บัญชี$roleNameของคุณกำลังอยู่ในระหว่างการตรวจสอบ\nหากแอดมินพิจารณาอนุมัติเรียบร้อยแล้ว จะแจ้งผลให้ทราบทางอีเมล",
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "ตกลง",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  // 🎯 ฟังก์ชันล็อกอินรวม
  Future<void> doLogin() async {
    FocusScope.of(context).unfocus();

    if (formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        if (_selectedRole == 0) {
          // ลูกค้า (Member)
          MemberModel member = MemberModel(
            username: usernameController.text.trim(),
            password: passwordController.text,
          );
          await memberService.doLoginMember(member);
          GlobalData.usernameMember = usernameController.text.trim();

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeMember()),
              (route) => false,
            );
          }
        } else if (_selectedRole == 1) {
          // ร้านค้า (Restaurant)
          final restaurant = await restaurantService.doLoginRestaurant(
            usernameController.text.trim(),
            passwordController.text,
          );
          GlobalData.usernameRestaurant = usernameController.text.trim();

          if (mounted) {
            _handleVerificationStatus(
              restaurant.verificationStatus,
              const HomeRestaurant(),
              "ร้านค้า",
            );
          }
        } else if (_selectedRole == 2) {
          // ไรเดอร์ (Rider)
          RiderModel rider = RiderModel(
            studentid: usernameController.text.trim(),
            password: passwordController.text,
          );
          await riderService.doLoginRider(rider);
          final loggedInRider = await riderService.getRiderByStudentId(
            usernameController.text.trim(),
          );
          GlobalData.usernameRider = usernameController.text.trim();

          if (mounted) {
            _handleVerificationStatus(
              loggedInRider.verificationStatus,
              const HomeRider(),
              "ผู้จัดส่ง",
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String inputLabel = _selectedRole == 2
        ? 'รหัสนักศึกษา (Student ID)'
        : 'ชื่อผู้ใช้ (Username)';
    String inputHint = _selectedRole == 2
        ? 'กรอกรหัสนักศึกษา'
        : 'กรอกชื่อผู้ใช้ของคุณ';
    IconData inputIcon = _selectedRole == 2
        ? Icons.badge_outlined
        : Icons.person_outline_rounded;

    String registerBtnText = _selectedRole == 0
        ? 'สร้างบัญชีผู้ใช้ใหม่'
        : _selectedRole == 1
        ? 'ลงทะเบียนเปิดร้านใหม่'
        : 'สมัครเป็นไรเดอร์';

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 254, 254),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          top: true,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ─── โลโก้แอปพลิเคชัน ───
                  Container(
                    height: 240,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Image.asset(
                      'assets/images/campusFood_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/image/campusFoodDelivery_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8FCD0),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Icon(
                                Icons.delivery_dining_rounded,
                                size: 60,
                                color: primaryGreen,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── กล่องฟอร์ม ───
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      // 🎯 เส้นขอบไล่เฉดสีเขียว (gradient border) แทนเส้นดำทึบเดิม
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryGreen,
                          primaryGreen.withOpacity(0.45),
                          const Color(0xFFCFF5B4),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryGreen.withOpacity(0.20),
                          blurRadius: 28,
                          spreadRadius: 1,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    // 🎯 padding ตรงนี้คือ "ความหนา" ของเส้นขอบไล่สี
                    padding: const EdgeInsets.all(1.8),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22.5),
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ─── แถบเลือกบทบาท (Role Selector) ───
                            Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  _buildRoleTab(0, "ลูกค้า"),
                                  _buildRoleTab(1, "ร้านค้า"),
                                  _buildRoleTab(2, "ไรเดอร์"),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ─── ช่องกรอก Username / ID ───
                            _buildInputFieldLabel(inputLabel),
                            const SizedBox(height: 8),
                            _buildTextFormField(
                              controller: usernameController,
                              focusNode: usernameFocus,
                              hintText: inputHint,
                              icon: inputIcon,
                            ),
                            const SizedBox(height: 20),

                            // ─── ช่องกรอก Password ───
                            _buildInputFieldLabel('รหัสผ่าน (Password)'),
                            const SizedBox(height: 8),
                            _buildTextFormField(
                              controller: passwordController,
                              focusNode: passwordFocus,
                              hintText: 'กรอกรหัสผ่านเพื่อความปลอดภัย',
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                            ),
                            const SizedBox(height: 30),

                            // ─── ปุ่ม เข้าสู่ระบบ ───
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : doLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'เข้าสู่ระบบ',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ─── เส้นคั่น "หรือ" ───
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey.shade300,
                                    thickness: 1.2,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    "หรือ",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey.shade300,
                                    thickness: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // ─── ปุ่ม สร้างบัญชี / สมัคร ───
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: () {
                                  FocusScope.of(context).unfocus();
                                  Widget registerPage;
                                  if (_selectedRole == 0) {
                                    registerPage = const RegisterMember();
                                  } else if (_selectedRole == 1) {
                                    registerPage = const AgreesRestaurant();
                                  } else {
                                    registerPage = const AgreesRider();
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => registerPage,
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: primaryGreen,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: Colors.white,
                                ),
                                child: Text(
                                  registerBtnText,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: primaryGreen,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // ─── แถบเมนูด้านล่าง ───
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeUser(),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(50),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.home_rounded,
                        color: Colors.grey.shade400,
                        size: 24,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "หน้าหลัก",
                        style: menuTextStyle.copyWith(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_pin_rounded,
                      color: primaryGreen,
                      size: 24,
                    ),
                    const SizedBox(height: 2),
                    Text("เข้าสู่ระบบ", style: menuTextStyle),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(int roleIndex, String title) {
    bool isSelected = _selectedRole == roleIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRole = roleIndex;
            usernameController.clear();
            passwordController.clear();
            formKey.currentState?.reset();
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputFieldLabel(String labelText) {
    return Text(
      labelText,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: isPassword ? _obscurePassword : false,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'กรุณากรอกข้อมูลในช่องนี้';
        }
        return null;
      },
      style: const TextStyle(fontSize: 14, color: Colors.black),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: Colors.grey.shade700, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFFBFBFC),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primaryGreen.withOpacity(0.3),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreen, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
        ),
      ),
    );
  }
}
