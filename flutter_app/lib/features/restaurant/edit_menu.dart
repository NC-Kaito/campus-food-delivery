// features/restaurant/edit_menu.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/data/services/restaurant/type_restaurant_service.dart';
import 'package:flutter_app/features/restaurant/restaurant_navbar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/data/models/type_menu_model.dart';
import 'package:flutter_app/data/services/menu/menu_service.dart';
import 'package:flutter_app/data/services/menu/type_menu_service.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/global_data.dart';

const String _riceCurryTypeName = "ข้าวราดแกง";

class _MenuTheme {
  static const Color primary = Color(0xFFFF8A00);
  static const Color accent = Color(0xFF2FB86A);
  static const Color danger = Color(0xFFE5484D);
  static const Color surface = Colors.white;
  static const Color pageBg = Color(0xFFF6F7F9);
  static const Color textPrimary = Color(0xFF1F2430);
  static const Color textSecondary = Color(0xFF8A8F98);
  static const Color fieldBg = Color(0xFFF4F5F7);
  static const Color border = Color(0xFFE7E8EC);
}

class EditMenu extends StatefulWidget {
  final MenuModel menuModel;

  const EditMenu({super.key, required this.menuModel});

  @override
  State<EditMenu> createState() => _EditMenuState();
}

class _EditMenuState extends State<EditMenu> {
  final MenuService menuService = MenuService();
  final TypeRestaurantService typeRestaurantService = TypeRestaurantService();
  final TypeMenuService typeMenuService = TypeMenuService();
  final RestaurantService restaurantService = RestaurantService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController menuNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController _newTypeNameController = TextEditingController();
  final FocusNode _newTypeFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isInitialLoading = true;
  bool _isAddingNewType = false;
  bool _isEditable = false;
  bool _isRiceCurryRestaurant = false;

  List<TypeMenuModel> typeMenuList = [];

  int? _selectedTypeMenuId;
  String? _selectedTypeMenuName;
  String? _newTypeName;

