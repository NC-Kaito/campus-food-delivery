// features/restaurant/profile_restaurant.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/type_restaurant_model.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/features/restaurant/restaurant_navbar.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/features/restaurant/location_restaurant.dart';
import 'package:flutter_app/data/models/restaurant_opening_hour_model.dart';
import 'package:flutter_app/global_data.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import 'package:dio/dio.dart'
    as dio_package; // 🎯 นำเข้า dio สำหรับอัปโหลดไฟล์รูปภาพ

class ProfileRestaurant extends StatefulWidget {
  const ProfileRestaurant({super.key});

  @override
  State<ProfileRestaurant> createState() => _ProfileRestaurantState();
}

class _ProfileRestaurantState extends State<ProfileRestaurant> {
  // ── ธีมสีหลักของหน้า (ปรับให้ดูโปรและสม่ำเสมอทั้งหน้า) ──────────────────
  static const Color _primary = Color(0xFF16A34A); // เขียวหลัก
  static const Color _primaryDark = Color(0xFF0F7A38);
  static const Color _accent = Color(0xFFEA7C1E); // ส้มสำหรับหัวข้อ section
  static const Color _bg = Color(0xFFF5F6F8);
  static const Color _textDark = Color(0xFF1E1E24);
  static const Color _textMuted = Color(0xFF8A8D93);
  static const Color _danger = Color(0xFFE53935);

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final RestaurantService restaurantService = RestaurantService();
  RestaurantModel? restaurantModel;

  bool isLooding = true;
  bool isLoadingAction = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  String? restaurantimage;

  LatLng? _restaurantLatLng;

  bool _obscurePassword = true;
  // 🎯 Status is kept to send with payload when saving
  bool _isStoreOpen = true;
  bool _isEditable = false;

  // Controllers
  late final TextEditingController usernameController;
  late final TextEditingController passwordController;
  late final TextEditingController restaurantnameController;
  late final TextEditingController opentimeController;
  late final TextEditingController closetimeController;
  late final TextEditingController ownerfirstnameController;
  late final TextEditingController ownerlastnameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;

  List<TypeRestaurantModel> _typeList = [];
  String? _selectedType;
  int? _selectedTypeId;

