// features/restaurant/edit_addon.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/menu_addon_detail_model.dart';
import 'package:flutter_app/data/models/addon_group_request_model.dart';
import 'package:flutter_app/data/models/addon_menu_model.dart';
import 'package:flutter_app/features/restaurant/add_menu.dart'
    show CustomAddonItem;
import 'package:flutter_app/features/restaurant/restaurant_navbar.dart';
import 'package:flutter_app/data/services/menu/menu_addon_service.dart';
import 'package:flutter_app/global_data.dart';

class _AddonTheme {
  static const Color primary = Color(0xFFFF8A00);
  static const Color accent = Color(0xFF2FB86A);
  static const Color danger = Color(0xFFE5484D);
  static const Color surface = Colors.white;
  static const Color pageBg = Color(0xFFF6F7F9);
  static const Color textPrimary = Color(0xFF1F2430);
  static const Color textSecondary = Color(0xFF8A8F98);
  static const Color fieldBg = Color(0xFFF4F5F7);
}

class _AddonSnapshot {
  final String name;
  final String price;
  final int? addonId;
  final bool allowqtystatus;
  final bool status;

  _AddonSnapshot({
    required this.name,
    required this.price,
    required this.addonId,
    required this.allowqtystatus,
    required this.status,
  });
}

class EditAddon extends StatefulWidget {
  final int? groupId;
  final String? groupName;
  final bool isMultipleChoice;
  final bool groupStatus;
  final List<MenuAddonDetailModel> details;

  const EditAddon({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.isMultipleChoice,
    required this.groupStatus,
    required this.details,
  });

  @override
  State<EditAddon> createState() => _EditAddonState();
}

class _EditAddonState extends State<EditAddon> {
  final MenuAddonService _addonService = MenuAddonService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late final TextEditingController groupNameController;
  late bool isMultipleChoice;
  late bool groupStatus;

  bool _isLoading = false;
  bool _isEditMode = false;

  List<CustomAddonItem> selectedAddons = [];

  final Map<CustomAddonItem, FocusNode> _nameFocusNodes = {};
  final Map<CustomAddonItem, LayerLink> _layerLinks = {};
  final Map<CustomAddonItem, OverlayEntry> _overlayEntries = {};
  final Map<CustomAddonItem, List<AddonMenuModel>> _suggestions = {};
  Timer? _debounce;

  String _originalGroupName = "";
  bool _originalIsMultipleChoice = false;
  List<_AddonSnapshot> _originalAddons = [];

  @override
  void initState() {
    super.initState();
    _prefillFromExistingData();
  }

