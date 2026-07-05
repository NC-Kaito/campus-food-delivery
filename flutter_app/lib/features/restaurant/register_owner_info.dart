// features/restaurant/register_owner_info.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/features/restaurant/login_restaurant.dart';
import 'package:image_picker/image_picker.dart'; // 🎯 ดึง ImagePicker มาใช้งานในหน้านี้
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
  final File? imagecardid;

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
    this.imagecardid,
  });

  @override
  State<RegisterOwnerInfo> createState() => _RegisterOwnerInfoState();
}

class _RegisterOwnerInfoState extends State<RegisterOwnerInfo> {
  RestaurantService restaurantService = RestaurantService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ImagePicker ownerImagePicker =
      ImagePicker(); // 🎯 สแตนด์บายตัวเลือกรูปภาพ

  bool _isLoading = false;
  String? _ownerImageError; // 🎯 ตัวแปรจับ Error ของรูปเจ้าของร้าน
  File? _selectedOwnerImage; // 🎯 ถือไฟล์รูปภาพใบหน้าในหน้านี้

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

    // ตั้งค่าเริ่มต้นรูปภาพจากหน้าแรก (ถ้ามี)
    if (widget.imagecardid != null) {
      _selectedOwnerImage = widget.imagecardid;
    }
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

  // 🎯 เพิ่มฟังก์ชันเปิดแผงเลือกรูปภาพ (กล้อง/คลังภาพ)
  Future<void> pickOwnerImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text("ถ่ายรูป"),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await ownerImagePicker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (image != null) {
                  setState(() {
                    _selectedOwnerImage = File(image.path);
                    _ownerImageError = null;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text("เลือกจากแกลเลอรี่"),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await ownerImagePicker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                if (image != null) {
                  setState(() {
                    _selectedOwnerImage = File(image.path);
                    _ownerImageError = null;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String? _validateImage(File? file, String fieldName) {
    if (file == null) return "กรุณาแนบ$fieldName";
    final ext = file.path.split('.').last.toLowerCase();
    if (ext != 'jpg' && ext != 'jpeg' && ext != 'png') {
      return "$fieldName ต้องเป็น .jpg หรือ .png";
    }
    final size = file.lengthSync();
    if (size > 1024 * 1024) return "ขนาดเกิน 1MB";
    return null;
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
    // 🎯 ทำการตรวจสอบความครบถ้วนของรูปภาพใบหน้าควบคู่กับฟอร์ม
    setState(() {
      _ownerImageError = _validateImage(
        _selectedOwnerImage,
        "รูปหน้าเจ้าของร้านค้า",
      );
    });

    if (formKey.currentState!.validate() && _ownerImageError == null) {
      setState(() => _isLoading = true);
      try {
        final restaurantImageUrl = await uploadImage(
          widget.restaurantImage,
          'restaurant',
        );

        // ยิงภาพประเภท 'owner' ตรงเข้าหลังบ้าน
        final imagecardIdUrl = await uploadImage(
          _selectedOwnerImage,
          'ownerImage',
        );

        RestaurantModel restaurant = RestaurantModel(
          username: widget.username,
          password: widget.password,
          restaurantName: widget.restaurantName,
          restaurantImage: restaurantImageUrl,
          imagecardid: imagecardIdUrl,
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
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginRestaurant()),
            (route) => false,
          );
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
            color: Color.fromARGB(255, 255, 111, 0),
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
                  const SizedBox(height: 10),

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
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value))
                        return "รูปแบบอีเมลไม่ถูกต้อง";
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

                  // 🎯 ย้ายกล่องอัปโหลดรูปภาพใบหน้าเจ้าของร้านมาสแตนด์บายฝั่งขวาหน้าจอนี้เรียบร้อยครับ
                  _buildUploadBox(
                    "รูปภาพบัตรประชาชน (CardID Image)",
                    _selectedOwnerImage,
                    pickOwnerImage,
                  ),
                  if (_ownerImageError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        _ownerImageError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, {
                            'ownerFirstName': ownerFirstNameController.text,
                            'ownerLastName': ownerLastnameController.text,
                            'email': emailController.text,
                            'phone': phoneController.text,
                            'ownerImage':
                                _selectedOwnerImage, // ส่งย้อนกลับไปเก็บเผื่อด้วย
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
                            backgroundColor: const Color.fromARGB(
                              255,
                              0,
                              255,
                              51,
                            ),
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

  // วิดเจ็ตกล่องอัปโหลดรูปภาพใบหน้าเจ้าของร้านค้า
  Widget _buildUploadBox(String label, File? selectedFile, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: selectedFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(selectedFile, fit: BoxFit.cover),
                  )
                : const Icon(
                    Icons.add_a_photo_outlined,
                    color: Colors.grey,
                    size: 40,
                  ),
          ),
        ),
      ],
    );
  }
}
