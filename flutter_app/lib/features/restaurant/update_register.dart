// features/restaurant/update_register_fields.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/type_restaurant_model.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/data/services/restaurant/type_restaurant_service.dart';
import 'package:flutter_app/features/member/test_map.dart';
import 'package:flutter_app/features/restaurant/update_register_owner.dart';
import 'package:flutter_app/core/network/dio_client.dart';
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
  static const Color _primary = Color(0xFF16A34A);
  static const Color _primaryDark = Color(0xFF0F7A38);
  static const Color _accent = Color(0xFFEA7C1E);
  static const Color _bg = Color(0xFFF5F6F8);
  static const Color _textDark = Color(0xFF1E1E24);
  static const Color _textMuted = Color(0xFF8A8D93);
  static const Color _danger = Color(0xFFE53935);

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TypeRestaurantService typeRestaurantService = TypeRestaurantService();
  final RestaurantService restaurantService = RestaurantService();
  RestaurantModel? restaurantModel;

  bool isLoading = true;
  bool _isEditable = false;
  bool _obscureText = true;

  late final TextEditingController usernameController;
  late final TextEditingController passwordController;
  late final TextEditingController restaurantNameController;

  double? latitude;
  double? longitude;
  String? _selectedLocation;
  String? _selectedType;
  int? _selectedTypeId;
  File? _selectedImage;
  File? _selectedOwnerImage;

  String? restaurantImageNetwork;
  String? ownerImageNetwork;

  List<TypeRestaurantModel> typeList = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    passwordController = TextEditingController();
    restaurantNameController = TextEditingController();
    _initData();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    restaurantNameController.dispose();
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
      try {
        final types = await typeRestaurantService.getAllTypeRestaurant();
        setState(() => typeList = types);
      } catch (err) {
        debugPrint("Error fetching types: $err");
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

  Future<void> _fetchRestaurantProfile() async {
    try {
      final result = await restaurantService.getRestaurantByUsername(
        GlobalData.usernameRestaurant,
      );

      setState(() {
        restaurantModel = result;

        usernameController.text = result.username ?? "";
        passwordController.text = result.password ?? "";
        restaurantNameController.text = result.restaurantName ?? "";

        if (result.latitude != null && result.longitude != null) {
          _selectedLocation = "${result.latitude}, ${result.longitude}";
          latitude = result.latitude;
          longitude = result.longitude;
        }

        restaurantImageNetwork =
            result.restaurantImage != null && result.restaurantImage!.isNotEmpty
            ? _getFinalImageUrl(result.restaurantImage)
            : null;

        ownerImageNetwork =
            result.imagecardid != null && result.imagecardid!.isNotEmpty
            ? _getFinalImageUrl(result.imagecardid)
            : null;

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
      });
    } catch (e) {
      debugPrint("Error fetching profile data: $e");
    }
  }

  Future<void> pickImage(bool isRestaurantImage) async {
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
                    setState(() {
                      if (isRestaurantImage) {
                        _selectedImage = File(image.path);
                      } else {
                        _selectedOwnerImage = File(image.path);
                      }
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
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    setState(() {
                      if (isRestaurantImage) {
                        _selectedImage = File(image.path);
                      } else {
                        _selectedOwnerImage = File(image.path);
                      }
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      color: Colors.white,
                      child: _buildStepIndicator(),
                    ),
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
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 10),
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
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: usernameController,
                                  enabled: false,
                                  decoration: _inputDecoration(
                                    enabled: false,
                                    suffixIcon: Icon(
                                      Icons.person_outline,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 15),

                                const Text(
                                  "รหัสผ่าน (Password)",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: passwordController,
                                  obscureText: _obscureText,
                                  enabled: false,
                                  decoration: _inputDecoration(
                                    enabled: false,
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
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: restaurantNameController,
                                  enabled: _isEditable,
                                  decoration: _inputDecoration(
                                    enabled: _isEditable,
                                    suffixIcon: Icon(
                                      Icons.storefront_outlined,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 15),

                                const Text(
                                  "ที่ตั้งร้านค้า (Location)",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: _isEditable
                                      ? () async {
                                          final LatLng? pickedLocation =
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const TestMap(),
                                                ),
                                              );
                                          if (pickedLocation != null) {
                                            setState(() {
                                              _selectedLocation =
                                                  "${pickedLocation.latitude}, ${pickedLocation.longitude}";
                                              latitude =
                                                  pickedLocation.latitude;
                                              longitude =
                                                  pickedLocation.longitude;
                                            });
                                          }
                                        }
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: !_isEditable
                                          ? const Color(0xFFF0F1F3)
                                          : (_selectedLocation == null
                                                ? const Color(0xFFF0F1F3)
                                                : _primary.withOpacity(0.06)),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: !_isEditable
                                            ? Colors.grey.shade200
                                            : (_selectedLocation == null
                                                  ? Colors.grey.shade300
                                                  : _primary.withOpacity(0.4)),
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
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
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
                                        if (_isEditable)
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            color: Colors.grey[400],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),

                                const Text(
                                  "รูปภาพร้านค้า (Restaurant Image)",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                _buildUploadBox(
                                  _selectedImage,
                                  restaurantImageNetwork,
                                  () => pickImage(true),
                                  enabled: _isEditable,
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
      bottomNavigationBar: isLoading ? null : _buildActionButtons(isWaitStatus),
    );
  }

  Widget _buildActionButtons(bool isWaitStatus) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: isWaitStatus
            ? _buildPrimaryButton("ถัดไป", _navigateToNextPage)
            : (!_isEditable
                  ? Row(
                      children: [
                        Expanded(
                          child: _buildOutlineButton(
                            "ถัดไป",
                            _navigateToNextPage,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPrimaryButton(
                            "แก้ไขข้อมูล",
                            () => setState(() => _isEditable = true),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildOutlineButton("ยกเลิก", () {
                            setState(() => _isEditable = false);
                            _fetchRestaurantProfile();
                          }, isDanger: true),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPrimaryButton(
                            "ถัดไป",
                            _navigateToNextPage,
                          ),
                        ),
                      ],
                    )),
      ),
    );
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
          updatedImage: _selectedImage,
          updatedOwnerImage: _selectedOwnerImage,
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

  Widget _buildDropdown(
    List<String> items,
    String? val,
    Function(String?) change, {
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFF0F1F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: val,
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
          onChanged: enabled ? change : null,
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
