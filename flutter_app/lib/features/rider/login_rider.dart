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

class _LoginRiderState extends State<LoginRider>
    with SingleTickerProviderStateMixin {
  final RiderService riderService = RiderService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late final TextEditingController studentIdController;
  late final TextEditingController passwordController;
  bool _isLoading = false;
  bool _obscurePassword = true;

  // ── โทนสีหลักของหน้านี้ ──────────────────────────────────────────
  static const Color _accentGreen = Color(0xFF64F02D);
  static const Color _deepGreen = Color(0xFF0B3D1E);
  static const Color _midGreen = Color(0xFF1F6B3A);
  static const Color _ink = Color(0xFF14181C);
  static const Color _muted = Color(0xFF8A93A3);
  static const Color _fieldFill = Color(0xFFF3F6F2);

  late final AnimationController _introController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    studentIdController = TextEditingController();
    passwordController = TextEditingController();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fade = CurvedAnimation(parent: _introController, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
        );
    _introController.forward();
  }

  @override
  void dispose() {
    studentIdController.dispose();
    passwordController.dispose();
    _introController.dispose();
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
              behavior: SnackBarBehavior.fixed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 หาความสูงหน้าจอ เพื่อใช้กางและดันฟอร์มให้อยู่กลางจอ
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        bottom: true,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            // 🎯 บังคับให้ ScrollView มีความสูงอย่างน้อยเท่ากับหน้าจอ
            constraints: BoxConstraints(minHeight: screenHeight),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(context, screenHeight),

                  FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: _buildFormSheet(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── ส่วนหัวฮีโร่: 🎯 ขยายความสูงให้กินพื้นที่เพื่อดันฟอร์มลง ──
  Widget _buildHero(BuildContext context, double screenHeight) {
    final double topInset = MediaQuery.of(context).padding.top;

    return ClipPath(
      clipper: _RoadCurveClipper(),
      child: Container(
        width: double.infinity,
        // 🎯 กำหนดความสูง 38% ของหน้าจอ เพื่อดันฟอร์มให้ตกมาตรงกลางพอดี
        height: screenHeight * 0.38,
        padding: EdgeInsets.fromLTRB(24, topInset + 10, 24, 40),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_deepGreen, _midGreen],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(right: -10, top: 34, child: _speedStreaks()),
            Column(
              mainAxisAlignment: MainAxisAlignment
                  .center, // 🎯 จัดข้อความให้อยู่กึ่งกลางพื้นที่ฮีโร่
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'CAMPUS DELIVERY · RIDER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'เข้าสู่ระบบไรเดอร์',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.15,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'รับออเดอร์ วิ่งงาน ส่งอาหารรอบมหาวิทยาลัย',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white.withOpacity(0.75),
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _riderBadge(),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _riderBadge() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: _accentGreen.withOpacity(0.45),
            blurRadius: 22,
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/login_rider.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.delivery_dining_rounded,
            size: 34,
            color: _accentGreen,
          ),
        ),
      ),
    );
  }

  Widget _speedStreaks() {
    Widget streak(double width, double opacity) => Transform.rotate(
      angle: -0.5,
      child: Container(
        width: width,
        height: 3,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(opacity),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [streak(46, 0.22), streak(30, 0.16), streak(18, 0.10)],
    );
  }

  Widget _buildFormSheet(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -34),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(26, 30, 26, 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, -6),
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
            const SizedBox(height: 18),
            _buildTextField(
              label: 'รหัสผ่าน (Password)',
              hint: 'กรุณากรอกรหัสผ่าน',
              icon: Icons.lock_outline_rounded,
              controller: passwordController,
              isPassword: _obscurePassword,
              suffixIcon: IconButton(
                splashRadius: 20,
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: _muted,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 34),

            _buildActionButton(
              text: 'เข้าสู่ระบบไรเดอร์',
              onPressed: doLogin,
              loading: _isLoading,
              isPrimary: true,
            ),
            const SizedBox(height: 22),
            _buildOrDivider(),
            const SizedBox(height: 22),

            _buildActionButton(
              text: 'สมัครเป็นไรเดอร์',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AgreesRider()),
                );
              },
              isPrimary: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: const Text(
            'หรือ',
            style: TextStyle(
              color: _muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'กรุณากรอกข้อมูลในช่องนี้ให้เรียบร้อยครับ';
            }
            return null;
          },
          style: const TextStyle(
            fontSize: 15,
            color: _ink,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _accentGreen.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: _midGreen,
                  size: 18,
                ), // 🎯 ลบคำว่า const ออก
              ),
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: _fieldFill,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _midGreen, width: 1.6),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
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
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: isPrimary
            ? const LinearGradient(colors: [_accentGreen, Color(0xFF4CC91F)])
            : null,
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: _accentGreen.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.transparent : Colors.white,
          foregroundColor: _ink,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(
              color: isPrimary ? Colors.transparent : Colors.grey.shade300,
              width: 1.2,
            ),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: _ink, strokeWidth: 2.5),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: isPrimary ? _ink : _ink.withOpacity(0.85),
                ),
              ),
      ),
    );
  }
}

class _RoadCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 46);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.52,
      size.height - 22,
    );
    path.quadraticBezierTo(
      size.width * 0.78,
      size.height - 46,
      size.width,
      size.height - 14,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
