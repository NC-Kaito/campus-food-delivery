// features/restaurant/login_restaurant.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/features/restaurant/agrees_restaurant.dart';
import 'package:flutter_app/features/restaurant/home_restaurant.dart';
import 'package:flutter_app/features/restaurant/wait_approve.dart';
import 'package:flutter_app/global_data.dart';

class LoginRestaurant extends StatefulWidget {
  const LoginRestaurant({super.key});

  @override
  State<LoginRestaurant> createState() => _LoginRestaurantState();
}

class _LoginRestaurantState extends State<LoginRestaurant> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late final TextEditingController usernameController;
  late final TextEditingController passwordController;
  bool _isLoading = false;
  bool _obscureText = true;

  @override
  void initState() {
    usernameController = TextEditingController();
    passwordController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> doLogin() async {
    if (formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final restaurant = await RestaurantService().doLoginRestaurant(
          usernameController.text,
          passwordController.text,
        );

        if (mounted) {
          setState(() => _isLoading = false);
          GlobalData.usernameRestaurant = usernameController.text;

          final status = restaurant.verificationStatus;

          // --- ส่วนตรวจสอบสถานะ 'close' ---
          if (status == 'close') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'บัญชีนี้ถูกปิดใช้งานแล้ว',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          if (status == 'true') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeRestaurant()),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => WaitApprove(
                  verificationStatus: status ?? 'wait',
                  notApproveDetail: restaurant.notApproveDetail,
                ),
              ),
              (route) => false,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.transparent, // 🎯 ให้ Scaffold โปร่งใสเพื่อโชว์พื้นหลัง
      body: Stack(
        children: [
          // 🎯 เลเยอร์ที่ 1: พื้นหลัง 2 สี (บนขาว - ล่างเขียว)
          Container(
            height: MediaQuery.of(context).size.height,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white, // สีครึ่งบน
                  Color.fromARGB(255, 210, 210, 210), // สีครึ่งล่าง (เขียว)
                ],
                stops: [
                  0.40,
                  0.40,
                ], // 🎯 จุดตัดสี (เปลี่ยนเลขตรงนี้ถ้าอยากให้สีขาวหรือสีเขียวเยอะขึ้น)
              ),
            ),
          ),

          // 🎯 เลเยอร์ที่ 2: เนื้อหาเดิมของคุณทั้งหมด
          SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  // ─── ส่วนที่ 1: ข้อความส่วนหัว (White Header) ───
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Column(
                      children: [
                        SizedBox(height: 70),
                        Text(
                          'Restaurant',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2ECC40),
                          ),
                        ),
                        Text(
                          'Campus Food Delivery',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 30),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20), // ระยะห่างระหว่างหัวกับรูป
                  // ─── ส่วนที่ 2: รูปภาพแบนเนอร์ (ตำแหน่งเดิม) ───
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: Image.asset(
                      'assets/images/restaurant_banner.png',
                      height: 210, // ปรับความสูงให้พอดี
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 30), // ระยะห่างก่อนถึงฟอร์ม
                  // ─── ส่วนที่ 3: ฟอร์มกรอกข้อมูล (ลอยซ้อนขึ้นมา) ───
                  Transform.translate(
                    offset: const Offset(
                      0,
                      -30,
                    ), // 🎯 ลูกเล่น: ดึงกล่องฟอร์มลอยซ้อนทับภาพนิดนึงเพื่อมิติ
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: const Text(
                                "เข้าสู่ระบบ",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(221, 255, 128, 0),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Username Field
                            _buildLabel('ชื่อผู้ใช้ (Username)'),
                            _buildCustomTextField(
                              controller: usernameController,
                              hintText: 'กรอกชื่อผู้ใช้ของคุณ',
                              icon: Icons.person_outline_rounded,
                              obscure: false,
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return "กรุณากรอกชื่อผู้ใช้";
                                if (value.contains(' '))
                                  return "ต้องไม่มีช่องว่าง";
                                if (!RegExp(
                                  r'^[a-zA-Z0-9]+$',
                                ).hasMatch(value)) {
                                  return "ภาษาอังกฤษหรือตัวเลขเท่านั้น";
                                }
                                if (value.length < 6 || value.length > 20) {
                                  return "ความยาว 6-20 ตัวอักษร";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Password Field
                            _buildLabel('รหัสผ่าน (Password)'),
                            _buildCustomTextField(
                              controller: passwordController,
                              hintText: 'กรอกรหัสผ่านของคุณ',
                              icon: Icons.lock_outline_rounded,
                              obscure: _obscureText,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey[500],
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () => _obscureText = !_obscureText,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return "กรุณากรอกรหัสผ่าน";
                                if (value.length < 8)
                                  return "รหัสผ่านต้องมี 8 ตัวอักษรขึ้นไป";
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),

                            // ปุ่มเข้าสู่ระบบ
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(
                                    0xFF76FF03,
                                  ), // เขียวหลักของแอป
                                  foregroundColor: Colors.black,
                                  elevation: 4,
                                  shadowColor: const Color(
                                    0xFF76FF03,
                                  ).withOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _isLoading ? null : doLogin,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.black,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        'เข้าสู่ระบบ',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ส่วนสมัครสมาชิก
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "ต้องการเปิดร้านใหม่? ",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const AgreesRestaurant(),
                                      ),
                                    ),
                                    child: const Text(
                                      "สมัครสมาชิก",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // เผื่อระยะด้านล่าง
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          children: const [
            TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool obscure,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey.shade100, // สีพื้นหลังช่องกรอกเบาๆ
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF76FF03), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}
