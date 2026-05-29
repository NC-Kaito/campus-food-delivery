import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/type_menu_model.dart';
import 'package:flutter_app/data/services/menu/menu_service.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/features/restaurant/add_menu.dart';
import 'package:flutter_app/features/restaurant/restaurant_navbar.dart';
import 'package:flutter_app/features/restaurant/view_menu.dart';
import 'package:flutter_app/global_data.dart';

class ListMenuRestaurant extends StatefulWidget {
  const ListMenuRestaurant({super.key});

  @override
  State<ListMenuRestaurant> createState() => _ListMenuRestaurantState();
}

class _ListMenuRestaurantState extends State<ListMenuRestaurant>
    with TickerProviderStateMixin {
  final RestaurantService restaurantService = RestaurantService();
  final MenuService menuService = MenuService();

  TabController? _tabController;

  List<TypeMenuModel> typeMenus = [];
  RestaurantModel? restaurantModel;

  String? restaurantimage;
  String? restaurantname = "กำลังโหลด...";

  Map<int, List<MenuModel>> categoryMenus = {};
  Map<int, bool> categoryLoading = {};

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

  Future<void> loadRestaurantData() async {
    final rest = await restaurantService.getRestaurantByUsername(
      GlobalData.usernameRestaurant,
    );

    if (rest != null) {
      restaurantModel = rest;

      // ✅ แก้ไขจุดที่ 1: ดึง URL รูปหน้าร้านตรงๆ ไม่ต้องใช้ .replaceAll สับขาหลอกไอพีแล้ว
      restaurantimage = rest.restaurantImage;

      restaurantname = rest.restaurantName;
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

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: const RestaurantNavbar(title: ""),
      body: Column(
        children: [
          Expanded(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // --- ส่วนหัวรูปภาพร้านค้าเสมือนลอยพื้นหลัง ---
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            SizedBox(
                              height: 290,
                              width: double.infinity,
                              child: restaurantimage != null
                                  ? Image.network(
                                      Uri.encodeFull(restaurantimage!),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (
                                            context,
                                            error,
                                            stackTrace,
                                          ) => Image.asset(
                                            'assets/images/default_restaurant.png',
                                            fit: BoxFit.cover,
                                          ),
                                    )
                                  : Container(
                                      color: const Color(0xFFD92D2D),
                                      child: const Center(
                                        child: Icon(
                                          Icons.image_outlined,
                                          size: 80,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                            ),
                            Positioned(
                              bottom: -1,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 35,
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

                        // กล่องรายละเอียดร้านค้า
                        Container(
                          width: double.infinity,
                          color: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        restaurantname ?? "-",
                                        style: const TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(
                                          255,
                                          43,
                                          255,
                                          0,
                                        ),
                                        side: const BorderSide(
                                          color: Color.fromARGB(
                                            255,
                                            158,
                                            158,
                                            158,
                                          ),
                                          width: 1,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 3,
                                        ),
                                      ),
                                      onPressed: () async {
                                        // 🌟 พอกลับมาจากหน้าเพิ่มเมนู ให้โหลดข้อมูลหมวดหมู่และลิสต์ใหม่เพื่อความชัวร์
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const AddMenu(),
                                          ),
                                        );
                                        await loadRestaurantData();
                                      },
                                      child: const Text(
                                        "เพิ่มเมนู",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // --- TAB BAR (แถบประเภทเมนูอาหารกลาง) ---
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
                                  isScrollable: typeMenus.length > 3,
                                  tabAlignment: typeMenus.length > 3
                                      ? TabAlignment.start
                                      : TabAlignment.fill,
                                  labelColor: Colors.black,
                                  unselectedLabelColor: Colors.black54,
                                  indicatorColor: Colors.black,
                                  indicatorWeight: 3,
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  dividerColor: Colors.transparent,
                                  labelStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  unselectedLabelStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
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
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ];
              },

              // --- CONTENT (รายการสไลด์อาหารจานย่อย) ---
              body: TabBarView(
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
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            itemCount: currentMenus.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final menu = currentMenus[index];
                              final isAvailable = menu.status ?? true;

                              return GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ViewMenu(),
                                    ),
                                  );
                                  loadMenusByType(typeId);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isAvailable
                                        ? Colors.white
                                        : const Color(0xFFEEEEEE),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        // รูปภาพอาหาร
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: SizedBox(
                                            width: 110,
                                            height: 110,
                                            child: menu.menuImage != null
                                                ? Image.network(
                                                    // ✅ แก้ไขจุดที่ 2: ดึงผ่านไอพีตรงๆ จาก DB ไม่ต้องสั่งสลับตัวเลขไอพีขัดขาตัวเองแล้ว
                                                    Uri.encodeFull(
                                                      menu.menuImage!,
                                                    ),
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (_, __, ___) =>
                                                            _placeholderImage(),
                                                  )
                                                : _placeholderImage(),
                                          ),
                                        ),
                                        const SizedBox(width: 25),

                                        // รายละเอียดเมนูอาหาร
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              const SizedBox(height: 10),

                                              // ปุ่มเปิด-ปิดสถานะ มี / หมด
                                              Row(
                                                children: [
                                                  const SizedBox(width: 55),
                                                  SizedBox(
                                                    width: 100,
                                                    child:
                                                        _buildInlineStatusButton(
                                                          label: "มี",
                                                          isSelected:
                                                              isAvailable,
                                                          selectedColor:
                                                              const Color(
                                                                0xFF8BC34A,
                                                              ),
                                                          onTap: isAvailable
                                                              ? null
                                                              : () =>
                                                                    toggleStatus(
                                                                      typeId,
                                                                      index,
                                                                    ),
                                                        ),
                                                  ),
                                                  const SizedBox(width: 30),
                                                  SizedBox(
                                                    width: 100,
                                                    child:
                                                        _buildInlineStatusButton(
                                                          label: "หมด",
                                                          isSelected:
                                                              !isAvailable,
                                                          selectedColor:
                                                              const Color(
                                                                0xFFE53935,
                                                              ),
                                                          onTap: !isAvailable
                                                              ? null
                                                              : () =>
                                                                    toggleStatus(
                                                                      typeId,
                                                                      index,
                                                                    ),
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
              ),
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

  Widget _buildInlineStatusButton({
    required String label,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.grey.shade400,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }
}
