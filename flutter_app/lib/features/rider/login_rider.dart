import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/rider_model.dart';
import 'package:flutter_app/data/services/rider/rider_service.dart';
import 'package:flutter_app/features/rider/agrees_rider.dart';
import 'package:flutter_app/features/rider/home_rider.dart'; // หน้า Home ของ Rider
// import 'package:flutter_app/features/rider/register_rider.dart'; // หน้า Register ของ Rider
import 'package:flutter_app/global_data.dart';

class LoginRider extends StatefulWidget {
  const LoginRider({super.key});

  @override
  State<LoginRider> createState() => _LoginRiderState();
}

class _LoginRiderState extends State<LoginRider> {
  // ✅ เปลี่ยนมาใช้ RiderService
  final RiderService riderService = RiderService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late final TextEditingController studentIdController;
  late final TextEditingController passwordController;
  bool _isLoading = false;

  @override
  void initState() {
    // ✅ Rider ใช้ Student ID ในการ Login
    studentIdController = TextEditingController();
    passwordController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    studentIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> doLogin() async {
    if (formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        // ✅ สร้าง RiderModel เพื่อส่งไป Login
        RiderModel rider = RiderModel(
          studentid: studentIdController.text,
          password: passwordController.text,
        );

        await riderService.doLoginRider(rider);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // ✅ เก็บข้อมูลลง GlobalData (ปรับชื่อตัวแปรตามที่คุณมี)
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
      // แนะนำให้ใช้ AppBar ของ Rider หรือแบบทั่วไป
      appBar: AppBar(
        title: const Text("Rider Login"),
        backgroundColor: Colors.orange, // ใช้สีส้มเพื่อให้ต่างจาก Member
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              const Text(
                'Campus Delivery - Rider',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.delivery_dining,
                  size: 80,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 30),
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
                    _buildTextField(
                      label: 'รหัสนักศึกษา (Student ID)',
                      hint: 'กรุณากรอกรหัสนักศึกษา',
                      icon: Icons.badge_outlined,
                      controller: studentIdController,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'รหัสผ่าน (Password)',
                      hint: 'กรุณากรอกรหัสผ่าน',
                      icon: Icons.lock_outline,
                      controller: passwordController,
                      isPassword: true,
                    ),
                    const SizedBox(height: 30),
                    _buildButton(
                      text: 'เข้าสู่ระบบไรเดอร์',
                      onPressed: doLogin,
                      color: Colors.orange,
                      loading: _isLoading,
                    ),
                    const SizedBox(height: 15),
                    _buildButton(
                      text: 'สมัครเป็นไรเดอร์',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AgreesRider(),
                          ),
                        );
                      },
                      color: Colors.orange[200]!,
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
                  color: Colors.white,
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
