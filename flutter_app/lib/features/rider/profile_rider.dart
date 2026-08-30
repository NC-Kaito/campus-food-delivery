// features/rider/profile_rider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/rider_model.dart';
import 'package:flutter_app/data/services/rider/rider_service.dart';
import 'package:flutter_app/features/rider/navbar_rider.dart';
import 'package:flutter_app/global_data.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio_package;

class ProfileRider extends StatefulWidget {
  const ProfileRider({super.key});

  @override
  State<ProfileRider> createState() => _ProfileRiderState();
}

class _ProfileRiderState extends State<ProfileRider> {
  // ── ธีมสีหลัก (Theme) ปรับให้แมตช์กับ ProfileRestaurant ──
  static const Color _primary = Color(0xFF16A34A); // เขียวหลัก
  static const Color _primaryDark = Color(0xFF0F7A38);
  static const Color _accent = Color(0xFFEA7C1E); // ส้มสำหรับหัวข้อ Section
  static const Color _bg = Color(0xFFF5F6F8);
  static const Color _textDark = Color(0xFF1E1E24);
  static const Color _textMuted = Color(0xFF8A8D93);
  static const Color _danger = Color(0xFFE53935);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final RiderService _riderService = RiderService();
  final ImagePicker _picker = ImagePicker();

  RiderModel? _rider;
  bool _isLoading = true;
  bool _isLoadingAction = false;
  bool _isEditable = false; // 🎯 ตัวแปรสถานะเปิด/ปิด โหมดแก้ไข

  File? _selectedImage;
  String? _profileImageUrl;

  // Controllers
  late final TextEditingController _studentIdController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _birthdayController;
  late final TextEditingController _facultyController;
  late final TextEditingController _majorController;
  late final TextEditingController _vehiclePlateController;

  @override
  void initState() {
    super.initState();
    _studentIdController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _birthdayController = TextEditingController();
    _facultyController = TextEditingController();
    _majorController = TextEditingController();
    _vehiclePlateController = TextEditingController();

    _loadRiderProfile();
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthdayController.dispose();
    _facultyController.dispose();
    _majorController.dispose();
    _vehiclePlateController.dispose();
    super.dispose();
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;
    final String baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/') ? "$baseUrl$rawPath" : "$baseUrl/$rawPath";
  }

