// features/restaurant/register_restaurant.dart
import 'package:flutter/cupertino.dart'; // 🎯 อิมพอร์ตเพิ่มเข้ามาสำหรับใช้ตัวเลือกช่องเลื่อนสากล
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/type_restaurant_model.dart';
import 'package:flutter_app/data/services/restaurant/type_restaurant_service.dart';
import 'package:flutter_app/features/member/test_map.dart';
import 'package:flutter_app/features/restaurant/register_owner_info.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_app/data/models/restaurant_opening_hour_model.dart';

import 'dart:io';

class RegisterRestaurant extends StatefulWidget {
  const RegisterRestaurant({super.key});

  @override
  State<RegisterRestaurant> createState() => _RegisterRestaurantState();
}

class _RegisterRestaurantState extends State<RegisterRestaurant> {
  // ── ธีมสีหลักของหน้า (ใช้ชุดเดียวกับหน้าโปรไฟล์ร้านค้าเพื่อความสม่ำเสมอ) ──
  static const Color _primary = Color(0xFF16A34A); // เขียวหลัก (ปุ่มหลัก/โฟกัส)
  static const Color _primaryDark = Color(0xFF0F7A38);
  static const Color _accent = Color(0xFFEA7C1E); // ส้มสำหรับหัวข้อ/แบรนด์
  static const Color _bg = Color(0xFFF5F6F8);
  static const Color _textDark = Color(0xFF1E1E24);
  static const Color _textMuted = Color(0xFF8A8D93);
  static const Color _danger = Color(0xFFE53935);

  String? _ownerFirstName;
  String? _ownerLastName;
  String? _ownerEmail;
  String? _ownerPhone;

  String? _locationError;
  String? _restaurantImageError;
  String? _typeError;
  bool _obscureText = true;

  late List<RestaurantOpeningHourModel> _openingHours;

  String? _openingHoursError;

  // ── GlobalKey ของแต่ละช่อง ใช้สำหรับเลื่อนจอไปหาช่องแรกที่ยังไม่ได้กรอก ──
  final GlobalKey _usernameKey = GlobalKey();
  final GlobalKey _passwordKey = GlobalKey();
  final GlobalKey _restaurantNameKey = GlobalKey();
  final GlobalKey _typeFieldKey = GlobalKey();
  final GlobalKey _locationKey = GlobalKey();
  final GlobalKey _imageKey = GlobalKey();

  final GlobalKey _openingHoursKey = GlobalKey();

  final TypeRestaurantService typeRestaurantService = TypeRestaurantService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late final TextEditingController usernameController;
  late final TextEditingController passwordController;
  late final TextEditingController restaurantNameController;
  double? latilude;
  double? longitude;

  final ImagePicker restaurantImage = ImagePicker();

  late final TextEditingController typeRestaurantController;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    passwordController = TextEditingController();
    restaurantNameController = TextEditingController();
    typeRestaurantController = TextEditingController();

    _openingHours = RestaurantDayOfWeek.values.map((day) {
      return RestaurantOpeningHourModel(
        dayOfWeek: day,
        opentime: const TimeOfDay(hour: 8, minute: 0),
        closetime: const TimeOfDay(hour: 18, minute: 0),
        closed: false,
      );
    }).toList();

