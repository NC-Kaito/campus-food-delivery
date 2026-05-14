import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/member_model.dart';
import 'package:flutter_app/data/services/member/member_service.dart';
import 'package:flutter_app/features/member/login_member.dart';

class RegisterMember extends StatefulWidget {
  const RegisterMember({super.key});

  @override
  State<RegisterMember> createState() => _RegisterMemberState();
}

class _RegisterMemberState extends State<RegisterMember> {
  final MemberService memberService = MemberService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscureText = true;

  // Check If Used username || Email it's repeat
  String? _usernameServerError;
  String? _emailServerError;

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
      setState(() => _isLoading = true);
      try {
        MemberModel member = MemberModel(
          username: usernameController.text.trim(),
          password: passwordController.text,
          firstname: firstNameController.text.trim(),
          lastname: lastNameController.text.trim(),
          email: emailController.text.trim(),
          phone: phoneController.text.trim(),
        );

        await memberService.doRegsiterMember(member);

        if (mounted) {
          // ✅ Popup สำเร็จ
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 72,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "สมัครสมาชิกสำเร็จ!",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "ยินดีต้อนรับ ${firstNameController.text.trim()} ",
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "เข้าสู่ระบบ",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );

          // ✅ ไปหน้า Login หลังกด "เข้าสู่ระบบ"
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginMember()),
              (route) => false,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          final errorMsg = e.toString();