  Future<void> _loadRiderProfile() async {
    setState(() => _isLoading = true);
    try {
      final rider = await _riderService.getRiderByStudentId(
        GlobalData.usernameRider,
      );
      setState(() {
        _rider = rider;
        _studentIdController.text = rider.studentid ?? "-";
        _firstNameController.text = rider.firstName ?? "-";
        _lastNameController.text = rider.lastName ?? "-";
        _emailController.text = rider.email ?? "";
        _phoneController.text = rider.phone ?? "";
        _birthdayController.text = rider.birthday ?? "-";
        _facultyController.text = rider.facultyName ?? "-";
        _majorController.text = rider.majorName ?? "-";
        _vehiclePlateController.text = rider.vehiclePlate ?? "-";
        _profileImageUrl = rider.studentCardImage; // หรือฟิลด์รูปโปรไฟล์
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("โหลดข้อมูลโปรไฟล์ไม่สำเร็จ: $e"),
            backgroundColor: _danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: _primary),
                ),
                title: const Text(
                  "ถ่ายรูป",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
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
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library, color: _primary),
                ),
                title: const Text(
                  "เลือกจากคลัง",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
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
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_rider == null) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoadingAction = true);
      try {
        final updated = RiderModel(
          studentid: _rider!.studentid,
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          firstName: _rider!.firstName,
          lastName: _rider!.lastName,
          birthday: _rider!.birthday,
          facultyName: _rider!.facultyName,
          majorName: _rider!.majorName,
          vehiclePlate: _rider!.vehiclePlate,
        );

        await _riderService.updateProfileMember(updated);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("บันทึกข้อมูลเรียบร้อยแล้ว"),
              backgroundColor: _primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          setState(() {
            _isEditable = false;
            _selectedImage = null;
          });

          await _loadRiderProfile();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("บันทึกไม่สำเร็จ: $e"),
              backgroundColor: _danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoadingAction = false);
      }
    }
  }

  // ── UI Components Builders ──

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: _textDark,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, left: 2),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _accent, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: _textDark,
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration({
    String hint = "",
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: enabled ? Colors.white : const Color(0xFFF0F1F3),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _danger, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String finalAvatarUrl = _getFinalImageUrl(_profileImageUrl);

    return Scaffold(
      backgroundColor: _bg,
      appBar: const NavbarRider(title: "โปรไฟล์"),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
                  child: Column(
                    children: [
                      // ── รูปโปรไฟล์ Rider ────────────────────────────
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: _primary, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 52,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: _selectedImage != null
                                    ? FileImage(_selectedImage!)
                                          as ImageProvider
                                    : (finalAvatarUrl.isNotEmpty
                                          ? NetworkImage(finalAvatarUrl)
                                          : null),
                                child:
                                    (_selectedImage == null &&
                                        finalAvatarUrl.isEmpty)
                                    ? const Icon(
                                        Icons.person,
                                        size: 58,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                            ),
                            if (_isEditable)
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: _primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "${_firstNameController.text} ${_lastNameController.text}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                        ),
                      ),
                      Text(
                        "รหัสนักศึกษา: ${_studentIdController.text}",
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: _textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ══ Section 1: ข้อมูลติดต่อ ════════════════════════
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildSectionHeader(
                          icon: Icons.contact_mail_outlined,
                          title: "ข้อมูลติดต่อ",
                        ),
                      ),
                      _sectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("อีเมล (Email)"),
                            TextFormField(
                              controller: _emailController,
                              enabled: _isEditable,
                              keyboardType: TextInputType.emailAddress,
                              validator: _isEditable
                                  ? (v) {
                                      if (v == null || v.trim().isEmpty)
                                        return "กรุณากรอกอีเมล";
                                      if (!RegExp(
                                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                      ).hasMatch(v)) {
                                        return "รูปแบบอีเมลไม่ถูกต้อง";
                                      }
                                      return null;
                                    }
                                  : null,
                              decoration: _inputDecoration(
                                enabled: _isEditable,
                                suffixIcon: Icon(
                                  Icons.email_outlined,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                            _buildLabel("เบอร์โทรศัพท์ (Phone)"),
                            TextFormField(
                              controller: _phoneController,
                              enabled: _isEditable,
                              keyboardType: TextInputType.phone,
                              validator: _isEditable
                                  ? (v) {
                                      if (v == null || v.trim().isEmpty)
                                        return "กรุณากรอกเบอร์โทรศัพท์";
                                      if (!RegExp(r'^[0-9]+$').hasMatch(v))
                                        return "ต้องเป็นตัวเลขเท่านั้น";
                                      if (v.length < 10 || v.length > 15)
                                        return "ความยาว 10-15 หลัก";
                                      return null;
                                    }
                                  : null,
                              decoration: _inputDecoration(
                                enabled: _isEditable,
                                suffixIcon: Icon(
                                  Icons.phone_in_talk_outlined,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ══ Section 2: ข้อมูลส่วนตัว ════════════════════════
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildSectionHeader(
                          icon: Icons.person_outline_rounded,
                          title: "ข้อมูลส่วนตัว",
                        ),
                      ),
                      _sectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("รหัสนักศึกษา"),
                            TextFormField(
                              controller: _studentIdController,
                              enabled: false,
                              decoration: _inputDecoration(enabled: false),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel("ชื่อจริง"),
                                      TextFormField(
                                        controller: _firstNameController,
                                        enabled: false,
                                        decoration: _inputDecoration(
                                          enabled: false,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel("นามสกุล"),
                                      TextFormField(
                                        controller: _lastNameController,
                                        enabled: false,
                                        decoration: _inputDecoration(
                                          enabled: false,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            _buildLabel("วันเดือนปีเกิด"),
                            TextFormField(
                              controller: _birthdayController,
                              enabled: false,
                              decoration: _inputDecoration(enabled: false),
                            ),
                            _buildLabel("คณะ"),
                            TextFormField(
                              controller: _facultyController,
                              enabled: false,
                              decoration: _inputDecoration(enabled: false),
                            ),
                            _buildLabel("สาขาวิชา"),
                            TextFormField(
                              controller: _majorController,
                              enabled: false,
                              decoration: _inputDecoration(enabled: false),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ══ Section 3: ยานพาหนะ ════════════════════════
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildSectionHeader(
                          icon: Icons.two_wheeler_outlined,
                          title: "ข้อมูลยานพาหนะ",
                        ),
                      ),
                      _sectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("ทะเบียนรถ"),
                            TextFormField(
                              controller: _vehiclePlateController,
                              enabled: false,
                              decoration: _inputDecoration(
                                enabled: false,
                                suffixIcon: Icon(
                                  Icons.pin_outlined,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── ปุ่มควบคุมการทำงานด้านล่าง ────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: _isEditable
                            ? Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 52,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          setState(() {
                                            _isEditable = false;
                                            _selectedImage = null;
                                          });
                                          _loadRiderProfile();
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: _textMuted,
                                          side: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          "ยกเลิก",
                                          style: TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: SizedBox(
                                      height: 52,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          gradient: const LinearGradient(
                                            colors: [_primary, _primaryDark],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _primary.withOpacity(0.35),
                                              blurRadius: 14,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: _isLoadingAction
                                              ? null
                                              : _saveProfile,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                          ),
                                          child: _isLoadingAction
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : const Text(
                                                  "บันทึกข้อมูล",
                                                  style: TextStyle(
                                                    fontSize: 15.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: const LinearGradient(
                                      colors: [_primary, _primaryDark],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primary.withOpacity(0.35),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        setState(() => _isEditable = true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                    ),
                                    label: const Text(
                                      "แก้ไขข้อมูล",
                                      style: TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
