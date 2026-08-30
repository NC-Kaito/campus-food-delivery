// features/restaurant/add_addon.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/addon_menu_model.dart';
import 'package:flutter_app/data/models/addon_group_request_model.dart';
import 'package:flutter_app/features/restaurant/edit_addon.dart'
    show CustomAddonItem;
import 'package:flutter_app/features/restaurant/restaurant_navbar.dart';
import 'package:flutter_app/data/services/menu/menu_addon_service.dart';
import 'package:flutter_app/global_data.dart';

// ============================================================
// 🎨 Design tokens — สีและระยะห่างที่ใช้ทั้งหน้า
// ============================================================
class _AddonTheme {
  static const Color primary = Color(0xFFFF8A00); // ส้ม — โทนหลักของแบรนด์
  static const Color accent = Color(0xFF2FB86A); // เขียว — ปุ่มยืนยัน/สถานะ on
  static const Color danger = Color(0xFFE5484D);
  static const Color surface = Colors.white;
  static const Color pageBg = Color(0xFFF6F7F9);
  static const Color textPrimary = Color(0xFF1F2430);
  static const Color textSecondary = Color(0xFF8A8F98);
  static const Color fieldBg = Color(0xFFF4F5F7);
}

class AddAddon extends StatefulWidget {
  const AddAddon({super.key});

  @override
  State<AddAddon> createState() => _AddAddonState();
}

class _AddAddonState extends State<AddAddon> {
  final MenuAddonService _addonService = MenuAddonService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController groupNameController = TextEditingController();

  // 🎯 ปรับใช้ is_multiple_choice แทน maxSelect และ isRequired
  bool isMultipleChoice = false;
  bool _isLoading = false;

  List<CustomAddonItem> selectedAddons = [];

