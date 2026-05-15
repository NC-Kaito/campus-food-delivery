import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/admin_model.dart';
import 'package:flutter_app/data/services/Admin/admin_service.dart';
import 'package:flutter_app/features/admin/home_admin.dart';
import 'admin_navbar.dart'; // เปลี่ยน path ตาม structure โปรเจกต์

class LoginAdmin extends StatefulWidget {
  const LoginAdmin({super.key});

  @override
  State<LoginAdmin> createState() => _LoginAdminState();
}

class _LoginAdminState extends State<LoginAdmin> {
  final AdminService adminService = AdminService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late final TextEditingController usernameController;
  late final TextEditingController passwordController;

  bool _isLoading = false;

  static const Color _orange = Color(0xFFFF8C00);
  static const Color _green = Color(0xFF4CAF50);

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

  //-----------------------------------------------------------------------
  Future<void> doLogin() async {
    // ตรวจสอบความถูกต้องผ่าน formKey (ต้องครอบ Form ไว้ใน UI ก่อนถึงจะไม่พัง)
    if (formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        print("Try to Login");
        AdminModel admin = AdminModel(
          username: usernameController.text,
          password: passwordController.text,
        );

        await adminService.doLoginAdmin(admin);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeAdmin()),
            (route) => false,
          );
        }
      } catch (e) {
        print("ERROR: $e");
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

  //-------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      // appBar: const AdminNavbar(), // ← เรียกใช้ AdminNavbar
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header Icon + Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.account_circle,
                        size: 64,
                        color: _orange,
                      ),
                      Positioned(
                        right: -6,
                        bottom: -6,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(
                            Icons.settings,
                            size: 26,
                            color: _orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Login Admin',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _orange,
                        ),
                      ),
                      Text(
                        'กรุณาเข้าสู่ระบบด้วยบัญชีผู้ดูแลระบบ',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Login Card
              Container(
                width: 500,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 231, 231, 231),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      label: 'ชื่อผู้ใช้ (Username)',
                      hint: 'กรุณากรอกชื่อผู้ใช้',
                      icon: Icons.person_outline,
                      controller: usernameController,
                    ),
                    const SizedBox(height: 30),
                    _buildTextField(
                      label: 'รหัสผ่าน (Password)',
                      hint: 'กรุณากรอกรหัสผ่าน',
                      icon: Icons.lock_outline,
                      controller: passwordController,
                      isPassword: true,
                    ),

                    const SizedBox(height: 30),
                    _buildButton(
                      text: 'เข้าสู่ระบบ',
                      onPressed: doLogin,
                      color: const Color(0xFF76FF03),
                      loading: _isLoading,
                    ),

                    const SizedBox(height: 30),

                    Center(
                      child: Text(
                        'หากลืมรหัสผ่าน โปรดติดต่อฝ่าย IT',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color.fromARGB(136, 59, 195, 25),
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
    );
  }

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

        TextFormField(
          controller: controller,
          obscureText: isPassword,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณากรอก$label';
            }
            return null;
          },
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
        // ถ้ากำลังโหลด ให้ปุ่มกดไม่ได้ (เป็น null)
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
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
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
