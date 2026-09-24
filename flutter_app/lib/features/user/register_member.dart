// features/member/register_member.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/member_model.dart';
import 'package:flutter_app/data/services/member/member_service.dart';
import 'package:flutter_app/main_login.dart';

class RegisterMember extends StatefulWidget {
  const RegisterMember({super.key});

  @override
  State<RegisterMember> createState() => _RegisterMemberState();
}

class _RegisterMemberState extends State<RegisterMember> {
  final MemberService memberService = MemberService();

  // 🎯 แก้จุดนี้: เดิม GlobalKey เฉยๆ ทำให้ currentState เป็น State ธรรมดา
  // ไม่มีเมธอด validate() ต้องระบุ type argument เป็น FormState
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscureText = true;

  String? _usernameServerError;
  String? _emailServerError;

  late TextEditingController usernameController;
  late TextEditingController passwordController;
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  static const Color _primary = Color(0xFF00B300);
  static const Color _primaryDark = Color(0xFF00B300);
  static const Color _accent = Color(0xFFEA7C1E);
  static const Color _bg = Color(0xFFF5F6F8);
  static const Color _textDark = Color(0xFF1E1E24);
  static const Color _textMuted = Color(0xFF8A8D93);
  static const Color _danger = Color(0xFFE53935);

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
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              icon: const Icon(
                Icons.check_circle_rounded,
                color: _primary,
                size: 80,
              ),
              title: const Text(
                "สำเร็จ!",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Text(
                "ยินดีต้อนรับคุณ " +
                    firstNameController.text.trim() +
                    "\nสมัครสมาชิกเรียบร้อยแล้ว",
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
                      backgroundColor: const Color(0xFF00B300),
                      foregroundColor: Colors.white,
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

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainLogin()),
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
            formKey.currentState!.validate();
          } else if (errorMsg.contains("email") || errorMsg.contains("อีเมล")) {
            setState(() => _emailServerError = "อีเมลนี้ถูกใช้งานแล้ว");
            formKey.currentState!.validate();
          } else {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                icon: const Icon(
                  Icons.error_outline_rounded,
                  color: _danger,
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
                    child: const Text("ตกลง", style: TextStyle(color: _danger)),
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

  InputDecoration _inputDecoration({
    String hint = "",
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      errorText: errorText,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _danger, width: 1.6),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 14),
      child: RichText(
        text: TextSpan(
          text: text.replaceAll('*', ''),
          style: const TextStyle(
            color: _textDark,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          children: [
            if (text.contains('*'))
              const TextSpan(
                text: ' *',
                style: TextStyle(color: _danger, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader({required IconData icon, required String title}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, left: 2),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _textDark,
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: _bg, shape: BoxShape.circle),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: _textDark,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'สมัครสมาชิกลูกค้า',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      icon: Icons.account_circle_outlined,
                      title: "ข้อมูลบัญชีเข้าสู่ระบบ",
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("ชื่อผู้ใช้ (Username) *"),
                            TextFormField(
                              controller: usernameController,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              onChanged: (_) {
                                if (_usernameServerError != null) {
                                  setState(() => _usernameServerError = null);
                                }
                              },
                              validator: (value) {
                                if (_usernameServerError != null)
                                  return _usernameServerError;
                                if (value == null || value.isEmpty)
                                  return "กรุณากรอก ชื่อผู้ใช้";
                                if (value.contains(' '))
                                  return "ชื่อผู้ใช้ต้องไม่มีช่องว่าง";
                                if (!RegExp(
                                  r'^[a-zA-Z0-9]+$',
                                ).hasMatch(value)) {
                                  return "ต้องเป็นภาษาอังกฤษหรือตัวเลขเท่านั้น";
                                }
                                if (value.length < 6 || value.length > 20) {
                                  return "ต้องมีอย่างน้อย 6 ถึง 20 ตัวอักษร";
                                }
                                return null;
                              },
                              decoration: _inputDecoration(
                                hint: "ภาษาอังกฤษหรือตัวเลข 6-20 ตัว",
                                suffixIcon: Icon(
                                  Icons.person_outline,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),

                            const SizedBox(height: 5),

                            _buildLabel("รหัสผ่าน (Password) *"),
                            TextFormField(
                              controller: passwordController,
                              obscureText: _obscureText,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return "กรุณากรอกรหัสผ่าน";
                                if (value.contains(" "))
                                  return "รหัสผ่านต้องไม่มีช่องว่าง";
                                if (!RegExp(
                                  r'^[a-zA-Z0-9!#_.]+$',
                                ).hasMatch(value)) {
                                  return "อนุญาตเฉพาะ a-z, A-Z, 0-9 และ ! # _ .";
                                }
                                if (value.length < 8 || value.length > 20) {
                                  return "รหัสผ่านต้องมีความยาวตั้งแต่ 8 ถึง 20 ตัวอักษร";
                                }

                                if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
                                  return "รหัสผ่านต้องมีตัวอักษรอย่างน้อย 1 ตัว";
                                }

                                // ต้องมีตัวเลข
                                if (!RegExp(r'[0-9]').hasMatch(value)) {
                                  return "รหัสผ่านต้องมีตัวเลขอย่างน้อย 1 ตัว";
                                }

                                // ต้องมีอักขระพิเศษ
                                if (!RegExp(r'[!#_.]').hasMatch(value)) {
                                  return "รหัสผ่านต้องมีอักขระพิเศษอย่างน้อย 1 ตัว (! # _ .)";
                                }
                                return null;
                              },
                              decoration: _inputDecoration(
                                hint: "8-20 ตัว (a-Z, 0-9 และอักขระพิเศษ !#_.)",
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.grey[400],
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureText = !_obscureText,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    _sectionHeader(
                      icon: Icons.badge_outlined,
                      title: "ข้อมูลส่วนตัว",
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("ชื่อ *"),
                          TextFormField(
                            controller: firstNameController,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return "กรุณากรอกชื่อ";
                              if (!RegExp(
                                r'^[a-zA-Z\u0E00-\u0E7F]+$',
                              ).hasMatch(value)) {
                                return "ไทยหรืออังกฤษเท่านั้น";
                              }
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
                            decoration: _inputDecoration(
                              hint: "ตัวอย่าง: สมชาย",
                              suffixIcon: Icon(
                                Icons.assignment_ind_outlined,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),

                          const SizedBox(height: 5),

                          _buildLabel("นามสกุล *"),
                          TextFormField(
                            controller: lastNameController,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return "กรุณากรอกนามสกุล";
                              if (!RegExp(
                                r'^[a-zA-Z\u0E00-\u0E7F]+$',
                              ).hasMatch(value)) {
                                return "ไทยหรืออังกฤษเท่านั้น";
                              }
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
                                    !RegExp(r'^[a-zA-Z]+$').hasMatch(value)) {
                                  return "นามสกุลต้องเป็นภาษาอังกฤษเหมือนชื่อ";
                                }
                                if (firstIsThai &&
                                    !RegExp(
                                      r'^[\u0E00-\u0E7F]+$',
                                    ).hasMatch(value)) {
                                  return "นามสกุลต้องเป็นภาษาไทยเหมือนชื่อ";
                                }
                              }
                              if (value.length < 3 || value.length > 30)
                                return "ความยาว 3-30 ตัวอักษร";
                              return null;
                            },
                            decoration: _inputDecoration(
                              hint: "ตัวอย่าง: ใจดี",
                              suffixIcon: Icon(
                                Icons.assignment_ind_outlined,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),

                          const SizedBox(height: 5),

                          _buildLabel("อีเมล (Email) *"),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            onChanged: (_) {
                              if (_emailServerError != null) {
                                setState(() => _emailServerError = null);
                              }
                            },
                            validator: (value) {
                              if (_emailServerError != null)
                                return _emailServerError;
                              if (value == null || value.isEmpty)
                                return "กรุณากรอกอีเมล";
                              if (!RegExp(
                                r'^[\w+\-\.]+@([\w\-]+\.)+[a-zA-Z]{2,}$',
                              ).hasMatch(value)) {
                                return "รูปแบบอีเมลไม่ถูกต้อง";
                              }
                              return null;
                            },
                            decoration: _inputDecoration(
                              hint: "ตัวอย่าง: example@email.com",
                              suffixIcon: Icon(
                                Icons.email_outlined,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),

                          const SizedBox(height: 5),

                          _buildLabel("เบอร์โทรศัพท์ (Phone) *"),
                          TextFormField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return "กรุณากรอกเบอร์โทรศัพท์";
                              if (!RegExp(r'^[0-9]+$').hasMatch(value))
                                return "กรุณากรอกเป็นตัวเลขเท่านั้น";
                              if (value.length < 10 || value.length > 15) {
                                return "เบอร์โทรศัพท์ต้องมียาวตั้งแต่ 10 ถึง 15 หลัก";
                              }
                              return null;
                            },
                            decoration: _inputDecoration(
                              hint: "ตัวอย่าง: 08XXXXXXXX",
                              suffixIcon: Icon(
                                Icons.phone_android_outlined,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textMuted,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      "ย้อนกลับ",
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [_primary, _primaryDark],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : doRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "สมัครสมาชิก",
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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
}
