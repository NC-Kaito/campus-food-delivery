// features/restaurant/menu_to_addon.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/data/models/menu_addon_group_model.dart';
import 'package:flutter_app/data/models/menu_addon_detail_model.dart';
import 'package:flutter_app/data/services/menu/menu_addon_service.dart';
import 'package:flutter_app/global_data.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/features/restaurant/restaurant_navbar.dart';

class MenuToAddon extends StatefulWidget {
  final MenuModel menuModel;
  const MenuToAddon({super.key, required this.menuModel});

  @override
  State<MenuToAddon> createState() => _MenuToAddonState();
}

class _MenuToAddonState extends State<MenuToAddon> {
  static const Color _primary = Color(0xFF16A34A);
  static const Color _primaryDark = Color(0xFF0F7A38);
  static const Color _bg = Color(0xFFF5F6F8);
  static const Color _textDark = Color(0xFF1E1E24);
  static const Color _textMuted = Color(0xFF8A8D93);
  static const Color _danger = Color(0xFFE53935);
  static const Color _linkBlue = Color(0xFF2F80ED);
  static const Color _accent = Color(0xFFEA7C1E);

  final MenuAddonService _addonService = MenuAddonService();

  bool _loading = true;
  bool _saving = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _searchLayerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Timer? _debounce;

  List<_AddonGroupAggregate> _allGroups = [];
  List<_AddonGroupAggregate> _searchResults = [];

