import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/member_model.dart';
import 'package:flutter_app/data/services/member/member_service.dart';
import 'package:flutter_app/features/member/login_member.dart';
// import 'package:flutter_application_1/data/models/member_model.dart';
// import 'package:flutter_application_1/data/service/member_service.dart';
// อย่าลืม import SharedAppBar ถ้าคุณแยกไฟล์ไว้
// import 'package:flutter_app/features/member/shared-appbar-member.dart';

class RegisterMember extends StatefulWidget {
  const RegisterMember({super.key});

  @override
  State<RegisterMember> createState() => _RegisterMemberState();
}

class _RegisterMemberState extends State<RegisterMember> {
  final MemberService memberService = MemberService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController usernameController;
  late TextEditingController passwordController;
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  @override
  void initState() {
    usernameController = TextEditingController();
    passwordController = TextEditingController();
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> doRegister() async {
    if (formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        print("Try to Register");
        MemberModel member = MemberModel(
          username: usernameController.text,
          password: passwordController.text,
          firstname: firstNameController.text,
          lastname: lastNameController.text,
          email: emailController.text,
          phone: phoneController.text,
        );

        await memberService.doRegsiterMember(member);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginMember()),
            (route) => false,
          );
        }
      } catch (e) {
        print("ERROR: $e ");
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
      backgroundColor: const Color(0xFFF1F1F1), // พื้นหลังเทาอ่อนตามรูป
      // ใช้ SharedAppBarMember ที่เราทำกันไว้ก่อนหน้านี้
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.home_outlined, color: Colors.orange),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.shopping_cart_outlined,
              color: Colors.orange,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Colors.orange,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          children: [
            const Text(
              "สมัครสมาชิก",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Container หลักสีขาว (Form)
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFDFDFD),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("ชื่อผู้ใช้ (Username) *"),
                    _buildTextField(
                      controller: usernameController,
                      hint: "Username",
                      icon: Icons.person_outline,
                      validator: (value) =>
                          value!.isEmpty ? "กรุณากรอก Username" : null,
                    ),
                    const SizedBox(height: 15),

                    _buildLabel("รหัสผ่าน (Password) *"),
                    _buildTextField(
                      controller: passwordController,
                      hint: "ตัวอย่าง pas012",
                      icon: Icons.visibility_off_outlined,
                      isPassword: true,
                      validator: (value) =>
                          value!.length < 8 ? "รหัสผ่านต้อง 8 ตัวขึ้นไป" : null,
                    ),
                    const SizedBox(height: 15),

                    _buildLabel("ชื่อ (Firstname) *"),
                    _buildTextField(
                      controller: firstNameController,
                      hint: "Firstname",
                      validator: (value) =>
                          value!.isEmpty ? "กรุณากรอกชื่อ" : null,
                    ),
                    const SizedBox(height: 15),

                    _buildLabel("นามสกุล (Lastname) *"),
                    _buildTextField(
                      controller: lastNameController,
                      hint: "Lastname",
                      validator: (value) =>
                          value!.isEmpty ? "กรุณากรอกนามสกุล" : null,
                    ),
                    const SizedBox(height: 15),

                    _buildLabel("อีเมล (Email) *"),
                    _buildTextField(
                      controller: emailController,
                      hint: "ตัวอย่าง xxx@gmail.com",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          !value!.contains('@') ? "อีเมลไม่ถูกต้อง" : null,
                    ),
                    const SizedBox(height: 15),

                    _buildLabel("เบอร์โทรศัพท์ (Phone) *"),
                    _buildTextField(
                      controller: phoneController,
                      hint: "ตัวเลข 10 หลัก",
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value!.length != 10 ? "ต้องครบ 10 หลัก" : null,
                    ),
                    const SizedBox(height: 30),

                    // โซนปุ่มกดย้อนกลับ และ สมัครสมาชิก
                    Row(
                      children: [
                        Expanded(
                          child: _buildSideButton(
                            text: "ย้อนกลับ",
                            color: const Color(0xFFE0E0E0),
                            textColor: Colors.black54,
                            onPressed: doRegister,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildSideButton(
                            text: "สมัครสมาชิก",
                            color: const Color(0xFF76FF03),
                            textColor: Colors.black87,
                            isLoading: _isLoading,
                            onPressed: doRegister,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันแสดงหัวข้อ Field
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: RichText(
        text: TextSpan(
          text: text.replaceAll('*', ''),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          children: const [
            TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันสร้าง TextField ให้ตรงตามรูป
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        suffixIcon: icon != null
            ? Icon(icon, color: Colors.grey[400], size: 20)
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  // ฟังก์ชันสร้างปุ่มด้านล่าง
  Widget _buildSideButton({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  // Logic การกดสมัครสมาชิก
  void _onRegister() async {
    if (formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      // try {
      //   MemberModel newMember = MemberModel(
      //     username: usernameController.text,
      //     password: passwordController.text,
      //     firstname: firstNameController.text,
      //     lastname: lastNameController.text,
      //     email: emailController.text,
      //     phone: phoneController.text,
      //   );
      // await memberService.createMember(newMember);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("ลงทะเบียนสำเร็จ"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
      // } catch (e) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      //   );
      // } finally {
      //   if (mounted) setState(() => _isLoading = false);
      // }
    }
  }
}
