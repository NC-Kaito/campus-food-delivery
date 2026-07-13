// features/restaurant/edit_menu.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/services/restaurant/type_restaurant_service.dart';
import 'package:flutter_app/features/restaurant/restaurant_navbar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/data/models/type_menu_model.dart';
import 'package:flutter_app/data/services/menu/menu_service.dart';
import 'package:flutter_app/data/services/menu/type_menu_service.dart';
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
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController menuNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController extraPriceController = TextEditingController();
  final TextEditingController _newTypeNameController = TextEditingController();
  final FocusNode _newTypeFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isInitialLoading = true;
  bool _isAddingNewType = false;
  bool _hasExtraPrice = false;
  bool _isRiceCurryMenu = false; // 🎯 ตรวจสอบและควบคุมสถานะข้าวราดแกง

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
    _loadAllData();
  }

  void _initializeFromMenuModel() {
    menuNameController.text = widget.menuModel.menuName ?? "";
    descriptionController.text = widget.menuModel.description ?? "";
    priceController.text = widget.menuModel.price?.toStringAsFixed(0) ?? "";
    _existingImageUrl = widget.menuModel.menuImage;
    _selectedTypeMenuId = widget.menuModel.typeMenuId;
    _selectedTypeMenuName = widget.menuModel.typeMenuName;

    // 🎯 ตรวจสอบฟล็กซ์สถานะว่าเป็นข้าวราดแกงหรือไม่ (เช็คเผื่อจากทั้ง Model direct หรือจากชื่อประเภทโมเดล)
    _isRiceCurryMenu = widget.menuModel.typeMenuName == _riceCurryTypeName;

    final double existingExtraPrice = widget.menuModel.extraprice ?? 0;
    _hasExtraPrice = !_isRiceCurryMenu && existingExtraPrice > 0;
    extraPriceController.text = _hasExtraPrice
        ? existingExtraPrice.toStringAsFixed(0)
        : "";
  }

  @override
  void dispose() {
    menuNameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    extraPriceController.dispose();
    _newTypeNameController.dispose();
    _newTypeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isInitialLoading = true);
    try {
      final types = await typeMenuService.getAllTypeMenu();

      if (!mounted) return;

      setState(() {
        typeMenuList = types;

        if (_isRiceCurryMenu) {
          final match = typeMenuList
              .where((e) => e.typemenuName == _riceCurryTypeName)
              .firstOrNull;
          if (match != null) {
            _selectedTypeMenuName = match.typemenuName;
            _selectedTypeMenuId = match.typemenuId;
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
                color: Colors.grey[300],
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

      // 🎯 ตรรกะปลอดภัยสอดคล้องกับหน้า AddMenu: บล็อกราคากลับเข้าส่วนกลาง 25 บาทหากตรวจพบโหมดข้าวราดแกง
      final double finalPrice = _isRiceCurryMenu
          ? 25.0
          : double.parse(priceController.text);
      final String finalDesc = _isRiceCurryMenu
          ? "เมนูข้าวราดแกง (ราคาตามเกณฑ์มหาวิทยาลัย)"
          : descriptionController.text.trim();

      final Map<String, dynamic> requestData = {
        "menuId": widget.menuModel.menuId,
        "menuname": menuNameController.text.trim(),
        "description": finalDesc,
        "price": finalPrice,
        "extraprice": !_isRiceCurryMenu && _hasExtraPrice
            ? (double.tryParse(extraPriceController.text.trim()) ?? 0.0)
            : 0.0,
        "status": widget.menuModel.status ?? true,
        "imageUrl": imageUrl ?? "",
        "restaurantId": GlobalData.usernameRestaurant,
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
        Navigator.pop(context);
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
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _MenuTheme.textSecondary, fontSize: 14),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      filled: true,
      fillColor: fillColor ?? _MenuTheme.fieldBg,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
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
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
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

  Widget _fieldLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _MenuTheme.textSecondary,
          ),
          children: required
              ? const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: _MenuTheme.danger),
                  ),
                ]
              : null,
        ),
      ),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isRiceCurryMenu
                                    ? "แก้ไขเมนูข้าวราดแกง"
                                    : "แก้ไขเมนู",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: _MenuTheme.textPrimary,
                                ),
                              ),
                              Text(
                                _isRiceCurryMenu
                                    ? "ปรับปรุงชื่อและรูปภาพเมนูข้าวราดแกงของร้าน"
                                    : "ปรับปรุงรายละเอียดเมนูให้ตรงกับข้อมูลล่าสุด",
                                style: const TextStyle(
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
                              onTap: pickImage,
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

                          _fieldLabel("ชื่อเมนู", required: true),
                          TextFormField(
                            controller: menuNameController,
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                ? "กรุณากรอกชื่อเมนู"
                                : null,
                            style: const TextStyle(fontSize: 14),
                            decoration: _inputDecoration(
                              hint: _isRiceCurryMenu
                                  ? "เช่น แกงเผ็ดหน่อไม้ไก่"
                                  : "เช่น กะเพราหมูกรอบ",
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _fieldLabel("ประเภทเมนู", required: true),
                              if (!_isRiceCurryMenu)
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
                                              if (mounted)
                                                FocusScope.of(
                                                  context,
                                                ).requestFocus(
                                                  _newTypeFocusNode,
                                                );
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
                          const SizedBox(height: 6),

                          // 🎯 [UI MATCHED] ถ้าเป็นข้าวราดแกงจะถูกล็อกประเภทตายตัว ไม่เปิดให้แอดประเภทใหม่
                          if (_isRiceCurryMenu) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _MenuTheme.accent.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _MenuTheme.accent.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 18,
                                    color: _MenuTheme.accent,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedTypeMenuName ?? _riceCurryTypeName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _MenuTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (!_isAddingNewType) ...[
                            typeMenuList.isEmpty
                                ? Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: _MenuTheme.fieldBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: _MenuTheme.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          "กำลังโหลดประเภทหมวดหมู่...",
                                          style: TextStyle(
                                            color: _MenuTheme.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : _buildDropdown(
                                    typeMenuList
                                        .where(
                                          (e) =>
                                              e.typemenuName !=
                                              _riceCurryTypeName,
                                        )
                                        .map((e) => e.typemenuName ?? "")
                                        .toList(),
                                    _selectedTypeMenuName,
                                    (val) {
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
                                    },
                                  ),
                          ] else ...[
                            TextFormField(
                              controller: _newTypeNameController,
                              focusNode: _newTypeFocusNode,
                              autofocus: true,
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
                                hint: "ชื่อประเภทอาหาร...",
                              ),
                            ),
                          ],

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
                          const SizedBox(height: 16),

                          // 🎯 [UI MATCHED] ซ่อนช่องกรอกรายละเอียดเมื่อตรวจพบว่าเป็นหมวดข้าวราดแกง
                          if (!_isRiceCurryMenu) ...[
                            _fieldLabel("รายละเอียด"),
                            TextFormField(
                              controller: descriptionController,
                              maxLines: 2,
                              style: const TextStyle(fontSize: 14),
                              decoration: _inputDecoration(
                                hint: "รายละเอียดอาหาร...",
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // 🎯 [UI MATCHED] ซ่อนช่องกรอกราคาราคาปกติ/พิเศษเมื่อเป็นข้าวราดแกง และโชว์ป้ายเกณฑ์ราคาควบคุมของมหาวิทยาลัยแทน
                          _isRiceCurryMenu
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _MenuTheme.primary.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _MenuTheme.primary.withOpacity(
                                        0.2,
                                      ),
                                    ),
                                  ),
                                  child: const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline_rounded,
                                            color: _MenuTheme.primary,
                                            size: 18,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            "เกณฑ์ราคาควบคุมของมหาวิทยาลัย",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: _MenuTheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        "• กับข้าว 1 อย่าง: 25 บาท",
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: _MenuTheme.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        "• กับข้าว 2 อย่าง: 30 บาท",
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: _MenuTheme.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        "• กับข้าว 3 อย่าง: 35 บาท",
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: _MenuTheme.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        "• ตัวเลือกเพิ่มข้าวปกติระบบจะบังคับเปิดใช้งานในหน้าเว็บฝั่งลูกค้า (+5 บาท)",
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: _MenuTheme.textSecondary,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _fieldLabel(
                                            "ราคาปกติ",
                                            required: true,
                                          ),
                                          TextFormField(
                                            controller: priceController,
                                            keyboardType: TextInputType.number,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.trim().isEmpty)
                                                return "กรุณากรอกราคาเมนู";
                                              if (double.tryParse(value) ==
                                                  null)
                                                return "กรุณากรอกตัวเลขที่ถูกต้อง";
                                              return null;
                                            },
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                            decoration: _inputDecoration(
                                              hint: "0",
                                              suffixIcon: const Padding(
                                                padding: EdgeInsets.only(
                                                  right: 12,
                                                ),
                                                child: Center(
                                                  widthFactor: 1,
                                                  child: Text(
                                                    "บาท",
                                                    style: TextStyle(
                                                      color: _MenuTheme
                                                          .textSecondary,
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Text(
                                                "พิเศษ",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      _MenuTheme.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              _buildExtraPriceToggle(),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: extraPriceController,
                                            enabled: _hasExtraPrice,
                                            keyboardType: TextInputType.number,
                                            validator: (value) {
                                              if (!_hasExtraPrice) return null;
                                              if (value == null ||
                                                  value.trim().isEmpty)
                                                return "กรอกราคาพิเศษ";
                                              if (double.tryParse(value) ==
                                                  null)
                                                return "ไม่ถูกต้อง";
                                              return null;
                                            },
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                            decoration: _inputDecoration(
                                              hint: "0",
                                              fillColor: _hasExtraPrice
                                                  ? _MenuTheme.fieldBg
                                                  : _MenuTheme.border,
                                              suffixIcon: const Padding(
                                                padding: EdgeInsets.only(
                                                  right: 12,
                                                ),
                                                child: Center(
                                                  widthFactor: 1,
                                                  child: Text(
                                                    "บาท",
                                                    style: TextStyle(
                                                      color: _MenuTheme
                                                          .textSecondary,
                                                      fontWeight:
                                                          FontWeight.w600,
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

      bottomNavigationBar: _isInitialLoading
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _doSaveMenu,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _MenuTheme.accent,
                      foregroundColor: Colors.white,
                      elevation: 6,
                      shadowColor: _MenuTheme.accent.withOpacity(0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 19),
                              SizedBox(width: 8),
                              Text(
                                "บันทึกการแก้ไข",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
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

  Widget _buildExtraPriceToggle() {
    return SizedBox(
      width: 40,
      height: 22,
      child: FittedBox(
        fit: BoxFit.fill,
        child: Switch(
          value: _hasExtraPrice,
          activeColor: Colors.white,
          activeTrackColor: _MenuTheme.primary,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey.shade300,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: (value) {
            setState(() {
              _hasExtraPrice = value;
              if (!_hasExtraPrice) {
                extraPriceController.clear();
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildDropdown(
    List<String> items,
    String? value,
    Function(String?) onChanged,
  ) {
    final String? safeValue = (value != null && items.contains(value))
        ? value
        : null;
    final bool isEmpty = items.isEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _MenuTheme.fieldBg,
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
          onChanged: isEmpty ? null : onChanged,
        ),
      ),
    );
  }
}