  final Map<int, bool> _groupLinked = {};
  final Map<int, bool> _groupExpanded = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        _updateSearchResults(_searchController.text);
      } else {
        _removeSearchOverlay();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeSearchOverlay();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;
    final String baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/') ? "$baseUrl$rawPath" : "$baseUrl/$rawPath";
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final allGroups = await _addonService.getAddonGroupsByRestaurant(
        GlobalData.usernameRestaurant ?? "",
      );

      final linkedDetails = await _addonService.getAddonsByMenuId(
        widget.menuModel.menuId!,
      );

      final Set<int> linkedGroupIds = linkedDetails
          .map((d) => d.menuAddonGroup?.addonGroupId)
          .whereType<int>()
          .toSet();

      if (!mounted) return;

      setState(() {
        _allGroups = allGroups.map((group) {
          final agg = _AddonGroupAggregate(group);
          for (final detail in group.details ?? []) {
            final itemKey =
                detail.addonMenu?.addonId ??
                detail.addonDetailId ??
                detail.hashCode;
            agg.items.putIfAbsent(itemKey, () => detail);
          }
          return agg;
        }).toList();

        for (final agg in _allGroups) {
          final gid = agg.group.addonGroupId;
          if (gid != null) {
            _groupLinked[gid] = linkedGroupIds.contains(gid);
            _groupExpanded[gid] = false;
          }
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack("โหลดข้อมูลไม่สำเร็จ", isError: true);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _updateSearchResults(value);
    });
  }

  void _updateSearchResults(String value) {
    final query = value.trim().toLowerCase();
    final results = _allGroups.where((agg) {
      final isLinked = _groupLinked[agg.group.addonGroupId] ?? false;
      if (isLinked) return false;
      if (query.isEmpty) return true;
      final name = agg.group.addonGroupName?.toLowerCase() ?? "";
      return name.contains(query);
    }).toList();

    if (!mounted) return;
    setState(() => _searchResults = results);

    if (results.isEmpty) {
      _removeSearchOverlay();
    } else {
      _showSearchOverlay();
    }
  }

  void _showSearchOverlay() {
    _removeSearchOverlay();

    final overlay = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 40,
        child: CompositedTransformFollower(
          link: _searchLayerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 58),
          child: Material(
            elevation: 10,
            shadowColor: Colors.black.withOpacity(0.15),
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  final agg = _searchResults[index];
                  final groupId = agg.group.addonGroupId ?? -1;
                  final itemCount = agg.items.length;

                  return InkWell(
                    onTap: () => _selectGroupToUse(groupId),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              size: 18,
                              color: _primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  agg.group.addonGroupName ?? "ไม่มีชื่อกลุ่ม",
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: _textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "$itemCount ตัวเลือกย่อย",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: _primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
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
    _overlayEntry = overlay;
  }

  void _removeSearchOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectGroupToUse(int groupId) {
    setState(() {
      _groupLinked[groupId] = true;
      _groupExpanded[groupId] = false;
    });
    _searchController.clear();
    _removeSearchOverlay();
    _searchFocusNode.unfocus();
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? _danger : _primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          content: Text(message),
        ),
      );
  }

  Future<void> _handleSave() async {
    if (widget.menuModel.menuId == null || _saving) return;

    setState(() => _saving = true);

    final selectedGroupIds = _groupLinked.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();

    try {
      await _addonService.updateMenuAddonMapping(
        widget.menuModel.menuId!,
        selectedGroupIds,
      );
      if (!mounted) return;
      _showSnack("บันทึกข้อมูลสำเร็จ");
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnack("เกิดข้อผิดพลาด: $e", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuName = widget.menuModel.menuName ?? "ไม่มีชื่อเมนู";
    final priceText = widget.menuModel.price?.toStringAsFixed(0) ?? "0";
    final imageUrl = _getFinalImageUrl(widget.menuModel.menuImage);
    final linkedCount = _groupLinked.values.where((v) => v).length;

    final linkedGroups = _allGroups
        .where((agg) => _groupLinked[agg.group.addonGroupId] == true)
        .toList();

    return Scaffold(
      backgroundColor: _bg,
      appBar: const RestaurantNavbar(title: ""),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          top: false,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _primary))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _buildPageHeader(),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              width: 72,
                              height: 72,
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      Uri.encodeFull(imageUrl),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _placeholderImage(),
                                    )
                                  : _placeholderImage(),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  menuName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "ราคา $priceText บาท",
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: _primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _linkBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.layers_outlined,
                                        size: 13,
                                        color: _linkBlue,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "มี $linkedCount กลุ่มตัวเลือกเสริม",
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: _linkBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    CompositedTransformTarget(
                      link: _searchLayerLink,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: _onSearchChanged,
                          style: const TextStyle(fontSize: 14.5),
                          decoration: InputDecoration(
                            hintText: "ค้นหากลุ่มตัวเลือกเสริม",
                            hintStyle: const TextStyle(
                              color: _textMuted,
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: _textMuted,
                              size: 22,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: _textMuted,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _updateSearchResults('');
                                      setState(() {});
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'กลุ่มตัวเลือกเสริมที่ใช้งาน',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                        Text(
                          "$linkedCount กลุ่ม",
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (linkedGroups.isEmpty)
                      _buildEmptyState()
                    else
                      ...linkedGroups.map(
                        (agg) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildActiveAddonGroupCard(agg),
                        ),
                      ),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _danger,
                      side: BorderSide(color: _danger.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "ยกเลิก",
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [_primary, _primaryDark],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _saving ? null : _handleSave,
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "บันทึกข้อมูล",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.playlist_add_check_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'เมนู + ตัวเลือกเพิ่มเติม',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'จัดการกลุ่มตัวเลือกเสริมให้ตรงกับเมนูนี้',
                style: TextStyle(
                  fontSize: 12.5,
                  color: _textMuted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.tune_rounded, color: _primary, size: 26),
          ),
          const SizedBox(height: 14),
          const Text(
            "ยังไม่มีกลุ่มตัวเลือกเสริมสำหรับเมนูนี้",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "ค้นหาจากช่องด้านบนแล้วกด + เพื่อเพิ่มกลุ่มตัวเลือกเสริม",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: _textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }

  // 🎯 Badge โชว์สถานะ "เลือกได้หลายอย่าง" / "เลือกได้ 1 อย่าง"
  Widget _buildAddonMetaBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleExpandButton({
    required bool expanded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: _primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: AnimatedRotation(
          turns: expanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _primary,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveAddonGroupCard(_AddonGroupAggregate agg) {
    final groupId = agg.group.addonGroupId ?? -1;
    final isExpanded = _groupExpanded[groupId] ?? false;

    // 🎯 อ่านค่า is_multiple_choice
    final isMultipleChoice = agg.group.is_multiple_choice ?? false;
    final items = agg.items.values.toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _groupExpanded[groupId] = !isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agg.group.addonGroupName ?? "ไม่มีชื่อกลุ่ม",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "${items.length} ตัวเลือกย่อย",
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 🎯 แสดงเฉพาะ Badge รูปแบบการเลือก
                        _buildAddonMetaBadge(
                          icon: isMultipleChoice
                              ? Icons.check_box_outlined
                              : Icons.radio_button_checked_rounded,
                          label: isMultipleChoice
                              ? "เลือกได้หลายอย่าง"
                              : "เลือกได้ 1 อย่าง",
                          color: isMultipleChoice
                              ? _linkBlue
                              : Colors.orange[800]!,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCircleExpandButton(
                        expanded: isExpanded,
                        onTap: () => setState(
                          () => _groupExpanded[groupId] = !isExpanded,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () =>
                            setState(() => _groupLinked[groupId] = false),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: _danger.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: _danger,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
                  const SizedBox(height: 10),
                  if (items.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: _primary.withOpacity(0.7),
                            width: 3,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.only(left: 10),
                      child: Column(
                        children: [
                          for (int i = 0; i < items.length; i++) ...[
                            _buildDetailItemRow(items[i]),
                            if (i < items.length - 1)
                              const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        "กลุ่มนี้ยังไม่มีตัวเลือกย่อย",
                        style: TextStyle(fontSize: 12.5, color: _textMuted),
                      ),
                    ),
                ],
              ),
            ),
            secondChild: const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItemRow(MenuAddonDetailModel detail) {
    return Row(
      children: [
        Expanded(
          child: Text(
            detail.addonMenu?.addonName ?? "ไม่มีชื่อ",
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: _textDark,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          "+${detail.addonPrice?.toInt() ?? 0} บาท",
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textMuted,
          ),
        ),
      ],
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: Colors.grey.shade100,
      child: Icon(
        Icons.fastfood_rounded,
        color: Colors.grey.shade300,
        size: 30,
      ),
    );
  }
}

class _AddonGroupAggregate {
  final MenuAddonGroupModel group;
  final Map<int, MenuAddonDetailModel> items = {};

  _AddonGroupAggregate(this.group);
}
