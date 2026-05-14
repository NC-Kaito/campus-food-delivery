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
                  _buildTextField(controller: studentIdController, hint: ""),

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
                  ),

                  _buildLabel("ชื่อ (Firstname)"),
                  _buildTextField(controller: firstNameController, hint: ""),

                  _buildLabel("นามสกุล (Lastname)"),
                  _buildTextField(controller: lastNameController, hint: ""),

                  _buildLabel("วันเดือนปีเกิด (Date of Birth)"),
                  _buildTextField(
                    controller: birthdayController,
                    hint: "mm/dd/yyyy",
                    readOnly: true,
                    icon: Icons.calendar_month_outlined,
                    onTap: () => _selectDate(context),
                  ),

                  _buildLabel("อีเมล (Email)"),
                  _buildTextField(
                    controller: emailController,
                    hint: "ตัวอย่าง xxx@gmail.com",
                    icon: Icons.email_outlined,
                  ),

                  _buildLabel("เบอร์โทรศัพท์ (Phone)"),
                  _buildTextField(
                    controller: phoneController,
                    hint: "ตัวเลข 10 หลัก",
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && _obscureText,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        validator: (val) =>
            val == null || val.isEmpty ? "กรุณากรอกข้อมูล" : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 12,
          ),
          border: InputBorder.none,
          suffixIcon: icon != null
              ? InkWell(
                  onTap: onIconTap,
                  child: Icon(icon, color: Colors.grey[400], size: 22),
                )
              : null,
        ),
      ),
    );
  }
}
