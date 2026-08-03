// features/restaurant/register_restaurant.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/type_restaurant_model.dart';
import 'package:flutter_app/data/services/restaurant/type_restaurant_service.dart';
import 'package:flutter_app/features/member/test_map.dart';
import 'package:flutter_app/features/restaurant/register_owner_info.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';

class RegisterRestaurant extends StatefulWidget {
  const RegisterRestaurant({super.key});

  @override
  State<RegisterRestaurant> createState() => _RegisterRestaurantState();
}

class _RegisterRestaurantState extends State<RegisterRestaurant> {
  static const Color _primary = Color(0xFF16A34A);
  static const Color _primaryDark = Color(0xFF0F7A38);
  static const Color _accent = Color(0xFFEA7C1E);
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

  final GlobalKey _typeFieldKey = GlobalKey();
  final GlobalKey _usernameKey = GlobalKey();
  final GlobalKey _passwordKey = GlobalKey();
  final GlobalKey _restaurantNameKey = GlobalKey();
  final GlobalKey _locationKey = GlobalKey();
  final GlobalKey _imageKey = GlobalKey();

  final TypeRestaurantService typeRestaurantService = TypeRestaurantService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late final TextEditingController usernameController;
  late final TextEditingController passwordController;
  late final TextEditingController restaurantNameController;
  double? latilude;
  double? longitude;

  final ImagePicker restaurantImage = ImagePicker();
  late final TextEditingController typeRestaurantController;

  List<TypeRestaurantModel> typeList = [];
  int? _selectedTypeId;
  String? _selectedType;
  String? _selectedLocation;
  File? _selectedImage;
  File? _selectedOwnerImage;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    passwordController = TextEditingController();
    restaurantNameController = TextEditingController();
    typeRestaurantController = TextEditingController();
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

  Future<void> fetchTypes() async {
    try {
      final types = await typeRestaurantService.getAllTypeRestaurant();
      setState(() {
        typeList = types;
      });
    } catch (e) {
      debugPrint("เกิดข้อผิดพลาด ไม่สามารถโหลดข้อมูลประเภทร้านค้าได้");
    }
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
    if (file.lengthSync() > 1024 * 1024) return "ขนาดเกิน 1MB";
    return null;
  }

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

  void _scrollToFirstInvalidField() {
    final List<MapEntry<GlobalKey, bool>> checksInOrder = [
      MapEntry(_typeFieldKey, _selectedTypeId == null),
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
      MapEntry(_locationKey, _selectedLocation == null),
      MapEntry(_imageKey, _restaurantImageError != null),
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
            decoration: const BoxDecoration(color: _bg, shape: BoxShape.circle),
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
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      icon: Icons.category_outlined,
                      title: "ประเภทของร้านค้า",
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
                          const Text(
                            "ประเภทร้านค้า (Restaurant Type)",
                            style: TextStyle(color: Colors.black, fontSize: 14),
                          ),
                          const SizedBox(height: 10),
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
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

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
                          const SizedBox(height: 5),
                          const Text(
                            "ชื่อผู้ใช้ (Username)",
                            style: TextStyle(color: Colors.black, fontSize: 14),
                          ),
                          const SizedBox(height: 10),
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

                          const SizedBox(height: 15),

                          const Text(
                            "รหัสผ่าน (Password)",
                            style: TextStyle(color: Colors.black, fontSize: 14),
                          ),
                          const SizedBox(height: 10),
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

                          const SizedBox(height: 15),

                          const Text(
                            "ชื่อร้านค้า (Restaurant Name)",
                            style: TextStyle(color: Colors.black, fontSize: 14),
                          ),
                          const SizedBox(height: 10),
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

                          const SizedBox(height: 15),

                          const Text(
                            "ที่ตั้งร้านค้า (Location)",
                            style: TextStyle(color: Colors.black, fontSize: 14),
                          ),
                          const SizedBox(height: 5),

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
                          const SizedBox(height: 15),

                          const Text(
                            "รูปภาพร้านค้า (Restaurant Image)",
                            style: TextStyle(color: Colors.black, fontSize: 14),
                          ),
                          const SizedBox(height: 10),

                          _buildUploadBox(
                            "",
                            _selectedImage,
                            () => pickImage(),
                            key: _imageKey,
                          ),
                          _fieldError(_restaurantImageError),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // 🎯 ส่วนปุ่มล่างสุด สไตล์เดียวกับหน้า Home เป๊ะๆ เลยครับ
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
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
                onPressed: () async {
                  final isFormValid = formKey.currentState!.validate();
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
                  });

                  if (!isFormValid ||
                      _typeError != null ||
                      _locationError != null ||
                      _restaurantImageError != null) {
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
                        restaurantImage: _selectedImage,
                        imagecardid: _selectedOwnerImage,
                      ),
                    ),
                  );

                  if (result != null && result is Map<String, dynamic>) {
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
                    borderRadius: BorderRadius.circular(18),
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
