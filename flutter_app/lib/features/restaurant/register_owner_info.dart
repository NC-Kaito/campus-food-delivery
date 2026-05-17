import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';

class RegisterOwnerInfo extends StatefulWidget {
  final String? initialFirstName;
  final String? initialLastName;
  final String? initialEmail;
  final String? initialPhone;

  final String username;
  final String password;
  final String restaurantName;
  final int typeId;
  final double latitude;
  final double longitude;
  final String openTime;
  final String closeTime;
  final List<bool> selectedDays;
  final File? restaurantImage;
  final File? leaseImage;

  const RegisterOwnerInfo({
    super.key,
    this.initialFirstName,
    this.initialLastName,
    this.initialEmail,
    this.initialPhone,
    required this.username,
    required this.password,
    required this.restaurantName,
    required this.typeId,
    required this.latitude,
    required this.longitude,
    required this.openTime,
    required this.closeTime,
    required this.selectedDays,
    this.restaurantImage,
    this.leaseImage,
  });

  @override
  State<RegisterOwnerInfo> createState() => _RegisterOwnerInfoState();
}

class _RegisterOwnerInfoState extends State<RegisterOwnerInfo> {
  RestaurantService restaurantService = RestaurantService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late final TextEditingController ownerFirstNameController;
  late final TextEditingController ownerLastnameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;

  @override
  void initState() {
    ownerFirstNameController = TextEditingController(
      text: widget.initialFirstName,
    );
    ownerLastnameController = TextEditingController(
      text: widget.initialLastName,
    );
    emailController = TextEditingController(text: widget.initialEmail);
    phoneController = TextEditingController(text: widget.initialPhone);
    super.initState();
  }

