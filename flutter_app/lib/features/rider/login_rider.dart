// features/rider/login_rider.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/rider_model.dart';
import 'package:flutter_app/data/services/rider/rider_service.dart';
import 'package:flutter_app/features/rider/agrees_rider.dart';
import 'package:flutter_app/features/rider/home_rider.dart';
import 'package:flutter_app/global_data.dart';

class LoginRider extends StatefulWidget {
  const LoginRider({super.key});

  @override
  State<LoginRider> createState() => _LoginRiderState();
}

class _LoginRiderState extends State<LoginRider> {
  final RiderService riderService = RiderService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late final TextEditingController studentIdController;
  late final TextEditingController passwordController;

  // 🎯 เพิ่ม FocusNode เพื่อป้องกันอาการพิมพ์แล้วลบไม่ได้
  late final FocusNode studentIdFocus;
  late final FocusNode passwordFocus;

  bool _isLoading = false;
  bool _obscurePassword = true;

  // 🎯 โทนสีเขียวเดียวกับ Member
  final menuTextStyle = const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: Color(0xFF64F02D),
  );

  @override
  void initState() {
    super.initState();
    studentIdController = TextEditingController();
    passwordController = TextEditingController();
    studentIdFocus = FocusNode();
    passwordFocus = FocusNode();
  }

  @override
  void dispose() {
    studentIdController.dispose();
    passwordController.dispose();
    studentIdFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  Future<void> doLogin() async {
    // ปิดคีย์บอร์ดเวลาคลิกปุ่มเข้าสู่ระบบ
    FocusScope.of(context).unfocus();

    if (formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        RiderModel rider = RiderModel(
          studentid: studentIdController.text,
          password: passwordController.text,
        );

        await riderService.doLoginRider(rider);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          GlobalData.usernameRider = studentIdController.text;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeRider()),
            (route) => false,
          );
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
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF9),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          top: true,
          // 🎯 เพิ่ม Center ครอบ SingleChildScrollView เพื่อให้เนื้อหาอยู่กึ่งกลางจอ
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ─── โลโก้ ───
                  Container(
                    height: 120,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Image.asset(
                      'assets/images/login_rider.png', // 🎯 เปลี่ยนชื่อรูปถ้ามี หรือจะใช้ Icon แทน
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8FCD0),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(20),
                          child: const Icon(
                            Icons
                                .sports_motorsports_rounded, // 🎯 ไอคอนสำหรับไรเดอร์
                            size: 60,
                            color: Color(0xFF64F02D),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── กล่องฟอร์ม (Card) ───
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF64F02D).withOpacity(0.06),
                          blurRadius: 30,
                          spreadRadius: 4,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── รหัสนักศึกษา (Student ID) ───
                          _buildInputFieldLabel('รหัสนักศึกษา (Student ID)'),
                          const SizedBox(height: 8),
                          _buildTextFormField(
                            controller: studentIdController,
                            focusNode: studentIdFocus,
                            hintText: 'กรอกรหัสนักศึกษาของคุณ',
                            icon: Icons.badge_outlined,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),

                          // ─── รหัสผ่าน (Password) ───
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
                                backgroundColor: const Color(0xFF64F02D),
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
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Text(
                                          'เข้าสู่ระบบไรเดอร์',
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

                          // ─── ปุ่ม สมัครเป็นไรเดอร์ ───
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AgreesRider(),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF64F02D),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: Colors.white,
                              ),
                              child: const Text(
                                'สมัครเป็นไรเดอร์',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF64F02D),
                                ),
                              ),
                            ),
                          ),
                        ],
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
              color: Colors.black.withOpacity(0.04),
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
                    Navigator.pop(context);
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
                    const Icon(
                      Icons.sports_motorsports_rounded,
                      color: Color(0xFF64F02D),
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: keyboardType,
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
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
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
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF64F02D), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}
