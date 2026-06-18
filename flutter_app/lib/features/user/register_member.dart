// features/member/register_member.dart
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

  // 🎯 ✅ คุมโทนสีหลักระบบสีเขียวแอปธีมนี้ #64F02D ของคุณ Kaito
  final Color primaryColor = const Color(0xFF64F02D);
  final Color gradientStart = const Color(0xFF64F02D);
  final Color gradientEnd = const Color(0xFF64F02D).withOpacity(0.8);

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
          // ✅ Popup สำเร็จ ปรับเปลี่ยนสไตล์ให้ใช้สีเขียวใหม่
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              icon: Icon(
                Icons.check_circle_rounded,
                color: primaryColor, // ใช้สีเขียวใหม่
                size: 80,
              ),
              title: const Text(
                "สำเร็จ!",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Text(
                "ยินดีต้อนรับคุณ ${firstNameController.text.trim()}\nสมัครสมาชิกเรียบร้อยแล้ว",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor, // สีปุ่มสำเร็จเขียวใหม่
                      foregroundColor:
                          Colors.black87, // ปรับสีตัวอักษรให้ตัดกับเขียวสว่าง
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "ไปหน้าเข้าสู่ระบบ",
                      style: TextStyle(
                        fontSize: 16,
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
            // Popup ผิดพลาดแบบปรับปรุงใหม่
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                icon: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 80,
                ),
                title: const Text(
                  "เกิดข้อผิดพลาด",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: Text(
                  e.toString(),
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "ตกลง",
                      style: TextStyle(color: Colors.red),
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
      backgroundColor: const Color(0xFFF8F9FA),
      // ─── 🎯 ส่วนหัวแอปบาร์ เพิ่มกลับมาตามระเบียบคลิกโฟกัสเสร็จสมบูรณ์ ───
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "สมัครสมาชิก",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Container(
                  padding: const EdgeInsets.all(25.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- ส่วนข้อมูลบัญชี ---
                        _buildSectionTitle(
                          Icons.account_circle,
                          "ข้อมูลบัญชีเข้าสู่ระบบ",
                        ),
                        const SizedBox(height: 15),

                        _buildTextField(
                          controller: usernameController,
                          label: "ชื่อผู้ใช้ (Username) *",
                          hint: "ภาษาอังกฤษหรือตัวเลข 6-20 ตัว",
                          icon: Icons.person_outline,
                          serverError: _usernameServerError,
                          onChanged: () {
                            if (_usernameServerError != null) {
                              setState(() => _usernameServerError = null);
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return "กรุณากรอก ชื่อผู้ใช้";
                            if (value.contains(' '))
                              return "ชื่อผู้ใช้ต้องไม่มีช่องว่าง";
                            if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value))
                              return "ต้องเป็นภาษาอังกฤษหรือตัวเลขเท่านั้น";
                            if (value.length < 6 || value.length > 20)
                              return "ต้องมีอย่างน้อย 6 ถึง 20 ตัวอักษร";
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        _buildTextField(
                          controller: passwordController,
                          label: "รหัสผ่าน (Password) *",
                          hint: "8-20 ตัว (a-Z, 0-9 และอักขระพิเศษ !#_.)",
                          icon: Icons.lock_outline_rounded,
                          isPassword: _obscureText,
                          suffixIcon: InkWell(
                            onTap: () =>
                                setState(() => _obscureText = !_obscureText),
                            child: Icon(
                              _obscureText
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey.shade600,
                              size: 22,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return "กรุณากรอกรหัสผ่าน";
                            if (value.contains(" "))
                              return "รหัสผ่านต้องไม่มีช่องว่าง";
                            if (!RegExp(r'^[a-zA-Z0-9!#_.]+$').hasMatch(value))
                              return "อนุญาตเฉพาะ a-z, A-Z, 0-9 และ ! # _ .";
                            if (value.length < 8 || value.length > 20)
                              return "รหัสผ่านต้องมีความยาวตั้งแต่ 8 ถึง 20 ตัวอักษร";
                            return null;
                          },
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(
                            thickness: 1,
                            color: Color(0xFFEEEEEE),
                          ),
                        ),

                        // --- ส่วนข้อมูลส่วนตัว ---
                        _buildSectionTitle(
                          Icons.badge_outlined,
                          "ข้อมูลส่วนตัว",
                        ),
                        const SizedBox(height: 15),

                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: firstNameController,
                                label: "ชื่อ *",
                                hint: "สมชาย",
                                icon: Icons.assignment_ind_outlined,
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return "กรุณากรอกชื่อ";
                                  if (!RegExp(
                                    r'^[a-zA-Z\u0E00-\u0E7F]+$',
                                  ).hasMatch(value))
                                    return "ไทยหรืออังกฤษเท่านั้น";
                                  final hasEng = RegExp(
                                    r'[a-zA-Z]',
                                  ).hasMatch(value);
                                  final hasThai = RegExp(
                                    r'[\u0E00-\u0E7F]',
                                  ).hasMatch(value);
                                  if (hasEng && hasThai)
                                    return "ชื่อต้องเป็นภาษาใดภาษาหนึ่งเท่านั้น";
                                  if (value.length < 3 || value.length > 30)
                                    return "ความยาว 3-30 ตัวอักษร";
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildTextField(
                                controller: lastNameController,
                                label: "นามสกุล *",
                                hint: "ใจดี",
                                icon: Icons.assignment_ind_outlined,
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return "กรุณากรอกนามสกุล";
                                  if (!RegExp(
                                    r'^[a-zA-Z\u0E00-\u0E7F]+$',
                                  ).hasMatch(value))
                                    return "ไทยหรืออังกฤษเท่านั้น";
                                  final hasEng = RegExp(
                                    r'[a-zA-Z]',
                                  ).hasMatch(value);
                                  final hasThai = RegExp(
                                    r'[\u0E00-\u0E7F]',
                                  ).hasMatch(value);
                                  if (hasEng && hasThai)
                                    return "ห้ามปนภาษาไทยและอังกฤษ";
                                  final firstName = firstNameController.text;
                                  if (firstName.isNotEmpty) {
                                    final firstIsEng = RegExp(
                                      r'^[a-zA-Z]+$',
                                    ).hasMatch(firstName);
                                    final firstIsThai = RegExp(
                                      r'^[\u0E00-\u0E7F]+$',
                                    ).hasMatch(firstName);
                                    if (firstIsEng &&
                                        !RegExp(r'^[a-zA-Z]+$').hasMatch(value))
                                      return "นามสกุลต้องเป็นภาษาอังกฤษเหมือนชื่อ";
                                    if (firstIsThai &&
                                        !RegExp(
                                          r'^[\u0E00-\u0E7F]+$',
                                        ).hasMatch(value))
                                      return "นามสกุลต้องเป็นภาษาไทยเหมือนชื่อ";
                                  }
                                  if (value.length < 3 || value.length > 30)
                                    return "ความยาว 3-30 ตัวอักษร";
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        _buildTextField(
                          controller: emailController,
                          label: "อีเมล (Email) *",
                          hint: "example@email.com",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          serverError: _emailServerError,
                          onChanged: () {
                            if (_emailServerError != null) {
                              setState(() => _emailServerError = null);
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return "กรุณากรอกอีเมล";
                            if (!RegExp(
                              r'^[\w+\-\.]+@([\w\-]+\.)+[a-zA-Z]{2,}$',
                            ).hasMatch(value))
                              return "รูปแบบอีเมลไม่ถูกต้อง";
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        _buildTextField(
                          controller: phoneController,
                          label: "เบอร์โทรศัพท์ (Phone) *",
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

                        const SizedBox(height: 35),

                        // --- ปุ่มกดยกเลิก/สมัครสมาชิกสไตล์โค้งสปอร์ตชุดสีเขียว ---
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  side: BorderSide(color: Colors.black),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  "ย้อนกลับ",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [gradientStart, gradientEnd],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : doRegister,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.black87,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.black87,
                                          ),
                                        )
                                      : const Text(
                                          "สมัครสมาชิก",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    VoidCallback? onChanged,
    String? serverError,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: RichText(
            text: TextSpan(
              text: label.replaceAll('*', ''),
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              children: [
                if (label.contains('*'))
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          onChanged: (_) => onChanged?.call(),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            prefixIcon: Icon(icon, color: primaryColor, size: 22),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            errorText: serverError,
          ),
          validator: (value) {
            final normalValidate = validator?.call(value);
            if (normalValidate != null) return normalValidate;
            if (serverError != null) return serverError;
            return null;
          },
        ),
      ],
    );
  }
}
