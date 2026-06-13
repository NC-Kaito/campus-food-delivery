// features/restaurant/update_register_owner.dart
import 'package:dio/dio.dart'
    as dio_package; // 🎯 ดึง dio_package มาใช้อัปโหลดไฟล์แทน http ตัวเก่า
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/core/network/dio_client.dart'; // 🎯 อิมพอร์ตตัวแปรไอพีกลาง
import 'dart:io';

class UpdateRegisterOwner extends StatefulWidget {
  final String verificationStatus;
  final RestaurantModel? restaurantData;
  final bool isFormFieldsEditable;

  final String? updatedRestaurantName;
  final int? updatedTypeId;
  final double? updatedLatitude;
  final double? updatedLongitude;
  final String? updatedOpenTime;
  final String? updatedCloseTime;
  final List<bool>? updatedSelectedDays;
  final File? updatedImage;
  final File?
  updatedOwnerImage; // รูปหน้าเจ้าของร้านที่มีการเลือกปรับเปลี่ยนใหม่จากหน้าแรก

  const UpdateRegisterOwner({
    super.key,
    required this.verificationStatus,
    this.restaurantData,
    required this.isFormFieldsEditable,
    this.updatedRestaurantName,
    this.updatedTypeId,
    this.updatedLatitude,
    this.updatedLongitude,
    this.updatedOpenTime,
    this.updatedCloseTime,
    this.updatedSelectedDays,
    this.updatedImage,
    this.updatedOwnerImage,
  });

  @override
  State<UpdateRegisterOwner> createState() => _UpdateRegisterOwnerState();
}

