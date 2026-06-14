// features/member/list_menu_member.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/data/models/type_menu_model.dart'; // 🎯 ดึงโมเดลประเภทเมนูมาร่วมประกอบโครงสร้าง
import 'package:flutter_app/data/services/menu/menu_service.dart';
import 'package:flutter_app/features/member/add_order_member.dart';
import 'package:flutter_app/features/member/navbar_member.dart';
import 'package:flutter_app/core/network/dio_client.dart'; // 🎯 เรียกไอพีส่วนกลางมาดักพาร์ทรูปภาพ

class ListMenuMember extends StatefulWidget {
  final RestaurantModel
  restaurantModel; // 🎯 รับข้อมูลร้านค้าต่อสายมาจากหน้า ViewRestaurantMember
  const ListMenuMember({super.key, required this.restaurantModel});

  @override
  State<ListMenuMember> createState() => _ListMenuMemberState();
}

class _ListMenuMemberState extends State<ListMenuMember>
    with TickerProviderStateMixin {
  final MenuService _menuService = MenuService();
  TabController? _tabController;

  bool _isLoading = true;
  List<TypeMenuModel> _typeMenus =
      []; // 🎯 เก็บรายการหมวดหมู่ประเภทอาหารของร้าน
  Map<int, List<MenuModel>> _categoryMenus =
      {}; // 🎯 คัดกลุ่มเมนูอาหารลงกล่อง Map

  String? restaurantimage;
  String? restaurantname = "กำลังโหลด...";

  @override
  void initState() {
    super.initState();
    _loadAllMenuData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // 🎯 ฟังก์ชันช่วยต่อสายพาร์ทรูปภาพสั้นเข้าหาเซิร์ฟเวอร์ไอพีหลัก
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

  // 🎯 ดึงพาร์ทประเภทและจับคัดเมนูแยกหมวดหมู่ที่พร้อมขายจริง (status != false)
  Future<void> _loadAllMenuData() async {
    if (widget.restaurantModel.username == null) return;

    try {
      // 1. เรียกประเภทเมนูทั้งหมดของร้านค้า
      final categories = await _menuService.getTypeMenuByRestaurant(
        widget.restaurantModel.username!,
      );

      // 2. ดึงรายการอาหารในแต่ละหมวดหมู่และคัดเฉพาะสถานะพร้อมขาย
      for (var cat in categories) {
        if (cat.typemenuId != null) {
          final menuData = await _menuService.getMenusByTypeMenu(
            widget.restaurantModel.username!,
            cat.typemenuId!,
          );

          // โชว์เฉพาะเมนูที่มีของขายอยู่ ณ เวลาปัจจุบัน
          _categoryMenus[cat.typemenuId!] = menuData
              .where((m) => m.status ?? true)
              .toList();
        }
      }

      final newController = TabController(
        length: categories.isEmpty ? 1 : categories.length,
        vsync: this,
      );

      _tabController?.dispose();

      if (mounted) {
        setState(() {
          _typeMenus = categories;
          _tabController = newController;
          restaurantimage = _getFinalImageUrl(
            widget.restaurantModel.restaurantImage,
          );
          restaurantname = widget.restaurantModel.restaurantName;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching member menus data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _tabController == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: const NavbarMember(
        title: "",
      ), // เรียกใช้ Navbar โครงสร้างระบบสมาชิกตามเดิม
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

                        // กล่องรายละเอียดชื่อร้านค้า
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
                                child: Text(
                                  restaurantname ?? "-",
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // 🌟 ก๊อปปี้โครง CSS ยอดนิยม: แถบหมวดหมู่สีเหลืองพาสเทลตัวอักษรและขีดล่างเน้นดำ คลีนตามาก!
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
                                  isScrollable: _typeMenus.length > 3,
                                  tabAlignment: _typeMenus.length > 3
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
                                  tabs: _typeMenus.isEmpty
                                      ? [const Tab(text: "ไม่มีประเภท")]
                                      : _typeMenus
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

              // --- CONTENT (รายการสินค้ากดสั่งลงตะกร้าแยกตามแต่ละแท็บ) ---
              body: TabBarView(
                controller: _tabController!,
                children: _typeMenus.isEmpty
                    ? [const Center(child: Text("ไม่มีข้อมูลเมนู"))]
                    : _typeMenus.map((type) {
                        final typeId = type.typemenuId!;
                        final currentMenus = _categoryMenus[typeId] ?? [];

                        if (currentMenus.isEmpty) {
                          return const Center(
                            child: Text(
                              "ไม่มีเมนูพร้อมจำหน่ายในหมวดหมู่นี้",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: currentMenus.length,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemBuilder: (context, index) {
                            final menu = currentMenus[index];
                            String? rawMenuImage =
                                menu.menuImage ?? (menu as dynamic).imageUrl;
                            String finalMenuUrl = _getFinalImageUrl(
                              rawMenuImage,
                            );

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 8,
                              ),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: InkWell(
                                // กดยิงเข้าหน้าสั่งเมนูอาหารใส่ตะกร้าจริงของ Member
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AddOrderMember(menuModel: menu),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(15),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: finalMenuUrl.isNotEmpty
                                        ? Image.network(
                                            Uri.encodeFull(finalMenuUrl),
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return _buildPlaceholderIcon();
                                                },
                                          )
                                        : _buildPlaceholderIcon(),
                                  ),
                                  title: Text(
                                    menu.menuName ?? "ไม่มีชื่อเมนู",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (menu.description != null &&
                                            menu.description!.isNotEmpty)
                                          Text(
                                            menu.description!,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "ราคา ${menu.price?.toStringAsFixed(0) ?? '0'} บาท",
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: IconButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AddOrderMember(menuModel: menu),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.add_circle,
                                      color: Colors.green,
                                      size: 36,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.orange.shade50,
      child: const Icon(Icons.fastfood, size: 32, color: Colors.orange),
    );
  }
}
