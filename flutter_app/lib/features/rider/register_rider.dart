import 'package:flutter/material.dart';
import 'package:flutter_app/features/rider/register_rider2.dart';
import 'package:intl/intl.dart'; // อย่าลืมลงแพ็คเกจ intl ใน pubspec.yaml นะครับ

class RegisterRider extends StatefulWidget {
  const RegisterRider({super.key});

  @override
  State<RegisterRider> createState() => _RegisterRiderState();
}

class _RegisterRiderState extends State<RegisterRider> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController studentIdController;
  late final TextEditingController passwordController;
  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController birthdayController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;

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
              primary: Colors.green, // MJU Color
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // จัดรูปแบบวันที่เพื่อแสดงใน TextField (MM/dd/yyyy ตามรูป)
        birthdayController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  // ✅ แปลง MM/dd/yyyy → yyyy-MM-dd เพราะ Java LocalDate รับแค่ yyyy-MM-dd
  String _convertDateFormat(String date) {
    try {
      final parsed = DateFormat('MM/dd/yyyy').parse(date);
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (e) {
      return date; // ถ้า parse ไม่ได้ส่งค่าเดิมไป
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'สมัครผู้จัดส่ง',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ข้อมูลส่วนตัว',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  _buildLabel("รหัสนักศึกษา (Student ID)"),
                  _buildTextField(
                    controller: studentIdController,
                    hint: "6XXXXXXXXX",
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "กรุณากรอกรหัสนักศึกษา";
                      if (!RegExp(r'^[0-9]+$').hasMatch(value))
                        return "ต้องเป็นตัวเลขเท่านั้น";
                      if (value.length != 10) return "ต้องมี 10 หลักเท่านั้น";
                      if (!value.startsWith('6'))
                        return "ต้องขึ้นต้นด้วย 6 เท่านั้น";
                      return null;
                    },
                  ),

                  _buildLabel("รหัสผ่าน (Password)"),
                  _buildTextField(
                    controller: passwordController,
                    hint: "ตัวอย่าง pas012",
                    isPassword: true,
                    icon: _obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    onIconTap: () =>
                        setState(() => _obscureText = !_obscureText),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "กรุณากรอกรหัสผ่าน";
                      if (value.contains(' ')) return "ห้ามมีช่องว่าง";
                      if (!RegExp(r'^[a-zA-Z0-9!#_.]+$').hasMatch(value))
                        return "ใช้ได้เฉพาะ a-z, A-Z, 0-9 และ ! # _ .";
                      if (value.length < 8 || value.length > 20)
                        return "ความยาว 8-20 ตัวอักษร";
                      return null;
                    },
                  ),

                  _buildLabel("ชื่อ (Firstname)"),
                  _buildTextField(
                    controller: firstNameController,
                    hint: "",
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "กรุณากรอกชื่อ";
                      if (value.contains(' ')) return "ห้ามมีช่องว่าง";
                      if (!RegExp(r'^[a-zA-Z\u0E00-\u0E7F]+$').hasMatch(value))
                        return "ต้องเป็นภาษาไทยหรืออังกฤษเท่านั้น";
                      final hasEng = RegExp(r'[a-zA-Z]').hasMatch(value);
                      final hasThai = RegExp(
                        r'[\u0E00-\u0E7F]',
                      ).hasMatch(value);
                      if (hasEng && hasThai) return "ห้ามปนภาษาไทยและอังกฤษ";
                      if (value.length < 3 || value.length > 30)
                        return "ความยาว 3-30 ตัวอักษร";
                      return null;
                    },
                  ),

                  _buildLabel("นามสกุล (Lastname)"),
                  _buildTextField(
                    controller: lastNameController,
                    hint: "",
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "กรุณากรอกนามสกุล";
                      if (value.contains(' ')) return "ห้ามมีช่องว่าง";
                      if (!RegExp(r'^[a-zA-Z\u0E00-\u0E7F]+$').hasMatch(value))
                        return "ต้องเป็นภาษาไทยหรืออังกฤษเท่านั้น";
                      final hasEng = RegExp(r'[a-zA-Z]').hasMatch(value);
                      final hasThai = RegExp(
                        r'[\u0E00-\u0E7F]',
                      ).hasMatch(value);
                      if (hasEng && hasThai) return "ห้ามปนภาษาไทยและอังกฤษ";
                      // ✅ cross-field เช็คภาษาต้องตรงกับชื่อ
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
                            !RegExp(r'^[\u0E00-\u0E7F]+$').hasMatch(value))
                          return "นามสกุลต้องเป็นภาษาไทยเหมือนชื่อ";
                      }
                      if (value.length < 3 || value.length > 30)
                        return "ความยาว 3-30 ตัวอักษร";
                      return null;
                    },
                  ),

                  _buildLabel("วันเดือนปีเกิด (Date of Birth)"),
                  _buildTextField(
                    controller: birthdayController,
                    hint: "mm/dd/yyyy",
                    readOnly: true,
                    icon: Icons.calendar_month_outlined,
                    onTap: () => _selectDate(context),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "กรุณาเลือกวันเกิด";
                      // ✅ ตรวจรูปแบบ MM/dd/yyyy
                      if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value))
                        return "รูปแบบวันที่ไม่ถูกต้อง (mm/dd/yyyy)";
                      return null;
                    },
                  ),

                  _buildLabel("อีเมล (Email)"),
                  _buildTextField(
                    controller: emailController,
                    hint: "ตัวอย่าง xxx@gmail.com",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
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
                  ),

                  _buildLabel("เบอร์โทรศัพท์ (Phone)"),
                  _buildTextField(
                    controller: phoneController,
                    hint: "ตัวเลข 10 หลัก",
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
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
                  ),

                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            backgroundColor: Colors.grey[300],
                            side: BorderSide.none,
                          ),
                          child: const Text(
                            "ย้อนกลับ",
                            style: TextStyle(color: Colors.black, fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              Navigator.push(
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
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF76FF03,
                            ), // สีเขียวตามรูป
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "ถัดไป",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 10),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    IconData? icon,
    VoidCallback? onTap,
    VoidCallback? onIconTap,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator, // ✅ รับ validator จากข้างนอกได้ด้วย
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscureText,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ realtime
      validator:
          validator ??
          (val) => val == null || val.isEmpty ? "กรุณากรอกข้อมูล" : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 12,
        ),
        filled: true,
        fillColor: Colors.white,
        // ✅ border แบบปกติ
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        suffixIcon: icon != null
            ? InkWell(
                onTap: onIconTap ?? onTap,
                child: Icon(icon, color: Colors.grey[400], size: 22),
              )
            : null,
      ),
    );
  }
}
