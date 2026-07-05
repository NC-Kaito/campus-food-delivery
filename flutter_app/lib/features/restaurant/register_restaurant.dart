// features/restaurant/register_restaurant.dart
import 'package:flutter/cupertino.dart'; // 🎯 อิมพอร์ตเพิ่มเข้ามาสำหรับใช้ตัวเลือกช่องเลื่อนสากล
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
  String? _ownerFirstName;
  String? _ownerLastName;
  String? _ownerEmail;
  String? _ownerPhone;

  String? _locationError;
  String? _restaurantImageError;
  String? _typeError;
  String? _openDayError;
  bool _obscureText = true;

  final TypeRestaurantService typeRestaurantService = TypeRestaurantService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

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
  void _selectTimeScrollWheel(BuildContext context, bool isOpenTime) {
    Duration initialDuration = const Duration(hours: 8, minutes: 0);

    if (isOpenTime && openTimeController.text.isNotEmpty) {
      final parts = openTimeController.text.split(':');
      initialDuration = Duration(
        hours: int.parse(parts[0]),
        minutes: int.parse(parts[1]),
      );
    } else if (!isOpenTime && closeTimeController.text.isNotEmpty) {
      final parts = closeTimeController.text.split(':');
      initialDuration = Duration(
        hours: int.parse(parts[0]),
        minutes: int.parse(parts[1]),
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext context) {
        Duration tempDuration = initialDuration;
        return SafeArea(
          child: SizedBox(
            height: 380, // 🌟 ขยายความสูงกล่องรวมเพื่อรองรับวงล้อขนาดใหญ่
            child: Column(
              children: [
                // แถบเมนูกดยืนยันด้านบน (เพิ่มขนาดอักษรให้ใหญ่และหนาขึ้น)
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
                        child: const Text(
                          "ยกเลิก",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        isOpenTime ? "เลือกเวลาเปิดร้าน" : "เลือกเวลาปิดร้าน",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            String formattedTime =
                                "${tempDuration.inHours.toString().padLeft(2, '0')}:${(tempDuration.inMinutes % 60).toString().padLeft(2, '0')}";
                            if (isOpenTime) {
                              openTimeController.text = formattedTime;
                            } else {
                              closeTimeController.text = formattedTime;
                            }
                          });
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "ตกลง",
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1),

                // 🌟 ขยายขนาดตัวเลขและช่องเลื่อนดรัมให้ใหญ่สะใจ 1.3 เท่า
                Expanded(
                  child: Center(
                    child: Transform.scale(
                      scale: 1.3, // 🎯 สั่งขยายสเกลตรงนี้เลยครับ
                      child: CupertinoTimerPicker(
                        mode: CupertinoTimerPickerMode.hm,
                        initialTimerDuration: initialDuration,
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
                    _selectedImage = File(image.path);
                    _restaurantImageError = null;
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
                    _selectedImage = File(image.path);
                    _restaurantImageError = null;
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
            color: Color.fromARGB(255, 255, 111, 0),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
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
                  Text(
                    "ข้อมูลร้านค้า",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 10),
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
                    decoration: _inputDecoration(hint: "ตัวอย่าง rest1234"),
                  ),

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
                                "--- แแตะเพื่อเลือกตำแหน่งบนแผนที่ ---",
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

                  _buildUploadBox(
                    "รูปภาพร้านค้า (Restaurant Image)",
                    _selectedImage,
                    () => pickImage(),
                  ),
                  if (_restaurantImageError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        _restaurantImageError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),

                  const SizedBox(height: 15),

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
                              onTap: () =>
                                  _selectTimeScrollWheel(context, true),
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                  ? "กรุณาระบุเวลาเปิด"
                                  : null,
                              decoration: InputDecoration(
                                hintText: "00:00",
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
                              onTap: () =>
                                  _selectTimeScrollWheel(context, false),
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                  ? "กรุณาระบุเวลาปิด"
                                  : null,
                              decoration: InputDecoration(
                                hintText: "00:00",
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
                                ? const Color.fromARGB(255, 246, 127, 0)
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
                            _openDayError = _selectedDays.every((d) => !d)
                                ? "กรุณาเลือกวันเปิดร้านอย่างน้อย 1 วัน"
                                : null;
                          });

                          if (!isFormValid ||
                              _typeError != null ||
                              _locationError != null ||
                              _restaurantImageError != null ||
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
                          backgroundColor: const Color.fromARGB(
                            255,
                            0,
                            255,
                            51,
                          ),
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
            height: 200,
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
                : const Icon(
                    Icons.add_a_photo_outlined,
                    color: Colors.grey,
                    size: 40,
                  ),
          ),
        ),
      ],
    );
  }
}
