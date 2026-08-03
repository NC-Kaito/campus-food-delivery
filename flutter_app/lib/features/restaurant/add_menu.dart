// features/restaurant/add_menu.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/data/services/restaurant/type_restaurant_service.dart';
import 'package:flutter_app/features/restaurant/restaurant_navbar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_app/data/models/type_menu_model.dart';
import 'package:flutter_app/data/models/addon_menu_model.dart';
import 'package:flutter_app/data/services/menu/menu_service.dart';
import 'package:flutter_app/data/services/menu/type_menu_service.dart';
import 'package:flutter_app/global_data.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';

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

class CustomAddonItem {
  TextEditingController nameController;
  TextEditingController priceController;
  int? addonId;
  bool allowqtystatus;
  bool status;

  CustomAddonItem({
    required this.nameController,
    required this.priceController,
    this.addonId,
    this.allowqtystatus = false,
    this.status = true,
  });
}

class AddonGroupFormState {
  final TextEditingController groupNameController = TextEditingController();
  int maxSelect = 1;
  bool isRequired = true;
  final TextEditingController searchController = TextEditingController();
  List<AddonMenuModel> currentSearchResults = [];
  List<CustomAddonItem> selectedAddons = [];
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

  bool isAddonOn = false;
  bool _isLoading = false;
  bool _isAddingNewType = false;
  bool _isLoadingTypeMenu = true;
  bool _isLoadingRestaurant = true;
  bool _isRiceCurryRestaurant = false;

  List<AddonGroupFormState> addonGroups = [];
  List<AddonMenuModel> dbAddonList = [];
  List<TypeMenuModel> typeMenuList = [];

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
      print("ตรวจสอบประเภทร้านค้าผิดพลาด: $e");
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
      print("ไม่สามารถโหลดประเภทอาหารได้: $e");
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
    _clearAllAddonGroups();
    super.dispose();
  }

  void _clearAllAddonGroups() {
    for (var group in addonGroups) {
      group.groupNameController.dispose();
      group.searchController.dispose();
      for (var addon in group.selectedAddons) {
        addon.nameController.dispose();
        addon.priceController.dispose();
      }
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

  Future<void> _doSaveMenu() async {
    final isFormValid = formKey.currentState!.validate();

    setState(() {
      _imageError = _selectedImage == null
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
      final String? imageUrl = await menuService.uploadMenuImage(
        _selectedImage,
      );

      final double finalPrice = _isRiceCurryRestaurant
          ? 0.0
          : (double.tryParse(priceController.text) ?? 0.0);

      final String finalDesc = descriptionController.text.trim();

      final Map<String, dynamic> requestData = {
        "menuname": menuNameController.text.trim(),
        "description": finalDesc,
        "price": finalPrice,
        "extraprice": 0.0,
        "status": true,
        "imageUrl": imageUrl ?? "",
        "restaurantId": GlobalData.usernameRestaurant,
        "isRiceCurry": _isRiceCurryRestaurant,
        if (_selectedTypeMenuId != null) "typeMenuId": _selectedTypeMenuId,
        if (_newTypeName != null && _newTypeName!.isNotEmpty)
          "typeMenuName": _newTypeName,
      };

      if (isAddonOn) {
        requestData["addonGroups"] = addonGroups.map((group) {
          return {
            "addongroupname": group.groupNameController.text.trim(),
            "maxselect": group.maxSelect,
            "isRequired": group.isRequired,
            "details": group.selectedAddons.map((addon) {
              return {
                "addonid": addon.addonId,
                "customaddonname": addon.addonId == null
                    ? addon.nameController.text.trim()
                    : null,
                "addonprice":
                    double.tryParse(addon.priceController.text) ?? 0.0,
              };
            }).toList(),
          };
        }).toList();
      }

      await menuService.saveMenu(requestData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("บันทึกเมนูสำเร็จ"),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 100),

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
                      Icons.restaurant_menu_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "เพิ่มเมนูใหม่",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _MenuTheme.textPrimary,
                          ),
                        ),
                        Text(
                          "กรอกรายละเอียดเมนูให้ลูกค้าเห็นในร้านของคุณ",
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
                        if (!_isRiceCurryRestaurant)
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
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted) {
                                      FocusScope.of(
                                        context,
                                      ).requestFocus(_newTypeFocusNode);
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
                          color: _MenuTheme.fieldBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _MenuTheme.border),
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
                    else if (!_isAddingNewType) ...[
                      _isLoadingTypeMenu
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
                                  const Text(
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
                                    (e) => e.typemenuName != _riceCurryTypeName,
                                  )
                                  .map((e) => e.typemenuName ?? "")
                                  .toList(),
                              _selectedTypeMenuName,
                              (val) {
                                setState(() {
                                  _selectedTypeMenuName = val;
                                  _selectedTypeMenuId = typeMenuList
                                      .firstWhere((e) => e.typemenuName == val)
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
                  ],
                ),
              ),

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
                                border: Border.all(color: _MenuTheme.border),
                              ),
                              child: _selectedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_rounded,
                                          size: 40,
                                          color: _MenuTheme.textSecondary
                                              .withOpacity(0.6),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "แตะเพื่อเลือกรูป",
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: _MenuTheme.textSecondary
                                                .withOpacity(0.8),
                                          ),
                                        ),
                                      ],
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
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? "กรุณากรอกชื่อเมนู"
                          : null,
                      style: const TextStyle(fontSize: 14),
                      decoration: _inputDecoration(
                        hint: _isRiceCurryRestaurant
                            ? "เช่น แกงไก่, ผัดผัก หรือ ไข่ดาว"
                            : "เช่น ข้าวผัด, ผัดซีอิ๊ว",
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ซ่อนส่วนของรายละเอียดเมนูถ้าร้านเป็นประเภทร้านข้าวราดแกง
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
                        style: const TextStyle(fontSize: 14),
                        decoration: _inputDecoration(
                          hint: "รายละเอียดอาหารเพิ่มเติม...",
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
      bottomNavigationBar: SafeArea(
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
                          "บันทึกเมนู",
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
