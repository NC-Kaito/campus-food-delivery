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
  // เพิ่มตัวแปรพวกนี้
  String? _ownerFirstName;
  String? _ownerLastName;
  String? _ownerEmail;
  String? _ownerPhone;

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

  // สร้าง List สำหรับเก็บวันที่เลือก (จ.-อา.)
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
            colorScheme: const ColorScheme.light(
              primary: Colors.green, // สีหลักของ MJU
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // แปลง TimeOfDay เป็น String Format "HH:mm:ss"
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
                    } else {
                      _selectedLeaseImage = File(image.path);
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
                    } else {
                      _selectedLeaseImage = File(image.path);
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
      body: SingleChildScrollView(
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

                _buildLabel("ชื่อผู้ใช้ (Username)"),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                _buildLabel("รหัสผ่าน (Password)"),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "ตัวอย่าง pas012",
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      border: InputBorder.none,
                      suffixIcon: Icon(
                        Icons.visibility_off_outlined,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),

                _buildLabel("ชื่อร้านค้า (Restaurant Name)"),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: TextField(
                    controller: restaurantNameController,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                _buildLabel("ประเภทร้านค้า (Restaurant Type)"),
                _buildDropdown(
                  // ✅ ดึงเฉพาะรายชื่อ (String) จาก Object ใน typeList มาสร้างเป็นลิสต์ใหม่
                  typeList.map((e) => e.name).toList(),
                  _selectedType,
                  (val) {
                    setState(() {
                      _selectedType = val;

                      // ✅ ถ้าต้องการหาค่า ID ของประเภทที่เลือก เพื่อเอาไว้ส่งไป API
                      _selectedTypeId = typeList
                          .firstWhere((e) => e.name == val)
                          .id;
                    });
                  },
                ),

                // ในหน้า RegisterRestaurant ส่วนที่เคยเป็น TextField ที่ตั้งร้าน
                _buildLabel("ที่ตั้งร้านค้า (location)"),
                InkWell(
                  onTap: () async {
                    // 1. เปิดหน้าแผนที่ และรอรับค่าพิกัดที่ส่งกลับมา (Result)
                    final LatLng? pickedLocation = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TestMap()),
                    );

                    // 2. ถ้ามีการเลือกพิกัดกลับมา ให้บันทึกค่าลงตัวแปร
                    if (pickedLocation != null) {
                      setState(() {
                        _selectedLocation =
                            "${pickedLocation.latitude}, ${pickedLocation.longitude}";
                        // เก็บค่า double ไว้ส่งเข้า DTO ด้วย
                        latilude = pickedLocation.latitude;
                        longitude = pickedLocation.longitude;
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

                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _buildUploadBox(
                        "รูปภาพร้านค้า (Restaurant Image)",
                        _selectedImage,
                        () => pickImage(true),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildUploadBox(
                        "รูปสัญญาเช่า (lease_agreement)",
                        _selectedLeaseImage,
                        () => pickImage(false),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),
                Row(
                  children: [
                    // เวลาเปิด
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("เวลาเปิดร้าน"),
                          TextFormField(
                            controller: openTimeController,
                            readOnly: true, // ห้ามพิมพ์เอง
                            onTap: () =>
                                _selectTime(context, true), // กดแล้วเปิด Picker
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
                    // เวลาปิด
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("เวลาปิดร้าน"),
                          TextFormField(
                            controller: closeTimeController,
                            readOnly: true,
                            onTap: () => _selectTime(context, false),
                            decoration: InputDecoration(
                              hintText: "00:00:00",
                              prefixIcon: const Icon(Icons.history_toggle_off),
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
                        setState(
                          () => _selectedDays[index] = !_selectedDays[index],
                        );
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

                const SizedBox(height: 30),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // ✅ validate ก่อนไปหน้าถัดไป

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegisterOwnerInfo(
                              // ข้อมูล owner เดิม
                              initialFirstName: _ownerFirstName,
                              initialLastName: _ownerLastName,
                              initialEmail: _ownerEmail,
                              initialPhone: _ownerPhone,
                              // ✅ ส่งข้อมูลร้านไปด้วย
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

  Widget _buildTextField(String hint, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: TextField(
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 10,
          ),
          border: InputBorder.none,
          suffixIcon: isPassword
              ? Icon(Icons.visibility_off_outlined, color: Colors.grey[400])
              : null,
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
          onTap: onTap, // เรียก pickImage ตรงนี้
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
