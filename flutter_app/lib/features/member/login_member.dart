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
      backgroundColor: Colors.white, // พื้นหลังหลักของจอเป็นสีขาวตามแบบ 100%
      body: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            children: [
              // ─── ส่วนหัวด้านบน (เลเยอร์สีขาว) ───
              const SizedBox(height: 60),
              const Text(
                'Campus Food Delivery',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),

              // กล่องแสดงรูปภาพแบนเนอร์สมัครสมาชิก
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  color: Colors.white,
                  child: Image.asset(
                    'assets/images/login_member.png', // *อย่าลืมเปลี่ยนชื่อที่อยู่ภาพตามโฟลเดอร์จริงของคุณนะครับ*
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.shopping_bag_outlined,
                        size: 80,
                        color: Colors.green,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── ส่วนฟอร์มข้อมูลด้านล่าง (เลเยอร์กล่องสีเทาโค้งมนลอยขึ้นมา) ───
              Container(
                width: double.infinity,
                // กำหนดความยาวขั้นต่ำให้กล่องสีเทากินพื้นที่คลุมลงไปจนสุดขอบหน้าจอ
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 318,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 35,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFEEEEEE), // สีเทาอ่อนตามภาพม็อคอัพ
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ฟิลด์ Username
                    _buildInputFieldLabel('ชื่อผู้ใช้ (Username)'),
                    const SizedBox(height: 8),
                    _buildTextFormField(
                      controller: usernameController,
                      hintText: '',
                      icon: Icons.person_outline, // สไตล์ไอคอนโครงเส้นบางตามแบบ
                    ),

                    const SizedBox(height: 24),

                    // ฟิลด์ Password
                    _buildInputFieldLabel('รหัสผ่าน (Password)'),
                    const SizedBox(height: 8),
                    _buildTextFormField(
                      controller: passwordController,
                      hintText: '',
                      icon: Icons.lock_open_outlined,
                      isPassword: true,
                    ),
                    const SizedBox(height: 45),

                    // ปุ่มเข้าสู่ระบบ (สีเขียวสว่าง มีเอฟเฟกต์เงาฟุ้งด้านล่าง)
                    _buildActionButton(
                      text: 'เข้าสู่ระบบ',
                      onPressed: doLogin,
                      loading: _isLoading,
                    ),
                    const SizedBox(height: 18),

                    // ปุ่มสมัครสมาชิก
                    _buildActionButton(
                      text: 'สมัครสมาชิก',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterMember(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget สร้างหัวข้อกำกับฟิลด์
  Widget _buildInputFieldLabel(String labelText) {
    return Text(
      labelText,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  // Widget ตกแต่งรูปทรงช่องป้อนข้อมูล (ขอบเหลี่ยมมน พื้นขาว เส้นขอบบาง)
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
          return 'กรุณากรอกข้อมูลช่องนี้';
        }
        return null;
      },
      style: const TextStyle(fontSize: 16, color: Colors.black),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 10, right: 4),
          child: Icon(icon, color: Colors.grey[500], size: 26),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20), // ความโค้งมนตามภาพต้นแบบ
          borderSide: const BorderSide(color: Colors.grey, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  // Widget ตกแต่งกลุ่มปุ่มควบคุมสีเขียวสว่างสะท้อนแสง + พร้อมเงา (BoxShadow) บดบังความแข็งกระด้าง
  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    bool loading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.15,
            ), // มิติเงาดำจาง ๆ ทอดลงด้านล่างปุ่ม
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(
            0xFF55FF33,
          ), // เฉดสีเขียวสว่างตรงตามภาพ UI 100%
          foregroundColor: Colors.black,
          elevation:
              0, // ปิดเงาเริ่มต้นของตัวปุ่มเพื่อใช้เงา Custom ด้านบนที่เนียนกว่า
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
