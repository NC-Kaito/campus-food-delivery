// features/restaurant/add_menu.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/data/models/option_group_request_model.dart';
import 'package:flutter_app/data/models/type_menu_model.dart';
import 'package:flutter_app/data/services/menu/menu_service.dart';
import 'package:flutter_app/data/services/menu/type_menu_service.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/data/services/restaurant/type_restaurant_service.dart';
import 'package:flutter_app/features/restaurant/restaurant_navbar.dart';
import 'package:flutter_app/global_data.dart';
import 'package:image_picker/image_picker.dart';

const String _riceCurryTypeName = "ข้าวราดแกง";

class _MenuTheme {
  static const Color primary = Color(0xFFFF8A00);
  static const Color primaryLight = Color(0xFFFFF3E0);
  static const Color accent = Color(0xFF10B981); // Emerald Green
  static const Color danger = Color(0xFFEF4444); // Soft Red
  static const Color surface = Colors.white;
  static const Color pageBg = Color(0xFFF3F4F6); // Soft Light Gray
  static const Color textPrimary = Color(0xFF111827); // Dark Gray
  static const Color textSecondary = Color(0xFF6B7280); // Medium Gray
  static const Color fieldBg = Color(0xFFF9FAFB); // Very Light Gray
}

// 🎯 คลาสเก็บข้อมูลกลุ่มตัวเลือก (Option Group)
class DraftOptionGroup {
  TextEditingController nameController = TextEditingController();

  // 🎯 ตั้งค่าเริ่มต้นเป็น false (ปิด)
  bool isRequired = false;

  // 🎯 ตั้งค่าเริ่มต้นเป็น true เพื่อให้สวิตช์ "เลือกได้ 1 อย่าง" (!isMultipleChoice) เริ่มต้นที่ false (ปิด)
  bool isMultipleChoice = true;
  List<DraftOption> options = [];

  void dispose() {
    nameController.dispose();
    for (var opt in options) {
      opt.dispose();
    }
  }
}

// 🎯 คลาสเก็บข้อมูลตัวเลือกย่อย (Option)
class DraftOption {
  TextEditingController nameController = TextEditingController();
  TextEditingController priceController = TextEditingController();

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }
}

class AddMenu extends StatefulWidget {
  const AddMenu({super.key});

  @override
  State<AddMenu> createState() => _AddMenuState();
}

class _AddMenuState extends State<AddMenu> {
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

  final List<DraftOptionGroup> _draftOptionGroups = [];

  bool _isLoading = false;
  bool _isAddingNewType = false;
  bool _isLoadingTypeMenu = true;
  bool _isLoadingRestaurant = true;
  bool _isRiceCurryRestaurant = false;

  List<TypeMenuModel> typeMenuList = [];
  List<MenuModel> existingMenuList = [];

