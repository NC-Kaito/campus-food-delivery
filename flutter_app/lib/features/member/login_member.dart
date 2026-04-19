import 'package:flutter/material.dart';
import 'package:flutter_app/features/member/shared_appbar_member.dart';
import 'package:flutter_app/features/user/register_member.dart';

class LoginMember extends StatefulWidget {
  const LoginMember({super.key});

  @override
  State<LoginMember> createState() => _LoginMemberState();
}

class _LoginMemberState extends State<LoginMember> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isNotEmpty && password.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          // เช็คว่าหน้าจอยังเปิดอยู่ไหมก่อน setState
          setState(() {
            _isLoading = false;
          });
          print('Login attempts with: $username, $password');
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          const SharedAppBarMember(), // เรียกใช้ตัวที่คุณเพิ่งแก้ preferredSize ไป
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          children: [
            const Text(
              'Campus Food Delivery',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Illustration Placeholder
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.image, size: 50, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Form Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFDFDFD),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // หมายเหตุ: อย่าลืมสร้างคลาส CustomTextField และ PrimaryButton ไว้ในโปรเจกต์ด้วยนะครับ
                  _buildTextField(
                    label: 'ชื่อผู้ใช้ (Username)',
                    hint: 'กรุณากรอกชื่อผู้ใช้',
                    icon: Icons.person_outline,
                    controller: _usernameController,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'รหัสผ่าน (Password)',
                    hint: 'กรุณากรอกรหัสผ่าน',
                    icon: Icons.lock_outline,
                    controller: _passwordController,
                    isPassword: true,
                  ),
                  const SizedBox(height: 30),

                  // ปุ่ม Login
                  _buildButton(
                    text: 'เข้าสู่ระบบ',
                    onPressed: _handleLogin,
                    color: const Color(0xFF76FF03),
                    loading: _isLoading,
                  ),
                  const SizedBox(height: 15),

                  // ปุ่มสมัครสมาชิก
                  _buildButton(
                    text: 'สมัครสมาชิก',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterMember(),
                        ),
                      );
                    },
                    color: const Color(0xFF76FF03),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันช่วยสร้าง TextField แบบง่ายๆ ภายในไฟล์เดียว
  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // ฟังก์ชันช่วยสร้างปุ่มแบบง่ายๆ
  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    required Color color,
    bool loading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: loading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                text,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