  File? _selectedImage;
  String? _existingImageUrl;
  String? _imageError;
  String? _typeMenuError;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeFromMenuModel();
    _initializeData();
  }

  void _initializeFromMenuModel() {
    menuNameController.text = widget.menuModel.menuName ?? "";
    descriptionController.text = widget.menuModel.description ?? "";
    priceController.text = widget.menuModel.price?.toStringAsFixed(0) ?? "";
    _existingImageUrl = widget.menuModel.menuImage;
    _selectedTypeMenuId = widget.menuModel.typeMenuId;
    _selectedTypeMenuName = widget.menuModel.typeMenuName;
  }

  @override
  void dispose() {
    menuNameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    _newTypeNameController.dispose();
    _newTypeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _checkRestaurantType();
    await _loadAllData();
  }

  Future<void> _checkRestaurantType() async {
    try {
      final restaurant = await restaurantService.getRestaurantByUsername(
        GlobalData.usernameRestaurant,
      );
      setState(() {
        final typeName = restaurant.typerestaurantName?.toLowerCase() ?? "";
        _isRiceCurryRestaurant =
            typeName.contains("ข้าวแกง") || typeName.contains("ข้าวราดแกง");
      });
    } catch (e) {
      debugPrint("ตรวจสอบประเภทร้านค้าผิดพลาด: $e");
    }
  }

  Future<void> _loadAllData() async {
    setState(() => _isInitialLoading = true);
    try {
      final types = await typeMenuService.getAllTypeMenu();

      if (!mounted) return;

      setState(() {
        typeMenuList = types;

        if (_isRiceCurryRestaurant) {
          final match = typeMenuList
              .where((e) => e.typemenuName == _riceCurryTypeName)
              .firstOrNull;
          if (match != null) {
            _selectedTypeMenuName = match.typemenuName;
            _selectedTypeMenuId = match.typemenuId;
          } else {
            _selectedTypeMenuName = _riceCurryTypeName;
            _newTypeName = _riceCurryTypeName;
          }
        } else {
          final bool typeStillExists = typeMenuList.any(
            (e) => e.typemenuId == _selectedTypeMenuId,
          );
          if (_selectedTypeMenuId != null && !typeStillExists) {
            _selectedTypeMenuName = null;
            _selectedTypeMenuId = null;
          }
        }

        _isInitialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isInitialLoading = false);
      debugPrint("EditMenu _loadAllData error: $e");
    }
  }

  Future<void> pickImage() async {
    if (!_isEditable) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: _MenuTheme.accent,
              ),
              title: const Text("ถ่ายรูปด้วยกล้อง"),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (image != null) {
                  setState(() {
                    _selectedImage = File(image.path);
                    _imageError = null;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: _MenuTheme.accent,
              ),
              title: const Text("เลือกจากแกลเลอรี่"),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                if (image != null) {
                  setState(() {
                    _selectedImage = File(image.path);
                    _imageError = null;
                  });
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;
    final String baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/') ? "$baseUrl$rawPath" : "$baseUrl/$rawPath";
  }

  Future<void> _doSaveMenu() async {
    final isFormValid = formKey.currentState!.validate();

    setState(() {
      _imageError =
          (_selectedImage == null &&
              (_existingImageUrl == null || _existingImageUrl!.isEmpty))
          ? "กรุณาเลือกรูปภาพอาหารประกอบด้วย"
          : null;
      _typeMenuError =
          (_selectedTypeMenuId == null &&
              (_newTypeName == null || _newTypeName!.isEmpty))
          ? "กรุณาเลือกหรือกรอกประเภทหมวดหมู่เมนู"
          : null;
    });

    if (!isFormValid || _imageError != null || _typeMenuError != null) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl = _existingImageUrl;
      if (_selectedImage != null) {
        imageUrl = await menuService.uploadMenuImage(_selectedImage);
      }

      final double finalPrice = _isRiceCurryRestaurant
          ? 0.0
          : (double.tryParse(priceController.text) ?? 0.0);

      final String finalDesc = _isRiceCurryRestaurant
          ? ""
          : descriptionController.text.trim();

      final Map<String, dynamic> requestData = {
        "menuId": widget.menuModel.menuId,
        "menuname": menuNameController.text.trim(),
        "description": finalDesc,
        "price": finalPrice,
        "extraprice": 0.0,
        "status": widget.menuModel.status ?? true,
        "imageUrl": imageUrl ?? "",
        "restaurantId": GlobalData.usernameRestaurant,
        "isRiceCurry": _isRiceCurryRestaurant,
        if (_selectedTypeMenuId != null) "typeMenuId": _selectedTypeMenuId,
        if (_newTypeName != null && _newTypeName!.isNotEmpty)
          "typeMenuName": _newTypeName,
      };

      await menuService.updateMenuByRestaurant(requestData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("อัปเดตเมนูสำเร็จ"),
            backgroundColor: _MenuTheme.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        setState(() {
          _isEditable = false;
          if (_selectedImage != null && imageUrl != null) {
            _existingImageUrl = imageUrl;
            _selectedImage = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("เกิดข้อผิดพลาด: $e"),
            backgroundColor: _MenuTheme.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration({
    String hint = "",
    Widget? suffixIcon,
    Color? fillColor,
    bool enabled = true,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _MenuTheme.textSecondary, fontSize: 14),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      filled: true,
      fillColor: enabled
          ? (fillColor ?? _MenuTheme.fieldBg)
          : const Color(0xFFF0F1F3),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _MenuTheme.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _MenuTheme.danger, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _MenuTheme.danger, width: 1.6),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _MenuTheme.surface,
        borderRadius: BorderRadius.circular(20),
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

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _MenuTheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: _MenuTheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _MenuTheme.textPrimary,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _MenuTheme.pageBg,
      extendBodyBehindAppBar: true,
      appBar: const RestaurantNavbar(title: ""),
      body: _isInitialLoading
          ? const Center(
              child: CircularProgressIndicator(color: _MenuTheme.primary),
            )
          : Form(
              key: formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 100),

                    // ── Hero header ────────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_MenuTheme.primary, Color(0xFFFFB13D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: _MenuTheme.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.edit_note_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "แก้ไขเมนู",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: _MenuTheme.textPrimary,
                                ),
                              ),
                              Text(
                                "ปรับปรุงรายละเอียดเมนูให้ตรงกับข้อมูลล่าสุด",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: _MenuTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // ── Section: หมวดหมู่เมนู (ประเภทเมนู) ───────────
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            icon: Icons.category_rounded,
                            title: "หมวดหมู่เมนู",
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "ประเภทเมนู",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _MenuTheme.textSecondary,
                                ),
                              ),
                              if (!_isRiceCurryRestaurant && _isEditable)
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(9),
                                    onTap: () {
                                      setState(() {
                                        _isAddingNewType = !_isAddingNewType;
                                        if (!_isAddingNewType) {
                                          _newTypeNameController.clear();
                                          _newTypeName = null;
                                        } else {
                                          _selectedTypeMenuId = null;
                                          _selectedTypeMenuName = null;
                                        }
                                      });
                                      if (_isAddingNewType) {
                                        FocusScope.of(context).unfocus();
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              if (mounted) {
                                                FocusScope.of(
                                                  context,
                                                ).requestFocus(
                                                  _newTypeFocusNode,
                                                );
                                              }
                                            });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _isAddingNewType
                                            ? _MenuTheme.primary
                                            : _MenuTheme.fieldBg,
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _isAddingNewType
                                                ? Icons.close_rounded
                                                : Icons.add_rounded,
                                            size: 14,
                                            color: _isAddingNewType
                                                ? Colors.white
                                                : _MenuTheme.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "เพิ่มใหม่",
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: _isAddingNewType
                                                  ? Colors.white
                                                  : _MenuTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          if (_isRiceCurryRestaurant)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F1F3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.lock_rounded,
                                    size: 18,
                                    color: _MenuTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedTypeMenuName ?? _riceCurryTypeName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _MenuTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (!_isAddingNewType)
                            _buildDropdown(
                              typeMenuList
                                  .where(
                                    (e) => e.typemenuName != _riceCurryTypeName,
                                  )
                                  .map((e) => e.typemenuName ?? "")
                                  .toList(),
                              _selectedTypeMenuName,
                              _isEditable
                                  ? (val) {
                                      setState(() {
                                        _selectedTypeMenuName = val;
                                        _selectedTypeMenuId = typeMenuList
                                            .firstWhere(
                                              (e) => e.typemenuName == val,
                                            )
                                            .typemenuId;
                                        _typeMenuError = null;
                                        _newTypeName = null;
                                      });
                                    }
                                  : null,
                            )
                          else
                            TextFormField(
                              controller: _newTypeNameController,
                              focusNode: _newTypeFocusNode,
                              enabled: _isEditable,
                              onChanged: (val) {
                                setState(() {
                                  _newTypeName = val.trim().isEmpty
                                      ? null
                                      : val.trim();
                                  _selectedTypeMenuId = null;
                                  _selectedTypeMenuName = null;
                                  _typeMenuError = null;
                                });
                              },
                              style: const TextStyle(fontSize: 14),
                              decoration: _inputDecoration(
                                hint: "ชื่อประเภทอาหารใหม่...",
                                enabled: _isEditable,
                              ),
                            ),

                          if (_typeMenuError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Text(
                                _typeMenuError!,
                                style: const TextStyle(
                                  color: _MenuTheme.danger,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ── Section: รูปภาพเมนู ──────────────────────────
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            icon: Icons.image_rounded,
                            title: "รูปภาพเมนู",
                          ),
                          const SizedBox(height: 14),
                          Center(
                            child: GestureDetector(
                              onTap: _isEditable ? pickImage : null,
                              child: Stack(
                                children: [
                                  Container(
                                    height: 190,
                                    width: 190,
                                    decoration: BoxDecoration(
                                      color: _MenuTheme.fieldBg,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _MenuTheme.border,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: _buildImagePreview(),
                                    ),
                                  ),
                                  if (_isEditable)
                                    Positioned(
                                      bottom: 6,
                                      right: 6,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: const BoxDecoration(
                                          color: _MenuTheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.edit_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (_imageError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Center(
                                child: Text(
                                  _imageError!,
                                  style: const TextStyle(
                                    color: _MenuTheme.danger,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ── Section: ข้อมูลเมนู ──────────────────────────
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            icon: Icons.receipt_long_rounded,
                            title: "ข้อมูลเมนู",
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            "ชื่อเมนู",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _MenuTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: menuNameController,
                            enabled: _isEditable,
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                ? "กรุณากรอกชื่อเมนู"
                                : null,
                            style: const TextStyle(fontSize: 14),
                            decoration: _inputDecoration(
                              hint: _isRiceCurryRestaurant
                                  ? "เช่น แกงไก่, ผัดผัก หรือ ไข่ดาว"
                                  : "เช่น ข้าวผัด, ผัดซีอิ๊ว",
                              enabled: _isEditable,
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (!_isRiceCurryRestaurant) ...[
                            const Text(
                              "รายละเอียด",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _MenuTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: descriptionController,
                              maxLines: 2,
                              enabled: _isEditable,
                              style: const TextStyle(fontSize: 14),
                              decoration: _inputDecoration(
                                hint: "รายละเอียดอาหารเพิ่มเติม...",
                                enabled: _isEditable,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          const Text(
                            "ราคา",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _MenuTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_isRiceCurryRestaurant)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _MenuTheme.accent.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _MenuTheme.accent.withOpacity(0.3),
                                ),
                              ),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: _MenuTheme.accent,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "ราคาข้าวราดแกง",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: _MenuTheme.textPrimary,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          "• 1 อย่าง 30 บาท\n• 2 อย่าง 35 บาท\n• 3 อย่าง 40 บาท",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: _MenuTheme.textSecondary,
                                            height: 1.6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            TextFormField(
                              controller: priceController,
                              enabled: _isEditable,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "กรุณากรอกราคาเมนู";
                                }
                                if (double.tryParse(value) == null) {
                                  return "ต้องเป็นตัวเลขเท่านั้น";
                                }
                                return null;
                              },
                              style: const TextStyle(fontSize: 14),
                              decoration: _inputDecoration(
                                hint: "0",
                                enabled: _isEditable,
                                suffixIcon: const Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: Center(
                                    widthFactor: 1,
                                    child: Text(
                                      "บาท",
                                      style: TextStyle(
                                        color: _MenuTheme.textSecondary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

      // ── แผงปุ่มควบคุมด้านล่าง (ตามสไตล์หน้า Profile ร้านค้า) ─────
      bottomNavigationBar: _isInitialLoading
          ? null
          : Container(
              color: _MenuTheme.pageBg,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: SafeArea(
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
                                  _initializeFromMenuModel();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _MenuTheme.textSecondary,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
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
                                  borderRadius: BorderRadius.circular(30),
                                  gradient: const LinearGradient(
                                    colors: [
                                      _MenuTheme.accent,
                                      Color(0xFF239E56),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _MenuTheme.accent.withOpacity(
                                        0.35,
                                      ),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _doSaveMenu,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          "บันทึกการแก้ไข",
                                          style: TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w700,
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
                              colors: [_MenuTheme.primary, Color(0xFFFFB13D)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _MenuTheme.primary.withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => setState(() => _isEditable = true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 20),
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
            ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage != null) {
      return Image.file(_selectedImage!, fit: BoxFit.cover);
    }
    final url = _getFinalImageUrl(_existingImageUrl);
    if (url.isNotEmpty) {
      return Image.network(
        Uri.encodeFull(url),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Center(
          child: Icon(
            Icons.image_outlined,
            size: 40,
            color: _MenuTheme.textSecondary.withOpacity(0.6),
          ),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_rounded,
            size: 40,
            color: _MenuTheme.textSecondary.withOpacity(0.6),
          ),
          const SizedBox(height: 8),
          Text(
            "แตะเพื่อเลือกรูป",
            style: TextStyle(
              fontSize: 12.5,
              color: _MenuTheme.textSecondary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    List<String> items,
    String? value,
    Function(String?)? onChanged,
  ) {
    final String? safeValue = (value != null && items.contains(value))
        ? value
        : null;
    final bool isEmpty = items.isEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _isEditable ? _MenuTheme.fieldBg : const Color(0xFFF0F1F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          hint: Text(
            isEmpty ? "ยังไม่มีประเภท" : "เลือกประเภท",
            style: const TextStyle(
              fontSize: 14,
              color: _MenuTheme.textSecondary,
            ),
          ),
          items: items.toSet().map((String e) {
            return DropdownMenuItem<String>(
              value: e,
              child: Text(e, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: _isEditable && !isEmpty ? onChanged : null,
        ),
      ),
    );
  }
}
