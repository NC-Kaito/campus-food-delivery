// features/member/login_member.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/member_model.dart';
import 'package:flutter_app/data/services/member/member_service.dart';
import 'package:flutter_app/features/member/home_member.dart';
import 'package:flutter_app/features/user/register_member.dart';
import 'package:flutter_app/global_data.dart';

class LoginMember extends StatefulWidget {
  const LoginMember({super.key});

  @override
  State<LoginMember> createState() => _LoginMemberState();
}

class _LoginMemberState extends State<LoginMember> {
  final MemberService memberService = MemberService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late final TextEditingController usernameController;
  late final TextEditingController passwordController;
  bool _isLoading = false;

  final menuTextStyle = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Colors.green,
  );

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
        MemberModel member = MemberModel(
          username: usernameController.text,
          password: passwordController.text,
        );

        await memberService.doLoginMember(member);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          GlobalData.usernameMember = usernameController.text;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeMember()),
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
      backgroundColor: Colors.white, // พื้นหลังหลักของจอเป็นสีขาวคลีนพรีเมียม
      body: SafeArea(
        top: true,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── 🎯 เอาปุ่มย้อนกลับด้านบนออกตามคำขอ เว้นระยะด้วยช่องไฟสวยงามแทนคราบบบ ───
                const SizedBox(height: 35),

                // ─── ส่วนหัวข้อแสดงชื่อระบบ ───
                const Center(
                  child: Column(
                    children: [
                      Text(
                        'Campus Food Delivery',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2E7D32), // เฉดเขียวสไตล์ Material 3
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'เข้าสู่ระบบสมาชิกเพื่อสั่งอาหาร',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // แบนเนอร์แสดงภาพประกอบล็อกอิน
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    color: Colors.white,
                    child: Image.asset(
                      'assets/images/login_member.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            size: 65,
                            color: Colors.green.shade700,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // ─── ส่วนฟอร์มข้อมูลด้านล่าง (เลเยอร์กล่องแผ่นชีทสีเทาอ่อนหรูหรา) ───
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 390,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 35,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5), // เทาพาสเทลสะอาดตา ไม่มืดมน
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputFieldLabel('ชื่อผู้ใช้ (Username)'),
                      const SizedBox(height: 8),
                      _buildTextFormField(
                        controller: usernameController,
                        hintText: 'กรอกชื่อผู้ใช้ของคุณ',
                        icon: Icons.person_outline_rounded,
                      ),

                      const SizedBox(height: 20),

                      _buildInputFieldLabel('รหัสผ่าน (Password)'),
                      const SizedBox(height: 8),
                      _buildTextFormField(
                        controller: passwordController,
                        hintText: 'กรอกรหัสผ่านผ่านความปลอดภัย',
                        icon: Icons.lock_open_outlined,
                        isPassword: true,
                      ),
                      const SizedBox(height: 40),

                      _buildActionButton(
                        text: 'เข้าสู่ระบบ',
                        onPressed: doLogin,
                        loading: _isLoading,
                        isPrimary: true,
                      ),
                      const SizedBox(height: 14),

                      _buildActionButton(
                        text: 'สร้างบัญชีผู้ใช้ใหม่',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterMember(),
                            ),
                          );
                        },
                        isPrimary: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // ─── 🎯 ส่วนที่เพิ่มใหม่: แถบเมนูด้านล่าง ถอดแบบโมเดลมาจากหน้า HomeUser ───
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomAppBar(
          color: Colors.white,
          elevation: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // ปุ่มหน้าหลัก (กดแล้วดีดกลับไป HomeUser)
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(50),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.home_rounded,
                      color: Colors.grey.shade400,
                      size: 26,
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
              // ปุ่มเข้าสู่ระบบ (สถานะ Active เปิดไฟสีเขียว)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_pin_rounded,
                    color: Colors.green,
                    size: 26,
                  ),
                  const SizedBox(height: 2),
                  Text("เข้าสู่ระบบ", style: menuTextStyle),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputFieldLabel(String labelText) {
    return Text(
      labelText,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.green.shade900,
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'กรุณากรอกข้อมูลในช่องนี้ให้เรียบร้อยครับ';
        }
        return null;
      },
      style: const TextStyle(fontSize: 15, color: Colors.black),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.green.shade600, size: 22),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    bool loading = false,
    required bool isPrimary,
  }) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: const Color(0xFF55FF33).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFF55FF33) : Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? Colors.black87 : Colors.grey.shade700,
                ),
              ),
      ),
    );
  }
}
