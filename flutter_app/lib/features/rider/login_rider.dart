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
  bool _isLoading = false;

  // 🎯 ✅ เคลือบสีเขียวรหัสหลักประจำโปรเจกต์ 0xFF64F02D ตามสั่งเป๊ะครับคุณ Kaito
  final Color primaryGreen = const Color(0xFF64F02D);

  @override
  void initState() {
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
              behavior: SnackBarBehavior
                  .fixed, // ป้องกัน SnackBar บดบัง UI เลเยอร์ล่างพัง
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // คุมพื้นหลังจอนอกสะอาดตาพรีเมียม
      body: SafeArea(
        top: true,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🎯 ✅ เอาแผงปุ่มย้อนกลับและแถบเก่าด้านบนออกถาวรเรียบร้อยครับ ดันระยะหลบสลัวขอบบนสวยงาม
                const SizedBox(height: 35),

                // ส่วนหัวข้อต้อนรับระบบไรเดอร์
                const Center(
                  child: Column(
                    children: [
                      Text(
                        'Campus Delivery - Rider',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2E7D32), // เฉดเขียวสไตล์โมเดิร์น
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'เข้าสู่ระบบไรเดอร์เพื่อรับส่งอาหารรอบมหาวิทยาลัย',
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

                // แบนเนอร์แสดงภาพประกอบล็อกอิน เปลี่ยนรูปภาพทรงกลมเข้าชุดมอเตอร์ไซค์
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Center(
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: const BoxDecoration(color: Colors.white),
                      child: Image.asset(
                        'assets/images/login_rider.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // ดักจับ Fallback กรณีพาร์ทรูปในเครื่องยังไม่สมบูรณ์ วาดวงกลมสไตล์ไอคอนมอเตอร์ไซค์สปอร์ตสีเขียวใหม่แทน
                          return Container(
                            decoration: BoxDecoration(
                              color: primaryGreen.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Icon(
                              Icons.delivery_dining_rounded,
                              size: 70,
                              color: primaryGreen,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // ส่วนก้อนแผ่นฟอร์มกล่องกรอกข้อมูลด้านล่าง (แผ่นชีทสไตล์เทาอ่อนคลีน)
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
                    color: const Color(0xFFF5F5F5),
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
                      _buildTextField(
                        label: 'รหัสนักศึกษา (Student ID)',
                        hint: 'กรุณากรอกรหัสนักศึกษา',
                        icon: Icons.badge_outlined,
                        controller: studentIdController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        label: 'รหัสผ่าน (Password)',
                        hint: 'กรุณากรอกรหัสผ่าน',
                        icon: Icons.lock_outline_rounded,
                        controller: passwordController,
                        isPassword: true,
                      ),
                      const SizedBox(height: 40),

                      // ปุ่มล็อกอินเข้าสู่ระบบสีเขียว 0xFF64F02D สว่างมีมิติ
                      _buildActionButton(
                        text: 'เข้าสู่ระบบไรเดอร์',
                        onPressed: doLogin,
                        loading: _isLoading,
                        isPrimary: true,
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: Colors.grey, thickness: 0.8),
                      const SizedBox(height: 20),

                      // ปุ่มสร้างบัญชีไรเดอร์สีขาวขอบตัดคม
                      _buildActionButton(
                        text: 'สมัครเป็นไรเดอร์',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AgreesRider(),
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
    );
  }

  // ─── 🎯 ย้อนสไตล์กลับมาใช้โครงสร้าง OutlineInputBorder เพื่อล็อกสเปซเว้นให้ตัวหนังสือ Alert สีแดงเด้งแสดงผลสวยงามชัดเจน ไม่เลอะเทอะ ───
  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          // เปิดตรวจเช็กเรียลไทม์ทีละฟิลด์เฉพาะช่องที่กำลังพิมพ์กรอกอยู่แบบหน้าร้านค้าสากล
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'กรุณากรอกข้อมูลในช่องนี้ให้เรียบร้อยครับ';
            }
            return null;
          },
          style: const TextStyle(fontSize: 15, color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(icon, color: primaryGreen, size: 22),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: primaryGreen, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            // บังคับสลับทิศทางฟอนต์แจ้งเตือนตัวหนังสือสีแดงให้คมชัดเว้นบรรทัด
            errorStyle: const TextStyle(
              color: Colors.redAccent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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
                  color: primaryGreen.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? primaryGreen : Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              30,
            ), // ดีไซน์ขอบปุ่มโค้งสปอร์ตหรูหรา
            side: BorderSide(
              color: isPrimary ? Colors.transparent : Colors.grey.shade400,
              width: 1.0,
            ),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.black87,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
      ),
    );
  }
}
