// features/restaurant/edit_menu.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/data/models/option_group_request_model.dart';
import 'package:flutter_app/data/models/type_menu_model.dart';
import 'package:flutter_app/data/services/menu/menu_service.dart';
import 'package:flutter_app/data/services/menu/type_menu_service.dart';
import 'package:flutter_app/data/services/menu/menu_option_service.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/data/services/restaurant/type_restaurant_service.dart';
import 'package:flutter_app/features/restaurant/restaurant_navbar.dart';
import 'package:flutter_app/core/network/dio_client.dart';
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
  static const Color border = Color(0xFFE7E8EC);
}

// 🎯 คลาสเก็บข้อมูลกลุ่มตัวเลือก (Option Group)
class DraftOptionGroup {
  int? optionGroupId;
  TextEditingController nameController = TextEditingController();

  bool isRequired = false;
  bool isMultipleChoice = false;
  List<DraftOption> options = [];

  DraftOptionGroup({
    this.optionGroupId,
    String name = "",
    this.isRequired = false,
    this.isMultipleChoice = false,
    List<DraftOption>? initialOptions,
  }) {
    nameController.text = name;
    if (initialOptions != null) {
      options.addAll(initialOptions);
    }
  }

  void dispose() {
    nameController.dispose();
    for (var opt in options) {
      opt.dispose();
    }
  }
}

// 🎯 คลาสเก็บข้อมูลตัวเลือกย่อย (Option)
class DraftOption {
  int? optionId;
  TextEditingController nameController = TextEditingController();
  TextEditingController priceController = TextEditingController();

