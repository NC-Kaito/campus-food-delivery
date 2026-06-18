// features/restaurant/update_register_owner.dart
import 'package:dio/dio.dart' as dio_package;
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class UpdateRegisterOwner extends StatefulWidget {
  final String verificationStatus;
  final RestaurantModel? restaurantData;
  final bool isFormFieldsEditable;
  final String? updatedRestaurantName;
  final int? updatedTypeId;
  final double? updatedLatitude;
  final double? updatedLongitude;
  final String? updatedOpenTime;
  final String? updatedCloseTime;
  final List<bool>? updatedSelectedDays;
  final File? updatedImage;
  final File? updatedOwnerImage;

  const UpdateRegisterOwner({
    super.key,
    required this.verificationStatus,
    this.restaurantData,
    required this.isFormFieldsEditable,
    this.updatedRestaurantName,
    this.updatedTypeId,
    this.updatedLatitude,
    this.updatedLongitude,
    this.updatedOpenTime,
    this.updatedCloseTime,
    this.updatedSelectedDays,
    this.updatedImage,
    this.updatedOwnerImage,
  });

  @override
  State<UpdateRegisterOwner> createState() => _UpdateRegisterOwnerState();
}

class _UpdateRegisterOwnerState extends State<UpdateRegisterOwner> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final RestaurantService restaurantService = RestaurantService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoadingAction = false;
  File? _selectedOwnerImage;
  String? ownerImageNetwork;

  late final TextEditingController ownerFirstNameController;
  late final TextEditingController ownerLastNameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;

  @override
  void initState() {
    super.initState();
    ownerFirstNameController = TextEditingController(
      text: widget.restaurantData?.ownerFirstName ?? "",
    );
    ownerLastNameController = TextEditingController(
      text: widget.restaurantData?.ownerLastName ?? "",
    );
    emailController = TextEditingController(
      text: widget.restaurantData?.email ?? "",
    );
    phoneController = TextEditingController(
      text: widget.restaurantData?.phone ?? "",
    );

    _selectedOwnerImage = widget.updatedOwnerImage;

    if (widget.restaurantData?.ownerImage != null &&
        widget.restaurantData!.ownerImage!.isNotEmpty) {
      ownerImageNetwork = _getFinalImageUrl(widget.restaurantData!.ownerImage!);
    }
  }

  @override
  void dispose() {
    ownerFirstNameController.dispose();
    ownerLastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;
    final String baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/') ? "$baseUrl$rawPath" : "$baseUrl/$rawPath";
  }

  Future<void> pickOwnerImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() => _selectedOwnerImage = File(image.path));
    }
  }

  Future<String?> _uploadImage(File imageFile, String type) async {
    try {
      String fileName = imageFile.path.split('/').last;
      dio_package.FormData formData = dio_package.FormData.fromMap({
        'image': await dio_package.MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
        'type': type,
      });
      var response = await DioClient.dio.post(
        '/v1/restaurant/uploadImage',
        data: formData,
      );
      return response.statusCode == 200 ? response.data['url'] : null;
    } catch (e) {
      return null;
    }
  }

  int _convertDaysToInt(List<bool> days) {
    int result = 0;
    for (int i = 0; i < days.length; i++) {
      if (days[i]) result += (1 << i);
    }
    return result;
  }

  Future<void> doUpdateRegisterData() async {
    if (formKey.currentState!.validate()) {
      setState(() => _isLoadingAction = true);
      try {
        String? newRestaurantImageUrl;
        String? newOwnerImageUrl;

        if (widget.updatedImage != null) {
          newRestaurantImageUrl = await _uploadImage(
            widget.updatedImage!,
            'restaurant',
          );
        }

        // บังคับอัปโหลดรูปใหม่ถ้ามีการเลือกไฟล์เข้ามา
        if (_selectedOwnerImage != null) {
          newOwnerImageUrl = await _uploadImage(
            _selectedOwnerImage!,
            'ownerImage',
          );
        }

        RestaurantModel updatedModel = RestaurantModel(
          username: widget.restaurantData?.username,
          password: widget.restaurantData?.password,
          restaurantName:
              widget.updatedRestaurantName ??
              widget.restaurantData?.restaurantName,
          restaurantImage:
              newRestaurantImageUrl ?? widget.restaurantData?.restaurantImage,
          ownerImage: newOwnerImageUrl ?? widget.restaurantData?.ownerImage,
          openTime: widget.updatedOpenTime ?? widget.restaurantData?.openTime,
          closeTime:
              widget.updatedCloseTime ?? widget.restaurantData?.closeTime,
          openDay: widget.updatedSelectedDays != null
              ? _convertDaysToInt(widget.updatedSelectedDays!)
              : widget.restaurantData?.openDay,
          typerestaurantId:
              widget.updatedTypeId ?? widget.restaurantData?.typerestaurantId,
          latitude: widget.updatedLatitude ?? widget.restaurantData?.latitude,
          longitude:
              widget.updatedLongitude ?? widget.restaurantData?.longitude,
          ownerFirstName: ownerFirstNameController.text,
          ownerLastName: ownerLastNameController.text,
          email: emailController.text,
          phone: phoneController.text,
          statusOpen: widget.restaurantData?.statusOpen ?? false,
        );

        // 🎯 ตรวจสอบค่าก่อนยิง API (เปิดใช้บรรทัดล่างเพื่อดูใน Log)
        // print("Sending Model: ${updatedModel.toJson()}");

        await restaurantService.updateProfileRestaurant(updatedModel);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('บันทึกสำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, 'success');
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
      } finally {
        if (mounted) setState(() => _isLoadingAction = false);
      }
    }
  }

  InputDecoration _inputDecoration({bool enabled = true}) => InputDecoration(
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
    filled: true,
    fillColor: enabled ? Colors.white : const Color(0xFFE0E0E0),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade400),
    ),
  );

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4, top: 10),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    ),
  );

  Widget _buildButton(
    String text,
    Color bg,
    Color textC,
    VoidCallback press,
  ) => Container(
    width: double.infinity,
    height: 48,
    child: ElevatedButton(
      onPressed: press,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: textC,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    ),
  );

  Widget _buildUploadBox(
    String lbl,
    File? localFile,
    String? networkUrl,
    VoidCallback tap, {
    bool enabled = true,
  }) {
    ImageProvider? imageProvider;
    if (localFile != null)
      imageProvider = FileImage(localFile);
    else if (networkUrl != null && networkUrl.isNotEmpty)
      imageProvider = NetworkImage(Uri.encodeFull(networkUrl));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(lbl),
        GestureDetector(
          onTap: enabled ? tap : null,
          child: Container(
            height: 230,
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

  Widget _buildActionButtons(bool isWaitStatus, bool canEdit) {
    if (isWaitStatus)
      return _buildButton(
        "ย้อนกลับ",
        const Color(0xFFE0E0E0),
        Colors.black,
        () => Navigator.pop(context),
      );
    if (!canEdit)
      return Column(
        children: [
          _buildButton(
            "แก้ไขข้อมูล",
            const Color(0xFF55FF33),
            Colors.white,
            () => Navigator.pop(context, 'edit'),
          ),
          const SizedBox(height: 12),
          _buildButton(
            "ย้อนกลับ",
            const Color(0xFFE0E0E0),
            Colors.black,
            () => Navigator.pop(context),
          ),
        ],
      );
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildButton(
                "ยกเลิก",
                const Color(0xFFFF5252),
                Colors.white,
                () => Navigator.pop(context, 'cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildButton(
                "ย้อนกลับ",
                const Color(0xFFE0E0E0),
                Colors.black,
                () => Navigator.pop(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildButton(
          _isLoadingAction ? "กำลังบันทึก..." : "บันทึกการแก้ไข",
          const Color(0xFF55FF33),
          Colors.white,
          _isLoadingAction ? () {} : doUpdateRegisterData,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWaitStatus = widget.verificationStatus == 'wait';
    final bool canEdit = widget.isFormFieldsEditable;

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
      body: Form(
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
                  'ข้อมูลเจ้าของร้านค้า หรือผู้ดูแลร้าน',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                _buildLabel("ชื่อ (FirstName)"),
                TextFormField(
                  controller: ownerFirstNameController,
                  enabled: canEdit,
                  decoration: _inputDecoration(enabled: canEdit),
                ),
                _buildLabel("นามสกุล (LastName)"),
                TextFormField(
                  controller: ownerLastNameController,
                  enabled: canEdit,
                  decoration: _inputDecoration(enabled: canEdit),
                ),
                _buildLabel("อีเมล (Email)"),
                TextFormField(
                  controller: emailController,
                  enabled: canEdit,
                  decoration: _inputDecoration(enabled: canEdit),
                ),
                _buildLabel("เบอร์โทรศัพท์ (Phone)"),
                TextFormField(
                  controller: phoneController,
                  enabled: canEdit,
                  decoration: _inputDecoration(enabled: canEdit),
                ),
                const SizedBox(height: 15),
                _buildUploadBox(
                  "บัตรประชาชน",
                  _selectedOwnerImage,
                  ownerImageNetwork,
                  canEdit ? pickOwnerImage : () {},
                  enabled: canEdit,
                ),
                const SizedBox(height: 40),
                _buildActionButtons(isWaitStatus, canEdit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