    fetchTypes();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    restaurantNameController.dispose();
    typeRestaurantController.dispose();
    super.dispose();
  }

  List<TypeRestaurantModel> typeList = [];
  int? _selectedTypeId;
  String? _selectedType;
  String? _selectedLocation;
  File? _selectedImage;
  File?
  _selectedOwnerImage; // 🎯 ประกาศไว้เพื่อสแตนด์บายรับค่าขากลับป้องกันตัวแดง Undefined

  Future<void> fetchTypes() async {
    try {
      final types = await typeRestaurantService.getAllTypeRestaurant();
      setState(() {
        typeList = types;
      });
    } catch (e) {
      print("เกิดข้อผิดพลาด ไม่สามารถโหลดข้อมูลประเภทร้านค้าได้");
    }
  }

  // 🎯 ฟังก์ชันเลือกเวลาแบบดรัมสไลด์เวอร์ชันอัปเกรดขยายขนาดใหญ่เต็มตา (1.3x)
  void _selectTimeScrollWheel(
    BuildContext context,
    int dayIndex,
    bool isOpenTime,
  ) {
    final current = _openingHours[dayIndex];
    final initialTime = isOpenTime ? current.opentime : current.closetime;
    Duration tempDuration = Duration(
      hours: initialTime.hour,
      minutes: initialTime.minute,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: SizedBox(
            height: 380,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "ยกเลิก",
                          style: TextStyle(
                            color: _textMuted,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        isOpenTime
                            ? "เลือกเวลาเปิด (${_openingHours[dayIndex].dayOfWeek.labelTh})"
                            : "เลือกเวลาปิด (${_openingHours[dayIndex].dayOfWeek.labelTh})",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            final newTime = TimeOfDay(
                              hour: tempDuration.inHours,
                              minute: tempDuration.inMinutes % 60,
                            );
                            _openingHours[dayIndex] = _openingHours[dayIndex]
                                .copyWith(
                                  opentime: isOpenTime ? newTime : null,
                                  closetime: isOpenTime ? null : newTime,
                                );
                            _openingHoursError = null;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "ตกลง",
                          style: TextStyle(
                            color: _primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1),
                Expanded(
                  child: Center(
                    child: Transform.scale(
                      scale: 1.3,
                      child: CupertinoTimerPicker(
                        mode: CupertinoTimerPickerMode.hm,
                        initialTimerDuration: tempDuration,
                        onTimerDurationChanged: (Duration newDuration) {
                          tempDuration = newDuration;
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> pickImage() async {
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
                  final XFile? image = await restaurantImage.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    setState(() {
                      _selectedImage = File(image.path);
                      _restaurantImageError = null;
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
                  final XFile? image = await restaurantImage.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    setState(() {
                      _selectedImage = File(image.path);
                      _restaurantImageError = null;
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

  // ── ดึงตรรกะ validate ของแต่ละช่องข้อความออกมาเป็นฟังก์ชันแยก ──────────
  // เพื่อใช้ทั้งใน TextFormField.validator และใช้ตรวจซ้ำตอนหาช่องแรกที่ error
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) return "กรุณากรอกชื่อผู้ใช้";
    if (value.contains(' ')) return "ต้องไม่มีช่องว่าง";
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return "ใช้ได้เฉพาะ a-z, A-Z, 0-9 และ _";
    }
    if (value.length < 8 || value.length > 20) return "ความยาว 8-20 ตัวอักษร";
    return null;
  }

  String? _validatePasswordField(String? value) {
    if (value == null || value.isEmpty) return "กรุณากรอกรหัสผ่าน";
    if (value.contains(' ')) return "ต้องไม่มีช่องว่าง";
    if (!RegExp(r'^[a-zA-Z0-9!#_.]+$').hasMatch(value)) {
      return "ใช้ได้เฉพาะ a-z, A-Z, 0-9 และ ! # _ .";
    }
    if (value.length < 8 || value.length > 16) return "ความยาว 8-16 ตัวอักษร";
    return null;
  }

  String? _validateRestaurantName(String? value) {
    if (value == null || value.isEmpty) return "กรุณากรอกชื่อร้านค้า";
    if (!RegExp(r'^[a-zA-Z\u0E00-\u0E7F0-9 ]+$').hasMatch(value)) {
      return "ต้องเป็นภาษาไทย อังกฤษ หรือตัวเลขเท่านั้น";
    }
    if (value.length < 8 || value.length > 50) return "ความยาว 8-50 ตัวอักษร";
    return null;
  }

  // ── เลื่อนจอไปหาช่องแรกสุดที่ยังไม่ผ่าน/ยังไม่ได้กรอก ตามลำดับบนจอ ──────
  void _scrollToFirstInvalidField() {
    final List<MapEntry<GlobalKey, bool>> checksInOrder = [
      MapEntry(
        _usernameKey,
        _validateUsername(usernameController.text) != null,
      ),
      MapEntry(
        _passwordKey,
        _validatePasswordField(passwordController.text) != null,
      ),
      MapEntry(
        _restaurantNameKey,
        _validateRestaurantName(restaurantNameController.text) != null,
      ),
      MapEntry(_typeFieldKey, _selectedTypeId == null),
      MapEntry(_locationKey, _selectedLocation == null),
      MapEntry(_imageKey, _restaurantImageError != null),
      MapEntry(_openingHoursKey, _openingHours.every((h) => h.closed)),
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

  // ── ป้ายชื่อฟิลด์ พร้อมดอกจันสีแดงบอกว่าจำเป็นต้องกรอก ──────────────────
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
          children: const [
            TextSpan(
              text: ' *',
              style: TextStyle(color: _danger),
            ),
          ],
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

  // ── ตัวบอกขั้นตอน 1/2 ด้านบนสุดของฟอร์ม ─────────────────────────────
  Widget _buildStepIndicator() {
    Widget dot(bool active, String label) {
      return Column(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? _primary : Colors.grey[300],
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
              active ? Icons.storefront_rounded : Icons.person_outline_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? _textDark : _textMuted,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          dot(true, "ข้อมูลร้านค้า"),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Container(height: 2, color: Colors.grey[300]),
            ),
          ),
          dot(false, "ข้อมูลเจ้าของร้าน"),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: _bg, shape: BoxShape.circle),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: _textDark,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'สมัครร้านค้า',
          style: TextStyle(
            color: Color.fromARGB(255, 255, 157, 0),
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
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      icon: Icons.storefront_outlined,
                      title: "ข้อมูลร้านค้า",
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
                          _buildLabel("ชื่อผู้ใช้ (Username)"),
                          TextFormField(
                            key: _usernameKey,
                            controller: usernameController,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: _validateUsername,
                            decoration: _inputDecoration(
                              hint: "ตัวอย่าง rest1234",
                              suffixIcon: Icon(
                                Icons.person_outline,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),

                          _buildLabel("รหัสผ่าน (Password)"),
                          TextFormField(
                            key: _passwordKey,
                            controller: passwordController,
                            obscureText: _obscureText,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: _validatePasswordField,
                            decoration: _inputDecoration(
                              hint: "ตัวอย่าง pas012",
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey[400],
                                ),
                                onPressed: () => setState(
                                  () => _obscureText = !_obscureText,
                                ),
                              ),
                            ),
                          ),

                          _buildLabel("ชื่อร้านค้า (Restaurant Name)"),
                          TextFormField(
                            key: _restaurantNameKey,
                            controller: restaurantNameController,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: _validateRestaurantName,
                            decoration: _inputDecoration(
                              hint: "เช่น ร้านอาหารทะเลบ้านสวน",
                              suffixIcon: Icon(
                                Icons.storefront_outlined,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),

                          _buildLabel("ประเภทร้านค้า (Restaurant Type)"),
                          Container(
                            key: _typeFieldKey,
                            child: _buildDropdown(
                              typeList.map((e) => e.name).toList(),
                              _selectedType,
                              (val) {
                                setState(() {
                                  _selectedType = val;
                                  _selectedTypeId = typeList
                                      .firstWhere((e) => e.name == val)
                                      .id;
                                  _typeError = null;
                                });
                              },
                            ),
                          ),
                          _fieldError(_typeError),

                          _buildLabel("ที่ตั้งร้านค้า (Location)"),
                          InkWell(
                            key: _locationKey,
                            borderRadius: BorderRadius.circular(14),
                            onTap: () async {
                              final LatLng? pickedLocation =
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const TestMap(),
                                    ),
                                  );

                              if (pickedLocation != null) {
                                setState(() {
                                  _selectedLocation =
                                      "${pickedLocation.latitude}, ${pickedLocation.longitude}";
                                  latilude = pickedLocation.latitude;
                                  longitude = pickedLocation.longitude;
                                  _locationError = null;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedLocation == null
                                    ? const Color(0xFFF0F1F3)
                                    : _primary.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _selectedLocation == null
                                      ? Colors.grey.shade300
                                      : _primary.withOpacity(0.4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: _selectedLocation == null
                                          ? Colors.grey.shade200
                                          : _primary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.location_on_rounded,
                                      size: 18,
                                      color: _selectedLocation == null
                                          ? Colors.grey[500]
                                          : _primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedLocation ??
                                          "แตะเพื่อเลือกตำแหน่งร้านบนแผนที่",
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: _selectedLocation == null
                                            ? Colors.grey[500]
                                            : _textDark,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.grey[400],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _fieldError(_locationError),

                          const SizedBox(height: 6),

                          _buildUploadBox(
                            "รูปภาพร้านค้า (Restaurant Image)",
                            _selectedImage,
                            () => pickImage(),
                            key: _imageKey,
                          ),
                          _fieldError(_restaurantImageError),

                          const SizedBox(height: 6),

                          _buildLabel("เวลาเปิด-ปิดร้าน (แยกตามวัน)"),
                          const SizedBox(height: 4),
                          Container(
                            key: _openingHoursKey,
                            child: Column(
                              children: List.generate(_openingHours.length, (
                                index,
                              ) {
                                final hour = _openingHours[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: hour.closed
                                        ? Colors.grey.shade100
                                        : _primary.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: hour.closed
                                          ? Colors.grey.shade300
                                          : _primary.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 56,
                                        child: Text(
                                          hour.dayOfWeek.labelTh,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: _textDark,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: hour.closed
                                            ? Text(
                                                "ปิดวันนี้",
                                                style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                  fontSize: 13,
                                                ),
                                              )
                                            : Row(
                                                children: [
                                                  Expanded(
                                                    child: OutlinedButton(
                                                      onPressed: () =>
                                                          _selectTimeScrollWheel(
                                                            context,
                                                            index,
                                                            true,
                                                          ),
                                                      style: OutlinedButton.styleFrom(
                                                        side: BorderSide(
                                                          color: Colors
                                                              .grey
                                                              .shade300,
                                                        ),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 8,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        '${hour.opentime.hour.toString().padLeft(2, '0')}:${hour.opentime.minute.toString().padLeft(2, '0')}',
                                                      ),
                                                    ),
                                                  ),
                                                  const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                        ),
                                                    child: Text('-'),
                                                  ),
                                                  Expanded(
                                                    child: OutlinedButton(
                                                      onPressed: () =>
                                                          _selectTimeScrollWheel(
                                                            context,
                                                            index,
                                                            false,
                                                          ),
                                                      style: OutlinedButton.styleFrom(
                                                        side: BorderSide(
                                                          color: Colors
                                                              .grey
                                                              .shade300,
                                                        ),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 8,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        '${hour.closetime.hour.toString().padLeft(2, '0')}:${hour.closetime.minute.toString().padLeft(2, '0')}',
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                      const SizedBox(width: 8),
                                      Switch(
                                        value: !hour.closed,
                                        activeColor: _primary,
                                        onChanged: (isOpen) {
                                          setState(() {
                                            _openingHours[index] = hour
                                                .copyWith(closed: !isOpen);
                                            _openingHoursError = null;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                          _fieldError(_openingHoursError),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    SizedBox(
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
                        child: ElevatedButton(
                          onPressed: () async {
                            final isFormValid = formKey.currentState!
                                .validate();

                            setState(() {
                              _typeError = _selectedTypeId == null
                                  ? "กรุณาเลือกประเภทร้านค้า"
                                  : null;
                              _locationError = _selectedLocation == null
                                  ? "กรุณาเลือกที่ตั้งร้านค้า"
                                  : null;
                              _restaurantImageError = _validateImage(
                                _selectedImage,
                                "รูปร้านค้า",
                              );
                              _openingHoursError =
                                  _openingHours.every((h) => h.closed)
                                  ? "กรุณาเปิดร้านอย่างน้อย 1 วัน"
                                  : null;
                            });

                            if (!isFormValid ||
                                _typeError != null ||
                                _locationError != null ||
                                _restaurantImageError != null ||
                                _openingHoursError != null) {
                              // รอให้ error ใต้ช่องขึ้นแสดงก่อน 1 เฟรม แล้วค่อยเลื่อนจอ
                              // ไปหาช่องแรกสุดที่ยังไม่ได้กรอก/ยังไม่ถูกต้อง
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => _scrollToFirstInvalidField(),
                              );
                              return;
                            }

                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterOwnerInfo(
                                  initialFirstName: _ownerFirstName,
                                  initialLastName: _ownerLastName,
                                  initialEmail: _ownerEmail,
                                  initialPhone: _ownerPhone,
                                  username: usernameController.text,
                                  password: passwordController.text,
                                  restaurantName: restaurantNameController.text,
                                  typeId: _selectedTypeId!,
                                  latitude: latilude!,
                                  longitude: longitude!,
                                  openingHours: _openingHours, // ✅ แก้ตรงนี้

                                  restaurantImage: _selectedImage,
                                  imagecardid:
                                      _selectedOwnerImage, // ✅ ส่งตัวแปรที่ประกาศรองรับไว้สมบูรณ์แล้ว
                                ),
                              ),
                            );

                            if (result != null) {
                              setState(() {
                                _ownerFirstName = result['ownerFirstName'];
                                _ownerLastName = result['ownerLastName'];
                                _ownerEmail = result['email'];
                                _ownerPhone = result['phone'];
                                _selectedOwnerImage = result['ownerImage'];
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "ถัดไป",
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        "ขั้นตอนถัดไปคือกรอกข้อมูลเจ้าของร้านค้า",
                        style: TextStyle(fontSize: 12.5, color: _textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    List<String> items,
    String? value,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          hint: Text("---เลือก---", style: TextStyle(color: Colors.grey[400])),
          style: const TextStyle(
            color: _textDark,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
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
        _buildLabel(label),
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
                        "แตะเพื่ออัปโหลดรูปภาพร้านค้า",
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