          if (errorMsg.contains("username") ||
              errorMsg.contains("ชื่อผู้ใช้")) {
            setState(() => _usernameServerError = "ชื่อผู้ใช้นี้ถูกใช้งานแล้ว");
            formKey.currentState!.validate(); // ✅ trigger validator ใหม่
          } else if (errorMsg.contains("email") || errorMsg.contains("อีเมล")) {
            setState(() => _emailServerError = "อีเมลนี้ถูกใช้งานแล้ว");
            formKey.currentState!.validate(); // ✅ trigger validator ใหม่
          } else {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cancel_rounded,
                      color: Colors.red,
                      size: 72,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "สมัครสมาชิกไม่สำเร็จ",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.toString(),
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                actions: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "ลองใหม่อีกครั้ง",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "สมัครสมาชิก",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined, color: Colors.orange),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "สมัครสมาชิก",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Form(
                key: formKey,
                // ✅ เปิดโหมดตรวจสอบทันทีเมื่อมีการพิมพ์ (Realtime)
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("ชื่อผู้ใช้ (Username) *"),
                    _buildTextField(
                      controller: usernameController,
                      hint: "Username (ภาษาอังกฤษเท่านั้น)",
                      icon: Icons.person_outline,
                      onChanged: () =>
                          setState(() => _usernameServerError = null),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return "กรุณากรอก ชื่อผู้ใช้";

                        if (value.contains(' '))
                          return "ชื่อผู้ใช้ต้องไม่มีช่องว่าง";

                        if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                          return "ต้องเป็นภาษาอังกฤษหรือตัวเลขเท่านั้น";
                        }
                        if (value.length < 6 || value.length > 20)
                          return "ต้องมีอย่างน้อย 6 ถึง 20 ตัวอักษร";
                        if (_usernameServerError != null)
                          return _usernameServerError;
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    _buildLabel("รหัสผ่าน (Password) *"),
                    _buildTextField(
                      controller: passwordController,
                      hint: "รหัสผ่าน 8 ตัวขึ้นไป",
                      icon: _obscureText
                          ? Icons.visibility_off
                          : Icons.visibility,
                      isPassword: _obscureText,
                      onIconTap: () =>
                          setState(() => _obscureText = !_obscureText),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return "กรุณากรอกรหัสผ่าน";

                        if (value.contains(" "))
                          return "รหัสผ่านต้องไม่มีช่องว่าง";

                        if (!RegExp(r'^[a-zA-Z0-9!#_.]+$').hasMatch(value)) {
                          return "ต้องเป็นภาษาอังกฤษหรือตัวเลข รวมถึงอักขระพิเศษ ! # _ . เท่านั้น";
                        }

                        if (value.length < 8 || value.length > 20)
                          return "รหัสผ่านต้องมีความยาวตั้งแต่ 8 ถึง 20 ตัวอักษร";
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    _buildLabel("ชื่อ (Firstname) *"),
                    _buildTextField(
                      controller: firstNameController,
                      hint: "Firstname",
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return "กรุณากรอกชื่อ";

                        if (!RegExp(
                          r'^[a-zA-Z\u0E00-\u0E7F]+$',
                        ).hasMatch(value))
                          return "ชื่อต้องเป็นภาษาไทยหรืออังกฤษเท่านั้น";

                        final hasEng = RegExp(r'[a-zA-Z]').hasMatch(value);
                        final hasThai = RegExp(
                          r'[\u0E00-\u0E7F]',
                        ).hasMatch(value);
                        if (hasEng && hasThai)
                          return "ชื่อต้องเป็นภาษาใดภาษาหนึ่งเท่านั้น";

                        if (value.length < 3 || value.length > 30) {
                          return "ชื่อต้องมีความยาวตั้งแต่ 3 ถึง 30 ตัวอักษร";
                        }
                        return null;
                      },
                    ),

                    _buildLabel("นามสกุล (Lastname) *"),
                    _buildTextField(
                      controller: lastNameController,
                      hint: "Lastname",
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return "กรุณากรอกนามสกุล";

                        if (!RegExp(
                          r'^[a-zA-Z\u0E00-\u0E7F]+$',
                        ).hasMatch(value))
                          return "ชื่อต้องเป็นภาษาไทยหรืออังกฤษเท่านั้น";

                        final firstName = firstNameController.text;
                        if (firstName.isNotEmpty) {
                          final firstIsEng = RegExp(
                            r'^[a-zA-Z\s]+$',
                          ).hasMatch(firstName);
                          final lastIsEng = RegExp(
                            r'^[a-zA-Z\s]+$',
                          ).hasMatch(value);
                          final firstIsThai = RegExp(
                            r'^[\u0E00-\u0E7F\s]+$',
                          ).hasMatch(firstName);
                          final lastIsThai = RegExp(
                            r'^[\u0E00-\u0E7F\s]+$',
                          ).hasMatch(value);

                          if (firstIsEng && !lastIsEng)
                            return "นามสกุลต้องเป็นภาษาอังกฤษเหมือนชื่อ";
                          if (firstIsThai && !lastIsThai)
                            return "นามสกุลต้องเป็นภาษาไทยเหมือนชื่อ";
                        }
                        if (value.length < 3 || value.length > 30) {
                          return "นามสกุลต้องมีความยาวตั้งแต่ 3 ถึง 30 ตัวอักษร";
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    _buildLabel("อีเมล (Email) *"),
                    _buildTextField(
                      controller: emailController,
                      hint: "example@gmail.com",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: () => setState(() => _emailServerError = null),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return "กรุณากรอกอีเมล";

                        if (!RegExp(
                          r'^[\w+\-\.]+@([\w\-]+\.)+[a-zA-Z]{2,}$',
                        ).hasMatch(value)) {
                          return "รูปแบบอีเมลไม่ถูกต้อง";
                        }
                        if (_emailServerError != null) return _emailServerError;

                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    _buildLabel("เบอร์โทรศัพท์ (Phone) *"),
                    _buildTextField(
                      controller: phoneController,
                      hint: "08XXXXXXXX",
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return "กรุณากรอกเบอร์โทรศัพท์";
                        if (!RegExp(r'^[0-9]+$').hasMatch(value))
                          return "กรุณากรอกเป็นตัวเลขเท่านั้น";
                        if (value.length < 10 || value.length > 15)
                          return "เบอร์โทรศัพท์ต้องมียาวตั้งแต่ 10 ถึง 15 หลัก";

                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    Row(
                      children: [
                        Expanded(
                          child: _buildSideButton(
                            text: "ย้อนกลับ",
                            color: const Color(0xFFE0E0E0),
                            textColor: Colors.black54,
                            onPressed: () => Navigator.pop(context),
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

  // --- Helper Widgets ---

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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool isPassword = false,
    VoidCallback? onIconTap,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    VoidCallback? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: (_) => onChanged?.call(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        suffixIcon: icon != null
            ? InkWell(
                onTap: onIconTap,
                child: Icon(icon, color: Colors.grey[400], size: 20),
              )
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

  Widget _buildSideButton({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
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
}