  @override
  void dispose() {
    ownerFirstNameController.dispose();
    ownerLastnameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<String?> uploadImage(File? imageFile, String type) async {
    if (imageFile == null) return null;
    try {
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
        'type': type,
      });
      final response = await DioClient.dio.post(
        '/v1/restaurant/uploadImage',
        data: formData,
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data['url'];
      }
      return response.data['url'];
    } catch (e) {
      return null;
    }
  }

  Future<void> doRegister() async {
    if (formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final restaurantImageUrl = await uploadImage(
          widget.restaurantImage,
          'restaurant',
        );
        final leaseImageUrl = await uploadImage(widget.leaseImage, 'lease');

        RestaurantModel restaurant = RestaurantModel(
          username: widget.username,
          password: widget.password,
          restaurantName: widget.restaurantName,
          restaurantImage: restaurantImageUrl,
          leaseAgreementImg: leaseImageUrl,
          openTime: widget.openTime,
          closeTime: widget.closeTime,
          openDay: convertDaysToInt(widget.selectedDays),
          latitude: widget.latitude,
          longitude: widget.longitude,
          ownerFirstName: ownerFirstNameController.text,
          ownerLastName: ownerLastnameController.text,
          email: emailController.text,
          phone: phoneController.text,
          statusOpen: false,
          typerestaurantId: widget.typeId,
        );

        await restaurantService.doRegisterRestaurant(restaurant);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("สมัครร้านค้าสำเร็จ รอการอนุมัติ"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("เกิดข้อผิดพลาด: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  int convertDaysToInt(List<bool> selectedDays) {
    int result = 0;
    for (int i = 0; i < selectedDays.length; i++) {
      if (selectedDays[i]) {
        result += (1 << i);
      }
    }
    return result;
  }

  // สไตล์กลางสำหรับช่องกรอกข้อมูล (เพื่อให้ขอบ Error สีแดงแสดงผลถูกต้อง)
  InputDecoration _inputDecoration({String hint = "", Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
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
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'สมัครร้านค้า',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: formKey,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ข้อมูลเจ้าของร้านค้า หรือผู้ดูแลร้าน',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // ✅ 1. ชื่อจริง (ownerFirstName)
                  _buildLabel("ชื่อจริง (FirstName)"),
                  TextFormField(
                    controller: ownerFirstNameController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return "กรุณากรอกชื่อจริง";
                      if (value.contains(' '))
                        return "ต้องไม่มีเว้นวรรคหรือช่องว่าง";
                      if (!RegExp(
                        r'^[a-zA-Z\u0E00-\u0E7F]+$',
                      ).hasMatch(value)) {
                        return "ต้องเป็นภาษาไทย หรือภาษาอังกฤษเท่านั้น";
                      }
                      if (value.length < 3 || value.length > 30)
                        return "ความยาวต้องระว่าง 3 - 30 ตัวอักษร";
                      return null;
                    },
                    decoration: _inputDecoration(hint: "กรอกชื่อจริง"),
                  ),

                  // ✅ 2. นามสกุล (ownerLastName)
                  _buildLabel("นามสกุล (Lastname)"),
                  TextFormField(
                    controller: ownerLastnameController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return "กรุณากรอกนามสกุล";
                      if (value.contains(' '))
                        return "ต้องไม่มีเว้นวรรคหรือช่องว่าง";
                      if (!RegExp(
                        r'^[a-zA-Z\u0E00-\u0E7F]+$',
                      ).hasMatch(value)) {
                        return "ต้องเป็นภาษาไทย หรือภาษาอังกฤษเท่านั้น";
                      }
                      if (value.length < 3 || value.length > 30)
                        return "ความยาวต้องระว่าง 3 - 30 ตัวอักษร";
                      return null;
                    },
                    decoration: _inputDecoration(hint: "กรอกนามสกุล"),
                  ),

                  // ✅ 3. อีเมล (Email)
                  _buildLabel("อีเมล (Email)"),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return "กรุณากรอกอีเมล";
                      if (value.contains(' '))
                        return "ต้องไม่มีเว้นวรรคหรือช่องว่าง";

                      // คัดกรองรูปแบบ xxx@xxx.xx เบื้องต้นตามมาตรฐานสากล
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return "รูปแบบอีเมลไม่ถูกต้อง";
                      }
                      // ตรวจสอบความยาวของชื่อเมลด้านหน้าตามที่คุณกำหนด (8-20 ตัวอักษร)
                      final parts = value.split('@');
                      if (parts.isNotEmpty) {
                        final localPart = parts[0];
                        if (!RegExp(r'^[a-zA-Z0-9.]+$').hasMatch(localPart)) {
                          return "ชื่ออีเมลต้องเป็นภาษาอังกฤษ หรือตัวเลขเท่านั้น";
                        }
                        if (localPart.length < 3 || localPart.length > 20) {
                          return "ส่วนชื่ออีเมลหน้า @ ต้องยาว 3-20 ตัวอักษร";
                        }
                      }
                      return null;
                    },
                    decoration: _inputDecoration(
                      hint: "ตัวอย่าง xxx@gmail.com",
                      suffixIcon: Icon(
                        Icons.email_outlined,
                        color: Colors.grey[300],
                      ),
                    ),
                  ),

                  // ✅ 4. เบอร์โทรศัพท์ (Phone)
                  _buildLabel("เบอร์โทรศัพท์ (Phone)"),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return "กรุณากรอกเบอร์โทรศัพท์";
                      if (value.contains(' '))
                        return "ต้องไม่มีเว้นวรรคหรือช่องว่าง";
                      if (!RegExp(r'^[0-9]+$').hasMatch(value))
                        return "ต้องเป็นตัวเลข (0-9) เท่านั้น";
                      if (value.length < 10 || value.length > 15)
                        return "ความยาวต้องอยู่ระหว่าง 10 ถึง 15 หลัก";
                      return null;
                    },
                    decoration: _inputDecoration(
                      hint: "ตัวเลข 10-15 หลัก",
                      suffixIcon: Icon(
                        Icons.phone_android_outlined,
                        color: Colors.grey[300],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ปุ่ม ย้อนกลับ และ สมัครสมาชิก
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, {
                            'ownerFirstName': ownerFirstNameController.text,
                            'ownerLastName': ownerLastnameController.text,
                            'email': emailController.text,
                            'phone': phoneController.text,
                          }),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "ย้อนกลับ",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : doRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent[400],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
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
                                    fontSize: 16,
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
      padding: const EdgeInsets.only(bottom: 8, top: 14),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
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
}
