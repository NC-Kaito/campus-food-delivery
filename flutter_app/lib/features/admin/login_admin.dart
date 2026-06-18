import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/admin_model.dart';
import 'package:flutter_app/data/services/Admin/admin_service.dart';
import 'package:flutter_app/features/admin/home_admin.dart';

class LoginAdmin extends StatefulWidget {
  const LoginAdmin({super.key});

  @override
  State<LoginAdmin> createState() => _LoginAdminState();
}

class _LoginAdminState extends State<LoginAdmin>
    with SingleTickerProviderStateMixin {
  final AdminService adminService = AdminService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late final TextEditingController usernameController;
  late final TextEditingController passwordController;
  late final AnimationController _animController;
  late final Animation<double> _floatAnim;

  bool _isLoading = false;

  static const Color _orange = Color(0xFFFF8C00);
  static const Color _green = Color(0xFF4CAF50);

  @override
  void initState() {
    usernameController = TextEditingController();
    passwordController = TextEditingController();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    super.initState();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> doLogin() async {
    if (formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        print("Try to Login");
        AdminModel admin = AdminModel(
          username: usernameController.text,
          password: passwordController.text,
        );
        await adminService.doLoginAdmin(admin);
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeAdmin()),
            (route) => false,
          );
        }
      } catch (e) {
        print("ERROR: $e");
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient Background ────────────────────────────────────────
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(255, 255, 255, 255),
                  Color.fromARGB(255, 255, 255, 255),
                  Color.fromARGB(255, 255, 255, 255),
                ],
              ),
            ),
          ),

          // ── Decorative Circles ─────────────────────────────────────────
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _orange.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -60,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _orange.withOpacity(0.06),
              ),
            ),
          ),

          // ── Floating Food Emojis ───────────────────────────────────────
          AnimatedBuilder(
            animation: _floatAnim,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    left: size.width * 0.25,
                    top: size.height * 0.85 - _floatAnim.value,
                    child: _buildFoodEmoji('🍕', 142),
                  ),
                  Positioned(
                    left: size.width * 0.04,
                    top: size.height * 0.78 + _floatAnim.value * 0.7,
                    child: _buildFoodEmoji('🧋', 180),
                  ),
                  Positioned(
                    left: size.width * 0.15,
                    top: size.height * 0.78 - _floatAnim.value * 0.5,
                    child: _buildFoodEmoji('🍜', 200),
                  ),

                  Positioned(
                    right: size.width * 0.28,
                    top: size.height * 0.85 + _floatAnim.value,
                    child: _buildFoodEmoji('🌮', 142),
                  ),
                  Positioned(
                    right: size.width * 0.05,
                    top: size.height * 0.78 - _floatAnim.value * 0.6,
                    child: _buildFoodEmoji('🍦', 200),
                  ),
                  Positioned(
                    right: size.width * 0.17,
                    top: size.height * 0.78 + _floatAnim.value * 0.8,
                    child: _buildFoodEmoji('🍔', 200),
                  ),
                ],
              );
            },
          ),

          // ── โค้ดเดิมของคุณ ─────────────────────────────────────────────
          Form(
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
                            'Login Admin\nCampus Food Delivery', // แก้ไขจาก \ เป็น \n เพื่อให้ขึ้นบรรทัดใหม่สวยๆ
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(255, 140, 0, 1),
                            ),
                          ),
                          const SizedBox(
                            height: 8,
                          ), // เพิ่มระยะห่างระหว่างข้อความบนกับล่าง (ถ้าต้องการ)
                          Text(
                            'กรุณาเข้าสู่ระบบด้วยบัญชีผู้ดูแลระบบ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color.fromARGB(137, 0, 0, 0),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Login Card
                  Container(
                    width: 600,
                    height: 450,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 237, 237, 237),
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
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildFoodEmoji(String emoji, double size) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 232, 206).withOpacity(0.7),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.7)),
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
                  color: Color.fromARGB(255, 150, 73, 73),
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
