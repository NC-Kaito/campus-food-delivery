// features/rider/register_rider.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/features/rider/register_rider2.dart';
import 'package:intl/intl.dart'; // อย่าลืมลงแพ็คเกจ intl ใน pubspec.yaml นะครับ
import 'dart:io';

class RegisterRider extends StatefulWidget {
  const RegisterRider({super.key});

  @override
  State<RegisterRider> createState() => _RegisterRiderState();
}

class _RegisterRiderState extends State<RegisterRider> {
  static const Color _primary = Color(0xFF16A34A);
  static const Color _primaryDark = Color(0xFF0F7A38);
  static const Color _accent = Color(0xFFEA7C1E);
  static const Color _bg = Color(0xFFF5F6F8);
  static const Color _textDark = Color(0xFF1E1E24);
  static const Color _textMuted = Color(0xFF8A8D93);
  static const Color _danger = Color(0xFFE53935);

  // 🎯 แก้จุดนี้: เดิมเป็น GlobalKey เฉยๆ ทำให้ currentState เป็น State ธรรมดา
  // ไม่มีเมธอด validate() ต้องระบุ type argument เป็น FormState
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController studentIdController;
  late final TextEditingController passwordController;
  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController birthdayController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;

  int? savedFacultyId;
  int? savedMajorId;
  String? savedPlate;
  File? savedStudentCard;
  File? savedDrivingLicense;
  File? savedVehicleImage;

  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    studentIdController = TextEditingController();
    passwordController = TextEditingController();
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    birthdayController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
  }

  @override
  void dispose() {
    studentIdController.dispose();
    passwordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    birthdayController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // ฟังก์ชันเลือกวันเกิด
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary, // MJU Color
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        birthdayController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  // แปลง MM/dd/yyyy → yyyy-MM-dd
  String _convertDateFormat(String date) {
    try {
      final parsed = DateFormat('MM/dd/yyyy').parse(date);
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (e) {
      return date;
    }
  }

  InputDecoration _inputDecoration({String hint = "", Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
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
          text: text,
          style: const TextStyle(
            color: _textDark,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
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

  Widget _buildStepIndicator() {
    Widget dot(bool active, String label, IconData icon) {
      return Column(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? _primary : Colors.grey[300],
              shape: BoxShape.circle,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: _primary.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? _textDark : _textMuted,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          dot(true, "ข้อมูลส่วนตัว", Icons.person_outline_rounded),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Container(height: 2, color: Colors.grey[300]),
            ),
          ),
          dot(false, "ข้อมูลรถและหลักฐาน", Icons.two_wheeler_rounded),
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
          'สมัครผู้จัดส่ง',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(color: Colors.white, child: _buildStepIndicator()),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      icon: Icons.assignment_ind_outlined,
                      title: "ข้อมูลส่วนตัวของคุณ",
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
                          const SizedBox(height: 5),

                          _buildLabel("รหัสนักศึกษา (Student ID)"),
                          TextFormField(
                            controller: studentIdController,
                            keyboardType: TextInputType.number,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return "กรุณากรอกรหัสนักศึกษา";
                              if (!RegExp(r'^[0-9]+$').hasMatch(value))
                                return "ต้องเป็นตัวเลขเท่านั้น";
                              if (value.length != 10)
                                return "ต้องมี 10 หลักเท่านั้น";
                              if (!value.startsWith('6'))
                                return "ต้องขึ้นต้นด้วย 6 เท่านั้น";
                              return null;
                            },
                            decoration: _inputDecoration(
                              hint: "6XXXXXXXXX",
                              suffixIcon: Icon(
                                Icons.badge_outlined,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),

                          _buildLabel("รหัสผ่าน (Password)"),
                          TextFormField(
                            controller: passwordController,
                            obscureText: _obscureText,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return "กรุณากรอกรหัสผ่าน";
                              if (value.contains(' ')) return "ห้ามมีช่องว่าง";
                              if (!RegExp(
                                r'^[a-zA-Z0-9!#_.]+$',
                              ).hasMatch(value))
                                return "ใช้ได้เฉพาะ a-z, A-Z, 0-9 และ ! # _ .";
                              if (value.length < 8 || value.length > 20)
                                return "ความยาว 8-20 ตัวอักษร";

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
                              hint: "ตัวอย่าง pas012",
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

                          _buildLabel("ชื่อ (Firstname)"),
                          TextFormField(
                            controller: firstNameController,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return "กรุณากรอกชื่อ";
                              if (value.contains(' ')) return "ห้ามมีช่องว่าง";
                              if (!RegExp(
                                r'^[a-zA-Z\u0E00-\u0E7F]+$',
                              ).hasMatch(value))
                                return "ต้องเป็นภาษาไทยหรืออังกฤษเท่านั้น";
                              final hasEng = RegExp(
                                r'[a-zA-Z]',
                              ).hasMatch(value);
                              final hasThai = RegExp(
                                r'[\u0E00-\u0E7F]',
                              ).hasMatch(value);
                              if (hasEng && hasThai)
                                return "ห้ามปนภาษาไทยและอังกฤษ";
                              if (value.length < 3 || value.length > 30)
                                return "ความยาว 3-30 ตัวอักษร";
                              return null;
                            },
                            decoration: _inputDecoration(
                              hint: "กรอกชื่อจริง",
                              suffixIcon: Icon(
                                Icons.person_outline_rounded,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),

                          _buildLabel("นามสกุล (Lastname)"),
                          TextFormField(
                            controller: lastNameController,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return "กรุณากรอกนามสกุล";
                              if (value.contains(' ')) return "ห้ามมีช่องว่าง";
                              if (!RegExp(
                                r'^[a-zA-Z\u0E00-\u0E7F]+$',
                              ).hasMatch(value))
                                return "ต้องเป็นภาษาไทยหรืออังกฤษเท่านั้น";
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
                            decoration: _inputDecoration(
                              hint: "กรอกนามสกุล",
                              suffixIcon: Icon(
                                Icons.person_outline_rounded,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),

                          _buildLabel("วันเดือนปีเกิด (Date of Birth)"),
                          TextFormField(
                            controller: birthdayController,
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return "กรุณาเลือกวันเกิด";
                              if (!RegExp(
                                r'^\d{2}/\d{2}/\d{4}$',
                              ).hasMatch(value))
                                return "รูปแบบวันที่ไม่ถูกต้อง (mm/dd/yyyy)";
                              return null;
                            },
                            decoration: _inputDecoration(
                              hint: "mm/dd/yyyy",
                              suffixIcon: IconButton(
                                icon: Icon(
                                  Icons.calendar_month_outlined,
                                  color: Colors.grey[400],
                                ),
                                onPressed: () => _selectDate(context),
                              ),
                            ),
                          ),

                          _buildLabel("อีเมล (Email)"),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return "กรุณากรอกอีเมล";
                              if (value.contains(' ')) return "ห้ามมีช่องว่าง";
                              if (!RegExp(
                                r'^[\w+\-\.]+@([\w\-]+\.)+[a-zA-Z]{2,}$',
                              ).hasMatch(value))
                                return "รูปแบบอีเมลไม่ถูกต้อง";
                              return null;
                            },
                            decoration: _inputDecoration(
                              hint: "ตัวอย่าง xxx@gmail.com",
                              suffixIcon: Icon(
                                Icons.email_outlined,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),

                          _buildLabel("เบอร์โทรศัพท์ (Phone)"),
                          TextFormField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return "กรุณากรอกเบอร์โทรศัพท์";
                              if (value.contains(' ')) return "ห้ามมีช่องว่าง";
                              if (!RegExp(r'^[0-9]+$').hasMatch(value))
                                return "ต้องเป็นตัวเลขเท่านั้น";
                              if (value.length < 10 || value.length > 15)
                                return "ความยาว 10-15 หลัก";
                              return null;
                            },
                            decoration: _inputDecoration(
                              hint: "ตัวเลข 10 หลัก",
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
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterRider2(
                                studentId: studentIdController.text.trim(),
                                password: passwordController.text.trim(),
                                firstName: firstNameController.text.trim(),
                                lastName: lastNameController.text.trim(),
                                birthday: _convertDateFormat(
                                  birthdayController.text,
                                ),
                                email: emailController.text.trim(),
                                phone: phoneController.text.trim(),
                                savedFacultyId: savedFacultyId,
                                savedMajorId: savedMajorId,
                                savedPlate: savedPlate,
                                savedStudentCard: savedStudentCard,
                                savedDrivingLicense: savedDrivingLicense,
                                savedVehicleImage: savedVehicleImage,
                              ),
                            ),
                          );

                          if (result != null && result is Map) {
                            setState(() {
                              savedFacultyId = result['facultyId'];
                              savedMajorId = result['majorId'];
                              savedPlate = result['plate'];
                              savedStudentCard = result['studentCard'];
                              savedDrivingLicense = result['drivingLicense'];
                              savedVehicleImage = result['vehicleImage'];
                            });
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "ถัดไป",
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
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
