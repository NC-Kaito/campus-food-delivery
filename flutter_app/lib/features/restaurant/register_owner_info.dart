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

  Future<String?> uploadImage(File? imageFile) async {
    if (imageFile == null) return null;
    try {
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });
      final response = await DioClient.dio.post(
        '/v1/restaurant/uploadImgae',
        data: formData,
      );
      return response.data['url'];
    } catch (e) {
      return null;
    }
  }

  Future<void> doRegister() async {
    if (formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // ✅ อัปโหลดรูปก่อน แล้วค่อยสมัคร
        final restaurantImageUrl = await uploadImage(widget.restaurantImage);
        final leaseImageUrl = await uploadImage(widget.leaseImage);

        RestaurantModel restaurant = RestaurantModel(
          username: widget.username,
          password: widget.password,
          restaurantName: widget.restaurantName,
          restaurantImage: restaurantImageUrl, // ✅ URL จากการอัปโหลด
          leaseAgreementImg: leaseImageUrl, // ✅ URL จากการอัปโหลด
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
        result += (1 << i); // 2^i
      }
    }
    return result;
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100], // พื้นหลังเทาอ่อนตามรูป
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // ให้ความสูงยืดตามเนื้อหา
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ข้อมูลเจ้าของร้านค้า หรือผู้ดูแลร้าน',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                _buildLabel("ชื่อจริง (FirstName)"),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextFormField(
                    controller: ownerFirstNameController,
                    decoration: InputDecoration(
                      hintText: "",
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                _buildLabel("นามสกุล (Lastname)"),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextFormField(
                    controller: ownerLastnameController,
                    decoration: InputDecoration(
                      hintText: "",
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                _buildLabel("อีเมล (Email)"),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "ตัวอย่าง xxx@gmail.com",
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                      suffixIcon: Icon(
                        Icons.email_outlined,
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                ),

                _buildLabel("เบอร์โทรศัพท์ (Phone)"),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: "ตัวเลข 10 หลัก",
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                      suffixIcon: Icon(
                        Icons.phone_android_outlined,
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // ส่วนของปุ่ม ย้อนกลับ และ สมัครสมาชิก
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
                        child: const Text(
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
    );
  }

  // Widget สำหรับ Label หัวข้อ input
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  // Widget สำหรับช่องกรอกข้อมูล
  Widget _buildTextField(String hint, {IconData? icon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 12,
          ),
          border: InputBorder.none,
          suffixIcon: icon != null ? Icon(icon, color: Colors.grey[300]) : null,
        ),
      ),
    );
  }
}