  DraftOption({this.optionId, String name = "", double price = 0.0}) {
    nameController.text = name;
    priceController.text = price % 1 == 0
        ? price.toInt().toString()
        : price.toString();
  }

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }
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
  final MenuOptionService _optionService = MenuOptionService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController menuNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController _newTypeNameController = TextEditingController();
  final FocusNode _newTypeFocusNode = FocusNode();

  final List<DraftOptionGroup> _draftOptionGroups = [];

  bool _isLoading = false;
  bool _isInitialLoading = true;
  bool _isAddingNewType = false;
  bool _isEditable = false;
  bool _isRiceCurryRestaurant = false;

  bool _isAddonEnabled = false;

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
    priceController.text = widget.menuModel.price != null
        ? (widget.menuModel.price! % 1 == 0
              ? widget.menuModel.price!.toInt().toString()
              : widget.menuModel.price!.toString())
        : "";
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

    for (var group in _draftOptionGroups) {
      group.dispose();
    }
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

      List<DraftOptionGroup> loadedDraftGroups = [];
      final int? menuId = widget.menuModel.menuId;

      if (menuId != null) {
        final existingGroups = await _optionService.getOptionsByMenuId(menuId);

        for (var grp in existingGroups) {
          final List<DraftOption> groupOptions = [];
          if (grp.options != null) {
            for (var opt in grp.options!) {
              groupOptions.add(
                DraftOption(
                  optionId: opt.optionId,
                  name: opt.optionName ?? "",
                  price: opt.optionPrice ?? 0.0,
                ),
              );
            }
          }

          loadedDraftGroups.add(
            DraftOptionGroup(
              optionGroupId: grp.optionGroupId,
              name: grp.optionGroupName ?? "",
              isRequired: grp.isRequired,
              isMultipleChoice: grp.isMultipleChoice,
              initialOptions: groupOptions,
            ),
          );
        }
      }

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

        for (var g in _draftOptionGroups) {
          g.dispose();
        }
        _draftOptionGroups.clear();
        _draftOptionGroups.addAll(loadedDraftGroups);

        _isAddonEnabled = _draftOptionGroups.isNotEmpty;

        _isInitialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isInitialLoading = false);
      debugPrint("EditMenu _loadAllData error: $e");
    }
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

  Future<void> pickImage() async {
    if (!_isEditable) return;
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
                  if (image != null) {
                    setState(() {
                      _selectedImage = File(image.path);
                      _imageError = null;
                    });
                  }
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
      ),
    );
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;
    final String baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/')
        ? baseUrl + rawPath
        : baseUrl + '/' + rawPath;
  }

  Future<void> _doSaveMenu() async {
    final isFormValid = formKey.currentState!.validate();

    setState(() {
      _imageError =
          (_selectedImage == null &&
              (_existingImageUrl == null || _existingImageUrl!.isEmpty))
          ? "กรุณาเลือกรูปภาพอาหารประกอบด้วยนะครับ"
          : null;
      _typeMenuError =
          (_selectedTypeMenuId == null &&
              (_newTypeName == null || _newTypeName!.isEmpty))
          ? "กรุณาเลือกหรือกรอกประเภทหมวดหมู่เมนูนะ"
          : null;
    });

    bool hasOptionError = false;
    if (_isAddonEnabled) {
      for (var group in _draftOptionGroups) {
        if (group.nameController.text.trim().isEmpty) hasOptionError = true;
        for (var opt in group.options) {
          if (opt.nameController.text.trim().isEmpty) hasOptionError = true;
        }
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

    setState(() => _isLoading = true);

    try {
      String? imageUrl = _existingImageUrl;
      if (_selectedImage != null) {
        imageUrl = await menuService.uploadMenuImage(_selectedImage);
      }

      // 🎯 ถ้าเป็นข้าวราดแกงให้ราคาเป็น 0 อัตโนมัติ
      final double finalPrice = _isRiceCurryRestaurant
          ? 0.0
          : (double.tryParse(priceController.text) ?? 0.0);

      final String finalDesc = _isRiceCurryRestaurant
          ? ""
          : descriptionController.text.trim();

      final List<Map<dynamic, dynamic>> optionGroupsData = _isAddonEnabled
          ? _draftOptionGroups.map((group) {
              final requestGroup = OptionGroupRequestModel(
                optionGroupId: group.optionGroupId,
                menuId: widget.menuModel.menuId,
                optionGroupName: group.nameController.text.trim(),
                isRequired: group.isRequired,
                isMultipleChoice: group.isMultipleChoice,
                options: group.options.map((opt) {
                  return OptionDetailRequestModel(
                    optionId: opt.optionId,
                    optionName: opt.nameController.text.trim(),
                    optionPrice:
                        double.tryParse(opt.priceController.text) ?? 0.0,
                  );
                }).toList(),
              );
              return requestGroup.toJson();
            }).toList()
          : [];

      final Map<String, dynamic> requestData = {
        "menuid": widget.menuModel.menuId,
        "menuId": widget.menuModel.menuId,
        "menuname": menuNameController.text.trim(),
        "description": finalDesc,
        "price": finalPrice,
        "extraprice": 0.0,
        "status": widget.menuModel.status ?? true,
        "imageurl": imageUrl ?? "",
        "imageUrl": imageUrl ?? "",
        "username": GlobalData.usernameRestaurant,
        "restaurantId": GlobalData.usernameRestaurant,
        "isRiceCurry": _isRiceCurryRestaurant,
        if (_selectedTypeMenuId != null) "typeMenuId": _selectedTypeMenuId,
        if (_newTypeName != null && _newTypeName!.isNotEmpty)
          "typeMenuName": _newTypeName,
        if (optionGroupsData.isNotEmpty || !_isAddonEnabled)
          "optionGroups": optionGroupsData,
      };

      await menuService.updateMenuByRestaurant(requestData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "อัปเดตเมนูและตัวเลือกเสริมสำเร็จเรียบร้อยครับ!",
            ),
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

        await _loadAllData();
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString().replaceAll("Exception: ", "");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("เกิดข้อผิดพลาด: $errorMsg"),
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

  InputDecoration _cleanInputDecoration({
    String hint = "",
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: enabled ? _MenuTheme.fieldBg : const Color(0xFFF0F1F3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      disabledBorder: OutlineInputBorder(
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
                            Icons.edit_note_rounded,
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
                                "แก้ไขเมนู",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: _MenuTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "ปรับปรุงรายละเอียดเมนูและตัวเลือกให้ตรงกับล่าสุด",
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
                              if (!_isRiceCurryRestaurant && _isEditable)
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
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
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
                                          _isAddingNewType
                                              ? "ยกเลิก"
                                              : "เพิ่มใหม่",
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
                                hint:
                                    "พิมพ์หมวดหมู่ใหม่ เช่น ยำ, เครื่องดื่ม...",
                                enabled: _isEditable,
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

                    // ── 3. ข้อมูลเมนู ──
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            icon: Icons.receipt_long_rounded,
                            title: "ข้อมูลเมนู",
                          ),
                          const SizedBox(height: 15),
                          Center(
                            child: GestureDetector(
                              onTap: _isEditable ? pickImage : null,
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
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: _buildImagePreview(),
                                    ),
                                    if (_isEditable)
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

                          const SizedBox(height: 15),

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
                            enabled: _isEditable,
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                ? "อย่าลืมตั้งชื่อเมนูนะครับ"
                                : null,
                            style: const TextStyle(fontSize: 14),
                            decoration: _cleanInputDecoration(
                              hint: _isRiceCurryRestaurant
                                  ? "เช่น แกงไก่, ผัดผัก"
                                  : "เช่น ข้าวผัด, ผัดซีอิ๊ว",
                              enabled: _isEditable,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 🎯 ซ่อนรายละเอียดและราคาถ้าเป็นข้าวราดแกง
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
                              enabled: _isEditable,
                              style: const TextStyle(fontSize: 14),
                              decoration: _cleanInputDecoration(
                                hint: "อธิบายความอร่อยของเมนูนี้ซักหน่อย...",
                                enabled: _isEditable,
                              ),
                            ),
                            const SizedBox(height: 16),

                            const Text(
                              "ราคา",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _MenuTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: priceController,
                              enabled: _isEditable,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "กรุณากรอกราคาเมนูครับ";
                                }
                                return null;
                              },
                              style: const TextStyle(fontSize: 14),
                              decoration:
                                  _cleanInputDecoration(
                                    hint: "0",
                                    enabled: _isEditable,
                                  ).copyWith(
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
                        ],
                      ),
                    ),

                    // ── 4. ตัวเลือกเสริม ──
                    if (!_isRiceCurryRestaurant) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 4,
                          right: 4,
                          bottom: 12,
                          top: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "ตัวเลือกเสริม (Add-on)",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _MenuTheme.textPrimary,
                              ),
                            ),
                            Switch(
                              value: _isAddonEnabled,
                              activeColor: Colors.white,
                              activeTrackColor: const Color(0xFF65C466),
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: Colors.grey.shade300,
                              onChanged: _isEditable
                                  ? (val) {
                                      setState(() {
                                        _isAddonEnabled = val;
                                        if (val && _draftOptionGroups.isEmpty) {
                                          _addNewOptionGroup();
                                        }
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),

                      if (_isAddonEnabled) ...[
                        for (int i = 0; i < _draftOptionGroups.length; i++)
                          _buildOptionGroupSection(_draftOptionGroups[i], i),

                        if (_isEditable) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _addNewOptionGroup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _MenuTheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
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
                      ],
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

      // ── แผงปุ่มด้านล่าง ──
      bottomNavigationBar: _isInitialLoading
          ? null
          : Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                                  _loadAllData();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _MenuTheme.textSecondary,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
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
                        ],
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() => _isEditable = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _MenuTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _isEditable ? _MenuTheme.fieldBg : const Color(0xFFF0F1F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _typeMenuError != null
              ? _MenuTheme.danger
              : Colors.transparent,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _MenuTheme.textSecondary,
          ),
          hint: Text(
            isEmpty ? "ยังไม่มีประเภท" : "เลือกประเภทหมวดหมู่",
            style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
          ),
          items: items.toSet().map((String e) {
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
          }).toList(),
          onChanged: _isEditable && !isEmpty ? onChanged : null,
        ),
      ),
    );
  }

  Widget _buildOptionGroupSection(DraftOptionGroup group, int groupIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
              if (_isEditable)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _removeOptionGroup(groupIndex),
                  child: Container(
                    padding: const EdgeInsets.all(8),
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

          const Text(
            "ชื่อกลุ่มตัวเลือก",
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: _MenuTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: group.nameController,
            enabled: _isEditable,
            validator: (value) => (value == null || value.trim().isEmpty)
                ? "กรุณากรอกชื่อกลุ่ม"
                : null,
            style: const TextStyle(fontSize: 14),
            decoration: _cleanInputDecoration(
              hint: "ชื่อกลุ่ม เช่น ระดับความหวาน, ท็อปปิ้ง",
              enabled: _isEditable,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: group.isRequired,
                  activeColor: _MenuTheme.primary,
                  onChanged: _isEditable
                      ? (val) => setState(() => group.isRequired = val ?? false)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "จำเป็นต้องเลือกไหม",
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: _MenuTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: group.isMultipleChoice,
                  activeColor: _MenuTheme.primary,
                  onChanged: _isEditable
                      ? (val) => setState(
                          () => group.isMultipleChoice = val ?? false,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "ลูกค้าเลือกได้หลายอย่าง",
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: _MenuTheme.textPrimary,
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
          ),

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
              if (_isEditable)
                InkWell(
                  onTap: () => _addNewOptionToGroup(group),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade600,
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.add,
                          size: 16,
                          color: _MenuTheme.textSecondary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "เพิ่มรายการ",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _MenuTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              const Expanded(
                flex: 5,
                child: Text(
                  "ชื่อตัวเลือก",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _MenuTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                flex: 3,
                child: Text(
                  "ราคา",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _MenuTheme.textPrimary,
                  ),
                ),
              ),
              if (_isEditable) const SizedBox(width: 56),
            ],
          ),
          const SizedBox(height: 8),

          for (int j = 0; j < group.options.length; j++)
            _buildDraftOptionItemRow(group, j),
        ],
      ),
    );
  }

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
              enabled: _isEditable,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? "กรอกชื่อ" : null,
              style: const TextStyle(
                fontSize: 13.5,
                color: _MenuTheme.textPrimary,
              ),
              decoration: _cleanInputDecoration(
                hint: "ชื่อตัวเลือก",
                enabled: _isEditable,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: option.priceController,
              enabled: _isEditable,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 13.5,
                color: _MenuTheme.textPrimary,
              ),
              decoration: _cleanInputDecoration(hint: "", enabled: _isEditable)
                  .copyWith(
                    suffixIcon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          "บาท",
                          style: TextStyle(
                            color: _MenuTheme.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
            ),
          ),
          if (_isEditable) ...[
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
                  Icons.delete_outline_rounded,
                  color: _MenuTheme.danger,
                  size: 20,
                ),
              ),
            ),
          ],
        ],
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_photo_alternate_rounded,
              size: 28,
              color: _imageError != null
                  ? _MenuTheme.danger.withOpacity(0.6)
                  : _MenuTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "แตะเพื่อเลือกรูป",
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _imageError != null
                  ? _MenuTheme.danger
                  : _MenuTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
