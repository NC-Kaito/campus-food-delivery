import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/member_model.dart';
import 'package:flutter_app/data/services/member/member_service.dart';
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
  bool isLoading = false;
  File? _selectedImage; // เพิ่ม
  final ImagePicker _picker = ImagePicker(); // เพิ่ม

  late final TextEditingController profileImgController;
  late final TextEditingController usernameController;
  late final TextEditingController firstnameController;
  late final TextEditingController lastnameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;

  @override
  void initState() {
    profileImgController = TextEditingController();
    usernameController = TextEditingController();
    firstnameController = TextEditingController();
    lastnameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    fetchMemberData();
    super.initState();
  }

  @override
  void dispose() {
    profileImgController.dispose();
    usernameController.dispose();
    firstnameController.dispose();
    lastnameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> fetchMemberData() async {
    try {
      MemberModel requestModel = MemberModel();
      requestModel.username = GlobalData.usernameMember;
      final result = await memberService.getMemberByUsername(requestModel);

      setState(() {
        memberModel = result;
        isLooding = false;
        usernameController.text = memberModel.username ?? "";
        firstnameController.text = memberModel.firstname ?? "";
        lastnameController.text = memberModel.lastname ?? "";
        emailController.text = memberModel.email ?? "";
        phoneController.text = memberModel.phone ?? "";
        print("profileimg = ${memberModel.profileimg}");
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
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          'http://10.226.43.211:8081/v1/member/uploadProfileImage',
        ), // เปลี่ยน URL ตรงนี้
      );

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // สมมติ API return { "url": "https://..." }
        final json = jsonDecode(responseBody);
        return json['url']; // ได้ URL รูปกลับมา
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
        isLoading = true;
      });
      try {
        // อัปโหลดรูปก่อนถ้ามีการเลือกรูปใหม่
        String? imageUrl;
        if (_selectedImage != null) {
          imageUrl = await _uploadImage(_selectedImage!);
        }

        MemberModel member = MemberModel(
          username: usernameController.text,
          phone: phoneController.text,
          profileimg: imageUrl ?? memberModel.profileimg,
        );
        print(
          "Data ที่ส่งไป: username=${member.username}, phone=${member.phone}, profileimg=${member.profileimg}",
        );
        await memberService.updateProfileMember(member);
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          GlobalData.usernameMember = usernameController.text;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ProfileMember()),
            (route) => false,
          );
        }
      } catch (e) {
        print("ERROR: $e");
        if (mounted) {
          setState(() {
            isLoading = false;
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
      appBar: AppBar(
        title: const Text(
          "CAMPUS EAT",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
        foregroundColor: Colors.white,
        elevation: 0, // เอาเงาออกเพื่อให้ดูโมเดิร์น
      ),
      body: isLooding
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            // ใส่อันนี้แทน ↓
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: GestureDetector(
                                onTap: _pickImage,
                                behavior: HitTestBehavior.opaque,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundColor: Colors.green,
                                      backgroundImage: _selectedImage != null
                                          ? FileImage(_selectedImage!)
                                                as ImageProvider
                                          : (memberModel.profileimg != null
                                                ? NetworkImage(
                                                    memberModel.profileimg!,
                                                  )
                                                : null),
                                      child:
                                          (_selectedImage == null &&
                                              memberModel.profileimg == null)
                                          ? const Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // GestureDetector(
                            //   onTap: () {
                            //     _p
                            //   },
                            // )
                            SizedBox(height: 10),
                            Text(
                              "ข้อมูลโปรไฟล์",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // ใช้ฟังก์ชันเสริมเพื่อลดความซ้ำซ้อนของโค้ด (ช่วยให้แก้ง่าย)
                      _buildInputLabel(
                        Icons.person_outline,
                        "ชื่อผู้ใช้งาน (Username)",
                      ),
                      _buildReadOnlyTextField(usernameController),

                      _buildInputLabel(
                        Icons.badge_outlined,
                        "ชื่อจริง (First Name)",
                      ),
                      _buildReadOnlyTextField(firstnameController),

                      _buildInputLabel(
                        Icons.badge_outlined,
                        "นามสกุล (Last Name)",
                      ),
                      _buildReadOnlyTextField(lastnameController),

                      _buildInputLabel(Icons.email_outlined, "อีเมล (Email)"),
                      _buildReadOnlyTextField(emailController),

                      _buildInputLabel(
                        Icons.phone_android_outlined,
                        "เบอร์โทรศัพท์ (Phone)",
                      ),

                      TextFormField(
                        controller: phoneController,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.green.withOpacity(0.1),
                          prefixIcon: const Icon(
                            Icons.phone,
                            color: Colors.green,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: const BorderSide(
                              color: Colors.green,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ปุ่มปิดหรือกดย้อนกลับ (ถ้าต้องการ)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : doUpdateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "แก้ไขโปรไฟล์",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ฟังก์ชันสร้าง Label พร้อม Icon
  Widget _buildInputLabel(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 15),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันสร้าง TextFormField สำหรับอ่านอย่างเดียว (สไตล์เดียวกันทั้งหน้า)
  Widget _buildReadOnlyTextField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      enabled: false,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[100],
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 12,
        ),
      ),
    );
  }
}
