// features/restaurant/home_restaurant.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/menu_addon_group_model.dart';
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/data/models/menu_addon_detail_model.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/type_menu_model.dart';
import 'package:flutter_app/data/services/menu/menu_addon_service.dart';
import 'package:flutter_app/data/services/menu/menu_service.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/features/restaurant/add_menu.dart';
import 'package:flutter_app/features/restaurant/add_addon.dart';
import 'package:flutter_app/features/restaurant/edit_addon.dart';
// 🎯 หน้าแก้ไขเมนู — ปรับ path/ชื่อคลาสให้ตรงกับโปรเจกต์จริงถ้าไม่ตรงกัน
import 'package:flutter_app/features/restaurant/edit_menu.dart';
// 🎯 หน้าเชื่อมโยงตัวเลือกเสริมเข้ากับเมนู — ปรับ path/ชื่อคลาสให้ตรงกับ
// โปรเจกต์จริงถ้าไม่ตรงกัน
import 'package:flutter_app/features/restaurant/menu_to_addon.dart';
import 'package:flutter_app/features/restaurant/restaurant_scaffold.dart';
import 'package:flutter_app/features/restaurant/view_menu.dart';
import 'package:flutter_app/global_data.dart';
import 'package:flutter_app/core/network/dio_client.dart';

class HomeRestaurant extends StatefulWidget {
  const HomeRestaurant({super.key});

  @override
  State<HomeRestaurant> createState() => _HomeRestaurantState();
}

