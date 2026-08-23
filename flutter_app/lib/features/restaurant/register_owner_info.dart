// features/restaurant/register_owner_info.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/features/restaurant/login_restaurant.dart';
import 'package:image_picker/image_picker.dart';
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
    this.restaurantImage,
    this.imagecardid,
  });

  @override
  State<RegisterOwnerInfo> createState() => _RegisterOwnerInfoState();
}

class _RegisterOwnerInfoState extends State<RegisterOwnerInfo> {
  static const Color _primary = Color(0xFF16A34A);
  static const Color _primaryDark = Color(0xFF0F7A38);
  static const Color _accent = Color(0xFFEA7C1E);
  static const Color _bg = Color(0xFFF5F6F8);
  static const Color _textDark = Color(0xFF1E1E24);
  static const Color _textMuted = Color(0xFF8A8D93);
  static const Color _danger = Color(0xFFE53935);

  RestaurantService restaurantService = RestaurantService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ImagePicker ownerImagePicker = ImagePicker();

  bool _isLoading = false;
  String? _ownerImageError;
  File? _selectedOwnerImage;

  String? _emailServerError;
  String? _phoneServerError;

  late final TextEditingController ownerFirstNameController;
  late final TextEditingController ownerLastnameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;

  final GlobalKey _firstNameKey = GlobalKey();
  final GlobalKey _lastNameKey = GlobalKey();
  final GlobalKey _emailKey = GlobalKey();
  final GlobalKey _phoneKey = GlobalKey();
  final GlobalKey _ownerImageKey = GlobalKey();

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

