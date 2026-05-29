import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/member_model.dart';
import 'package:flutter_app/data/services/member/member_service.dart';
import 'package:flutter_app/features/member/home_member.dart';
import 'package:flutter_app/global_data.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

        // 🟢 แก้ไขเพื่อซ่อมอาการรูปไม่ขึ้น: ทำการสลับ IP จาก 211 เป็น 84 ให้ตรงกับเครื่องปัจจุบัน
        // และใช้ค่าพาร์ทเต็มตรง ๆ จากที่ฐานข้อมูลพ่นมาได้เลยครับ ไม่ต้องทำการหนีบแทรกพาร์ทโฟลเดอร์ซ้ำซ้อน
        if (memberModel.profileimg != null &&
            memberModel.profileimg!.isNotEmpty) {
          memberModel.profileimg = memberModel.profileimg!.replaceAll(
            '10.244.27.211',
            '10.244.27.84',
          );
        }
        print("profileimg (แก้ไขสลับ IP แล้ว) = ${memberModel.profileimg}");
      });
    } catch (e) {
      setState(() {
        isLooding = false;
      });
      print("เกิดข้อผิดพลาด: $e");
    }
  }

  Future<void> _pickImage() async {
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
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text("เลือกจากคลัง"),
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
      final String baseIp = "10.244.27.84";
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://$baseIp:8081/v1/member/uploadProfileImage'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(responseBody);
        return json['url'];
      }
      return null;
    } catch (e) {
      print("Upload error: $e");
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
          });
          GlobalData.usernameMember = usernameController.text;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('บันทึกการแก้ไขเรียบร้อยแล้ว'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeMember()),
            (route) => false,
          );
        }
      } catch (e) {
        print("ERROR: $e");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLooding
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SafeArea(
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── แถบเมนูด้านบนสุด ───
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomeMember(),
                                ),
                                (route) => false,
                              ),
                              child: const Icon(
                                Icons.home_outlined,
                                color: Colors.orange,
                                size: 30,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.shopping_cart_outlined,
                                  color: Colors.orange,
                                  size: 28,
                                ),
                                const SizedBox(width: 15),
                                Icon(
                                  Icons.account_circle,
                                  color: Colors.orange[700],
                                  size: 30,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 10,
                        ),
                        child: Column(
                          children: [
                            // ─── ส่วนรูปภาพโปรไฟล์ ───
                            Center(
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 110,
                                    height: 110,
                                    child: GestureDetector(
                                      onTap: _pickImage,
                                      child: Stack(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.grey.shade400,
                                                width: 2,
                                              ),
                                            ),
                                            child: CircleAvatar(
                                              radius: 52,
                                              backgroundColor: const Color(
                                                0xFFE0E0E0,
                                              ),
                                              backgroundImage:
                                                  _selectedImage != null
                                                  ? FileImage(_selectedImage!)
                                                        as ImageProvider
                                                  : (memberModel.profileimg !=
                                                                null &&
                                                            memberModel
                                                                .profileimg!
                                                                .isNotEmpty
                                                        ? NetworkImage(
                                                            Uri.encodeFull(
                                                              memberModel
                                                                  .profileimg!,
                                                            ),
                                                          ) // 🟢 ดึงข้อมูลตัวแปรสลับ IP สำเร็จรูปได้ทันที
                                                        : null),
                                              child:
                                                  (_selectedImage == null &&
                                                      memberModel.profileimg ==
                                                          null)
                                                  ? const Icon(
                                                      Icons.person,
                                                      size: 55,
                                                      color: Colors.grey,
                                                    )
                                                  : null,
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 2,
                                            right: 2,
                                            child: CircleAvatar(
                                              radius: 16,
                                              backgroundColor: Colors.grey[800],
                                              child: const Icon(
                                                Icons.edit,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "แก้โปรไฟล์ ",
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 22,
                                        color: Colors.black,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 25),

                            // ─── ฟอร์มข้อมูลดีไซน์กรอบสี่เหลี่ยมสีเทาตามแบบ ───
                            _buildInputLabel("ชื่อผู้ใช้ (Username)"),
                            _buildCustomTextField(
                              usernameController,
                              enabled: false,
                            ),

                            _buildInputLabel("ชื่อ (Firstname)"),
                            _buildCustomTextField(
                              firstnameController,
                              enabled: false,
                            ),

                            _buildInputLabel("นามสกุล (Lastname)"),
                            _buildCustomTextField(
                              lastnameController,
                              enabled: false,
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Divider(
                                color: Colors.grey,
                                thickness: 0.8,
                              ),
                            ),

                            const Center(
                              child: Text(
                                "ข้อมูลติดต่อ",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),

                            _buildInputLabel("อีเมล (Email)"),
                            _buildCustomTextField(
                              emailController,
                              enabled: false,
                            ),

                            _buildInputLabel("เบอร์โทรศัพท์ (Phone)"),
                            _buildCustomTextField(
                              phoneController,
                              enabled: true,
                            ),

                            const SizedBox(height: 40),

                            // ─── ปุ่มควบคุมด้านล่าง (ยกเลิก และ บันทึกการแก้ไข) ───
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 46,
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.12),
                                          blurRadius: 4,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // เด้งเคลียร์กลับไปหน้าหลักของสมาชิก
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const HomeMember(),
                                          ),
                                          (route) => false,
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFE0E0E0,
                                        ),
                                        foregroundColor: Colors.black,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        "ยกเลิก",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                Expanded(
                                  child: Container(
                                    height: 46,
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
                                      onPressed: isLoadingAction
                                          ? null
                                          : doUpdateProfile,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF55FF33,
                                        ),
                                        foregroundColor: Colors.black,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                        ),
                                      ),
                                      child: isLoadingAction
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.black,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              "บันทึกการแก้ไข",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 12),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTextField(
    TextEditingController controller, {
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFEAEAEA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1.0),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.green, width: 1.5),
        ),
      ),
    );
  }
}
