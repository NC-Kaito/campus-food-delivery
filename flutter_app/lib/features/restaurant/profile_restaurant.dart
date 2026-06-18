// features/restaurant/profile_restaurant.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/type_restaurant_model.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/features/restaurant/restaurant_navbar.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/features/restaurant/location_restaurant.dart';
import 'package:flutter_app/features/restaurant/login_restaurant.dart';
import 'package:flutter_app/features/restaurant/view_agrees.dart';
import 'package:flutter_app/features/restaurant/close_account.dart';
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

  final List<String> _days = ['อา.', 'จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.'];
  final List<bool> _selectedDays = List.generate(7, (_) => false);

  List<TypeRestaurantModel> _typeList = [];
  String? _selectedType;
  int? _selectedTypeId;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    passwordController = TextEditingController();
    restaurantnameController = TextEditingController();
    opentimeController = TextEditingController();
    closetimeController = TextEditingController();
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
    opentimeController.dispose();
    closetimeController.dispose();
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

  void _decodeopenDay(int? openDay) {
    if (openDay == null) return;
    for (int i = 0; i < 7; i++) {
      _selectedDays[i] = (openDay & (1 << i)) != 0;
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
        opentimeController.text = result.openTime ?? "";
        closetimeController.text = result.closeTime ?? "";
        _isStoreOpen = result.statusOpen ?? true;
        ownerfirstnameController.text = result.ownerFirstName ?? "";
        ownerlastnameController.text = result.ownerLastName ?? "";
        emailController.text = result.email ?? "";
        phoneController.text = result.phone ?? "";

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
          print("matched type: ${matched.name} (id=${matched.id})");
        } else {
          _selectedType = result.typerestaurantName;
          _selectedTypeId = result.typerestaurantId;
          print("type not matched in list, fallback: $_selectedType");
        }

        _decodeopenDay(result.openDay);
      });
    } catch (e) {
      print("Error fetching profile: $e");
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
      final formatted =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00";
      setState(() {
        if (isOpenTime) {
          opentimeController.text = formatted;
        } else {
          closetimeController.text = formatted;
        }
      });
    }
  }

  int _convertDaysToInt(List<bool> days) {
    int result = 0;
    for (int i = 0; i < days.length; i++) {
      if (days[i]) result += (1 << i);
    }
    return result;
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

  // 🎯 ปรับปรุงส่วนอัปโหลดรูปภาพร้านค้า: ยิงตรงผ่าน DioClient ยึดไอพีตัวแปรกลางสากล
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
        return response.data['url']; // ได้รับพาธสั้นสากลกลับมาทันที
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
          "ownerimage": restaurantModel?.ownerImage ?? "",
          "latitude": _restaurantLatLng?.latitude ?? restaurantModel?.latitude,
          "longitude":
              _restaurantLatLng?.longitude ?? restaurantModel?.longitude,
          "opentime": opentimeController.text,
          "closetime": closetimeController.text,
          "openday": _convertDaysToInt(_selectedDays),
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
            const SnackBar(
              content: Text('บันทึกข้อมูลเรียบร้อยแล้ว'),
              backgroundColor: Colors.green,
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
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => isLoadingAction = false);
      }
    }
  }

  // 🎯 ฟังก์ชันเชื่อมสายพาร์ทรูปภาพ: ตรวจจับและคั่นสแลชกลางให้เรียบร้อยป้องกันปัญหาลิงก์ติดกันรูปพัง
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
      padding: const EdgeInsets.only(bottom: 8, top: 10),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      filled: true,
      fillColor: enabled
          ? Colors.white
          : const Color.fromARGB(255, 224, 223, 223),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color.fromARGB(255, 21, 22, 21),
          width: 1.5,
        ),
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

  Widget _buildDropdown() {
    final Set<String> nameSet = _typeList.map((t) => t.name).toSet();
    final List<String> displayItems = List.from(nameSet);
    if (_selectedType != null && !nameSet.contains(_selectedType)) {
      displayItems.insert(0, _selectedType!);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: _isEditable ? Colors.white : Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          isExpanded: true,
          hint: const Text("---เลือก---"),
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

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ดึงค่า URL ภาพที่ผ่านการเชื่อมไอพีส่วนกลางเรียบร้อยมาเตรียมรอวาดขึ้นจอ
    final String finalProfileUrl = _getFinalImageUrl(restaurantimage);

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: const RestaurantNavbar(title: ""),
      body: isLooding
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SafeArea(
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // ── รูปภาพร้านค้า ──────────────────────────────────
                        Stack(
                          children: [
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade400),
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
                            ),
                            if (_isEditable)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: const CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 18,
                                    child: Icon(
                                      Icons.edit_outlined,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Toggle เปิด/ปิดร้าน ─────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "สถานะเปิด-ปิดร้าน",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 15),
                            GestureDetector(
                              onTap: () async {
                                if (restaurantModel == null) return;

                                final bool previousStatus = _isStoreOpen;
                                final bool newStatus = !_isStoreOpen;

                                setState(() => _isStoreOpen = newStatus);

                                try {
                                  restaurantModel!.statusOpen = newStatus;

                                  await restaurantService.updateStatusOpen(
                                    restaurantModel!,
                                  );

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          newStatus
                                              ? 'เปิดร้านสำเร็จ'
                                              : 'ปิดร้านสำเร็จ',
                                        ),
                                        backgroundColor: const Color.fromARGB(
                                          255,
                                          0,
                                          255,
                                          8,
                                        ),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  print("Update Status Error: $e");
                                  if (mounted) {
                                    setState(
                                      () => _isStoreOpen = previousStatus,
                                    );
                                    restaurantModel!.statusOpen =
                                        previousStatus;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'เปลี่ยนสถานะไม่สำเร็จ: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 75,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: _isStoreOpen
                                      ? const Color.fromARGB(255, 77, 255, 0)
                                      : Colors.grey[400],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisAlignment: _isStoreOpen
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  children: [
                                    if (!_isStoreOpen)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Text(
                                          "OFF",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.all(2),
                                      child: CircleAvatar(
                                        radius: 15,
                                        backgroundColor: Colors.white,
                                        child: _isStoreOpen
                                            ? const Text(
                                                "ON",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            "ข้อมูลร้านค้า",
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // ══ Section 1: ข้อมูลร้านค้า ════════════════════════
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
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
                                        if (v == null || v.trim().isEmpty)
                                          return "กรุณากรอกชื่อร้านค้า";
                                        if (v.length < 8)
                                          return "ความยาว 8 ตัวอักษรขึ้นไป";
                                        return null;
                                      }
                                    : null,
                                decoration: _inputDecoration(
                                  enabled: _isEditable,
                                ),
                              ),

                              _buildLabel("ประเภทร้านค้า (Restaurant Type)"),
                              _buildDropdown(),

                              const SizedBox(height: 3),

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
                                      color: Colors.grey.shade400,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: GoogleMap(
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
                                                position: _restaurantLatLng!,
                                              ),
                                            },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel("เวลาเปิดร้าน"),
                                        TextFormField(
                                          controller: opentimeController,
                                          enabled: _isEditable,
                                          onTap: _isEditable
                                              ? () => _selectTime(context, true)
                                              : null,
                                          validator: _isEditable
                                              ? (v) => (v == null || v.isEmpty)
                                                    ? "กรุณาระบุเวลาเปิด"
                                                    : null
                                              : null,
                                          decoration: _inputDecoration(
                                            hint: "00:00:00",
                                            enabled: _isEditable,
                                            suffixIcon: Icon(
                                              Icons.access_time,
                                              color: Colors.grey[400],
                                            ),
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
                                        _buildLabel("เวลาปิดร้าน"),
                                        TextFormField(
                                          controller: closetimeController,
                                          enabled: _isEditable,
                                          onTap: _isEditable
                                              ? () =>
                                                    _selectTime(context, false)
                                              : null,
                                          validator: _isEditable
                                              ? (v) => (v == null || v.isEmpty)
                                                    ? "กรุณาระบุเวลาปิด"
                                                    : null
                                              : null,
                                          decoration: _inputDecoration(
                                            hint: "00:00:00",
                                            enabled: _isEditable,
                                            suffixIcon: Icon(
                                              Icons.history_toggle_off,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              _buildLabel("วันที่เปิดร้าน (Open Date)"),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(7, (i) {
                                  return GestureDetector(
                                    onTap: _isEditable
                                        ? () => setState(
                                            () => _selectedDays[i] =
                                                !_selectedDays[i],
                                          )
                                        : null,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: _selectedDays[i]
                                            ? const Color.fromARGB(
                                                255,
                                                230,
                                                115,
                                                0,
                                              )
                                            : Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _days[i],
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: _selectedDays[i]
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            "ข้อมูลเจ้าของร้านค้า หรือผู้ดูแลร้าน",
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // ══ Section 2: ข้อมูลเจ้าของร้าน ════════════════════
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
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
                                        ).hasMatch(v))
                                          return "ต้องเป็นภาษาไทยหรืออังกฤษเท่านั้น";
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
                                        ).hasMatch(v))
                                          return "ต้องเป็นภาษาไทยหรืออังกฤษเท่านั้น";
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
                                        ).hasMatch(v))
                                          return "รูปแบบอีเมลไม่ถูกต้อง";
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
                                        height: 50,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              _isEditable = false;
                                              _selectedImage = null;
                                            });
                                            _fetchRestaurantProfile();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey[300],
                                            foregroundColor: Colors.black,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                          ),
                                          child: const Text(
                                            "ยกเลิก",
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: SizedBox(
                                        height: 50,
                                        child: ElevatedButton(
                                          onPressed: isLoadingAction
                                              ? null
                                              : doUpdateRestaurant,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromARGB(
                                                  255,
                                                  77,
                                                  255,
                                                  0,
                                                ),
                                            foregroundColor: Colors.white,
                                            elevation: 5,
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
                                                        color: Color.fromARGB(
                                                          255,
                                                          77,
                                                          255,
                                                          0,
                                                        ),
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : const Text(
                                                  "บันทึกข้อมูล",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        setState(() => _isEditable = true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                        255,
                                        77,
                                        255,
                                        0,
                                      ),
                                      foregroundColor: Colors.white,
                                      elevation: 5,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: const Text(
                                      "แก้ไขข้อมูล",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                        ),

                        // ── เมนูเพิ่มเติม (ซ่อนตอนแก้ไข) ────────────────────
                        if (!_isEditable)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                // ข้อตกลงและเงื่อนไขการยินยอม
                                _buildMenuTile(
                                  icon: Icons.article_outlined,
                                  iconColor: Colors.orange,
                                  label: 'ข้อตกลงและเงื่อนไขการยินยอม',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ViewAgrees(),
                                      ),
                                    );
                                  },
                                ),
                                Divider(
                                  height: 1,
                                  color: Colors.grey.shade300,
                                  indent: 16,
                                  endIndent: 16,
                                ),

                                // ปิดบัญชีผู้ใช้
                                _buildMenuTile(
                                  icon: Icons.cancel_outlined,
                                  iconColor: Colors.red,
                                  label: 'ปิดบัญชีผู้ใช้',
                                  // แก้จากเดิมที่เรียกแบบไม่มี parameter:
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CloseAccount(
                                          restaurant: restaurantModel!,
                                        ), // ใส่ตัวแปร restaurantModel เข้าไป
                                      ),
                                    );
                                  },
                                ),
                                Divider(
                                  height: 1,
                                  color: Colors.grey.shade300,
                                  indent: 16,
                                  endIndent: 16,
                                ),

                                // ออกจากระบบ
                                _buildMenuTile(
                                  icon: Icons.logout,
                                  iconColor: Colors.orange,
                                  label: 'ออกจากระบบ',
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      barrierColor: Colors.black.withOpacity(
                                        0.4,
                                      ),
                                      builder: (context) => Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        backgroundColor: Colors.white,
                                        child: Padding(
                                          padding: const EdgeInsets.all(28),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 64,
                                                height: 64,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFFFEBEE),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.logout_rounded,
                                                  color: Color(0xFFE53935),
                                                  size: 32,
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              const Text(
                                                'ออกจากระบบ',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1A1A2E),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              const Text(
                                                'คุณต้องการออกจากระบบใช่หรือไม่?',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black,
                                                  height: 1.5,
                                                ),
                                              ),
                                              const SizedBox(height: 28),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: OutlinedButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            false,
                                                          ),
                                                      style: OutlinedButton.styleFrom(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 14,
                                                            ),
                                                        side: BorderSide(
                                                          color: Colors
                                                              .grey
                                                              .shade300,
                                                        ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        'ยกเลิก',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              Colors.grey[700],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: ElevatedButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            true,
                                                          ),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                              0xFFE53935,
                                                            ),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 14,
                                                            ),
                                                        elevation: 0,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        'ออกจากระบบ',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );

                                    if (confirm == true && mounted) {
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginRestaurant(),
                                        ),
                                        (route) => false,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
