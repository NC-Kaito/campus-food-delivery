// features/restaurant/home_restaurant.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/data/models/menu_addon_detail_model.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/type_menu_model.dart';
import 'package:flutter_app/data/services/menu/menu_addon_service.dart';
import 'package:flutter_app/data/services/menu/menu_service.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/features/restaurant/add_menu.dart';
import 'package:flutter_app/features/restaurant/add_addon.dart';
// 🎯 หน้าแก้ไขเมนู — ปรับ path/ชื่อคลาสให้ตรงกับโปรเจกต์จริงถ้าไม่ตรงกัน
import 'package:flutter_app/features/restaurant/edit_menu.dart';
import 'package:flutter_app/features/restaurant/restaurant_navbar.dart';
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

    final newController = TabController(
      length: data.isEmpty ? 1 : data.length,
      vsync: this,
    );

    _tabController?.dispose();

    setState(() {
      typeMenus = data;
      _tabController = newController;
    });

    for (var type in data) {
      if (type.typemenuId != null) {
        loadMenusByType(type.typemenuId!);
      }
    }
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
      setState(() {
        categoryMenus[typeMenuId] = menuData;
        categoryLoading[typeMenuId] = false;
      });
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

  // 🎯 ลบเมนู พร้อม dialog ยืนยัน
  Future<void> confirmDeleteMenu(int typeMenuId, MenuModel menu) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("ลบเมนูนี้?"),
        content: Text("ต้องการลบ \"${menu.menuName ?? ''}\" ใช่หรือไม่"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("ยกเลิก"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("ลบ", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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

  // ================================================================
  // 🎯 ส่วน "ตัวเลือกเพิ่มเติม" — ดึง addon ของทุกเมนูในร้าน แล้ว
  // รวมกลุ่มกันฝั่ง Flutter (ใช้วิธีดึงข้อมูลเดียวกับ _ViewMenuState)
  // ================================================================
  Future<void> _loadAddonOptions() async {
    if (_isLoadingAddons) return;

    setState(() => _isLoadingAddons = true);

    // รวมเมนูทั้งหมดของร้าน (ทุกหมวดหมู่) ที่โหลดไว้แล้ว
    final allMenus = categoryMenus.values.expand((list) => list).toList();

    final futures = allMenus
        .where((m) => m.menuId != null)
        .map(
          (m) => _addonService
              .getAddonsByMenuId(m.menuId!)
              .then((details) => MapEntry(m.menuId!, details)),
        );

    List<MapEntry<int, List<MenuAddonDetailModel>>> results = [];
    try {
      results = await Future.wait(futures);
    } catch (e) {
      debugPrint("โหลดตัวเลือกเสริมผิดพลาด: $e");
    }

    final Map<int, _AddonGroupAggregate> groupMap = {};

    for (final entry in results) {
      final menuId = entry.key;
      for (final detail in entry.value) {
        final group = detail.menuAddonGroup;
        final groupId = group?.addonGroupId;
        if (group == null || groupId == null) continue;

        final agg = groupMap.putIfAbsent(
          groupId,
          () => _AddonGroupAggregate(group),
        );
        agg.menuIds.add(menuId);

        // dedup รายการ addon ในกลุ่มด้วย id ของ addon จริง (ไม่ใช่ addonDetailId
        // เพราะ addonDetailId อาจต่างกันไปตามเมนูที่ผูกไว้)
        final itemKey =
            detail.addonMenu?.addonId ??
            detail.addonDetailId ??
            detail.hashCode;
        agg.items.putIfAbsent(itemKey, () => detail);
      }
    }

    if (!mounted) return;

    setState(() {
      _addonGroups = groupMap.values.toList();
      for (final agg in _addonGroups) {
        final gid = agg.group.addonGroupId;
        if (gid != null) {
          _groupEnabled.putIfAbsent(gid, () => true);
          _groupExpanded.putIfAbsent(gid, () => false);
        }
        for (final item in agg.items.values) {
          final key =
              item.addonMenu?.addonId ?? item.addonDetailId ?? item.hashCode;
          _itemChecked.putIfAbsent(key, () => true);
        }
      }
      _isLoadingAddons = false;
      _addonsLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String finalImageUrl = _getFinalImageUrl(restaurantimage);

    if (_tabController == null) {
      return const RestaurantScaffold(
        title: "",
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return RestaurantScaffold(
      title: "",
      backgroundColor: Colors.white,
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
                        height: 290,
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
                      Positioned(
                        bottom: -1,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(35),
                              topRight: Radius.circular(35),
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
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                          child: Text(
                            restaurantname ?? "-",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // --- แถบ "เมนู" / "ตัวเลือกเพิ่มเติม" ---
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Expanded(child: _buildMainTabButton(0, "เมนู")),
                              Expanded(
                                child: _buildMainTabButton(
                                  1,
                                  "ตัวเลือกเพิ่มเติม",
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // --- แถบประเภทเมนู (TabBar) แสดงเฉพาะแท็บ "เมนู" ---
                        if (_mainTabIndex == 0)
                          Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFFFC8),
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
                                color: const Color(0xFFFFEB3B),
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
                                horizontal: 18,
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
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 24, 8),
                              child: Text(
                                "${_addonGroups.length} รายการ",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
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
                    ? [const Center(child: Text("ไม่มีข้อมูลเมนู"))]
                    : typeMenus.map((type) {
                        final typeId = type.typemenuId!;
                        final isTabLoading = categoryLoading[typeId] ?? true;
                        final currentMenus = categoryMenus[typeId] ?? [];

                        if (isTabLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (currentMenus.isEmpty) {
                          return const Center(
                            child: Text(
                              "ไม่มีเมนูในหมวดหมู่นี้",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          );
                        }

                        return RefreshIndicator(
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
                                      fontSize: 13,
                                      color: Colors.black54,
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
                                      const SizedBox(height: 10),
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
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF76FF03),
                foregroundColor: Colors.black,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
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
              child: Text(
                _mainTabIndex == 0 ? "เพิ่มเมนู" : "เพิ่มตัวเลือก",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
        decoration: BoxDecoration(
          color: isAvailable
              ? Colors.white
              : const Color.fromARGB(255, 206, 206, 206),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 90,
                      height: 90,
                      child: finalMenuImgUrl.isNotEmpty
                          ? Image.network(
                              Uri.encodeFull(finalMenuImgUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholderImage(),
                            )
                          : _placeholderImage(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 60),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            menu.menuName ?? "-",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "ราคา ${menu.price?.toStringAsFixed(0) ?? "-"} บาท",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  // 🎯 เปลี่ยนเป็นฟิลด์จำนวนตัวเลือกเสริมจริงของ MenuModel
                                  "มี 1 ตัวเลือกเสริม",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.blueAccent,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => goToEditMenu(typeId, menu),
                                child: const Text(
                                  "แก้ไข",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => confirmDeleteMenu(typeId, menu),
                                child: const Text(
                                  "ลบ",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _buildInlineStatusButton(
                isAvailable: isAvailable,
                onTap: () => toggleStatus(typeId, index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTabButton(int index, String label) {
    final bool selected = _mainTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _mainTabIndex = index);
        if (index == 1 && !_addonsLoaded) {
          _loadAddonOptions();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF9CFF57), Color(0xFFE8FFDD)],
                )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : const Color(0xFFE0E0E0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.black : Colors.black45,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // 🎯 UI ของแท็บ "ตัวเลือกเพิ่มเติม"
  // ================================================================
  Widget _buildAddonOptionsBody() {
    if (_isLoadingAddons) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    if (_addonGroups.isEmpty) {
      return const Center(
        child: Text(
          "ยังไม่มีตัวเลือกเสริม",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () {
        _addonsLoaded = false;
        return _loadAddonOptions();
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        itemCount: _addonGroups.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return _buildAddonGroupCard(_addonGroups[index]);
        },
      ),
    );
  }

  Widget _buildAddonGroupCard(_AddonGroupAggregate agg) {
    final int groupId = agg.group.addonGroupId ?? -1;
    final bool enabled = _groupEnabled[groupId] ?? true;
    final bool expanded = _groupExpanded[groupId] ?? false;
    final items = agg.items.values.toList();

    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFECECEC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    agg.group.addonGroupName ?? "ไม่มีชื่อกลุ่ม",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  "ใช้กับ ${agg.menuIds.length} เมนู",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    // 🎯 เชื่อมหน้าแก้ไขกลุ่มตัวเลือกเสริมจริงตรงนี้
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("ฟังก์ชันแก้ไขตัวเลือกยังไม่พร้อมใช้งาน"),
                      ),
                    );
                  },
                  child: const Text(
                    "แก้ไข",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.black54,
                  ),
                  onPressed: () =>
                      setState(() => _groupExpanded[groupId] = !expanded),
                ),
                const SizedBox(width: 4),
                Switch(
                  value: enabled,
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF8BC34A),
                  onChanged: (val) =>
                      setState(() => _groupEnabled[groupId] = val),
                ),
              ],
            ),
          ),
          if (expanded) ...[
            Divider(height: 1, thickness: 1, color: Colors.grey[300]),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: items
                    .map((detail) => _buildAddonItemRow(detail))
                    .toList(),
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
          Container(width: 3, height: 18, color: const Color(0xFF76FF03)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              detail.addonMenu?.addonName ?? "ไม่มีชื่อ",
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            "ราคา ${detail.addonPrice?.toInt() ?? 0} บาท",
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          Checkbox(
            value: checked,
            activeColor: Colors.blueAccent,
            onChanged: (val) => setState(() => _itemChecked[key] = val ?? true),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 36),
    );
  }

  Widget _buildPlaceholderBackground() {
    return Container(
      color: const Color(0xFFD92D2D),
      child: const Icon(Icons.image_outlined, size: 80, color: Colors.white),
    );
  }

  Widget _buildInlineStatusButton({
    required bool isAvailable,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 60,
      height: 26,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isAvailable
            ? const Color(0xFF8BC34A)
            : const Color.fromARGB(255, 255, 0, 0),
        borderRadius: BorderRadius.circular(20),
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
              child: Text(
                isAvailable ? "มี" : "หมด",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
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
  final Set<int> menuIds = {};
  final Map<int, MenuAddonDetailModel> items = {}; // key = addonId (dedup)

  _AddonGroupAggregate(this.group);
}