class _UpdateRegisterOwnerState extends State<UpdateRegisterOwner> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final RestaurantService restaurantService = RestaurantService();

  bool _isLoadingAction = false;

  // Controllers
  late final TextEditingController ownerFirstNameController;
  late final TextEditingController ownerLastNameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;

  @override
  void initState() {
    super.initState();
    ownerFirstNameController = TextEditingController();
    ownerLastNameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();

    if (widget.restaurantData != null) {
      ownerFirstNameController.text =
          widget.restaurantData!.ownerFirstName ?? "";
      ownerLastNameController.text = widget.restaurantData!.ownerLastName ?? "";
      emailController.text = widget.restaurantData!.email ?? "";
      phoneController.text = widget.restaurantData!.phone ?? "";
    }
  }

  @override
  void dispose() {
    ownerFirstNameController.dispose();
    ownerLastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  int _convertDaysToInt(List<bool> days) {
    int result = 0;
    for (int i = 0; i < days.length; i++) {
      if (days[i]) result += (1 << i);
    }
    return result;
  }

  // 🎯 ปรับฟังก์ชันอัปโหลดรูปภาพใหม่ผ่าน DioClient: มั่นคง ปลอดภัย รองรับการสลับไอพีเราเตอร์กลาง
  Future<String?> _uploadImage(File imageFile, String type) async {
    try {
      String fileName = imageFile.path.split('/').last;
      dio_package.FormData formData = dio_package.FormData.fromMap({
        'image': await dio_package.MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
        'type': type,
      });

      var response = await DioClient.dio.post(
        '/v1/restaurant/uploadImage',
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['url'];
      }
      return null;
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

  // ── ฟังก์ชันส่งข้อมูลแก้ไขทั้งหมดไปหาฐานข้อมูลผ่าน Service ──
  Future<void> doUpdateRegisterData() async {
    if (formKey.currentState!.validate()) {
      setState(() => _isLoadingAction = true);
      try {
        // 1. ตรวจสอบและอัปโหลดรูปภาพใหม่เข้าสู่ระบบปลายทางหลังบ้าน
        String? newRestaurantImageUrl;
        String? newOwnerImageUrl;

        if (widget.updatedImage != null) {
          newRestaurantImageUrl = await _uploadImage(
            widget.updatedImage!,
            'restaurant',
          );
        }
        if (widget.updatedOwnerImage != null) {
          // 🎯 ปรับเปลี่ยนฟิลด์ประเภทการยิงเซฟรูปจาก 'lease' เดิม สลับให้เป็นหมวดภาพ 'owner' ตามคำสั่งอาจารย์
          newOwnerImageUrl = await _uploadImage(
            widget.updatedOwnerImage!,
            'ownerImage',
          );
        }

        // 2. มัดรวมข้อมูลประกอบร่างเซฟทับตาราง PostgreSQL หลังบ้าน
        RestaurantModel updatedModel = RestaurantModel(
          username: widget.restaurantData?.username,
          password: widget.restaurantData?.password,
          restaurantName:
              widget.updatedRestaurantName ??
              widget.restaurantData?.restaurantName,
          restaurantImage:
              newRestaurantImageUrl ?? widget.restaurantData?.restaurantImage,

          // 🎯 แก้ไขจุดสำคัญ: ถอด leaseAgreementImg เก่าทิ้ง แล้วส่งค่าอัปเดตรูปใหม่เข้าตัวแปร ownerImage แทน
          ownerImage: newOwnerImageUrl ?? widget.restaurantData?.ownerImage,

          openTime: widget.updatedOpenTime ?? widget.restaurantData?.openTime,
          closeTime:
              widget.updatedCloseTime ?? widget.restaurantData?.closeTime,
          openDay: widget.updatedSelectedDays != null
              ? _convertDaysToInt(widget.updatedSelectedDays!)
              : widget.restaurantData?.openDay,
          typerestaurantId:
              widget.updatedTypeId ?? widget.restaurantData?.typerestaurantId,
          latitude: widget.updatedLatitude ?? widget.restaurantData?.latitude,
          longitude:
              widget.updatedLongitude ?? widget.restaurantData?.longitude,

          // ข้อมูลฟอร์มในหน้าที่สอง
          ownerFirstName: ownerFirstNameController.text,
          ownerLastName: ownerLastNameController.text,
          email: emailController.text,
          phone: phoneController.text,

          statusOpen: widget.restaurantData?.statusOpen ?? false,
          registerDate: widget.restaurantData?.registerDate,
          verificationStatus: widget.restaurantData?.verificationStatus,
          notApproveDetail: widget.restaurantData?.notApproveDetail,
        );

        // 3. ยิงข้อมูลอัปเดตผ่าน Service
        await restaurantService.updateProfileRestaurant(updatedModel);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('บันทึกการแก้ไขข้อมูลเรียบร้อยแล้ว'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, 'success');
        }
      } catch (e) {
        print("Update Register Error: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาดในการบันทึก: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoadingAction = false);
      }
    }
  }

  InputDecoration _inputDecoration({bool enabled = true}) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      filled: true,
      fillColor: enabled ? Colors.white : const Color(0xFFE0E0E0),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWaitStatus = widget.verificationStatus == 'wait';
    final bool canEdit = widget.isFormFieldsEditable;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.orange),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'ข้อมูลการสมัคร',
          style: TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ข้อมูลเจ้าของร้านค้า หรือผู้ดูแลร้าน',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                _buildLabel("ชื่อ (FirstName)"),
                TextFormField(
                  controller: ownerFirstNameController,
                  enabled: canEdit,
                  decoration: _inputDecoration(enabled: canEdit),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? "กรุณากรอกชื่อจริง" : null,
                ),

                _buildLabel("นามสกุล (LastName)"),
                TextFormField(
                  controller: ownerLastNameController,
                  enabled: canEdit,
                  decoration: _inputDecoration(enabled: canEdit),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? "กรุณากรอกนามสกุล" : null,
                ),

                _buildLabel("อีเมล (Email)"),
                TextFormField(
                  controller: emailController,
                  enabled: canEdit,
                  decoration: _inputDecoration(enabled: canEdit),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? "กรุณากรอกอีเมล" : null,
                ),

                _buildLabel("เบอร์โทรศัพท์ (Phone)"),
                TextFormField(
                  controller: phoneController,
                  enabled: canEdit,
                  decoration: _inputDecoration(enabled: canEdit),
                  validator: (v) => (v == null || v.isEmpty)
                      ? "กรุณากรอกเบอร์โทรศัพท์"
                      : null,
                ),

                const SizedBox(height: 40),
                _buildActionButtons(isWaitStatus, canEdit),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isWaitStatus, bool canEdit) {
    if (isWaitStatus) {
      return _buildButton(
        "ย้อนกลับ",
        const Color(0xFFE0E0E0),
        Colors.black,
        () => Navigator.pop(context),
      );
    } else {
      if (!canEdit) {
        return Column(
          children: [
            _buildButton(
              "แก้ไขข้อมูล",
              const Color(0xFF55FF33),
              Colors.white,
              () {
                Navigator.pop(context, 'edit');
              },
            ),
            const SizedBox(height: 12),
            _buildButton(
              "ย้อนกลับ",
              const Color(0xFFE0E0E0),
              Colors.black,
              () => Navigator.pop(context),
            ),
          ],
        );
      } else {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildButton(
                    "ยกเลิก",
                    const Color(0xFFFF5252),
                    Colors.white,
                    () {
                      Navigator.pop(context, 'cancel');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildButton(
                    "ย้อนกลับ",
                    const Color(0xFFE0E0E0),
                    Colors.black,
                    () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildButton(
              _isLoadingAction ? "กำลังบันทึก..." : "บันทึกการแก้ไข",
              const Color(0xFF55FF33),
              Colors.white,
              _isLoadingAction ? () {} : doUpdateRegisterData,
            ),
          ],
        );
      }
    }
  }

  Widget _buildButton(String text, Color bg, Color textC, VoidCallback press) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: press,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: textC,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4, top: 10),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    ),
  );
}