  Future<void> pickOwnerImage() async {
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
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library, color: _primary),
                ),
                title: const Text(
                  "เลือกจากแกลเลอรี่",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
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
              const SizedBox(height: 8),
            ],
          ),
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

  String? _validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) return "กรุณากรอกชื่อจริง";
    if (value.contains(' ')) return "ต้องไม่มีเว้นวรรคหรือช่องว่าง";
    if (!RegExp(r'^[a-zA-Z\u0E00-\u0E7F]+$').hasMatch(value)) {
      return "ต้องเป็นภาษาไทย หรือภาษาอังกฤษเท่านั้น";
    }
    if (value.length < 3 || value.length > 30) {
      return "ความยาวต้องระว่าง 3 - 30 ตัวอักษร";
    }
    return null;
  }

  String? _validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) return "กรุณากรอกนามสกุล";
    if (value.contains(' ')) return "ต้องไม่มีเว้นวรรคหรือช่องว่าง";
    if (!RegExp(r'^[a-zA-Z\u0E00-\u0E7F]+$').hasMatch(value)) {
      return "ต้องเป็นภาษาไทย หรือภาษาอังกฤษเท่านั้น";
    }
    if (value.length < 3 || value.length > 30) {
      return "ความยาวต้องระว่าง 3 - 30 ตัวอักษร";
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return "กรุณากรอกอีเมล";
    if (value.contains(' ')) return "ต้องไม่มีเว้นวรรคหรือช่องว่าง";
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return "รูปแบบอีเมลไม่ถูกต้อง";
    }
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
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return "กรุณากรอกเบอร์โทรศัพท์";
    if (value.contains(' ')) return "ต้องไม่มีเว้นวรรคหรือช่องว่าง";
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return "ต้องเป็นตัวเลข (0-9) เท่านั้น";
    }
    if (value.length < 10 || value.length > 15) {
      return "ความยาวต้องอยู่ระหว่าง 10 ถึง 15 หลัก";
    }
    if (!RegExp(r'^(06|08|09)').hasMatch(value)) {
      return "เบอร์โทรศัพท์ต้องขึ้นต้นด้วย 06, 08 หรือ 09";
    }
    return null;
  }

  void _scrollToFirstInvalidField() {
    final List<MapEntry<GlobalKey, bool>> checksInOrder = [
      MapEntry(
        _firstNameKey,
        _validateFirstName(ownerFirstNameController.text) != null,
      ),
      MapEntry(
        _lastNameKey,
        _validateLastName(ownerLastnameController.text) != null,
      ),
      MapEntry(
        _emailKey,
        _validateEmail(emailController.text) != null ||
            _emailServerError != null,
      ),
      MapEntry(
        _phoneKey,
        _validatePhone(phoneController.text) != null ||
            _phoneServerError != null,
      ),
      MapEntry(_ownerImageKey, _ownerImageError != null),
    ];

    for (final check in checksInOrder) {
      if (check.value) {
        final ctx = check.key.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            alignment: 0.15,
          );
        }
        break;
      }
    }
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
      return null;
    } catch (e) {
      // 🎯 สั่งให้ปริ้นท์ Error ออกมา จะได้รู้ว่า Supabase บ่นอะไร
      debugPrint("🚨 Upload Image Error ($type): $e");
      return null;
    }
  }

  Future<void> doRegister() async {
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
        final imagecardIdUrl = await uploadImage(
          _selectedOwnerImage,
          'ownerImage',
        );

        // 🎯 ดักจับ: ถ้าอัปโหลดรูปไม่ผ่าน ห้ามไปต่อเด็ดขาด!
        if (imagecardIdUrl == null) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("🚨 อัปโหลดรูปภาพไม่สำเร็จ กรุณาลองใหม่อีกครั้ง"),
                backgroundColor: _danger,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return; // หยุดการทำงานตรงนี้ ไม่ส่งไป Database
        }

        RestaurantModel restaurant = RestaurantModel(
          username: widget.username,
          password: widget.password,
          restaurantName: widget.restaurantName,
          restaurantImage:
              restaurantImageUrl, // อาจจะ null ได้ถ้าไม่ได้บังคับใส่รูปหน้าร้าน
          imagecardid: imagecardIdUrl, // มั่นใจได้ว่าตอนนี้ไม่ null แน่นอน
          openingHours: [],
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
            SnackBar(
              content: const Text("สมัครร้านค้าสำเร็จ รอการอนุมัติ"),
              backgroundColor: _primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginRestaurant()),
            (route) => false,
          );
        }
      } catch (e) {
        final buffer = StringBuffer();
        if (e is DioException) {
          final data = e.response?.data;
          if (data is String) {
            buffer.write(data);
          } else if (data != null) {
            buffer.write(data.toString());
          }
          if (e.message != null) buffer.write(' ${e.message}');
        }
        buffer.write(' ${e.toString()}');

        final combinedText = buffer.toString();
        final match = RegExp(
          r'Key\s*\(\s*(\w+)\s*\)\s*=',
          caseSensitive: false,
        ).firstMatch(combinedText);
        final duplicateField = match?.group(1)?.toLowerCase();

        if (duplicateField == 'email') {
          setState(() {
            _emailServerError = "อีเมลนี้ถูกใช้งานแล้ว";
          });
          formKey.currentState?.validate();
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToFirstInvalidField(),
          );
        } else if (duplicateField == 'phone') {
          setState(() {
            _phoneServerError = "เบอร์โทรศัพท์นี้ถูกใช้งานแล้ว";
          });
          formKey.currentState?.validate();
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToFirstInvalidField(),
          );
        } else if (duplicateField == 'username') {
          if (mounted) {
            showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text("ชื่อผู้ใช้นี้ถูกใช้งานแล้ว"),
                content: const Text(
                  "กรุณากดปุ่ม \"ย้อนกลับ\" เพื่อเปลี่ยนชื่อผู้ใช้ (Username) แล้วลองสมัครใหม่อีกครั้ง",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text(
                      "ตกลง",
                      style: TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                "เกิดข้อผิดพลาดในการสมัครร้านค้า กรุณาลองใหม่อีกครั้ง",
              ),
              backgroundColor: _danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToFirstInvalidField(),
      );
    }
  }

  InputDecoration _inputDecoration({String hint = "", Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 14),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: _textDark,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }

  Widget _fieldError(String? message) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 14, color: _danger),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _danger, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({required IconData icon, required String title}) {
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
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _textDark,
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    Widget dot({
      required bool active,
      required bool done,
      required IconData icon,
      required String label,
    }) {
      return Column(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (active || done) ? _primary : Colors.grey[300],
              shape: BoxShape.circle,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: _primary.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              done ? Icons.check_rounded : icon,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: (active || done) ? FontWeight.w700 : FontWeight.w500,
              color: (active || done) ? _textDark : _textMuted,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          dot(
            active: false,
            done: true,
            icon: Icons.storefront_rounded,
            label: "ข้อมูลร้านค้า",
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Container(height: 2, color: _primary.withOpacity(0.5)),
            ),
          ),
          dot(
            active: true,
            done: false,
            icon: Icons.person_outline_rounded,
            label: "ข้อมูลเจ้าของร้าน",
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> getFormData() {
      return {
        'ownerFirstName': ownerFirstNameController.text,
        'ownerLastName': ownerLastnameController.text,
        'email': emailController.text,
        'phone': phoneController.text,
        'ownerImage': _selectedOwnerImage,
      };
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        Navigator.pop(context, getFormData());
      },
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: _bg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: _textDark,
              ),
            ),
            onPressed: () => Navigator.pop(context, getFormData()),
          ),
          title: const Text(
            'สมัครร้านค้า',
            style: TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        body: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(color: Colors.white, child: _buildStepIndicator()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(
                        icon: Icons.person_outline_rounded,
                        title: "ข้อมูลเจ้าของร้านค้า หรือผู้ดูแลร้าน",
                      ),
                      Container(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            const Text(
                              "ชื่อจริง (First Name)",
                              style: TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              key: _firstNameKey,
                              controller: ownerFirstNameController,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: _validateFirstName,
                              decoration: _inputDecoration(
                                hint: "กรอกชื่อจริง",
                                suffixIcon: Icon(
                                  Icons.badge_outlined,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),
                            const Text(
                              "นามสกุล (Last Name)",
                              style: TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              key: _lastNameKey,
                              controller: ownerLastnameController,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: _validateLastName,
                              decoration: _inputDecoration(
                                hint: "กรอกนามสกุล",
                                suffixIcon: Icon(
                                  Icons.badge_outlined,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),
                            const Text(
                              "อีเมล (Email)",
                              style: TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              key: _emailKey,
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: (value) =>
                                  _validateEmail(value) ?? _emailServerError,
                              onChanged: (_) {
                                if (_emailServerError != null)
                                  setState(() => _emailServerError = null);
                              },
                              decoration: _inputDecoration(
                                hint: "ตัวอย่าง xxx@gmail.com",
                                suffixIcon: Icon(
                                  Icons.email_outlined,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),
                            const Text(
                              "เบอร์โทรศัพท์ (Phone)",
                              style: TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              key: _phoneKey,
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: (value) =>
                                  _validatePhone(value) ?? _phoneServerError,
                              onChanged: (_) {
                                if (_phoneServerError != null)
                                  setState(() => _phoneServerError = null);
                              },
                              decoration: _inputDecoration(
                                hint: "เช่น 08xxxxxxxx",
                                suffixIcon: Icon(
                                  Icons.phone_android_outlined,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),
                            const Text(
                              "รูปภาพบัตรประชาชน (CardID Image)",
                              style: TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),

                            _buildUploadBox(
                              "",
                              _selectedOwnerImage,
                              pickOwnerImage,
                              key: _ownerImageKey,
                            ),
                            _fieldError(_ownerImageError),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20), // เผื่อระยะก่อนสุดจอครับ
                      Center(
                        child: Text(
                          "ทีมงานจะตรวจสอบและอนุมัติร้านค้าของคุณหลังสมัครสำเร็จ",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, color: _textMuted),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // 🎯 ยกชุดปุ่มกดทั้งสองอันมายึดติดด้านล่างสุดเหมือนกันครับ
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, getFormData()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textMuted,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        "ย้อนกลับ",
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
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
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
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : doRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
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
                                  fontSize: 15.5,
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

  Widget _buildUploadBox(
    String label,
    File? selectedFile,
    VoidCallback onTap, {
    Key? key,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) _buildLabel(label),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: selectedFile != null
                  ? Colors.white
                  : const Color(0xFFF0F1F3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selectedFile != null
                    ? _primary.withOpacity(0.4)
                    : Colors.grey.shade300,
                width: 1.2,
              ),
            ),
            child: selectedFile != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(selectedFile, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 14,
                                color: _primary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "เปลี่ยนรูป",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_a_photo_outlined,
                          color: _primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "แตะเพื่ออัปโหลดรูปบัตรประชาชน",
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "รองรับ .jpg, .png ขนาดไม่เกิน 1MB",
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