  void _prefillFromExistingData() {
    groupNameController = TextEditingController(text: widget.groupName ?? "");
    isMultipleChoice = widget.isMultipleChoice;
    groupStatus = widget.groupStatus;

    if (widget.details.isEmpty) {
      _addNewCustomAddonRow();
    } else {
      selectedAddons = widget.details.map<CustomAddonItem>((d) {
        final priceVal = (d.addonPrice ?? 0).toInt().toString();
        return CustomAddonItem(
          nameController: TextEditingController(
            text: d.addonMenu?.addonName ?? "",
          ),
          priceController: TextEditingController(text: priceVal),
          addonId: d.addonDetailId,
          allowqtystatus: d.allowqtystatus,
          status: d.status ?? true,
        );
      }).toList();
    }
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
        status: true,
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

  void _enterEditMode() {
    _originalGroupName = groupNameController.text;
    _originalIsMultipleChoice = isMultipleChoice;
    _originalAddons = selectedAddons
        .map(
          (a) => _AddonSnapshot(
            name: a.nameController.text,
            price: a.priceController.text,
            addonId: a.addonId,
            allowqtystatus: a.allowqtystatus,
            status: a.status,
          ),
        )
        .toList();

    setState(() => _isEditMode = true);
  }

  void _cancelEdit() {
    for (var addon in selectedAddons) {
      _removeOverlay(addon);
      _nameFocusNodes[addon]?.dispose();
      _nameFocusNodes.remove(addon);
      _layerLinks.remove(addon);
      _suggestions.remove(addon);
      addon.nameController.dispose();
      addon.priceController.dispose();
    }

    final restoredAddons = _originalAddons.map((snap) {
      final item = CustomAddonItem(
        nameController: TextEditingController(text: snap.name),
        priceController: TextEditingController(text: snap.price),
        addonId: snap.addonId,
        allowqtystatus: snap.allowqtystatus,
        status: snap.status,
      );
      final focusNode = FocusNode();
      _nameFocusNodes[item] = focusNode;
      _layerLinks[item] = LayerLink();
      focusNode.addListener(() {
        if (!focusNode.hasFocus) _removeOverlay(item);
      });
      return item;
    }).toList();

    setState(() {
      groupNameController.text = _originalGroupName;
      isMultipleChoice = _originalIsMultipleChoice;
      selectedAddons = restoredAddons;
      _isEditMode = false;
    });

    formKey.currentState?.reset();
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

  Future<void> _toggleAddonDetailStatus(
    CustomAddonItem addon,
    bool value,
  ) async {
    final previousDetailStatus = addon.status;

    setState(() {
      addon.status = value;
    });

    // อัปเดตข้อมูลต้นทางในหน่วยความจำ
    if (addon.addonId != null) {
      final detailIndex = widget.details.indexWhere(
        (detail) => detail.addonDetailId == addon.addonId,
      );
      if (detailIndex != -1) {
        widget.details[detailIndex].status = value;
      }
    }

    if (addon.addonId == null) return;

    try {
      await _addonService.toggleAddonDetailStatus(addon.addonId!, value);
    } catch (e) {
      if (mounted) {
        setState(() {
          addon.status = previousDetailStatus;
        });

        // ถ้ายิง API ไม่สำเร็จ ให้ย้อนกลับค่าในหน่วยความจำด้วย
        if (addon.addonId != null) {
          final detailIndex = widget.details.indexWhere(
            (detail) => detail.addonDetailId == addon.addonId,
          );
          if (detailIndex != -1) {
            widget.details[detailIndex].status = previousDetailStatus;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("อัปเดตสถานะตัวเลือกไม่สำเร็จ: $e"),
            backgroundColor: _AddonTheme.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
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

  Future<void> _doUpdateAddonGroup() async {
    final isFormValid = formKey.currentState!.validate();
    if (!isFormValid) return;

    final names = selectedAddons
        .map((a) => a.nameController.text.trim().toLowerCase())
        .toList();
    if (names.toSet().length != names.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("ชื่อตัวเลือกซ้ำกัน กรุณาตรวจสอบอีกครั้ง"),
          backgroundColor: _AddonTheme.danger,
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
      final request = AddonGroupRequestModel(
        addonGroupId: widget.groupId,
        restaurantUsername: GlobalData.usernameRestaurant ?? "",
        addongroupname: groupNameController.text.trim(),
        is_multiple_choice: isMultipleChoice,
        status: groupStatus,
        details: selectedAddons.map((addon) {
          return AddonDetailRequestModel(
            addonDetailId: addon.addonId,
            addonname: addon.nameController.text.trim(),
            addonprice: (int.tryParse(addon.priceController.text.trim()) ?? 0)
                .toDouble(),
            status: addon.status,
            allowqtystatus: addon.allowqtystatus,
          );
        }).toList(),
      );

      await _addonService.updateAddonGroupTemplate(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("แก้ไขตัวเลือกสำเร็จ"),
            backgroundColor: _AddonTheme.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        setState(() {
          _isEditMode = false;
          _originalGroupName = groupNameController.text;
          _originalIsMultipleChoice = isMultipleChoice;
          _originalAddons = selectedAddons
              .map(
                (a) => _AddonSnapshot(
                  name: a.nameController.text,
                  price: a.priceController.text,
                  addonId: a.addonId,
                  allowqtystatus: a.allowqtystatus,
                  status: a.status,
                ),
              )
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("เกิดข้อผิดพลาด: $e"),
            backgroundColor: _AddonTheme.danger,
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
      fillColor: _isEditMode ? _AddonTheme.surface : _AddonTheme.fieldBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: _isEditMode
            ? BorderSide(color: Colors.grey.shade300, width: 1.2)
            : BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: _isEditMode
            ? BorderSide(color: Colors.grey.shade300, width: 1.2)
            : BorderSide.none,
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

  Widget _buildMultipleChoiceSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isEditMode ? _AddonTheme.surface : _AddonTheme.fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: _isEditMode ? Border.all(color: Colors.grey.shade300) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "เลือกได้หลายอย่าง",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _AddonTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isMultipleChoice
                    ? "ลูกค้าสามารถเลือกตัวเลือกได้มากกว่า 1 ข้อ"
                    : "ลูกค้าเลือกได้เพียง 1 ข้อเท่านั้น",
                style: const TextStyle(
                  fontSize: 11.5,
                  color: _AddonTheme.textSecondary,
                ),
              ),
            ],
          ),
          Switch(
            value: isMultipleChoice,
            activeColor: _AddonTheme.accent,
            onChanged: _isEditMode
                ? (value) {
                    setState(() {
                      isMultipleChoice = value;
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(int index) {
    final bool canDelete = selectedAddons.length > 1;
    return Material(
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
    );
  }

  Widget _buildAddonRow(int index) {
    final addon = selectedAddons[index];

    final layerLink = _layerLinks.putIfAbsent(addon, () => LayerLink());
    final focusNode = _nameFocusNodes.putIfAbsent(addon, () {
      final node = FocusNode();
      node.addListener(() {
        if (!node.hasFocus) {
          _removeOverlay(addon);
        }
      });
      return node;
    });

    return Container(
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
          Expanded(
            flex: 4,
            child: CompositedTransformTarget(
              link: layerLink,
              child: TextFormField(
                controller: addon.nameController,
                focusNode: focusNode,
                readOnly: !_isEditMode,
                onChanged: (value) => _onAddonNameChanged(addon, value),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? "กรอกชื่อ" : null,
                style: TextStyle(
                  fontSize: 14,
                  color: _isEditMode
                      ? _AddonTheme.textPrimary
                      : _AddonTheme.textSecondary,
                ),
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
                  fillColor: _isEditMode
                      ? _AddonTheme.surface
                      : Colors.transparent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: addon.priceController,
              keyboardType: TextInputType.number,
              readOnly: !_isEditMode,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (int.tryParse(value.trim()) == null) {
                    return "จำนวนเต็มเท่านั้น";
                  }
                }
                return null;
              },
              style: TextStyle(
                fontSize: 14,
                color: _isEditMode
                    ? _AddonTheme.textPrimary
                    : _AddonTheme.textSecondary,
              ),
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
                fillColor: _isEditMode
                    ? _AddonTheme.surface
                    : Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          _isEditMode
              ? _buildDeleteButton(index)
              : SizedBox(
                  width: 44,
                  child: Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: addon.status,
                      onChanged: (val) => _toggleAddonDetailStatus(addon, val),
                      activeColor: _AddonTheme.accent,
                    ),
                  ),
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
                    child: Icon(
                      _isEditMode
                          ? Icons.edit_rounded
                          : Icons.visibility_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditMode
                              ? "แก้ไขตัวเลือกเสริม"
                              : "รายละเอียดตัวเลือกเสริม",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _AddonTheme.textPrimary,
                          ),
                        ),
                        Text(
                          _isEditMode
                              ? "ปรับปรุงกลุ่มตัวเลือกที่มีอยู่ให้ตรงกับเมนูของคุณ"
                              : "ดูข้อมูลกลุ่มตัวเลือก (กดปุ่มแก้ไขด้านล่างเพื่อปรับปรุง)",
                          style: const TextStyle(
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
                      readOnly: !_isEditMode,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? "กรุณากรอกชื่อกลุ่มตัวเลือก"
                          : null,
                      style: TextStyle(
                        fontSize: 14,
                        color: _isEditMode
                            ? _AddonTheme.textPrimary
                            : _AddonTheme.textSecondary,
                      ),
                      decoration: _fieldDecoration(hint: "เช่น ประเภทข้าว"),
                    ),
                    const SizedBox(height: 16),
                    _buildMultipleChoiceSwitch(),
                  ],
                ),
              ),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: const [
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
                            width: 44,
                            child: Center(
                              child: Text(
                                "สถานะ",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      primary: false,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: selectedAddons.length,
                      itemBuilder: (context, index) => _buildAddonRow(index),
                    ),
                    if (_isEditMode) ...[
                      const SizedBox(height: 10),
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
          child: _isEditMode
              ? Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _cancelEdit,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _AddonTheme.textSecondary,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close_rounded, size: 19),
                              SizedBox(width: 8),
                              Text(
                                "ยกเลิก",
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _doUpdateAddonGroup,
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
                  ],
                )
              : SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _enterEditMode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _AddonTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 6,
                      shadowColor: _AddonTheme.primary.withOpacity(0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_rounded, size: 19),
                        SizedBox(width: 8),
                        Text(
                          "แก้ไขข้อมูล",
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
