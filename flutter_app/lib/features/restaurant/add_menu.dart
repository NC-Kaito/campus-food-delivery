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

class CustomAddonItem {
  final TextEditingController nameController;
  final TextEditingController priceController;
  int? addonId;

  CustomAddonItem({
    required this.nameController,
    required this.priceController,
    this.addonId,
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
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController menuNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController _newTypeNameController = TextEditingController();

  bool isAddonOn = false;
  bool _isLoading = false;
  bool _isAddingNewType = false;

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
    fetchTypeMenus();
    fetchAddonMenus();
  }

  @override
  void dispose() {
    menuNameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    _newTypeNameController.dispose();
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

  Future<void> fetchTypeMenus() async {
    try {
      final types = await typeMenuService.getAllTypeMenu();
      setState(() {
        typeMenuList = types;
      });
    } catch (e) {
      print("ไม่สามารถโหลดประเภทอาหารจาก /v1/typemenu ได้: $e");
    }
  }

  Future<void> fetchAddonMenus() async {
    try {
      final addons = await menuService.getAllAddonMenus(
        GlobalData.usernameRestaurant,
      );
      setState(() {
        dbAddonList = List<AddonMenuModel>.from(addons);
        if (addonGroups.isEmpty) {
          _addNewAddonGroup();
        } else {
          for (var group in addonGroups) {
            group.currentSearchResults = List<AddonMenuModel>.from(dbAddonList);
          }
        }
      });
    } catch (e) {
      print("ไม่สามารถโหลดรายการวัตถุดิบเฉพาะร้านได้: $e");
      if (addonGroups.isEmpty) {
        _addNewAddonGroup();
      }
    }
  }

  void _addNewAddonGroup() {
    setState(() {
      final newGroup = AddonGroupFormState();
      newGroup.currentSearchResults = List<AddonMenuModel>.from(dbAddonList);
      addonGroups.add(newGroup);
    });
  }

  void _removeAddonGroup(int groupIndex) {
    setState(() {
      addonGroups[groupIndex].groupNameController.dispose();
      addonGroups[groupIndex].searchController.dispose();
      for (var addon in addonGroups[groupIndex].selectedAddons) {
        addon.nameController.dispose();
        addon.priceController.dispose();
      }
      addonGroups.removeAt(groupIndex);
    });
  }

  void _onSearchChanged(int groupIndex, String query) {
    setState(() {
      if (query.trim().isEmpty) {
        addonGroups[groupIndex].currentSearchResults =
            List<AddonMenuModel>.from(dbAddonList);
      } else {
        addonGroups[groupIndex].currentSearchResults = dbAddonList
            .where(
              (item) => (item.addonName ?? "").toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .toList();
      }
    });
  }

  void _addAddonFromDb(int groupIndex, AddonMenuModel addonItem) {
    int? id = addonItem.addonId;
    String name = addonItem.addonName ?? "";
    if (id == null) return;
    bool isExist = addonGroups[groupIndex].selectedAddons.any(
      (e) => e.addonId == id,
    );
    if (isExist) return;
    setState(() {
      addonGroups[groupIndex].selectedAddons.add(
        CustomAddonItem(
          nameController: TextEditingController(text: name),
          priceController: TextEditingController(text: "7"),
          addonId: id,
        ),
      );
    });
  }

  void _addNewCustomAddonRow(int groupIndex) {
    setState(() {
      addonGroups[groupIndex].selectedAddons.add(
        CustomAddonItem(
          nameController: TextEditingController(),
          priceController: TextEditingController(),
          addonId: null,
        ),
      );
    });
  }

  void _removeAddonItemRow(int groupIndex, int addonIndex) {
    setState(() {
      addonGroups[groupIndex].selectedAddons[addonIndex].nameController
          .dispose();
      addonGroups[groupIndex].selectedAddons[addonIndex].priceController
          .dispose();
      addonGroups[groupIndex].selectedAddons.removeAt(addonIndex);
    });
  }

  Future<void> pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
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
              leading: const Icon(Icons.photo_library, color: Colors.green),
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

      final Map<String, dynamic> requestData = {
        "menuname": menuNameController.text.trim(),
        "description": descriptionController.text.trim(),
        "price": double.parse(priceController.text),
        "status": true,
        "imageUrl": imageUrl ?? "",
        "restaurantId": GlobalData.usernameRestaurant,
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

      await menuService.saveMenuWithAddons(requestData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ บันทึกเมนูสำเร็จ"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("เกิดข้อผิดพลาด: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration({String hint = "", Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF5DF232), width: 1.5),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      extendBodyBehindAppBar: true,
      appBar: const RestaurantNavbar(title: ""),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const SizedBox(height: 50),

                  Center(
                    child: Text(
                      'เพิ่มเมนู',
                      style: TextStyle(
                        color: Color(0xFFFF9800),
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  // ── รูปอาหาร ──────────────────────────────────────────
                  _buildLabel("รูปอาหาร"),
                  const SizedBox(height: 5),
                  Center(
                    child: GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        height: 200,
                        width: 300,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Icons.image_outlined,
                                size: 70,
                                color: Colors.grey[400],
                              ),
                      ),
                    ),
                  ),
                  if (_imageError != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _imageError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),

                  // ── ชื่อเมนู ──────────────────────────────────────────
                  _buildLabel("ชื่อเมนู (Menu Name)"),
                  TextFormField(
                    controller: menuNameController,
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? "กรุณากรอกชื่อเมนู"
                        : null,
                    decoration: _inputDecoration(hint: "เช่น กระเพราหมูกรอบ"),
                  ),

                  // ── ประเภทเมนู ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: const TextSpan(
                            text: "ประเภทเมนู (MenuType)",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: ' *',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isAddingNewType = !_isAddingNewType;
                              if (!_isAddingNewType) {
                                _newTypeNameController.clear();
                                _newTypeName = null;
                              } else {
                                // ✅ ล้าง dropdown ที่เลือกไว้ก่อนหน้า
                                _selectedTypeMenuId = null;
                                _selectedTypeMenuName = null;
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isAddingNewType
                                ? Colors.orange
                                : Colors.grey.shade300,
                            foregroundColor: _isAddingNewType
                                ? Colors.white
                                : Colors.black87,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "เพิ่ม",
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (!_isAddingNewType) ...[
                    // โหมดปกติ: Dropdown
                    typeMenuList.isEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.orange,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "กำลังโหลดประเภทหมวดหมู่...",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : _buildDropdown(
                            typeMenuList
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
                    // โหมดเพิ่มใหม่: TextField + ปุ่มยกเลิกใน suffix
                    TextFormField(
                      controller: _newTypeNameController,
                      autofocus: true,
                      onChanged: (val) {
                        setState(() {
                          _newTypeName = val.trim().isEmpty ? null : val.trim();
                          _selectedTypeMenuId = null; // ✅ ล้างทุกครั้งที่พิมพ์
                          _selectedTypeMenuName = null;
                          _typeMenuError = null;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "ชื่อประเภทอาหาร....",
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: SizedBox(
                          width: 80,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _isAddingNewType = false;
                                _newTypeNameController.clear();
                                _newTypeName = null;
                              });
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              "ยกเลิก",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF5DF232),
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (_typeMenuError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        _typeMenuError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),

                  // ── รายละเอียด ────────────────────────────────────────
                  _buildLabel("รายละเอียด (description)"),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration: _inputDecoration(
                      hint: "ระบุรายละเอียดเมนูอาหารหรือส่วนผสมเสริม",
                    ),
                  ),

                  // ── ราคา ──────────────────────────────────────────────
                  _buildLabel("ราคา (price)"),
                  TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return "กรุณากรอกราคาเมนู";
                      if (double.tryParse(value) == null)
                        return "กรุณากรอกตัวเลขที่ถูกต้อง";
                      return null;
                    },
                    decoration: _inputDecoration(
                      hint: "50",
                      suffixIcon: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text(
                          "บาท",
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(thickness: 1),
                  ),

                  // ── Add-on Toggle ─────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "ตัวเลือกเสริม Add-on Menu",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            isAddonOn ? "on " : "off ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isAddonOn ? Colors.green : Colors.grey,
                            ),
                          ),
                          Switch(
                            value: isAddonOn,
                            activeColor: const Color(0xFF5DF232),
                            onChanged: (value) {
                              setState(() {
                                isAddonOn = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  // ── Addon Groups ──────────────────────────────────────
                  if (isAddonOn) ...[
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: addonGroups.length,
                      itemBuilder: (context, gIndex) {
                        final group = addonGroups[gIndex];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      "ชื่อกลุ่มตัวเลือก : ชื่อ ",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                      child: SizedBox(
                                        height: 35,
                                        child: TextFormField(
                                          controller: group.groupNameController,
                                          validator: (value) =>
                                              (isAddonOn &&
                                                  (value == null ||
                                                      value.isEmpty))
                                              ? "กรุณากรอกชื่อกลุ่มตัวเลือก"
                                              : null,
                                          decoration: const InputDecoration(
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 0,
                                                ),
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                Row(
                                  children: [
                                    const Text(
                                      "จำนวนที่ลูกค้าจะเลือกได้สูงสุด : ",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      child: DropdownButton<int>(
                                        value: group.maxSelect,
                                        underline: const SizedBox(),
                                        items: [1, 2, 3, 4, 5].map((int val) {
                                          return DropdownMenuItem<int>(
                                            value: val,
                                            child: Text(val.toString()),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          setState(
                                            () => group.maxSelect = val ?? 1,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                Row(
                                  children: [
                                    const Text(
                                      "ลูกค้าจำเป็นต้องเลือกไหม : ",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ChoiceChip(
                                      label: Text(
                                        group.isRequired
                                            ? "จำเป็น"
                                            : "ไม่จำเป็น",
                                      ),
                                      selected: group.isRequired,
                                      selectedColor: Colors.orange,
                                      labelStyle: TextStyle(
                                        color: group.isRequired
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      onSelected: (bool selected) {
                                        setState(() {
                                          group.isRequired = !group.isRequired;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Divider(),

                                SizedBox(
                                  height: 40,
                                  child: TextField(
                                    controller: group.searchController,
                                    onChanged: (query) =>
                                        _onSearchChanged(gIndex, query),
                                    decoration: InputDecoration(
                                      hintText:
                                          "ค้นหาตัวเลือก (เฉพาะรายการของร้านคุณ)...",
                                      hintStyle: const TextStyle(fontSize: 13),
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        size: 20,
                                      ),
                                      contentPadding: const EdgeInsets.all(5),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Container(
                                  height: 110,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: ListView.builder(
                                    itemCount:
                                        group.currentSearchResults.length,
                                    itemBuilder: (context, index) {
                                      final item =
                                          group.currentSearchResults[index];
                                      return Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                        ),
                                        child: ListTile(
                                          dense: true,
                                          title: Text(
                                            "${index + 1}.   ${item.addonName ?? ""}",
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(
                                              Icons.add_circle,
                                              color: Colors.green,
                                            ),
                                            onPressed: () =>
                                                _addAddonFromDb(gIndex, item),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 15),

                                const Text(
                                  "ชื่อตัวเลือก                     ราคา",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),

                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: group.selectedAddons.length,
                                  itemBuilder: (context, aIndex) {
                                    final addon = group.selectedAddons[aIndex];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Text(
                                            "${aIndex + 1} ",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: SizedBox(
                                              height: 35,
                                              child: TextFormField(
                                                controller:
                                                    addon.nameController,
                                                readOnly: addon.addonId != null,
                                                decoration:
                                                    const InputDecoration(
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                          ),
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 2,
                                            child: SizedBox(
                                              height: 35,
                                              child: TextFormField(
                                                controller:
                                                    addon.priceController,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration:
                                                    const InputDecoration(
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                          ),
                                                      suffixText: "บาท",
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.grey,
                                            ),
                                            onPressed: () =>
                                                _removeAddonItemRow(
                                                  gIndex,
                                                  aIndex,
                                                ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),

                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text("ตัวเลือก"),
                                        onPressed: () =>
                                            _addNewCustomAddonRow(gIndex),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF5DF232,
                                          ),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 18,
                                        ),
                                        label: const Text("ลบกลุ่ม"),
                                        onPressed: () =>
                                            _removeAddonGroup(gIndex),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFE53935,
                                          ),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    Center(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text("กลุ่มตัวเลือกเสริม"),
                        onPressed: _addNewAddonGroup,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 40),
                          side: const BorderSide(color: Colors.black),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],

                  const SizedBox(height: 20),

                  // ── ปุ่มบันทึก ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _doSaveMenu,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5DF232),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 3,
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
                          : const Text(
                              "บันทึก",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 12),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          children: const [
            TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
          ],
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          hint: const Text(
            "---เลือกประเภท---",
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          items: items.toSet().map((String e) {
            return DropdownMenuItem<String>(value: e, child: Text(e));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