class _HomeRestaurantState extends State<HomeRestaurant>
    with TickerProviderStateMixin {
  // ── ธีมสีหลักของหน้า (ชุดเดียวกับหน้าอื่นๆ ในแอปเพื่อความสม่ำเสมอ) ──────
  static const Color _primary = Color(0xFF16A34A); // เขียวหลัก
  static const Color _primaryDark = Color(0xFF0F7A38);
  static const Color _accent = Color(0xFFEA7C1E); // ส้มสำหรับหัวข้อ/แบรนด์
  static const Color _bg = Color(0xFFF5F6F8);
  static const Color _textDark = Color(0xFF1E1E24);
  static const Color _textMuted = Color(0xFF8A8D93);
  static const Color _danger = Color(0xFFE53935);
  static const Color _linkBlue = Color(0xFF2F80ED);

  final RestaurantService restaurantService = RestaurantService();
  final MenuService menuService = MenuService();
  // 🎯 ใช้วิธีดึงข้อมูลเดียวกับ _ViewMenuState
  final MenuAddonService _addonService = MenuAddonService();

  RestaurantModel? restaurantModel;
  TabController? _tabController;

  String? restaurantimage;
  String? restaurantname = "กำลังโหลด...";

  List<TypeMenuModel> typeMenus = [];
  Map<int, List<MenuModel>> categoryMenus = {};
  Map<int, bool> categoryLoading = {};

  // 🎯 แถบบนสุด: เมนู / ตัวเลือกเพิ่มเติม
  int _mainTabIndex = 0;

  // --- state สำหรับหน้า "ตัวเลือกเพิ่มเติม" ---
  bool _isLoadingAddons = false;
  bool _addonsLoaded = false;
  List<_AddonGroupAggregate> _addonGroups = [];
  final Map<int, bool> _groupEnabled =
      {}; // groupId -> เปิด/ปิดกลุ่ม (UI เท่านั้น)
  final Map<int, bool> _groupExpanded = {}; // groupId -> ขยาย/ย่อ
  final Map<int, bool> _itemChecked = {}; // itemKey -> ติ๊กเลือก (UI เท่านั้น)

  // 🎯 menuId -> จำนวนกลุ่มตัวเลือกเสริมที่ผูกกับเมนูนั้นจริงๆ (นับสดจาก
  // MenuAddonService.getAddonsByMenuId เพราะ MenuModel ไม่มีฟิลด์นี้ให้ใช้ตรงๆ)
  final Map<int, int> _menuAddonGroupCounts = {};

  @override
  void initState() {
    super.initState();
    loadRestaurantData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
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

  Future<void> loadRestaurantData() async {
    final rest = await restaurantService.getRestaurantByUsername(
      GlobalData.usernameRestaurant,
    );

    if (rest != null) {
      setState(() {
        restaurantModel = rest;
        restaurantimage = rest.restaurantImage;
        restaurantname = rest.restaurantName;
      });

      await loadTypeMenus();
    }
  }

  Future<void> loadTypeMenus() async {
    if (restaurantModel == null) return;

    final data = await menuService.getTypeMenuByRestaurant(
      restaurantModel!.username!,
    );

    // 🎯 โหลดเมนูของทุกประเภทพร้อมกันก่อน แล้วเก็บไว้เฉพาะประเภทที่มี
    // เมนูอยู่จริงอย่างน้อย 1 รายการ ประเภทที่ไม่มีเมนูจะไม่ถูกสร้างเป็นแท็บเลย
    final entries = await Future.wait(
      data.where((t) => t.typemenuId != null).map((type) async {
        final typeId = type.typemenuId!;
        try {
          final menuData = await menuService.getMenusByTypeMenu(
            restaurantModel!.username!,
            typeId,
          );
          return MapEntry(type, menuData);
        } catch (e) {
          return MapEntry(type, <MenuModel>[]);
        }
      }),
    );

    final validEntries = entries.where((e) => e.value.isNotEmpty).toList();

    final newController = TabController(
      length: validEntries.isEmpty ? 1 : validEntries.length,
      vsync: this,
    );

    _tabController?.dispose();

    setState(() {
      typeMenus = validEntries.map((e) => e.key).toList();
      categoryMenus
        ..clear()
        ..addEntries(
          validEntries.map((e) => MapEntry(e.key.typemenuId!, e.value)),
        );
      categoryLoading
        ..clear()
        ..addEntries(
          validEntries.map((e) => MapEntry(e.key.typemenuId!, false)),
        );
      _tabController = newController;
    });

    // 🎯 นับจำนวนตัวเลือกเสริมของทุกเมนูที่โหลดมา (ไม่ต้องรอ ให้ทำงานเบื้องหลัง)
    _loadAddonCountsFor(validEntries.expand((e) => e.value).toList());
  }

  // 🎯 สร้าง TabController ใหม่หลังหมวดหมู่ถูกเอาออก โดยพยายามคง index/แท็บ
  // ที่ผู้ใช้กำลังดูอยู่ไว้ให้ใกล้เคียงเดิมที่สุด
  void _rebuildTabController({int? removedIndex}) {
    final int oldIndex = _tabController?.index ?? 0;
    _tabController?.dispose();

    final int length = typeMenus.isEmpty ? 1 : typeMenus.length;
    int newIndex = oldIndex;
    if (removedIndex != null && removedIndex < oldIndex) {
      newIndex = oldIndex - 1;
    }
    newIndex = newIndex.clamp(0, length - 1);

    _tabController = TabController(
      length: length,
      vsync: this,
      initialIndex: newIndex,
    );
  }

  Future<void> loadMenusByType(int typeMenuId) async {
    if (restaurantModel == null) return;

    setState(() {
      categoryLoading[typeMenuId] = true;
    });

    try {
      final menuData = await menuService.getMenusByTypeMenu(
        restaurantModel!.username!,
        typeMenuId,
      );

      if (menuData.isEmpty) {
        // 🎯 หมวดหมู่นี้ไม่มีเมนูเหลือแล้ว (เช่น เพิ่งลบเมนูสุดท้ายทิ้ง)
        // เอาแท็บนี้ออกไปเลย แทนที่จะโชว์ "ไม่มีเมนูในหมวดหมู่นี้"
        final removedIndex = typeMenus.indexWhere(
          (t) => t.typemenuId == typeMenuId,
        );
        setState(() {
          categoryMenus.remove(typeMenuId);
          categoryLoading.remove(typeMenuId);
          if (removedIndex != -1) typeMenus.removeAt(removedIndex);
          _rebuildTabController(removedIndex: removedIndex);
        });
      } else {
        setState(() {
          categoryMenus[typeMenuId] = menuData;
          categoryLoading[typeMenuId] = false;
        });
        // 🎯 นับจำนวนตัวเลือกเสริมของเมนูที่เพิ่งโหลด/รีเฟรชมาใหม่
        _loadAddonCountsFor(menuData);
      }
    } catch (e) {
      setState(() {
        categoryLoading[typeMenuId] = false;
      });
    }
  }

  Future<void> toggleStatus(int typeMenuId, int index) async {
    final currentMenus = categoryMenus[typeMenuId];
    if (currentMenus == null || currentMenus.isEmpty) return;

    final menu = currentMenus[index];
    if (menu.menuId == null) return;

    final newStatus = !(menu.status ?? true);

    setState(() {
      categoryMenus[typeMenuId]![index].status = newStatus;
    });

    try {
      await menuService.updateMenuStatus(menu.menuId!, newStatus);
    } catch (e) {
      setState(() {
        categoryMenus[typeMenuId]![index].status = !newStatus;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ไม่สามารถอัปเดตสถานะได้")),
        );
      }
    }
  }

  // 🎯 ไปหน้าแก้ไขเมนู แล้วรีโหลดข้อมูลตอนกลับมา
  Future<void> goToEditMenu(int typeMenuId, MenuModel menu) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditMenu(menuModel: menu)),
    );
    await loadMenusByType(typeMenuId);
  }

  // 🎯 ไปหน้า "menu_to_addon" เพื่อจัดการตัวเลือกเสริมที่ผูกกับเมนูนี้
  Future<void> goToMenuAddon(int typeMenuId, MenuModel menu) async {
    final isUpdated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MenuToAddon(menuModel: menu)),
    );

    // หากมีการกดบันทึกและย้อนกลับมา (isUpdated == true)
    if (isUpdated == true && menu.menuId != null) {
      setState(() {
        // ลบความจำจำนวนตัวเลือกเสริมของเมนูนี้ออก เพื่อบังคับให้นับใหม่
        _menuAddonGroupCounts.remove(menu.menuId);
      });
      // สั่งดึงข้อมูลและนับใหม่เฉพาะเมนูนี้เมนูเดียว (ทำงานรวดเร็วมาก)
      await _loadAddonCountsFor([menu]);
    }
  }

  // 🎯 นับจำนวนกลุ่มตัวเลือกเสริมที่ผูกอยู่กับเมนูนี้
  Future<void> _loadAddonCountsFor(List<MenuModel> menus) async {
    final idsToLoad = menus
        .where(
          (m) =>
              m.menuId != null && !_menuAddonGroupCounts.containsKey(m.menuId),
        )
        .map((m) => m.menuId!)
        .toSet()
        .toList();

    if (idsToLoad.isEmpty) return;

    final results = await Future.wait(
      idsToLoad.map((id) async {
        try {
          final details = await _addonService.getAddonsByMenuId(id);
          final groupIds = details
              .map((d) => d.menuAddonGroup?.addonGroupId)
              .whereType<int>()
              .toSet();
          return MapEntry(id, groupIds.length);
        } catch (e) {
          return MapEntry(id, 0);
        }
      }),
    );

    if (!mounted) return;
    setState(() {
      for (final entry in results) {
        _menuAddonGroupCounts[entry.key] = entry.value;
      }
    });
  }

  String _addonCountLabel(MenuModel menu) {
    final int? menuId = menu.menuId;
    final int count = menuId != null ? (_menuAddonGroupCounts[menuId] ?? 0) : 0;
    return count > 0 ? "มี $count ตัวเลือกเสริม" : "ไม่มีตัวเลือกเสริม";
  }

  // 🎯 ลบเมนู พร้อม dialog ยืนยัน
  Future<void> confirmDeleteMenu(int typeMenuId, MenuModel menu) async {
    final confirmed = await _showConfirmDialog(
      title: "ลบเมนูนี้?",
      message: "ต้องการลบ \"${menu.menuName ?? ''}\" ใช่หรือไม่",
    );

    if (confirmed != true || menu.menuId == null) return;

    try {
      // 🎯 ใช้ key 'menuid' ให้ตรงกับ updateMenuStatus (menuDto ฝั่ง Java)
      await menuService.deleteMenu({'menuid': menu.menuId});
      await loadMenusByType(typeMenuId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("ไม่สามารถลบเมนูได้")));
      }
    }
  }

  // 🎯 ลบกลุ่มตัวเลือกเสริม พร้อม dialog ยืนยัน (คู่กับปุ่มถังขยะแบบใหม่)
  Future<void> confirmDeleteAddonGroup(_AddonGroupAggregate agg) async {
    final groupId = agg.group.addonGroupId;
    if (groupId == null) return;

    final confirmed = await _showConfirmDialog(
      title: "ลบตัวเลือกเสริมกลุ่มนี้?",
      message:
          "ต้องการลบกลุ่ม \"${agg.group.addonGroupName ?? ''}\" ใช่หรือไม่",
    );

    if (confirmed != true) return;

    try {
      final success = await _addonService.deleteAddonGroup(groupId);
      if (success) {
        _addonsLoaded = false;
        await _loadAddonOptions();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ไม่สามารถลบตัวเลือกเสริมได้")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$e".replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  // 🎯 เปิด/ปิดกลุ่มตัวเลือกเสริม — อัปเดต UI ทันที (optimistic)
  Future<void> _toggleAddonGroupEnabled(int groupId, bool newValue) async {
    final bool previousValue = _groupEnabled[groupId] ?? true;
    setState(() => _groupEnabled[groupId] = newValue);

    try {
      final success = await _addonService.toggleAddonGroupStatus(
        groupId,
        newValue,
      );
      if (!success) {
        setState(() => _groupEnabled[groupId] = previousValue);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("ไม่สามารถอัปเดตสถานะได้")),
          );
        }
      }
    } catch (e) {
      setState(() => _groupEnabled[groupId] = previousValue);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$e".replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  // ── กล่อง dialog ยืนยันแบบเดียวกันทั้งหน้า (สไตล์เดียวกับหน้าอื่นในแอป) ──
  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _danger.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: _danger,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: _textMuted),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textMuted,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "ยกเลิก",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _danger,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "ลบ",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // 🎯 ส่วน "ตัวเลือกเพิ่มเติม" — ดึง addon ของทุกเมนูในร้าน แล้ว
  // รวมกลุ่มกันฝั่ง Flutter (ใช้วิธีดึงข้อมูลเดียวกับ _ViewMenuState)
  // ================================================================
  Future<void> _loadAddonOptions() async {
    if (_isLoadingAddons) return;
    setState(() => _isLoadingAddons = true);

    try {
      // ✅ ใช้ endpoint ใหม่ดึงตรงจาก username ไม่ต้องวนผ่านเมนู
      final groups = await _addonService.getAddonGroupsByRestaurant(
        GlobalData.usernameRestaurant ?? "",
      );

      debugPrint("📦 addon groups: ${groups.length} กลุ่ม");

      if (!mounted) return;

      setState(() {
        // แปลง MenuAddonGroupModel → _AddonGroupAggregate
        _addonGroups = groups.map((group) {
          final agg = _AddonGroupAggregate(group);

          // ใส่ details จาก group.details ที่ดึงมาพร้อมกันแล้ว
          for (final detail in group.details ?? []) {
            final itemKey =
                detail.addonMenu?.addonId ??
                detail.addonDetailId ??
                detail.hashCode;
            agg.items.putIfAbsent(itemKey, () => detail);
          }

          return agg;
        }).toList();

        // init state toggle/expand
        for (final agg in _addonGroups) {
          final gid = agg.group.addonGroupId;
          if (gid != null) {
            _groupEnabled.putIfAbsent(gid, () => agg.group.status ?? true);
            _groupExpanded.putIfAbsent(gid, () => false);
          }
          for (final item in agg.items.values) {
            final key =
                item.addonMenu?.addonId ?? item.addonDetailId ?? item.hashCode;
            _itemChecked.putIfAbsent(key, () => item.status ?? true);
          }
        }

        _isLoadingAddons = false;
        _addonsLoaded = true;
      });
    } catch (e) {
      debugPrint("❌ โหลด addon groups ผิดพลาด: $e");
      if (mounted) {
        setState(() => _isLoadingAddons = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("โหลดตัวเลือกเสริมไม่สำเร็จ: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String finalImageUrl = _getFinalImageUrl(restaurantimage);

    if (_tabController == null) {
      return RestaurantScaffold(
        title: "",
        backgroundColor: _bg,
        body: const Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    return RestaurantScaffold(
      title: "",
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // --- ส่วนหัวรูปภาพร้านค้า ---
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        height: 260,
                        width: double.infinity,
                        child: finalImageUrl.isNotEmpty
                            ? Image.network(
                                Uri.encodeFull(finalImageUrl),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholderBackground(),
                              )
                            : _buildPlaceholderBackground(),
                      ),
                      // ไล่เงาด้านล่างให้ตัวหนังสือ/ขอบโค้งอ่านง่ายขึ้น
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 90,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0),
                                  Colors.black.withOpacity(0.18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -1,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(28),
                              topRight: Radius.circular(28),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // --- ชื่อร้าน + แถบเมนู/ตัวเลือกเพิ่มเติม + แถบประเภทเมนู ---
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  restaurantname ?? "-",
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    color: _textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // --- แถบ "เมนู" / "ตัวเลือกเพิ่มเติม" ---
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildMainTabToggle(),
                        ),
                        const SizedBox(height: 12),

                        // --- แถบประเภทเมนู (TabBar) แสดงเฉพาะแท็บ "เมนู" ---
                        if (_mainTabIndex == 0)
                          Container(
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 255, 237, 196),
                              border: Border(
                                bottom: BorderSide(
                                  color: Color(0xFFE0E0E0),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: TabBar(
                              controller: _tabController!,
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              labelColor: Colors.black,
                              unselectedLabelColor: Colors.black87,
                              indicator: BoxDecoration(
                                color: const Color.fromARGB(255, 255, 179, 0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              labelStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              unselectedLabelStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 10,
                              ),
                              tabs: typeMenus.isEmpty
                                  ? [const Tab(text: "ไม่มีประเภท")]
                                  : typeMenus
                                        .map(
                                          (type) =>
                                              Tab(text: type.typemenuName),
                                        )
                                        .toList(),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "${_addonGroups.length} รายการ",
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: _textMuted,
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
          ];
        },

        // --- CONTENT: เมนู (TabBarView) หรือ ตัวเลือกเพิ่มเติม (list กลุ่ม addon) ---
        body: _mainTabIndex == 0
            ? TabBarView(
                controller: _tabController!,
                children: typeMenus.isEmpty
                    ? [
                        const Center(
                          child: Text(
                            "ไม่มีข้อมูลเมนู",
                            style: TextStyle(color: _textMuted),
                          ),
                        ),
                      ]
                    : typeMenus.map((type) {
                        final typeId = type.typemenuId!;
                        final isTabLoading = categoryLoading[typeId] ?? true;
                        final currentMenus = categoryMenus[typeId] ?? [];

                        if (isTabLoading) {
                          return const Center(
                            child: CircularProgressIndicator(color: _primary),
                          );
                        }

                        if (currentMenus.isEmpty) {
                          return const Center(
                            child: Text(
                              "ไม่มีเมนูในหมวดหมู่นี้",
                              style: TextStyle(fontSize: 15, color: _textMuted),
                            ),
                          );
                        }

                        return RefreshIndicator(
                          color: _primary,
                          onRefresh: () => loadMenusByType(typeId),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  0,
                                ),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    "${currentMenus.length} รายการ",
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: _textMuted,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    90,
                                  ),
                                  itemCount: currentMenus.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final menu = currentMenus[index];
                                    final isAvailable = menu.status ?? true;
                                    final finalMenuImgUrl = _getFinalImageUrl(
                                      menu.menuImage,
                                    );

                                    return _buildMenuCard(
                                      typeId: typeId,
                                      index: index,
                                      menu: menu,
                                      isAvailable: isAvailable,
                                      finalMenuImgUrl: finalMenuImgUrl,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
              )
            : _buildAddonOptionsBody(),
      ),
      // 🎯 ปุ่มด้านล่างสลับตามแท็บ: "เพิ่มเมนู" / "เพิ่มตัวเลือก"
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [_primary, _primaryDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () async {
                  if (_mainTabIndex == 0) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddMenu()),
                    );
                    await loadRestaurantData();
                  } else {
                    final saved = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const AddAddon()),
                    );
                    if (saved == true) {
                      _addonsLoaded = false;
                      await _loadAddonOptions();
                    }
                  }
                },
                icon: const Icon(Icons.add_rounded, size: 22),
                label: Text(
                  _mainTabIndex == 0 ? "เพิ่มเมนู" : "เพิ่มตัวเลือก",
                  style: const TextStyle(
                    fontSize: 16,
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

  // --- การ์ดรายการเมนู 1 รายการ ---
  Widget _buildMenuCard({
    required int typeId,
    required int index,
    required MenuModel menu,
    required bool isAvailable,
    required String finalMenuImgUrl,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ViewMenu(menuModel: menu)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAvailable ? Colors.white : const Color(0xFFEDEDED),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 84,
                height: 84,
                child: finalMenuImgUrl.isNotEmpty
                    ? Image.network(
                        Uri.encodeFull(finalMenuImgUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderImage(),
                      )
                    : _placeholderImage(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          menu.menuName ?? "-",
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildInlineStatusButton(
                        isAvailable: isAvailable,
                        onTap: () => toggleStatus(typeId, index),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "ราคา ${menu.price?.toStringAsFixed(0) ?? "-"} บาท",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => goToMenuAddon(typeId, menu),
                          child: Text(
                            _addonCountLabel(menu),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      _buildIconAction(
                        icon: Icons.edit_outlined,
                        color: _textMuted,
                        onTap: () => goToEditMenu(typeId, menu),
                      ),
                      const SizedBox(width: 4),
                      _buildIconAction(
                        icon: Icons.delete_outline_rounded,
                        color: _danger,
                        onTap: () => confirmDeleteMenu(typeId, menu),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ปุ่มไอคอนเล็กๆ ใช้ซ้ำสำหรับ แก้ไข/ลบ ทั้งการ์ดเมนูและกลุ่มตัวเลือกเสริม
  Widget _buildIconAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 19, color: color),
      ),
    );
  }

  // --- แถบ "เมนู" / "ตัวเลือกเพิ่มเติม" แบบมีแท่งไฮไลต์เลื่อนตาม (เหมือน TabBar) ---
  Widget _buildMainTabToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double segmentWidth = constraints.maxWidth / 2;
          return Stack(
            children: [
              // แท่งไฮไลต์สีขาวที่เลื่อนไปมาตามแท็บที่เลือก
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                alignment: _mainTabIndex == 0
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  width: segmentWidth,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(child: _buildMainTabButton(0, "เมนู")),
                  Expanded(child: _buildMainTabButton(1, "ตัวเลือกเพิ่มเติม")),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainTabButton(int index, String label) {
    final bool selected = _mainTabIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        if (_mainTabIndex == index) return;
        setState(() => _mainTabIndex = index);
        if (index == 1 && !_addonsLoaded) {
          // ✅ รอให้ทุก categoryLoading เป็น false ก่อน
          while (categoryLoading.values.any((v) => v == true)) {
            await Future.delayed(const Duration(milliseconds: 200));
          }
          await _loadAddonOptions();
        }
      },
      child: SizedBox(
        height: 42,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: selected ? _primary : _textMuted,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _buildAddonOptionsBody() {
    if (_isLoadingAddons) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    if (_addonGroups.isEmpty) {
      return const Center(
        child: Text(
          "ยังไม่มีตัวเลือกเสริม",
          style: TextStyle(fontSize: 15, color: _textMuted),
        ),
      );
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: () {
        _addonsLoaded = false;
        return _loadAddonOptions();
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        itemCount: _addonGroups.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildAddonGroupCard(_addonGroups[index]);
        },
      ),
    );
  }

  // 🎯 badge เล็กๆ ไว้โชว์ "เลือกได้สูงสุด" กับ "จำเป็น/ไม่บังคับ"
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

  Widget _buildAddonGroupCard(_AddonGroupAggregate agg) {
    final int groupId = agg.group.addonGroupId ?? -1;
    final bool enabled = _groupEnabled[groupId] ?? true;
    final bool expanded = _groupExpanded[groupId] ?? false;
    final bool isRequired = agg.group.isRequired ?? false;
    final int maxSelect = agg.group.maxSelect ?? 1;
    final items = agg.items.values.toList();

    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFF0F0F0),
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
          // ── แถวหัว group ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agg.group.addonGroupName ?? "ไม่มีชื่อกลุ่ม",
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: enabled ? _textDark : Colors.black38,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${items.length} ตัวเลือกย่อย",
                        style: const TextStyle(fontSize: 12, color: _textMuted),
                      ),
                      const SizedBox(height: 8),
                      // 🎯 badge: เลือกได้สูงสุด + จำเป็น/ไม่บังคับ
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildAddonMetaBadge(
                            icon: Icons.playlist_add_check_rounded,
                            label: "เลือกได้สูงสุด $maxSelect",
                            color: _linkBlue,
                          ),
                          _buildAddonMetaBadge(
                            icon: isRequired
                                ? Icons.priority_high_rounded
                                : Icons.check_circle_outline_rounded,
                            label: isRequired ? "จำเป็น" : "ไม่บังคับ",
                            color: isRequired ? _danger : _textMuted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ปุ่มแก้ไข
                _buildIconAction(
                  icon: Icons.edit_outlined,
                  color: _textMuted,
                  onTap: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditAddon(
                          groupId: agg.group.addonGroupId,
                          groupName: agg.group.addonGroupName,
                          isRequired: agg.group.isRequired ?? true,
                          maxSelect: agg.group.maxSelect ?? 1,
                          details: items,
                        ),
                      ),
                    );

                    if (updated == true) {
                      _addonsLoaded = false;
                      await _loadAddonOptions();
                    }
                  },
                ),

                // ปุ่มลบ
                _buildIconAction(
                  icon: Icons.delete_outline_rounded,
                  color: _danger,
                  onTap: () => confirmDeleteAddonGroup(agg),
                ),
                const SizedBox(width: 2),

                // ลูกศรขยาย/ย่อ
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _textMuted,
                      size: 22,
                    ),
                  ),
                  onPressed: () =>
                      setState(() => _groupExpanded[groupId] = !expanded),
                ),
                const SizedBox(width: 6),

                // Toggle switch
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: enabled,
                    activeColor: Colors.white,
                    activeTrackColor: _primary,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade400,
                    onChanged: (val) => _toggleAddonGroupEnabled(groupId, val),
                  ),
                ),
              ],
            ),
          ),

          // ── รายการ addon detail (ขยายได้) ───────────────
          if (expanded && items.isNotEmpty) ...[
            Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 14, 12),
              child: Container(
                // 🎯 เส้นซ้ายยาวต่อเนื่องครอบทุกแถว แบบเดียวกับหน้า menu_to_addon
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
                      _buildAddonItemRow(items[i]),
                      if (i < items.length - 1) const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddonItemRow(MenuAddonDetailModel detail) {
    final key =
        detail.addonMenu?.addonId ?? detail.addonDetailId ?? detail.hashCode;
    final bool checked = _itemChecked[key] ?? true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // ชื่อ addon
          Expanded(
            child: Text(
              detail.addonMenu?.addonName ?? "ไม่มีชื่อ",
              style: const TextStyle(
                fontSize: 14,
                color: _textDark,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ราคา
          Text(
            "ราคา ${detail.addonPrice?.toInt() ?? 0} บาท",
            style: const TextStyle(fontSize: 13, color: _textMuted),
          ),
          const SizedBox(width: 60),

          // Checkbox
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: checked,
              activeColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              onChanged: (val) =>
                  setState(() => _itemChecked[key] = val ?? true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 32),
    );
  }

  Widget _buildPlaceholderBackground() {
    return Container(
      color: _primary.withOpacity(0.85),
      child: const Icon(
        Icons.storefront_rounded,
        size: 72,
        color: Colors.white,
      ),
    );
  }

  // ── ปุ่มสถานะ "มี/หมด" ทรงแคปซูลลอยมุมขวาบนของการ์ดเมนู ────────────────
  Widget _buildInlineStatusButton({
    required bool isAvailable,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 58,
      height: 26,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isAvailable ? _primary : _danger,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isAvailable ? _primary : _danger).withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: isAvailable ? Alignment.centerRight : Alignment.centerLeft,
        children: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(
                left: isAvailable ? 0 : 13,
                right: isAvailable ? 13 : 0,
              ),
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    ),
  );
}

// 🎯 คลาสช่วยรวมข้อมูล addon detail ที่กระจายอยู่ตามเมนูต่าง ๆ
// ให้กลายเป็น "1 กลุ่ม = 1 การ์ด" สำหรับหน้าตัวเลือกเพิ่มเติม
class _AddonGroupAggregate {
  final MenuAddonGroupModel group;
  final Map<int, MenuAddonDetailModel> items = {};

  _AddonGroupAggregate(this.group);
}
