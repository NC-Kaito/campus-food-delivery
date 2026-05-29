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
      setState(() {
        _isLoading = true;
      });
      try {
        final restaurant = await RestaurantService().doLoginRestaurant(
          usernameController.text,
          passwordController.text,
        );
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          GlobalData.usernameRestaurant = usernameController.text;
          final status = restaurant.verificationStatus;
          // ── ค้นหาท่อน if-else ด้านล่างนี้ในฟังก์ชัน doLogin แล้วเปลี่ยนเป็นชุดนี้ครับ ──
          if (status == 'true') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeRestaurant()),
              (route) => false,
            );
          } else {
            // มั่นใจว่าส่งค่าทั้ง 2 ตัวข้ามไปหน้า WaitApprove ไม่ว่าจะ wait หรือ false
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
          setState(() {
            _isLoading = false;
          });
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
    // สีฟ้าเริ่มต้นที่ offset นี้ (ครึ่งล่างของ header)
    const double blueStartOffset = 290;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height, // ← เพิ่มตรงนี้
            ),
            child: Stack(
              children: [
                Positioned(
                  top: blueStartOffset,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: const Color.fromARGB(255, 219, 219, 219),
                  ),
                ),

                Column(
                  children: [
                    // ข้อความบนพื้นขาว
                    Container(
                      color: Colors.white,
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 60, bottom: 10),
                      child: const Column(
                        children: [
                          Text(
                            'Restaurant',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2ECC40),
                            ),
                          ),
                          Text(
                            'Campus Food Delivery',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2ECC40),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // รูป banner ลอยอยู่เหนือสีฟ้า
                    Image.asset(
                      'assets/images/restaurant_banner.png',
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                    ),
                    const SizedBox(height: 30),
                    // ── Form card ──────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 219, 219, 219),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(
                                255,
                                0,
                                0,
                                0,
                              ).withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: const TextSpan(
                                text: 'ชื่อผู้ใช้ (Username) ',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                children: [
                                  TextSpan(
                                    text: '*',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            _buildTextFormField(
                              controller: usernameController,
                              icon: Icons.person_outline,
                              obscure: false,
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return "กรุณากรอกชื่อผู้ใช้";
                                if (value.contains(' '))
                                  return "ชื่อผู้ใช้ต้องไม่มีช่องว่าง";
                                if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value))
                                  return "ต้องเป็นภาษาอังกฤษหรือตัวเลขเท่านั้น";
                                if (value.length < 6 || value.length > 20)
                                  return "ต้องมีความยาว 6-20 ตัวอักษร";
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            RichText(
                              text: const TextSpan(
                                text: 'รหัสผ่าน (Password) ',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                children: [
                                  TextSpan(
                                    text: '*',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextFormField(
                              controller: passwordController,
                              icon: Icons.lock_outline,
                              obscure: _obscureText,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () => setState(
                                  () => _obscureText = !_obscureText,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return "กรุณากรอกรหัสผ่าน";
                                if (value.contains(' '))
                                  return "รหัสผ่านต้องไม่มีช่องว่าง";
                                if (value.length < 8)
                                  return "รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร";
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    51,
                                    255,
                                    0,
                                  ),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: _isLoading ? null : doLogin,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'เข้าสู่ระบบ',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    51,
                                    255,
                                    0,
                                  ),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const AgreesRestaurant(),
                                  ),
                                ),
                                child: const Text(
                                  'สมัครสมาชิก',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required IconData icon,
    required bool obscure,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 219, 219, 219),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey[600], size: 22),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
