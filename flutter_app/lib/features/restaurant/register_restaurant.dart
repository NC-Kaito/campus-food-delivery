import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/type_restaurant_model.dart';
import 'package:flutter_app/data/services/restaurant/type_restaurant_service.dart';
import 'package:flutter_app/features/member/test_map.dart';
import 'package:flutter_app/features/restaurant/agrees_restaurant.dart';
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
  String? _ownerFirstName;
  String? _ownerLastName;
  String? _ownerEmail;
  String? _ownerPhone;

  String? _locationError;
  String? _restaurantImageError;
  String? _leaseImageError;
  String? _typeError;
  String? _openDayError;
  bool _obscureText = true;

  final TypeRestaurantService typeRestaurantService = TypeRestaurantService();
  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>(); // <--- ตัวนี้จะทำงานได้แล้ว

  late final TextEditingController usernameController;
  late final TextEditingController passwordController;
  late final TextEditingController restaurantNameController;
  double? latilude;
  double? longitude;

  late final TextEditingController openTimeController;
  late final TextEditingController closeTimeController;
  final ImagePicker restaurantImage = ImagePicker();

  late final TextEditingController typeRestaurantController;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    passwordController = TextEditingController();
    restaurantNameController = TextEditingController();
    openTimeController = TextEditingController();
    closeTimeController = TextEditingController();
    typeRestaurantController = TextEditingController();

    fetchTypes();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    restaurantNameController.dispose();
    openTimeController.dispose();
    closeTimeController.dispose();
    typeRestaurantController.dispose();
    super.dispose();
  }

  final List<String> _days = ['อา.', 'จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.'];
  final List<bool> _selectedDays = List.generate(7, (index) => false);

  List<TypeRestaurantModel> typeList = [];
  int? _selectedTypeId;
  String? _selectedType;
  String? _selectedLocation;
  File? _selectedImage;
  File? _selectedLeaseImage;

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

  Future<void> _selectTime(BuildContext context, bool isOpenTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.green),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        String formattedTime =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00";

        if (isOpenTime) {
          openTimeController.text = formattedTime;
        } else {
          closeTimeController.text = formattedTime;
        }
      });
    }
  }

  Future<void> pickImage(bool isRestaurantImage) async {
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
                final XFile? image = await restaurantImage.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (image != null) {
                  setState(() {
                    if (isRestaurantImage) {
                      _selectedImage = File(image.path);
                      _restaurantImageError = null;
                    } else {
                      _selectedLeaseImage = File(image.path);
                      _leaseImageError = null;
                    }
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text("เลือกจากแกลเลอรี่"),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await restaurantImage.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                if (image != null) {
                  setState(() {
                    if (isRestaurantImage) {
                      _selectedImage = File(image.path);
                      _restaurantImageError = null;
                    } else {
                      _selectedLeaseImage = File(image.path);
                      _leaseImageError = null;
                    }
                  });
                }
              },
            ),
          ],
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

  InputDecoration _inputDecoration({String hint = "", Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.green, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'สมัครร้านค้า',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      // ✅ แก้ไขจุดที่ 1: นำ Form ครอบ SingleChildScrollView เอาไว้ตรวจสอบค่าความถูกต้องภายในทั้งหมด
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ข้อมูลร้านค้า',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  // ✅ Username
                  _buildLabel("ชื่อผู้ใช้ (Username)"),
                  TextFormField(
                    controller: usernameController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "กรุณากรอกชื่อผู้ใช้";
                      if (value.contains(' ')) return "ต้องไม่มีช่องว่าง";
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                        return "ใช้ได้เฉพาะ a-z, A-Z, 0-9 และ _";
                      }
                      if (value.length < 8 || value.length > 20)
                        return "ความยาว 8-20 ตัวอักษร";
                      return null;
                    },
                    decoration: _inputDecoration(hint: ""),
                  ),

                  // ✅ Password
                  _buildLabel("รหัสผ่าน (Password)"),
                  TextFormField(
                    controller: passwordController,
                    obscureText: _obscureText,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "กรุณากรอกรหัสผ่าน";
                      if (value.contains(' ')) return "ต้องไม่มีช่องว่าง";
                      if (!RegExp(r'^[a-zA-Z0-9!#_.]+$').hasMatch(value)) {
                        return "ใช้ได้เฉพาะ a-z, A-Z, 0-9 และ ! # _ .";
                      }
                      if (value.length < 8 || value.length > 16)
                        return "ความยาว 8-16 ตัวอักษร";
                      return null;
                    },
                    decoration: _inputDecoration(
                      hint: "ตัวอย่าง pas012",
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey[400],
                        ),
                        onPressed: () =>
                            setState(() => _obscureText = !_obscureText),
                      ),
                    ),
                  ),

                  // ✅ Restaurant Name
                  _buildLabel("ชื่อร้านค้า (Restaurant Name)"),
                  TextFormField(
                    controller: restaurantNameController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "กรุณากรอกชื่อร้านค้า";
                      if (!RegExp(
                        r'^[a-zA-Z\u0E00-\u0E7F0-9 ]+$',
                      ).hasMatch(value)) {
                        return "ต้องเป็นภาษาไทย อังกฤษ หรือตัวเลขเท่านั้น";
                      }
                      if (value.length < 8 || value.length > 50)
                        return "ความยาว 8-50 ตัวอักษร";
                      return null;
                    },
                    decoration: _inputDecoration(hint: ""),
                  ),

                  // ✅ Restaurant Type
                  _buildLabel("ประเภทร้านค้า (Restaurant Type)"),
                  _buildDropdown(
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
                  if (_typeError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        _typeError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),

                  // ✅ Location
                  _buildLabel("ที่ตั้งร้านค้า (location)"),
                  InkWell(
                    onTap: () async {
                      final LatLng? pickedLocation = await Navigator.push(
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
                        horizontal: 15,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedLocation ??
                                "--- แตะเพื่อเลือกตำแหน่งบนแผนที่ ---",
                            style: TextStyle(
                              color: _selectedLocation == null
                                  ? Colors.grey[400]
                                  : Colors.black,
                            ),
                          ),
                          const Icon(Icons.map_outlined, color: Colors.green),
                        ],
                      ),
                    ),
                  ),
                  if (_locationError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        _locationError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),

                  const SizedBox(height: 15),

                  // ✅ แก้ไขจุดที่ 2: จัดระเบียบการจัดวางกล่องรูปภาพและ Error ใหม่ไม่ให้ทับซ้อนกันใน Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildUploadBox(
                              "รูปภาพร้านค้า (Restaurant Image)",
                              _selectedImage,
                              () => pickImage(true),
                            ),
                            if (_restaurantImageError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, left: 4),
                                child: Text(
                                  _restaurantImageError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildUploadBox(
                              "รูปสัญญาเช่า (lease_agreement)",
                              _selectedLeaseImage,
                              () => pickImage(false),
                            ),
                            if (_leaseImageError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, left: 4),
                                child: Text(
                                  _leaseImageError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // ✅ เวลาเปิด-ปิด
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("เวลาเปิดร้าน"),
                            TextFormField(
                              controller: openTimeController,
                              readOnly: true,
                              onTap: () => _selectTime(context, true),
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                  ? "กรุณาระบุเวลาเปิด"
                                  : null,
                              decoration: InputDecoration(
                                hintText: "00:00:00",
                                prefixIcon: const Icon(Icons.access_time),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("เวลาปิดร้าน"),
                            TextFormField(
                              controller: closeTimeController,
                              readOnly: true,
                              onTap: () => _selectTime(context, false),
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                  ? "กรุณาระบุเวลาปิด"
                                  : null,
                              decoration: InputDecoration(
                                hintText: "00:00:00",
                                prefixIcon: const Icon(
                                  Icons.history_toggle_off,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ✅ วันที่เปิดร้าน
                  _buildLabel("วันที่เปิดร้าน (Open Date)"),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDays[index] = !_selectedDays[index];
                            _openDayError = null;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _selectedDays[index]
                                ? Colors.greenAccent[400]
                                : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Center(
                            child: Text(
                              _days[index],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _selectedDays[index]
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_openDayError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4),
                      child: Text(
                        _openDayError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),

                  const SizedBox(height: 30),

                  // ✅ ปุ่มถัดไป
                  Center(
                    child: SizedBox(
                      width: double.infinity,
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
                            _leaseImageError = _validateImage(
                              _selectedLeaseImage,
                              "รูปสัญญาเช่า",
                            );
                            _openDayError = _selectedDays.every((d) => !d)
                                ? "กรุณาเลือกวันเปิดร้านอย่างน้อย 1 วัน"
                                : null;
                          });

                          if (!isFormValid ||
                              _typeError != null ||
                              _locationError != null ||
                              _restaurantImageError != null ||
                              _leaseImageError != null ||
                              _openDayError != null) {
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
                                openTime: openTimeController.text,
                                closeTime: closeTimeController.text,
                                selectedDays: _selectedDays,
                                restaurantImage: _selectedImage,
                                leaseImage: _selectedLeaseImage,
                              ),
                            ),
                          );

                          if (result != null) {
                            setState(() {
                              _ownerFirstName = result['ownerFirstName'];
                              _ownerLastName = result['ownerLastName'];
                              _ownerEmail = result['email'];
                              _ownerPhone = result['phone'];
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent[400],
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          "ถัดไป",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

  // --- Widget Builders ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 10),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          children: const [
            TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: const Text("---เลือก---"),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildUploadBox(String label, File? selectedFile, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: selectedFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(selectedFile, fit: BoxFit.cover),
                  )
                : const Icon(Icons.add, color: Colors.grey, size: 40),
          ),
        ),
      ],
    );
  }
}
