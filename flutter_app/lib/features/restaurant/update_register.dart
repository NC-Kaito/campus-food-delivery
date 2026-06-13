// features/restaurant/update_register_fields.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/type_restaurant_model.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/data/services/restaurant/type_restaurant_service.dart';
import 'package:flutter_app/features/member/test_map.dart';
import 'package:flutter_app/features/restaurant/update_register_owner.dart';
import 'package:flutter_app/core/network/dio_client.dart'; // 🎯 เรียกใช้งานไอพีกลาง
import 'package:flutter_app/global_data.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UpdateRegisterFields extends StatefulWidget {
  final String verificationStatus;

  const UpdateRegisterFields({super.key, required this.verificationStatus});

  @override
  State<UpdateRegisterFields> createState() => _UpdateRegisterFieldsState();
}

class _UpdateRegisterFieldsState extends State<UpdateRegisterFields> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TypeRestaurantService typeRestaurantService = TypeRestaurantService();
  final RestaurantService restaurantService = RestaurantService();
  RestaurantModel? restaurantModel;

  bool isLoading = true;
  bool _isEditable = false;
  bool _obscureText = true;

  // Controllers
  late final TextEditingController usernameController;
  late final TextEditingController passwordController;
  late final TextEditingController restaurantNameController;
  late final TextEditingController openTimeController;
  late final TextEditingController closeTimeController;

  double? latitude;
  double? longitude;
  String? _selectedLocation;
  String? _selectedType;
  int? _selectedTypeId;
  File? _selectedImage;
  File?
  _selectedOwnerImage; // 🎯 เปลี่ยนชื่อตัวแปรเก็บไฟล์ให้สื่อถึงรูปเจ้าของร้าน

  // URL รูปภาพเก่าจาก Server ที่แปลงผูกไอพีกลางแล้ว
  String? restaurantImageNetwork;
  String? ownerImageNetwork; // 🎯 ตัวแปรเก็บเครือข่ายรูปหน้าเจ้าของร้าน

  final List<String> _days = ['อา.', 'จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.'];
  final List<bool> _selectedDays = List.generate(7, (index) => false);
  List<TypeRestaurantModel> typeList = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    passwordController = TextEditingController();
    restaurantNameController = TextEditingController();
    openTimeController = TextEditingController();
    closeTimeController = TextEditingController();
    _initData();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    restaurantNameController.dispose();
    openTimeController.dispose();
    closeTimeController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    setState(() => isLoading = true);
    await _fetchTypeRestaurants();
    await _fetchRestaurantProfile();
    setState(() => isLoading = false);
  }

  Future<void> _fetchTypeRestaurants() async {
    const String typePath = "/v1/typerestaurant";
    try {
      final response = await DioClient.dio.get(typePath);
      if (response.statusCode == 200) {
        final List data = response.data;
        setState(() {
          typeList = data.map((e) => TypeRestaurantModel.fromJson(e)).toList();
        });
      }
    } catch (e) {
      print("typeList endpoint ไม่พบ — จะดึงค่าผ่าน getAllTypeRestaurant แทน");
      try {
        final types = await typeRestaurantService.getAllTypeRestaurant();
        setState(() => typeList = types);
      } catch (err) {
        print("Error fetching types: $err");
      }
    }
  }

  // 🎯 ฟังก์ชันดักจับคั่นกลางเครื่องหมายสแลช / ป้องกันลิงก์ชิดติดกันจนพัง
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

  Future<void> _fetchRestaurantProfile() async {
    try {
      final result = await restaurantService.getRestaurantByUsername(
        GlobalData.usernameRestaurant,
      );

      setState(() {
        restaurantModel = result;

        // ดึงข้อมูลลงฟอร์ม
        usernameController.text = result.username ?? "";
        passwordController.text = result.password ?? "";
        restaurantNameController.text = result.restaurantName ?? "";
        openTimeController.text = result.openTime ?? "";
        closeTimeController.text = result.closeTime ?? "";

        if (result.latitude != null && result.longitude != null) {
          _selectedLocation = "${result.latitude}, ${result.longitude}";
          latitude = result.latitude;
          longitude = result.longitude;
        }

        // 🎯 สลัดตรรกะ .replaceAll ทิ้งอย่างถาวร แล้วสวมฟังก์ชันผูกไอพีกลางแทน
        restaurantImageNetwork =
            result.restaurantImage != null && result.restaurantImage!.isNotEmpty
            ? _getFinalImageUrl(result.restaurantImage)
            : null;

        // 🎯 สลัดคราบสัญญาเช่าผี เปลี่ยนมาดึงฟังก์ชันเซ็ตหัวไอพีรูปใบหน้าเจ้าของร้านค้าแทน
        ownerImageNetwork =
            result.ownerImage != null && result.ownerImage!.isNotEmpty
            ? _getFinalImageUrl(result.ownerImage)
            : null;

        // จับคู่ประเภทร้านค้า
        final matched = typeList
            .where((t) => t.id == result.typerestaurantId)
            .firstOrNull;
        if (matched != null) {
          _selectedType = matched.name;
          _selectedTypeId = matched.id;
        } else {
          _selectedType = result.typerestaurantName;
          _selectedTypeId = result.typerestaurantId;
        }

        // แกะวันเปิดร้านเก่าลงปุ่มวงกลม
        if (result.openDay != null) {
          for (int i = 0; i < 7; i++) {
            _selectedDays[i] = (result.openDay! & (1 << i)) != 0;
          }
        }
      });
    } catch (e) {
      print("Error fetching profile data: $e");
    }
  }

  Future<void> _selectTime(BuildContext context, bool isOpenTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        String formattedTime =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00";
        if (isOpenTime)
          openTimeController.text = formattedTime;
        else
          closeTimeController.text = formattedTime;
      });
    }
  }

  Future<void> pickImage(bool isRestaurantImage) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        if (isRestaurantImage)
          _selectedImage = File(image.path);
        else
          _selectedOwnerImage = File(
            image.path,
          ); // 🎯 นำค่าไฟล์เก็บเข้าสู่ตัวแปรเจ้าของร้านค้า
      });
    }
  }

  InputDecoration _inputDecoration({bool enabled = true}) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      filled: true,
      fillColor: enabled ? Colors.white : const Color(0xFFCCCCCC),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWaitStatus = widget.verificationStatus == 'wait';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.orange),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'ข้อมูลการสมัคร',
          style: TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Form(
              key: formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'textอาหารแนะนำ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      _buildLabel("ชื่อผู้ใช้ (Username)"),
                      TextFormField(
                        controller: usernameController,
                        enabled: false,
                        decoration: _inputDecoration(enabled: false),
                      ),

                      _buildLabel("รหัสผ่าน (Password)"),
                      TextFormField(
                        controller: passwordController,
                        obscureText: _obscureText,
                        enabled: false,
                        decoration: _inputDecoration(enabled: false),
                      ),

                      _buildLabel("ชื่อร้านค้า (Restaurant Name)"),
                      TextFormField(
                        controller: restaurantNameController,
                        enabled: _isEditable,
                        decoration: _inputDecoration(enabled: _isEditable),
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
                          });
                        },
                        enabled: _isEditable,
                      ),

                      _buildLabel("ปักหมุดที่อยู่ร้านค้า (location)"),
                      InkWell(
                        onTap: _isEditable
                            ? () async {
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
                                    latitude = pickedLocation.latitude;
                                    longitude = pickedLocation.longitude;
                                  });
                                }
                              }
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            color: _isEditable
                                ? Colors.white
                                : const Color(0xFFCCCCCC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedLocation ?? "ปักหมุดที่อยู่ร้านค้า",
                              ),
                              const Icon(
                                Icons.map_outlined,
                                color: Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: _buildUploadBox(
                              "รูปภาพร้านค้า",
                              _selectedImage,
                              restaurantImageNetwork,
                              () => pickImage(true),
                              enabled: _isEditable,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildUploadBox(
                              // 🎯 แก้ไขคำกำกับหัวข้อและจัดสรรตัวแปรสกรีนภาพถ่ายหน้าเจ้าของร้านค้าแทนที่ของเดิม
                              "รูปหน้าเจ้าของร้านค้า",
                              _selectedOwnerImage,
                              ownerImageNetwork,
                              () => pickImage(false),
                              enabled: _isEditable,
                            ),
                          ),
                        ],
                      ),

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
                                  enabled: _isEditable,
                                  onTap: () => _selectTime(context, true),
                                  decoration: _inputDecoration(
                                    enabled: _isEditable,
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
                                  enabled: _isEditable,
                                  onTap: () => _selectTime(context, false),
                                  decoration: _inputDecoration(
                                    enabled: _isEditable,
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
                            onTap: _isEditable
                                ? () => setState(
                                    () => _selectedDays[index] =
                                        !_selectedDays[index],
                                  )
                                : null,
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

                      _buildActionButtons(isWaitStatus),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildActionButtons(bool isWaitStatus) {
    if (isWaitStatus) {
      return _buildButton(
        "ถัดไป",
        const Color(0xFFE0E0E0),
        Colors.black,
        _navigateToNextPage,
      );
    } else {
      if (!_isEditable) {
        return Column(
          children: [
            _buildButton(
              "แก้ไขข้อมูล",
              const Color(0xFF55FF33),
              Colors.white,
              () => setState(() => _isEditable = true),
            ),
            const SizedBox(height: 12),
            _buildButton(
              "ถัดไป",
              const Color(0xFFE0E0E0),
              Colors.black,
              _navigateToNextPage,
            ),
          ],
        );
      } else {
        return Row(
          children: [
            Expanded(
              child: _buildButton(
                "ยกเลิก",
                const Color(0xFFFF5252),
                Colors.white,
                () {
                  setState(() => _isEditable = false);
                  _fetchRestaurantProfile();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildButton(
                "ถัดไป",
                const Color(0xFFE0E0E0),
                Colors.black,
                _navigateToNextPage,
              ),
            ),
          ],
        );
      }
    }
  }

  Future<void> _navigateToNextPage() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateRegisterOwner(
          verificationStatus: widget.verificationStatus,
          restaurantData: restaurantModel,
          isFormFieldsEditable: _isEditable,

          updatedRestaurantName: restaurantNameController.text,
          updatedTypeId: _selectedTypeId,
          updatedLatitude: latitude,
          updatedLongitude: longitude,
          updatedOpenTime: openTimeController.text,
          updatedCloseTime: closeTimeController.text,
          updatedSelectedDays: _selectedDays,
          updatedImage: _selectedImage,
          updatedOwnerImage:
              _selectedOwnerImage, // 🎯 แมปส่งรูปหน้าเจ้าของร้านตัวแปรใหม่ไปหน้าที่สอง
        ),
      ),
    );

    if (result == 'cancel' || result == 'success') {
      setState(() => _isEditable = false);
      _fetchRestaurantProfile();
    } else if (result == 'edit') {
      setState(() => _isEditable = true);
    }
  }

  Widget _buildButton(String text, Color bg, Color textC, VoidCallback press) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: press,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: textC,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4, top: 10),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    ),
  );

  Widget _buildDropdown(
    List<String> items,
    String? val,
    Function(String?) change, {
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: val,
          isExpanded: true,
          hint: const Text("---เลือก---"),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: enabled ? change : null,
        ),
      ),
    );
  }

  Widget _buildUploadBox(
    String lbl,
    File? localFile,
    String? networkUrl,
    VoidCallback tap, {
    bool enabled = true,
  }) {
    ImageProvider? imageProvider;
    if (localFile != null) {
      imageProvider = FileImage(localFile);
    } else if (networkUrl != null) {
      imageProvider = NetworkImage(Uri.encodeFull(networkUrl));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(lbl),
        GestureDetector(
          onTap: enabled ? tap : null,
          child: Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: enabled ? Colors.white : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade400),
              image: imageProvider != null
                  ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                  : null,
            ),
            child: imageProvider == null
                ? const Icon(Icons.add, color: Colors.grey, size: 30)
                : null,
          ),
        ),
      ],
    );
  }
}