  List<RestaurantOpeningHourModel> _openingHours = RestaurantDayOfWeek.values
      .map((day) {
        return RestaurantOpeningHourModel(
          dayOfWeek: day,
          opentime: const TimeOfDay(hour: 8, minute: 0),
          closetime: const TimeOfDay(hour: 18, minute: 0),
          closed: false,
        );
      })
      .toList();

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    passwordController = TextEditingController();
    restaurantnameController = TextEditingController();
    ownerfirstnameController = TextEditingController();
    ownerlastnameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    _initData();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    restaurantnameController.dispose();
    ownerfirstnameController.dispose();
    ownerlastnameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    setState(() => isLooding = true);
    await _fetchTypeRestaurants();
    await _fetchRestaurantProfile();
    setState(() => isLooding = false);
  }

  Future<void> _fetchTypeRestaurants() async {
    const String typePath = "/v1/typerestaurant";
    try {
      final response = await DioClient.dio.get(typePath);
      if (response.statusCode == 200) {
        final List data = response.data;
        setState(() {
          _typeList = data.map((e) => TypeRestaurantModel.fromJson(e)).toList();
        });
        print("typeList loaded: ${_typeList.length} items");
      }
    } catch (e) {
      print("typeList endpoint ($typePath) ไม่พบ — จะใช้ข้อมูลจาก profile แทน");
    }
  }

  Future<void> _fetchRestaurantProfile() async {
    try {
      final result = await restaurantService.getRestaurantByUsername(
        GlobalData.usernameRestaurant,
      );

      setState(() {
        restaurantModel = result;
        restaurantimage = result.restaurantImage;

        if (result.latitude != null && result.longitude != null) {
          _restaurantLatLng = LatLng(result.latitude!, result.longitude!);
        } else {
          _restaurantLatLng = null;
        }

        usernameController.text = result.username ?? "";
        passwordController.text = result.password ?? "";
        restaurantnameController.text = result.restaurantName ?? "";
        _isStoreOpen = result.statusOpen ?? true;
        ownerfirstnameController.text = result.ownerFirstName ?? "";
        ownerlastnameController.text = result.ownerLastName ?? "";
        emailController.text = result.email ?? "";
        phoneController.text = result.phone ?? "";

        _openingHours = RestaurantDayOfWeek.values.map((day) {
          final existing = result.openingHours?.firstWhere(
            (h) => h.dayOfWeek == day,
            orElse: () => RestaurantOpeningHourModel(
              dayOfWeek: day,
              opentime: const TimeOfDay(hour: 8, minute: 0),
              closetime: const TimeOfDay(hour: 18, minute: 0),
              closed: true,
            ),
          );
          return existing ??
              RestaurantOpeningHourModel(
                dayOfWeek: day,
                opentime: const TimeOfDay(hour: 8, minute: 0),
                closetime: const TimeOfDay(hour: 18, minute: 0),
                closed: true,
              );
        }).toList();

        final matchedById = _typeList
            .where((t) => t.id == result.typerestaurantId)
            .firstOrNull;

        final matchedByName = _typeList
            .where((t) => t.name == result.typerestaurantName)
            .firstOrNull;

        final matched = matchedById ?? matchedByName;

        if (matched != null) {
          _selectedType = matched.name;
          _selectedTypeId = matched.id;
        } else {
          _selectedType = result.typerestaurantName;
          _selectedTypeId = result.typerestaurantId;
        }
      });
    } catch (e) {
      print("Error fetching profile: $e");
    }
  }

  Future<void> _selectDayTime(
    BuildContext context,
    int index,
    bool isOpenTime,
  ) async {
    final hour = _openingHours[index];
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isOpenTime ? hour.opentime : hour.closetime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: const ColorScheme.light(primary: _primary)),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _openingHours[index] = hour.copyWith(
          opentime: isOpenTime ? picked : null,
          closetime: isOpenTime ? null : picked,
        );
      });
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

  Future<String?> _uploadImage(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      dio_package.FormData formData = dio_package.FormData.fromMap({
        "image": await dio_package.MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
        "type": "restaurant",
      });

      var response = await DioClient.dio.post(
        '/v1/restaurant/uploadImage',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['url'];
      }
      return null;
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

  Future<void> doUpdateRestaurant() async {
    if (formKey.currentState!.validate()) {
      setState(() => isLoadingAction = true);
      try {
        String? imageUrl;
        if (_selectedImage != null) {
          imageUrl = await _uploadImage(_selectedImage!);
        }

        final Map<String, dynamic> updatePayload = {
          "username": usernameController.text,
          "password": passwordController.text,
          "restaurantname": restaurantnameController.text,
          "statusopen": _isStoreOpen,
          "restaurantimage": imageUrl ?? restaurantModel?.restaurantImage,
          "imagecardid": restaurantModel?.imagecardid ?? "",
          "latitude": _restaurantLatLng?.latitude ?? restaurantModel?.latitude,
          "longitude":
              _restaurantLatLng?.longitude ?? restaurantModel?.longitude,
          "openingHours": _openingHours.map((e) => e.toJson()).toList(),
          "typeid": _selectedTypeId ?? restaurantModel?.typerestaurantId,
          "ownerfirstname": ownerfirstnameController.text,
          "ownerlastname": ownerlastnameController.text,
          "email": emailController.text,
          "phone": phoneController.text,
        };
        final response = await DioClient.dio.post(
          "/v1/restaurant/updateProfileRestaurant",
          data: updatePayload,
        );

        if (response.statusCode == 200 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('บันทึกข้อมูลเรียบร้อยแล้ว'),
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

          await _fetchRestaurantProfile();
        }
      } catch (e) {
        print("Update Error: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'),
              backgroundColor: _danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => isLoadingAction = false);
      }
    }
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;

    final String baseUrl = DioClient.dio.options.baseUrl;
    if (rawPath.startsWith('/')) {
      return "$baseUrl$rawPath";
    } else {
      return "$baseUrl/$rawPath";
    }
  }

  // ─── Widget Builders ────────────────────────────────────────────────────────

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

  Widget _buildDropdown() {
    final Set<String> nameSet = _typeList.map((t) => t.name).toSet();
    final List<String> displayItems = List.from(nameSet);
    if (_selectedType != null && !nameSet.contains(_selectedType)) {
      displayItems.insert(0, _selectedType!);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _isEditable ? Colors.white : const Color(0xFFF0F1F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isEditable ? Colors.grey.shade300 : Colors.grey.shade200,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          hint: Text("---เลือก---", style: TextStyle(color: Colors.grey[400])),
          style: const TextStyle(
            color: _textDark,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          onChanged: _isEditable
              ? (val) {
                  setState(() {
                    _selectedType = val;
                    final matched = _typeList
                        .where((t) => t.name == val)
                        .firstOrNull;
                    if (matched != null) _selectedTypeId = matched.id;
                  });
                }
              : null,
          items: displayItems
              .map((name) => DropdownMenuItem(value: name, child: Text(name)))
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String finalProfileUrl = _getFinalImageUrl(restaurantimage);

    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: const RestaurantNavbar(title: ""),
      body: isLooding
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : SafeArea(
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      children: [
                        // ── รูปภาพร้านค้า ──────────────────────────────────
                        Stack(
                          children: [
                            Container(
                              height: 210,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                                image: DecorationImage(
                                  image: _selectedImage != null
                                      ? FileImage(_selectedImage!)
                                            as ImageProvider
                                      : finalProfileUrl.isNotEmpty
                                      ? NetworkImage(
                                          Uri.encodeFull(finalProfileUrl),
                                        )
                                      : const AssetImage(
                                              'assets/images/default.png',
                                            )
                                            as ImageProvider,
                                  fit: BoxFit.cover,
                                  onError: (_, __) {},
                                ),
                              ),
                              foregroundDecoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.0),
                                    Colors.black.withOpacity(0.28),
                                  ],
                                  stops: const [0.6, 1.0],
                                ),
                              ),
                            ),
                            if (_isEditable)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(9),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.edit_outlined,
                                      color: _primary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 26),

                        // ══ Section 1: ข้อมูลร้านค้า ════════════════════════
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _buildSectionHeader(
                            icon: Icons.storefront_outlined,
                            title: "ข้อมูลร้านค้า",
                          ),
                        ),
                        _sectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("ชื่อผู้ใช้ (Username)"),
                              TextFormField(
                                controller: usernameController,
                                enabled: false,
                                decoration: _inputDecoration(enabled: false),
                              ),
                              _buildLabel("รหัสผ่าน (Password)"),
                              TextFormField(
                                controller: passwordController,
                                obscureText: _obscurePassword,
                                readOnly: true,
                                decoration: _inputDecoration(
                                  enabled: false,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                              ),
                              _buildLabel("ชื่อร้านค้า (Restaurant Name)"),
                              TextFormField(
                                controller: restaurantnameController,
                                enabled: _isEditable,
                                validator: _isEditable
                                    ? (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return "กรุณากรอกชื่อร้านค้า";
                                        }
                                        if (v.length < 8) {
                                          return "ความยาว 8 ตัวอักษรขึ้นไป";
                                        }
                                        return null;
                                      }
                                    : null,
                                decoration: _inputDecoration(
                                  enabled: _isEditable,
                                ),
                              ),
                              _buildLabel("ประเภทร้านค้า (Restaurant Type)"),
                              _buildDropdown(),
                              const SizedBox(height: 4),
                              _buildLabel("ปักหมุดที่อยู่ร้านค้า"),
                              GestureDetector(
                                onTap: _isEditable
                                    ? () async {
                                        final LatLng? pickedLocation =
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    LocationRestaurant(
                                                      initialLocation:
                                                          _restaurantLatLng,
                                                    ),
                                              ),
                                            );
                                        if (pickedLocation != null) {
                                          setState(
                                            () => _restaurantLatLng =
                                                pickedLocation,
                                          );
                                        }
                                      }
                                    : null,
                                child: Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1.4,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Stack(
                                      children: [
                                        GoogleMap(
                                          initialCameraPosition: CameraPosition(
                                            target:
                                                _restaurantLatLng ??
                                                const LatLng(18.8920, 99.0145),
                                            zoom: 15.5,
                                          ),
                                          zoomControlsEnabled: false,
                                          zoomGesturesEnabled: false,
                                          scrollGesturesEnabled: false,
                                          rotateGesturesEnabled: false,
                                          tiltGesturesEnabled: false,
                                          markers: _restaurantLatLng == null
                                              ? {}
                                              : {
                                                  Marker(
                                                    markerId: const MarkerId(
                                                      'store_pos',
                                                    ),
                                                    position:
                                                        _restaurantLatLng!,
                                                  ),
                                                },
                                        ),
                                        if (_isEditable)
                                          Positioned(
                                            right: 10,
                                            bottom: 10,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.12),
                                                    blurRadius: 6,
                                                  ),
                                                ],
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.edit_location_alt,
                                                    size: 15,
                                                    color: _primary,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    "แตะเพื่อปักหมุด",
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: _textDark,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildLabel("เวลาเปิด-ปิดร้าน (แยกตามวัน)"),
                              const SizedBox(height: 4),
                              Column(
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
                                      color: !_isEditable
                                          ? const Color(0xFFF0F1F3)
                                          : hour.closed
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
                                                        onPressed: _isEditable
                                                            ? () =>
                                                                  _selectDayTime(
                                                                    context,
                                                                    index,
                                                                    true,
                                                                  )
                                                            : null,
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
                                                        onPressed: _isEditable
                                                            ? () =>
                                                                  _selectDayTime(
                                                                    context,
                                                                    index,
                                                                    false,
                                                                  )
                                                            : null,
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
                                          onChanged: _isEditable
                                              ? (isOpen) {
                                                  setState(() {
                                                    _openingHours[index] = hour
                                                        .copyWith(
                                                          closed: !isOpen,
                                                        );
                                                  });
                                                }
                                              : null,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ══ Section 2: ข้อมูลเจ้าของร้าน ════════════════════
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _buildSectionHeader(
                            icon: Icons.person_outline_rounded,
                            title: "ข้อมูลเจ้าของร้านค้า หรือผู้ดูแลร้าน",
                          ),
                        ),
                        _sectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("ชื่อ (FirstName)"),
                              TextFormField(
                                controller: ownerfirstnameController,
                                enabled: _isEditable,
                                validator: _isEditable
                                    ? (v) {
                                        if (v == null || v.trim().isEmpty)
                                          return "กรุณากรอกชื่อจริง";
                                        if (v.contains(' '))
                                          return "ต้องไม่มีเว้นวรรค";
                                        if (!RegExp(
                                          r'^[a-zA-Z\u0E00-\u0E7F]+$',
                                        ).hasMatch(v)) {
                                          return "ต้องเป็นภาษาไทยหรืออังกฤษเท่านั้น";
                                        }
                                        if (v.length < 3 || v.length > 30)
                                          return "ความยาว 3-30 ตัวอักษร";
                                        return null;
                                      }
                                    : null,
                                decoration: _inputDecoration(
                                  enabled: _isEditable,
                                ),
                              ),
                              _buildLabel("นามสกุล (Lastname)"),
                              TextFormField(
                                controller: ownerlastnameController,
                                enabled: _isEditable,
                                validator: _isEditable
                                    ? (v) {
                                        if (v == null || v.trim().isEmpty)
                                          return "กรุณากรอกนามสกุล";
                                        if (v.contains(' '))
                                          return "ต้องไม่มีเว้นวรรค";
                                        if (!RegExp(
                                          r'^[a-zA-Z\u0E00-\u0E7F]+$',
                                        ).hasMatch(v)) {
                                          return "ต้องเป็นภาษาไทยหรืออังกฤษเท่านั้น";
                                        }
                                        if (v.length < 3 || v.length > 30)
                                          return "ความยาว 3-30 ตัวอักษร";
                                        return null;
                                      }
                                    : null,
                                decoration: _inputDecoration(
                                  enabled: _isEditable,
                                ),
                              ),
                              _buildLabel("อีเมล (Email)"),
                              TextFormField(
                                controller: emailController,
                                enabled: _isEditable,
                                keyboardType: TextInputType.emailAddress,
                                validator: _isEditable
                                    ? (v) {
                                        if (v == null || v.trim().isEmpty)
                                          return "กรุณากรอกอีเมล";
                                        if (v.contains(' '))
                                          return "ต้องไม่มีช่องว่าง";
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
                                controller: phoneController,
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

                        // ── ปุ่มควบคุม ────────────────────────────────────────
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
                                            _fetchRestaurantProfile();
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: _textMuted,
                                            side: BorderSide(
                                              color: Colors.grey.shade300,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
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
                                                color: _primary.withOpacity(
                                                  0.35,
                                                ),
                                                blurRadius: 14,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: isLoadingAction
                                                ? null
                                                : doUpdateRestaurant,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),
                                            ),
                                            child: isLoadingAction
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
                                                      fontWeight:
                                                          FontWeight.w700,
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
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
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
            ),
    );
  }
}
