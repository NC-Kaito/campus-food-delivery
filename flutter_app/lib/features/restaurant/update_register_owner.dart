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
    this.updatedImage,
    this.updatedOwnerImage,
  });

  @override
  State<UpdateRegisterOwner> createState() => _UpdateRegisterOwnerState();
}

class _UpdateRegisterOwnerState extends State<UpdateRegisterOwner> {
  static const Color _primary = Color(0xFF16A34A);
  static const Color _primaryDark = Color(0xFF0F7A38);
  static const Color _accent = Color(0xFFEA7C1E);
  static const Color _bg = Color(0xFFF5F6F8);
  static const Color _textDark = Color(0xFF1E1E24);
  static const Color _textMuted = Color(0xFF8A8D93);
  static const Color _danger = Color(0xFFE53935);

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

    if (widget.restaurantData?.imagecardid != null &&
        widget.restaurantData!.imagecardid!.isNotEmpty) {
      ownerImageNetwork = _getFinalImageUrl(
        widget.restaurantData!.imagecardid!,
      );
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
                  if (image != null)
                    setState(() => _selectedOwnerImage = File(image.path));
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
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                  );
                  if (image != null)
                    setState(() => _selectedOwnerImage = File(image.path));
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
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
          imagecardid: newOwnerImageUrl ?? widget.restaurantData?.imagecardid,
          // ใช้ข้อมูลเดิมของเวลาเพื่อไม่ให้กระทบระบบหลังบ้าน แม้จะไม่ได้แสดงใน UI
          openingHours: widget.restaurantData?.openingHours,
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

        await restaurantService.updateProfileRestaurant(updatedModel);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('บันทึกสำเร็จ'),
              backgroundColor: _primary,
            ),
          );
          Navigator.pop(context, 'success');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: _danger),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoadingAction = false);
      }
    }
  }

  InputDecoration _inputDecoration({String hint = "", bool enabled = true}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: enabled ? Colors.white : const Color(0xFFF0F1F3),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
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
              active ? Icons.person_outline_rounded : Icons.storefront_rounded,
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
          dot(false, "ข้อมูลร้านค้า"),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Container(height: 2, color: _primary),
            ),
          ),
          dot(true, "ข้อมูลเจ้าของร้าน"),
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

  @override
  Widget build(BuildContext context) {
    final bool isWaitStatus = widget.verificationStatus == 'wait';
    final bool canEdit = widget.isFormFieldsEditable;

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
          'ข้อมูลการสมัคร',
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
                      icon: Icons.assignment_ind_outlined,
                      title: "ข้อมูลเจ้าของร้าน",
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
                            "ชื่อจริง (First Name)",
                            style: TextStyle(color: Colors.black, fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: ownerFirstNameController,
                            enabled: canEdit,
                            decoration: _inputDecoration(enabled: canEdit),
                          ),
                          const SizedBox(height: 15),

                          const Text(
                            "นามสกุล (Last Name)",
                            style: TextStyle(color: Colors.black, fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: ownerLastNameController,
                            enabled: canEdit,
                            decoration: _inputDecoration(enabled: canEdit),
                          ),
                          const SizedBox(height: 15),

                          const Text(
                            "อีเมล (Email)",
                            style: TextStyle(color: Colors.black, fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: emailController,
                            enabled: canEdit,
                            decoration: _inputDecoration(
                              enabled: canEdit,
                              hint: "example@email.com",
                            ),
                          ),
                          const SizedBox(height: 15),

                          const Text(
                            "เบอร์โทรศัพท์ (Phone Number)",
                            style: TextStyle(color: Colors.black, fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: phoneController,
                            enabled: canEdit,
                            decoration: _inputDecoration(
                              enabled: canEdit,
                              hint: "เช่น 0812345678",
                            ),
                          ),
                          const SizedBox(height: 15),

                          const Text(
                            "รูปภาพบัตรประชาชน (ID Card)",
                            style: TextStyle(color: Colors.black, fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          _buildUploadBox(
                            _selectedOwnerImage,
                            ownerImageNetwork,
                            canEdit ? pickOwnerImage : () {},
                            enabled: canEdit,
                          ),
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
      bottomNavigationBar: _buildActionButtons(isWaitStatus, canEdit),
    );
  }

  Widget _buildActionButtons(bool isWaitStatus, bool canEdit) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: isWaitStatus
            ? _buildOutlineButton("ย้อนกลับ", () => Navigator.pop(context))
            : (!canEdit
                  ? Row(
                      children: [
                        Expanded(
                          child: _buildOutlineButton(
                            "ย้อนกลับ",
                            () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPrimaryButton(
                            "แก้ไขข้อมูล",
                            () => Navigator.pop(context, 'edit'),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildOutlineButton(
                            "ยกเลิก",
                            () => Navigator.pop(context, 'cancel'),
                            isDanger: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPrimaryButton(
                            _isLoadingAction
                                ? "กำลังบันทึก..."
                                : "บันทึกการแก้ไข  ",
                            _isLoadingAction ? () {} : doUpdateRegisterData,
                          ),
                        ),
                      ],
                    )),
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(colors: [_primary, _primaryDark]),
          boxShadow: [
            BoxShadow(
              color: _primary.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineButton(
    String text,
    VoidCallback onPressed, {
    bool isDanger = false,
  }) {
    final color = isDanger ? _danger : _textDark;
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(
            color: isDanger ? _danger.withOpacity(0.5) : Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildUploadBox(
    File? localFile,
    String? networkUrl,
    VoidCallback tap, {
    bool enabled = true,
  }) {
    ImageProvider? imageProvider;
    if (localFile != null) {
      imageProvider = FileImage(localFile);
    } else if (networkUrl != null && networkUrl.isNotEmpty) {
      imageProvider = NetworkImage(Uri.encodeFull(networkUrl));
    }

    return GestureDetector(
      onTap: enabled ? tap : null,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: imageProvider != null ? Colors.white : const Color(0xFFF0F1F3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: imageProvider != null
                ? _primary.withOpacity(0.4)
                : Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        child: imageProvider != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image(image: imageProvider, fit: BoxFit.cover),
                  ),
                  if (enabled)
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
                    "แตะเพื่ออัปโหลดรูปภาพ",
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "รองรับ .jpg, .png ขนาดไม่เกิน 1MB",
                    style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                  ),
                ],
              ),
      ),
    );
  }
}
