// features/member/profile_member.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/member_model.dart';
import 'package:flutter_app/data/services/member/member_service.dart';
import 'package:flutter_app/features/member/home_member.dart';
import 'package:flutter_app/features/member/navbar_member.dart'; // 🎯 นำเข้า NavbarMember ส่วนกลาง
import 'package:flutter_app/global_data.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileMember extends StatefulWidget {
  const ProfileMember({super.key});

  @override
  State<ProfileMember> createState() => _ProfileMemberState();
}

class _ProfileMemberState extends State<ProfileMember> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late MemberModel memberModel = MemberModel();
  MemberService memberService = MemberService();

  GlobalData globalData = GlobalData();
  bool isLooding = true;
  bool isLoadingAction = false;
  bool _isEditable = false; // 🎯 ตัวแปรสถานะเปิด/ปิดสิทธิ์การแก้ไขโปรไฟล์
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController usernameController;
  late final TextEditingController firstnameController;
  late final TextEditingController lastnameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    firstnameController = TextEditingController();
    lastnameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    fetchMemberData();
  }

  @override
  void dispose() {
    usernameController.dispose();
    firstnameController.dispose();
    lastnameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> fetchMemberData() async {
    try {
      String username = GlobalData.usernameMember;
      final result = await memberService.getMemberByUsername(username);

      setState(() {
        memberModel = result;
        isLooding = false;
        usernameController.text = memberModel.username ?? "";
        firstnameController.text = memberModel.firstname ?? "";
        lastnameController.text = memberModel.lastname ?? "";
        emailController.text = memberModel.email ?? "";
        phoneController.text = memberModel.phone ?? "";
      });
    } catch (e) {
      setState(() {
        isLooding = false;
      });
      debugPrint("เกิดข้อผิดพลาดในการดึงโปรไฟล์: $e");
    }
  }

  Future<void> _pickImage() async {
    if (!_isEditable)
      return; // 🔒 ดักจับความปลอดภัย: ถ้าไม่ได้เปิดโหมดแก้ไข ห้ามกดเลือกภาพ
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF64F02D)),
              title: const Text("ถ่ายรูปโปรไฟล์ใหม่"),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (image != null) {
                  setState(() => _selectedImage = File(image.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFF64F02D),
              ),
              title: const Text("เลือกรูปจากคลังภาพ"),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                if (image != null) {
                  setState(() => _selectedImage = File(image.path));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      var response = await DioClient.dio.post(
        '/v1/member/uploadProfileImage',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['url'];
      }
      return null;
    } catch (e) {
      debugPrint("Upload profile image error: $e");
      return null;
    }
  }

  Future<void> doUpdateProfile() async {
    if (formKey.currentState!.validate()) {
      setState(() {
        isLoadingAction = true;
      });
      try {
        String? imageUrl;
        if (_selectedImage != null) {
          imageUrl = await _uploadImage(_selectedImage!);
        }

        MemberModel member = MemberModel(
          username: usernameController.text,
          phone: phoneController.text,
          profileimg: imageUrl ?? memberModel.profileimg,
        );

        await memberService.updateProfileMember(member);
        if (mounted) {
          setState(() {
            isLoadingAction = false;
            _isEditable =
                false; // บันทึกเสร็จแล้วให้ปิดสิทธิ์แก้ไขกลับสู่โหมดอ่านปกติ
            _selectedImage = null;
          });
          GlobalData.usernameMember = usernameController.text;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 บันทึกการแก้ไขข้อมูลโปรไฟล์เรียบร้อยแล้วครับ'),
              backgroundColor: Colors.green,
            ),
          );

          await fetchMemberData(); // สอยข้อมูลใหม่เบื้องหลังมาอัปเดตแผงจอ
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            isLoadingAction = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  String _getFinalProfileImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;

    final String baseUrl = DioClient.dio.options.baseUrl;
    if (rawPath.startsWith('/')) {
      return "$baseUrl$rawPath";
    } else {
      return "$baseUrl/$rawPath";
    }
  }

  @override
  Widget build(BuildContext context) {
    final String finalProfileUrl = _getFinalProfileImageUrl(
      memberModel.profileimg,
    );

    return Scaffold(
      backgroundColor: const Color(
        0xFFF9FBF7,
      ), // คุมโทนสีเบสเขียวอ่อนสบายตาแมตช์กันทั้งระบบ
      // 🌟 1. สวมใส่ AppBar ตัวเก่งเหมือนหน้า HomeMember ครบถ้วนตามระเบียบ
      appBar: const NavbarMember(title: ""),
      body: isLooding
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF64F02D)),
            )
          : SafeArea(
              top: false, // ปล่อยให้ Navbar คุมหัวสเปซด้านบนไปเลยครับ
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── ส่วนแสดงหัวข้อหน้าจอ ───
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            // ─── ส่วนรูปภาพโปรไฟล์วงกลมแบบสแต็ก ───
                            SizedBox(
                              width: 110,
                              height: 110,
                              child: GestureDetector(
                                onTap: _isEditable
                                    ? _pickImage
                                    : null, // ปิดการกดเลือกรูปถ้ายึดสถานะปิดโหมดแก้ไข
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _isEditable
                                              ? const Color(0xFF64F02D)
                                              : Colors.grey.shade400,
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 52,
                                        backgroundColor: const Color(
                                          0xFFE0E0E0,
                                        ),
                                        backgroundImage: _selectedImage != null
                                            ? FileImage(_selectedImage!)
                                                  as ImageProvider
                                            : finalProfileUrl.isNotEmpty
                                            ? NetworkImage(
                                                Uri.encodeFull(finalProfileUrl),
                                              )
                                            : null,
                                        child:
                                            (_selectedImage == null &&
                                                finalProfileUrl.isEmpty)
                                            ? const Icon(
                                                Icons.person,
                                                size: 55,
                                                color: Colors.grey,
                                              )
                                            : null,
                                      ),
                                    ),
                                    // โชว์แผ่นป้ายไอคอนดินสอแก้ไขเมื่อไรที่กดยืนยันโหมด _isEditable เท่านั้น
                                    if (_isEditable)
                                      Positioned(
                                        bottom: 2,
                                        right: 2,
                                        child: CircleAvatar(
                                          radius: 16,
                                          backgroundColor: const Color(
                                            0xFF64F02D,
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt_rounded,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _isEditable
                                  ? "โหมดแก้ไขข้อมูล"
                                  : "ข้อมูลโปรไฟล์ของฉัน",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _isEditable
                                    ? const Color(0xFF2E7D32)
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // ─── ฟอร์มกรอกข้อมูลสากล (ล็อกเบรกตายตัวตามสิทธิ์ร้านค้า) ───
                      _buildInputLabel("ชื่อผู้ใช้ (Username)"),
                      _buildCustomTextField(
                        usernameController,
                        enabled: false,
                      ), // ปิดตายถาวรเพราะเป็นคีย์หลักไอดีฐานข้อมูล

                      _buildInputLabel("ชื่อจริง (Firstname)"),
                      _buildCustomTextField(
                        firstnameController,
                        enabled: false,
                      ), // ปิดตายถาวรระบบหลังบ้านล็อกไว้

                      _buildInputLabel("นามสกุล (Lastname)"),
                      _buildCustomTextField(
                        lastnameController,
                        enabled: false,
                      ), // ปิดตายถาวรระบบหลังบ้านล็อกไว้

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Divider(color: Colors.black12, thickness: 1),
                      ),

                      const Center(
                        child: Text(
                          "ช่องทางข้อมูลติดต่อ",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ),

                      _buildInputLabel("อีเมลสถาบัน (Email)"),
                      _buildCustomTextField(
                        emailController,
                        enabled: false,
                      ), // ล็อกอ่านอย่างเดียวห้ามแก้ไขเปลี่ยนไอดีหลัก

                      _buildInputLabel("เบอร์โทรศัพท์จัดส่งสินค้า (Phone)"),
                      _buildCustomTextField(
                        phoneController,
                        enabled: _isEditable,
                      ), // 🎯 ปลดล็อก/ล็อก ตามสถานะ _isEditable ของตัวแปรกลุ่มหลัก

                      const SizedBox(height: 40),

                      // ─── 🎯 3. ส่วนควบคุมด้านล่างสลับสวิตช์อัตโนมัติแบบระบบร้านค้าต้นแบบ ───
                      _isEditable
                          ? Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 6,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _isEditable = false;
                                          _selectedImage = null;
                                        });
                                        fetchMemberData(); // รีดึงกวาดค่าเดิมกลับมาทับ Controller ทันทีป้องกันข้อมูลค้างเพี้ยน
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFE0E0E0,
                                        ),
                                        foregroundColor: Colors.black87,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        "ยกเลิก",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF64F02D,
                                          ).withOpacity(0.25),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: isLoadingAction
                                          ? null
                                          : doUpdateProfile,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF64F02D,
                                        ), // เขียวสปอร์ตตัวใหม่
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: isLoadingAction
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              "บันทึกข้อมูล",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF64F02D,
                                    ).withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditable = true;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(
                                    0xFF64F02D,
                                  ), // สวมสีเขียวสปอร์ตขวัญใจไรเดอร์แม่โจ้
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.edit_note_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "แก้ไขข้อมูลส่วนตัว",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 14),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildCustomTextField(
    TextEditingController controller, {
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: enabled
              ? Colors.white
              : const Color(
                  0xFFEEEEEE,
                ), // พ่นสีเทากลืนฟิลด์ถ้ายึดสถานะปิดอ่านอย่างเดียว
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1.0),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF64F02D), width: 1.5),
          ),
        ),
      ),
    );
  }
}