  int? _selectedTypeMenuId;
  String? _selectedTypeMenuName;
  String? _newTypeName;
  File? _selectedImage;
  String? _imageError;
  String? _typeMenuError;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _checkRestaurantType();
    await fetchTypeMenus();
    await _fetchExistingMenus();
  }

  Future<void> _fetchExistingMenus() async {
    try {
      final username = GlobalData.usernameRestaurant ?? "";
      if (username.isNotEmpty) {
        final menus = await menuService.getMenusByRestaurant(username);
        setState(() {
          existingMenuList = menus;
        });
      }
    } catch (e) {
      debugPrint("ไม่สามารถโหลดเมนูเดิมของร้านได้: $e");
    }
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
    } finally {
      if (mounted) setState(() => _isLoadingRestaurant = false);
    }
  }

  Future<void> fetchTypeMenus() async {
    try {
      final types = await typeMenuService.getAllTypeMenu();
      setState(() {
        typeMenuList = types;
      });

      if (_isRiceCurryRestaurant) {
        final match = typeMenuList
            .where((e) => e.typemenuName == _riceCurryTypeName)
            .firstOrNull;
        if (match != null) {
          setState(() {
            _selectedTypeMenuName = match.typemenuName;
            _selectedTypeMenuId = match.typemenuId;
            _typeMenuError = null;
          });
        } else {
          setState(() {
            _selectedTypeMenuName = _riceCurryTypeName;
            _newTypeName = _riceCurryTypeName;
            _typeMenuError = null;
          });
        }
      }
    } catch (e) {
      debugPrint("ไม่สามารถโหลดประเภทอาหารได้: $e");
    } finally {
      if (mounted) setState(() => _isLoadingTypeMenu = false);
    }
  }

  @override
  void dispose() {
    menuNameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    _newTypeNameController.dispose();
    _newTypeFocusNode.dispose();

    for (var group in _draftOptionGroups) {
      group.dispose();
    }
    super.dispose();
  }

  Future<void> pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: _MenuTheme.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: _MenuTheme.primary,
                  ),
                ),
                title: const Text(
                  "ถ่ายรูปด้วยกล้อง",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );
                  if (image != null)
                    setState(() {
                      _selectedImage = File(image.path);
                      _imageError = null;
                    });
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: _MenuTheme.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: _MenuTheme.primary,
                  ),
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
                    setState(() {
                      _selectedImage = File(image.path);
                      _imageError = null;
                    });
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _addNewOptionGroup() {
    setState(() {
      final newGroup = DraftOptionGroup();
      newGroup.options.add(DraftOption());
      _draftOptionGroups.add(newGroup);
    });
  }

  void _removeOptionGroup(int index) {
    setState(() {
      _draftOptionGroups[index].dispose();
      _draftOptionGroups.removeAt(index);
    });
  }

  void _addNewOptionToGroup(DraftOptionGroup group) {
    setState(() {
      group.options.add(DraftOption());
    });
  }

  void _removeOptionFromGroup(DraftOptionGroup group, int optionIndex) {
    setState(() {
      group.options[optionIndex].dispose();
      group.options.removeAt(optionIndex);
    });
  }

  Future<void> _doSaveMenu() async {
    final isFormValid = formKey.currentState!.validate();

    setState(() {
      _imageError = _selectedImage == null
          ? "กรุณาเลือกรูปภาพอาหารประกอบด้วยนะครับ"
          : null;
      _typeMenuError =
          (_selectedTypeMenuId == null &&
              (_newTypeName == null || _newTypeName!.isEmpty))
          ? "อย่าลืมเลือกหมวดหมู่เมนูนะ"
          : null;
    });

    bool hasOptionError = false;
    for (var group in _draftOptionGroups) {
      if (group.nameController.text.trim().isEmpty) hasOptionError = true;
      for (var opt in group.options) {
        if (opt.nameController.text.trim().isEmpty) hasOptionError = true;
      }
    }

    if (!isFormValid ||
        _imageError != null ||
        _typeMenuError != null ||
        hasOptionError) {
      if (hasOptionError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "กรุณากรอกชื่อกลุ่มและชื่อตัวเลือกเสริมให้ครบถ้วนด้วยนะครับ",
            ),
            backgroundColor: _MenuTheme.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    final String enteredMenuName = menuNameController.text.trim();
    final bool isDuplicate = existingMenuList.any(
      (m) =>
          (m.menuName ?? "").trim().toLowerCase() ==
          enteredMenuName.toLowerCase(),
    );

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "ชื่อเมนู \"$enteredMenuName\" มีอยู่ในระบบแล้วครับ ลองใช้ชื่ออื่นดูนะครับ",
          ),
          backgroundColor: _MenuTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String? imageUrl = await menuService.uploadMenuImage(
        _selectedImage,
      );
      final double finalPrice = _isRiceCurryRestaurant
          ? 0.0
          : (double.tryParse(priceController.text) ?? 0.0);
      final String finalDesc = descriptionController.text.trim();

      final List<Map<dynamic, dynamic>> optionGroupsData = _draftOptionGroups
          .map((group) {
            final requestGroup = OptionGroupRequestModel(
              optionGroupName: group.nameController.text.trim(),
              isRequired: group.isRequired,
              isMultipleChoice: group.isMultipleChoice,
              options: group.options.map((opt) {
                return OptionDetailRequestModel(
                  optionName: opt.nameController.text.trim(),
                  optionPrice: double.tryParse(opt.priceController.text) ?? 0.0,
                );
              }).toList(),
            );
            return requestGroup.toJson();
          })
          .toList();

      final Map<String, dynamic> requestData = {
        "menuname": enteredMenuName,
        "description": finalDesc,
        "price": finalPrice,
        "extraprice": 0.0,
        "status": true,
        "imageurl": imageUrl ?? "",
        "username": GlobalData.usernameRestaurant,
        "isRiceCurry": _isRiceCurryRestaurant,
        if (_selectedTypeMenuId != null) "typeMenuId": _selectedTypeMenuId,
        if (_newTypeName != null && _newTypeName!.isNotEmpty)
          "typeMenuName": _newTypeName,
        if (optionGroupsData.isNotEmpty) "optionGroups": optionGroupsData,
      };

      await menuService.saveMenu(requestData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "บันทึกเมนูพร้อมตัวเลือกเสริมเรียบร้อยแล้วครับ!",
            ),
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
            content: Text("เกิดข้อผิดพลาดนิดหน่อยครับ: $e"),
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

  // 🎨 Input Style แบบคลีนไร้ขอบ
  InputDecoration _cleanInputDecoration({
    String hint = "",
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _MenuTheme.fieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _MenuTheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _MenuTheme.danger, width: 1.2),
      ),
    );
  }

  // 🎨 การ์ดสไตล์นุ่มนวล
  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _MenuTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _MenuTheme.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: _MenuTheme.primary),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _MenuTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRestaurant) {
      return const Scaffold(
        backgroundColor: _MenuTheme.pageBg,
        body: Center(
          child: CircularProgressIndicator(color: _MenuTheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _MenuTheme.pageBg,
      extendBodyBehindAppBar: true,
      appBar: const RestaurantNavbar(title: ""),
      body: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 110),

              // ── Header ──
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_MenuTheme.primary, Color(0xFFFFB13D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _MenuTheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "เพิ่มเมนูใหม่",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _MenuTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "กรอกรายละเอียดเมนูเพื่อให้ลูกค้าเลือกสั่งได้เลยครับ",
                          style: TextStyle(
                            fontSize: 13,
                            color: _MenuTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── 1. หมวดหมู่เมนู ──
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      icon: Icons.grid_view_rounded,
                      title: "หมวดหมู่เมนู",
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "เลือกประเภทเมนู",
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: _MenuTheme.textPrimary,
                          ),
                        ),
                        if (!_isRiceCurryRestaurant)
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
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
                                _typeMenuError = null;
                              });
                              if (_isAddingNewType) {
                                FocusScope.of(context).unfocus();
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted)
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(_newTypeFocusNode);
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _isAddingNewType
                                    ? _MenuTheme.primary
                                    : _MenuTheme.fieldBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _isAddingNewType
                                        ? Icons.close_rounded
                                        : Icons.add_rounded,
                                    size: 14,
                                    color: _isAddingNewType
                                        ? Colors.white
                                        : _MenuTheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isAddingNewType ? "ยกเลิก" : "เพิ่มใหม่",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _isAddingNewType
                                          ? Colors.white
                                          : _MenuTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_isRiceCurryRestaurant)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _MenuTheme.fieldBg,
                          borderRadius: BorderRadius.circular(14),
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
                                fontWeight: FontWeight.w600,
                                color: _MenuTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (!_isAddingNewType)
                      _buildDropdown()
                    else
                      TextFormField(
                        controller: _newTypeNameController,
                        focusNode: _newTypeFocusNode,
                        validator: (value) =>
                            (_isAddingNewType &&
                                (value == null || value.trim().isEmpty))
                            ? "ช่วยกรอกชื่อประเภทอาหารด้วยนะครับ"
                            : null,
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
                        decoration: _cleanInputDecoration(
                          hint: "พิมพ์หมวดหมู่ใหม่ เช่น ยำ, เครื่องดื่ม...",
                        ),
                      ),

                    if (_typeMenuError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
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

              // ── 2. รูปภาพเมนู ──
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      icon: Icons.image_rounded,
                      title: "รูปภาพเมนู",
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: pickImage,
                        child: Container(
                          height: 160,
                          width: 160,
                          decoration: BoxDecoration(
                            color: _MenuTheme.fieldBg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _imageError != null
                                  ? _MenuTheme.danger
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (_selectedImage != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add_photo_alternate_rounded,
                                        size: 28,
                                        color: _MenuTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      "แตะเพื่อเลือกรูป",
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: _MenuTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: _MenuTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
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

              // ── 3. ข้อมูลเมนู ──
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      icon: Icons.receipt_long_rounded,
                      title: "ข้อมูลเมนู",
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      "ชื่อเมนู",
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _MenuTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: menuNameController,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? "อย่าลืมตั้งชื่อเมนูนะครับ"
                          : null,
                      style: const TextStyle(fontSize: 14),
                      decoration: _cleanInputDecoration(
                        hint: _isRiceCurryRestaurant
                            ? "เช่น แกงไก่, ผัดผัก"
                            : "เช่น ข้าวผัด, ผัดซีอิ๊ว",
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (!_isRiceCurryRestaurant) ...[
                      const Text(
                        "รายละเอียด (ตัวเลือก)",
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _MenuTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 14),
                        decoration: _cleanInputDecoration(
                          hint: "อธิบายความอร่อยของเมนูนี้ซักหน่อย...",
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const Text(
                      "ราคา",
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _MenuTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (_isRiceCurryRestaurant)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _MenuTheme.accent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: _MenuTheme.accent,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "ราคาข้าวราดแกง",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _MenuTheme.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "• 1 อย่าง 30 บาท\n• 2 อย่าง 35 บาท\n• 3 อย่าง 40 บาท",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _MenuTheme.textSecondary,
                                      height: 1.5,
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
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return "รบกวนระบุราคาด้วยนะครับ";
                          return null;
                        },
                        style: const TextStyle(fontSize: 14),
                        decoration: _cleanInputDecoration(
                          hint: "0",
                          suffixIcon: const Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: Center(
                              widthFactor: 1,
                              child: Text(
                                "บาท",
                                style: TextStyle(
                                  color: _MenuTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── 4. ตัวเลือกเสริม ──
              if (!_isRiceCurryRestaurant) ...[
                const Padding(
                  padding: EdgeInsets.only(
                    left: 4,
                    right: 4,
                    bottom: 12,
                    top: 8,
                  ),
                  child: Text(
                    "ตัวเลือกเสริม (Add-on)",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _MenuTheme.textPrimary,
                    ),
                  ),
                ),

                if (_draftOptionGroups.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 32,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "ยังไม่มีตัวเลือกเสริม",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "เช่น ระดับความหวาน, เพิ่มท็อปปิ้ง",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),

                for (int i = 0; i < _draftOptionGroups.length; i++)
                  _buildOptionGroupSection(_draftOptionGroups[i], i),

                // 🎯 ปุ่ม "เพิ่มกลุ่มตัวเลือก" ถูกย้ายมาไว้ด้านล่างสุดของส่วนตัวเลือกเสริม
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addNewOptionGroup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _MenuTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text(
                      "เพิ่มกลุ่มตัวเลือก",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20), // Spacer for bottom nav
            ],
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _doSaveMenu,
              style: ElevatedButton.styleFrom(
                backgroundColor: _MenuTheme.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      "บันทึกเมนู",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // 🎯 Dropdown แบบคลีน
  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _MenuTheme.fieldBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _typeMenuError != null
              ? _MenuTheme.danger
              : Colors.transparent,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTypeMenuName,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _MenuTheme.textSecondary,
          ),
          hint: const Text(
            "เลือกประเภทหมวดหมู่",
            style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
          ),
          items: typeMenuList
              .where((e) => e.typemenuName != _riceCurryTypeName)
              .map((e) => e.typemenuName ?? "")
              .toSet()
              .map((String e) {
                return DropdownMenuItem<String>(
                  value: e,
                  child: Text(
                    e,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _MenuTheme.textPrimary,
                    ),
                  ),
                );
              })
              .toList(),
          onChanged: (val) {
            setState(() {
              _selectedTypeMenuName = val;
              _selectedTypeMenuId = typeMenuList
                  .firstWhere((e) => e.typemenuName == val)
                  .typemenuId;
              _typeMenuError = null;
            });
          },
        ),
      ),
    );
  }

  // 🎯 การ์ดข้อมูลกลุ่มตัวเลือกแบบพรีเมียม สบายตา
  Widget _buildOptionGroupSection(DraftOptionGroup group, int groupIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _MenuTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── หัวข้อ: ข้อมูลกลุ่มตัวเลือก ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _MenuTheme.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.list_alt_rounded,
                      size: 16,
                      color: _MenuTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "กลุ่มตัวเลือกที่ ${groupIndex + 1}",
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: _MenuTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _removeOptionGroup(groupIndex),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: _MenuTheme.danger,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: group.nameController,
            validator: (value) => (value == null || value.trim().isEmpty)
                ? "กรุณากรอกชื่อกลุ่ม"
                : null,
            style: const TextStyle(fontSize: 14),
            decoration: _cleanInputDecoration(
              hint: "ชื่อกลุ่ม เช่น ระดับความหวาน, ท็อปปิ้ง",
            ),
          ),
          const SizedBox(height: 12),

          // 🎯 สวิตช์ตั้งค่า (จัดเรียงแนวตั้งแบบ Clean)
          Container(
            decoration: BoxDecoration(
              color: _MenuTheme.fieldBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    "ลูกค้าเลือกได้เพียง 1 อย่าง",
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _MenuTheme.textPrimary,
                    ),
                  ),
                  value: !group.isMultipleChoice,
                  activeColor: Colors.white,
                  activeTrackColor: _MenuTheme.primary,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey.shade300,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                  dense: true,
                  onChanged: (val) =>
                      setState(() => group.isMultipleChoice = !val),
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Colors.grey.shade200,
                ),
                SwitchListTile(
                  title: const Text(
                    "จำเป็นต้องเลือก",
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _MenuTheme.textPrimary,
                    ),
                  ),
                  value: group.isRequired,
                  activeColor: Colors.white,
                  activeTrackColor: _MenuTheme.accent,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey.shade300,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                  dense: true,
                  onChanged: (val) => setState(() => group.isRequired = val),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
          ),

          // ── หัวข้อ: รายการย่อย ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "รายการย่อย",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _MenuTheme.textPrimary,
                ),
              ),
              Text(
                "${group.options.length} รายการ",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _MenuTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          for (int j = 0; j < group.options.length; j++)
            _buildDraftOptionItemRow(group, j),

          const SizedBox(height: 8),

          // ปุ่ม "+ เพิ่มตัวเลือก"
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _addNewOptionToGroup(group),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: _MenuTheme.textSecondary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    "เพิ่มรายการ",
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _MenuTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 แถวตัวเลือกย่อย (Clean Row ไร้กรอบหนักๆ และไม่มีปุ่มลาก)
  Widget _buildDraftOptionItemRow(DraftOptionGroup group, int optionIndex) {
    final DraftOption option = group.options[optionIndex];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: TextFormField(
              controller: option.nameController,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? "กรอกชื่อ" : null,
              style: const TextStyle(fontSize: 13.5),
              decoration: _cleanInputDecoration(hint: "ชื่อตัวเลือก"),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: option.priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 13.5),
              decoration: _cleanInputDecoration(hint: "+ 0").copyWith(
                prefixText: "฿ ",
                prefixStyle: const TextStyle(
                  color: _MenuTheme.textSecondary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _removeOptionFromGroup(group, optionIndex),
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.remove_circle_outline_rounded,
                color: _MenuTheme.danger,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