  final Map<CustomAddonItem, FocusNode> _nameFocusNodes = {};
  final Map<CustomAddonItem, LayerLink> _layerLinks = {};
  final Map<CustomAddonItem, OverlayEntry> _overlayEntries = {};
  final Map<CustomAddonItem, List<AddonMenuModel>> _suggestions = {};
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _addNewCustomAddonRow();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    groupNameController.dispose();
    for (var addon in selectedAddons) {
      _removeOverlay(addon);
      _nameFocusNodes[addon]?.dispose();
      addon.nameController.dispose();
      addon.priceController.dispose();
    }
    super.dispose();
  }

  void _addNewCustomAddonRow() {
    setState(() {
      final newAddon = CustomAddonItem(
        nameController: TextEditingController(),
        priceController: TextEditingController(),
        addonId: null,
        allowqtystatus: false,
      );
      selectedAddons.add(newAddon);

      final focusNode = FocusNode();
      _nameFocusNodes[newAddon] = focusNode;
      _layerLinks[newAddon] = LayerLink();

      focusNode.addListener(() {
        if (!focusNode.hasFocus) {
          _removeOverlay(newAddon);
        }
      });
    });
  }

  void _removeAddonItemRow(int index) {
    if (selectedAddons.length <= 1) return;
    setState(() {
      final removed = selectedAddons[index];

      _removeOverlay(removed);
      _nameFocusNodes[removed]?.dispose();
      _nameFocusNodes.remove(removed);
      _layerLinks.remove(removed);
      _suggestions.remove(removed);

      removed.nameController.dispose();
      removed.priceController.dispose();
      selectedAddons.removeAt(index);
    });
  }

  void _onAddonNameChanged(CustomAddonItem addon, String value) {
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      _removeOverlay(addon);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final results = await _addonService.searchAddonName(value);
      if (!mounted) return;

      _suggestions[addon] = results;

      if (results.isEmpty) {
        _removeOverlay(addon);
      } else {
        _showOverlay(addon);
      }
    });
  }

  void _showOverlay(CustomAddonItem addon) {
    _removeOverlay(addon);

    final layerLink = _layerLinks[addon];
    if (layerLink == null) return;

    final overlay = OverlayEntry(
      builder: (context) => Positioned(
        width: 240,
        child: CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 48),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions[addon]?.length ?? 0,
                itemBuilder: (context, index) {
                  final item = _suggestions[addon]![index];
                  return InkWell(
                    onTap: () => _selectSuggestion(addon, item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Text(
                        item.addonName ?? "",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlay);
    _overlayEntries[addon] = overlay;
  }

  void _removeOverlay(CustomAddonItem addon) {
    _overlayEntries[addon]?.remove();
    _overlayEntries.remove(addon);
  }

  void _selectSuggestion(CustomAddonItem addon, AddonMenuModel item) {
    addon.nameController.text = item.addonName ?? "";
    _removeOverlay(addon);
    _nameFocusNodes[addon]?.unfocus();
  }

  // ─── ฟังก์ชันตัวช่วยสำหรับแจ้งเตือนข้อผิดพลาด ───
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _AddonTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _doSaveAddonGroup() async {
    final isFormValid = formKey.currentState!.validate();
    if (!isFormValid) return;

    final groupName = groupNameController.text.trim();
    if (groupName.isEmpty) {
      _showErrorSnackBar("กรุณากรอกชื่อกลุ่มตัวเลือก");
      return;
    }

    // 1. ตรวจสอบชื่อตัวเลือกย่อยซ้ำกันเองในฟอร์ม
    final names = selectedAddons
        .map((a) => a.nameController.text.trim().toLowerCase())
        .toList();
    if (names.toSet().length != names.length) {
      _showErrorSnackBar("ชื่อตัวเลือกย่อยซ้ำกัน กรุณาตรวจสอบอีกครั้ง");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. 🛡️ ดักป้องกัน: ดึงกลุ่มตัวเลือกทั้งหมดของร้านมาเช็คชื่อซ้ำก่อนบันทึก
      final restaurantUsername = GlobalData.usernameRestaurant ?? "";
      final existingGroups = await _addonService.getAddonGroupsByRestaurant(
        restaurantUsername,
      );

      final isDuplicate = existingGroups.any(
        (group) =>
            (group.addonGroupName ?? "").trim().toLowerCase() ==
            groupName.toLowerCase(),
      );

      if (isDuplicate) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackBar(
            "มีชื่อกลุ่มตัวเลือก '$groupName' นี้อยู่แล้วในระบบ กรุณาใช้ชื่ออื่น",
          );
        }
        return;
      }

      // 3. ส่งข้อมูลไปบันทึกผ่าน API
      final request = AddonGroupRequestModel(
        restaurantUsername: restaurantUsername,
        addongroupname: groupName,
        is_multiple_choice: isMultipleChoice,
        status: true,
        details: selectedAddons.map((addon) {
          return AddonDetailRequestModel(
            addonname: addon.nameController.text.trim(),
            addonprice:
                double.tryParse(addon.priceController.text.trim()) ?? 0.0,
            status: true,
            allowqtystatus: addon.allowqtystatus,
          );
        }).toList(),
      );

      await _addonService.createAddonGroupTemplate(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("บันทึกตัวเลือกสำเร็จ"),
            backgroundColor: _AddonTheme.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = "เกิดข้อผิดพลาด: $e";
        if (e.toString().toLowerCase().contains("duplicate") ||
            e.toString().toLowerCase().contains("exists") ||
            e.toString().toLowerCase().contains("unique") ||
            e.toString().contains("409")) {
          errorMessage =
              "ชื่อกลุ่มตัวเลือกนี้มีอยู่แล้วในระบบ กรุณาใช้ชื่ออื่น";
        }
        _showErrorSnackBar(errorMessage);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // Shared styles
  // ============================================================
  InputDecoration _fieldDecoration({String hint = "", Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: _AddonTheme.textSecondary,
        fontSize: 14,
      ),
      prefixIcon: prefixIcon,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      filled: true,
      fillColor: _AddonTheme.fieldBg,
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
        borderSide: const BorderSide(color: _AddonTheme.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _AddonTheme.danger, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _AddonTheme.danger, width: 1.6),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _AddonTheme.surface,
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
            color: _AddonTheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: _AddonTheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _AddonTheme.textPrimary,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _AddonTheme.textSecondary,
        ),
      ),
    );
  }

  // ============================================================
  // Toggle สวิตช์: เลือกได้หลายอย่าง (is_multiple_choice)
  // ============================================================
  Widget _buildMultipleChoiceSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _AddonTheme.fieldBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMultipleChoice
                    ? "ลูกค้าสามารถเลือกตัวเลือกได้ หลายอย่าง"
                    : "ลูกค้าเลือกได้เพียง 1 อย่างเท่านั้น",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _AddonTheme.textPrimary,
                ),
              ),
            ],
          ),
          Switch(
            value: isMultipleChoice,
            activeColor: _AddonTheme.accent,
            onChanged: (value) {
              setState(() {
                isMultipleChoice = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // แถวรายการตัวเลือกย่อย
  // ============================================================
  Widget _buildAddonRow(int index) {
    final addon = selectedAddons[index];
    final bool canDelete = selectedAddons.length > 1;

    return Container(
      key: ValueKey(
        addon,
      ), // เพิ่ม Key เพื่อให้ ReorderableListView ทำงานได้สมบูรณ์
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _AddonTheme.fieldBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _AddonTheme.primary.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Text(
              "${index + 1}",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _AddonTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // ─── ช่องชื่อตัวเลือก ───
          Expanded(
            flex: 4,
            child: CompositedTransformTarget(
              link: _layerLinks[addon]!,
              child: TextFormField(
                controller: addon.nameController,
                focusNode: _nameFocusNodes[addon],
                onChanged: (value) => _onAddonNameChanged(addon, value),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? "กรอกชื่อ" : null,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "ชื่อตัวเลือก",
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: _AddonTheme.textSecondary,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: _AddonTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: _AddonTheme.primary,
                      width: 1.4,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _AddonTheme.danger),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: _AddonTheme.danger,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ─── ช่องราคา ───
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: addon.priceController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (double.tryParse(value.trim()) == null) {
                    return "ตัวเลขเท่านั้น";
                  }
                }
                return null;
              },
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: "0",
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: _AddonTheme.textSecondary,
                ),
                prefixText: "฿ ",
                prefixStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _AddonTheme.textSecondary,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                filled: true,
                fillColor: _AddonTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: _AddonTheme.primary,
                    width: 1.4,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _AddonTheme.danger),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: _AddonTheme.danger,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── ปุ่มลบ (รูปถังขยะ) ───
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(9),
                  onTap: canDelete ? () => _removeAddonItemRow(index) : null,
                  child: Container(
                    width: 34,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: canDelete
                          ? _AddonTheme.danger.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: canDelete
                          ? _AddonTheme.danger
                          : _AddonTheme.textSecondary.withOpacity(0.35),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              // ─── ไอคอนจุด 6 จุดสำหรับลาก ───
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    size: 24,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AddonTheme.pageBg,
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

              // ── Hero header ────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_AddonTheme.primary, Color(0xFFFFB13D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _AddonTheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
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
                          "เพิ่มตัวเลือกเสริม",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _AddonTheme.textPrimary,
                          ),
                        ),
                        Text(
                          "สร้างกลุ่มตัวเลือกใหม่ให้ลูกค้าปรับแต่งเมนู",
                          style: TextStyle(
                            fontSize: 12.5,
                            color: _AddonTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ── Section: ข้อมูลกลุ่มตัวเลือก ────────────────────
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      icon: Icons.category_rounded,
                      title: "ข้อมูลกลุ่มตัวเลือก",
                    ),
                    const SizedBox(height: 16),

                    _fieldLabel("ชื่อกลุ่มตัวเลือก"),
                    TextFormField(
                      controller: groupNameController,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? "กรุณากรอกชื่อกลุ่มตัวเลือก"
                          : null,
                      style: const TextStyle(fontSize: 14),
                      decoration: _fieldDecoration(hint: "เช่น ประเภทข้าว"),
                    ),

                    const SizedBox(height: 16),

                    // 🎯 การ์ดสวิตช์เลือกได้หลายอย่าง
                    _buildMultipleChoiceSwitch(),
                  ],
                ),
              ),

              // ── Section: รายการตัวเลือก ─────────────────────────
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      icon: Icons.list_alt_rounded,
                      title: "รายการตัวเลือก",
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _AddonTheme.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${selectedAddons.length} รายการ",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _AddonTheme.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          SizedBox(width: 36),
                          Expanded(
                            flex: 4,
                            child: Text(
                              "ชื่อตัวเลือก",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: Text(
                              "ราคา",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 68,
                          ), // ปรับระยะให้ตรงกับไอคอนลบ + จุดลาก
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    ReorderableListView.builder(
                      shrinkWrap: true,
                      primary: false,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: selectedAddons.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final item = selectedAddons.removeAt(oldIndex);
                          selectedAddons.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) => _buildAddonRow(index),
                    ),

                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _addNewCustomAddonRow,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _AddonTheme.accent.withOpacity(0.4),
                              width: 1.3,
                            ),
                            color: _AddonTheme.accent.withOpacity(0.06),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 18,
                                color: _AddonTheme.accent,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "เพิ่มตัวเลือกเสริม",
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: _AddonTheme.accent,
                                ),
                              ),
                            ],
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

      // ── ปุ่มบันทึก ────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _doSaveAddonGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: _AddonTheme.accent,
                foregroundColor: Colors.white,
                elevation: 6,
                shadowColor: _AddonTheme.accent.withOpacity(0.35),
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
                          "บันทึกตัวเลือก",
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
}
