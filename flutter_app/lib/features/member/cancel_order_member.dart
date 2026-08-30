import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_app/data/services/order_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:dio/dio.dart' as dio_package;

class CancelOrderMember extends StatefulWidget {
  final int orderId; // 🎯 รับรหัสออเดอร์เข้ามาเพื่อส่ง API

  const CancelOrderMember({super.key, required this.orderId});

  @override
  State<CancelOrderMember> createState() => _CancelOrderMemberState();
}

class _CancelOrderMemberState extends State<CancelOrderMember> {
  File? _selectedImage;
  final TextEditingController _detailController = TextEditingController();
  bool _isUploading = false;

  final OrderService _orderService = OrderService();

  final Color primaryGreen = const Color(0xFF64F02D);

  // 🎯 ฟังก์ชันเลือกรูปภาพหลักฐาน
  Future<void> _pickImage() async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource
          .gallery, // เปลี่ยนเป็น ImageSource.camera ได้ถ้าบังคับให้ถ่ายรูปสด
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  // 🎯 ฟังก์ชันกดยืนยันส่งเรื่องแจ้งปัญหา
  Future<void> _submitIssue() async {
    if (_detailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณาระบุรายละเอียดปัญหาที่พบ")),
      );
      return;
    }
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณาอัปโหลดรูปภาพหลักฐาน")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String detail = "กรณีออเดอร์ไม่ตรง: ${_detailController.text.trim()}";

      // 🎯 เรียกใช้ Service แทนการยิง Dio โดยตรง
      bool isSuccess = await _orderService.reportIssue(
        widget.orderId,
        detail,
        _selectedImage!,
      );

      if (isSuccess) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("ส่งข้อมูลแจ้งปัญหาเรียบร้อยแล้ว"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(
          context,
          true,
        ); // เด้งกลับพร้อมส่ง true ไปสั่งรีเฟรชหน้า List
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryGreen),
        title: const Text(
          "แจ้งปัญหาคำสั่งซื้อ",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎯 1. กล่องข้อความแจ้งเตือน (Disclaimer) ลูกค้าต้องเคลียร์กับร้านเอง
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.orange.shade800,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "โปรดทำความเข้าใจ",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "การส่งเรื่องแจ้งปัญหานี้ เป็นเพียงการบันทึกประวัติและหลักฐานเข้าระบบ สำหรับการชดเชยหรือเปลี่ยนอาหาร ลูกค้าจะต้องทำการติดต่อและพูดคุยตกลงกับทางร้านค้าโดยตรงด้วยตนเอง",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange.shade900,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 🎯 2. หัวข้อปัญหา
            const Text(
              "หัวข้อปัญหา",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "ได้รับอาหารไม่ตรงกับออเดอร์ที่สั่ง",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 🎯 3. ช่องกรอกรายละเอียด
            const Text(
              "รายละเอียดเพิ่มเติม",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _detailController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    "กรุณาอธิบาย เช่น สั่งข้าวกะเพราหมูสับ แต่ได้รับข้าวหมูทอด...",
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.red, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 🎯 4. อัปโหลดรูปภาพ
            const Text(
              "รูปภาพหลักฐาน",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedImage == null
                        ? Colors.red.shade200
                        : Colors.grey.shade300,
                    width: 1.5,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            color: Colors.red.shade300,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "แตะเพื่ออัปโหลดรูปภาพ",
                            style: TextStyle(
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "กรุณาถ่ายให้เห็นอาหารที่ได้รับอย่างชัดเจน",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),

      // 🎯 ปุ่มยืนยันด้านล่าง
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, -4),
                blurRadius: 10,
              ),
            ],
          ),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isUploading ? null : _submitIssue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: _isUploading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      "ยืนยันการแจ้งปัญหา",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
