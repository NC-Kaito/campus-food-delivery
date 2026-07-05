// features/restaurant/list_menu_restaurant.dart
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
import 'package:flutter_app/core/network/dio_client.dart'; // 🎯 ดึงตัวแปรไอพีกลางเข้ามาร้อยสายรูปภาพสากล

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

  // 🎯 ฟังก์ชันสากลช่วยจัดรูปพาร์ทสั้นเข้าหาไอพีศูนย์กลาง
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
      restaurantModel = rest;

      // 🌟 ดึงพาร์ทรูปหน้าร้านร้อยผ่านฟังก์ชันประกอบไอพีสากล
      restaurantimage = _getFinalImageUrl(rest.restaurantImage);

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
                              child:
                                  restaurantimage != null &&
                                      restaurantimage!.isNotEmpty
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
                                    // 🎯 ปรับปุ่มเพิ่มเมนูอาหาร: ปลุกเสกเปลี่ยนจากโทนสีชมพูเป็นสีเขียวสากลเรียบร้อยครับ
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF76FF03,
                                        ), // สีเขียวสว่างสากลแมตช์ธีมแอป
                                        foregroundColor: Colors.black,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
                                      ),
                                      onPressed: () async {
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
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // --- TAB BAR (แถบประเภทเมนูอาหารกลาง) ---
                              // ค้นหาคำว่า Container ที่ครอบ TabBar ของคุณอยู่ แล้วเปลี่ยนเป็นแบบนี้ครับ
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
                                  isScrollable: true, // 🎯 ให้เลื่อนซ้าย-ขวาได้
                                  tabAlignment:
                                      TabAlignment.start, // 🎯 เริ่มจากซ้าย
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
                                  // 🎯 เพิ่ม labelPadding เพื่อให้ช่องว่างสวยงามและปรับความกว้าง tab ให้เห็น 3 อัน
                                  labelPadding: EdgeInsets.symmetric(
                                    horizontal:
                                        MediaQuery.of(context).size.width / 12,
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

              // --- CONTENT (รายการเมนูอาหารแยกตามแท็บหมวดหมู่) ---
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

                              final finalMenuImgUrl = _getFinalImageUrl(
                                menu.menuImage,
                              );

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ViewMenu(menuModel: menu),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isAvailable
                                        ? Colors.white
                                        : const Color.fromARGB(
                                            255,
                                            206,
                                            206,
                                            206,
                                          ),
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
                                            child: finalMenuImgUrl.isNotEmpty
                                                ? Image.network(
                                                    Uri.encodeFull(
                                                      finalMenuImgUrl,
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
                                              // ในส่วนของ Row ปุ่มเดิม เปลี่ยนเป็นอันนี้
                                              Row(
                                                children: [
                                                  const SizedBox(width: 200),
                                                  _buildInlineStatusButton(
                                                    isAvailable:
                                                        isAvailable, // ใช้ค่า status ปัจจุบัน
                                                    onTap: () => toggleStatus(
                                                      typeId,
                                                      index,
                                                    ), // กดแล้วเรียกฟังก์ชันสลับสถานะ
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
    required bool isAvailable,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 70, // ขยายความกว้างจาก 60 เป็น 70 เพื่อให้มีที่ว่างใส่ข้อความ
      height: 30,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isAvailable
            ? const Color(0xFF8BC34A) // เขียว
            : const Color.fromARGB(255, 255, 0, 0), // แดง
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: isAvailable ? Alignment.centerRight : Alignment.centerLeft,
        children: [
          // ข้อความแสดงสถานะ
          Center(
            child: Padding(
              padding: EdgeInsets.only(
                // เว้นที่ให้วงกลมไม่บังข้อความ
                left: isAvailable ? 0 : 15,
                right: isAvailable ? 15 : 0,
              ),
              child: Text(
                isAvailable ? "มี" : "หมด",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          // วงกลมปุ่มเลื่อน
          Container(
            width: 26,
            height: 26,
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
