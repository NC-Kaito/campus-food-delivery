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
                              const SizedBox(width: 60),
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
      onTap: () async {
        setState(() => _mainTabIndex = index);
        if (index == 1 && !_addonsLoaded) {
          // ✅ รอให้ทุก categoryLoading เป็น false ก่อน
          while (categoryLoading.values.any((v) => v == true)) {
            await Future.delayed(const Duration(milliseconds: 200));
          }
          await _loadAddonOptions();
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
        // ถ้าปิดอยู่ให้พื้นหลังเทา เหมือนในรูป "น้ำจิ้ม"
        color: enabled ? Colors.white : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? const Color(0xFFE0E0E0) : const Color(0xFFD0D0D0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── แถวหัว group ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // ชื่อกลุ่ม — bold ถ้าเปิด, dim ถ้าปิด
                Expanded(
                  flex: 3,
                  child: Text(
                    agg.group.addonGroupName ?? "ไม่มีชื่อกลุ่ม",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: enabled ? Colors.black : Colors.black38,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // "ใช้กับ X เมนู"
                Text(
                  "ใช้กับ ${agg.group.menuCount ?? 0} เมนู",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 10),

                // ปุ่มแก้ไข
                GestureDetector(
                  onTap: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditAddon(
                          groupId: agg.group.addonGroupId,
                          groupName: agg.group.addonGroupName,
                          isRequired: agg.group.isRequired ?? true,
                          maxSelect: agg.group.maxSelect ?? 1,
                          details:
                              items, // ← ส่ง List<MenuAddonDetailModel> ตรงๆ เลย
                        ),
                      ),
                    );

                    // ถ้าแก้ไขสำเร็จ (EditAddon ทำ Navigator.pop(context, true))
                    // ให้รีเฟรชข้อมูลกลุ่มตัวเลือกใหม่
                    if (updated == true) {
                      // TODO: เรียก method โหลดข้อมูลกลุ่มตัวเลือกใหม่ของหน้านี้
                      // เช่น await _loadAddonGroups();
                    }
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
                const SizedBox(width: 4),

                // ลูกศรขยาย/ย่อ
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.black54,
                      size: 22,
                    ),
                  ),
                  onPressed: () =>
                      setState(() => _groupExpanded[groupId] = !expanded),
                ),
                const SizedBox(width: 4),

                // Toggle switch
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: enabled,
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF8BC34A),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade400,
                    onChanged: (val) =>
                        setState(() => _groupEnabled[groupId] = val),
                  ),
                ),
              ],
            ),
          ),

          // ── รายการ addon detail (ขยายได้) ───────────────
          if (expanded && items.isNotEmpty) ...[
            Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          // เส้นสีเขียวซ้าย
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF76FF03),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),

          // ชื่อ addon
          Expanded(
            child: Text(
              detail.addonMenu?.addonName ?? "ไม่มีชื่อ",
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ราคา
          Text(
            "ราคา  ${detail.addonPrice?.toInt() ?? 0} บาท",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 8),

          // Checkbox
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: checked,
              activeColor: Colors.blueAccent,
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
  final Map<int, MenuAddonDetailModel> items = {};

  _AddonGroupAggregate(this.group);
}
