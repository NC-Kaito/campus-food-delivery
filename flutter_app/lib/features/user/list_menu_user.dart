// features/member/list_menu_user.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/data/models/type_menu_model.dart'; // 🎯 อิมพอร์ตโมเดลประเภทเมนู
import 'package:flutter_app/data/services/menu/menu_service.dart';
import 'package:flutter_app/features/member/login_member.dart';
import 'package:flutter_app/core/network/dio_client.dart'; // 🎯 ดึงตัวแปรไอพีกลางสากลเข้ามาจัดการความชัวร์ของรูปภาพ

class ListMenuUser extends StatefulWidget {
  final RestaurantModel restaurantModel;
  const ListMenuUser({super.key, required this.restaurantModel});

  @override
  State<ListMenuUser> createState() => _ListMenuUserState();
}

class _ListMenuUserState extends State<ListMenuUser>
    with TickerProviderStateMixin {
  final MenuService _menuService = MenuService();
  TabController? _tabController;

  bool _isLoading = true;
  List<TypeMenuModel> _typeMenus = []; // 🎯 เก็บรายการหมวดหมู่ประเภทอาหาร
  Map<int, List<MenuModel>> _categoryMenus =
      {}; // 🎯 แยกรายการเมนูตามไอดีประเภทอาหาร

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

  // 🎯 ฟังก์ชันสากลช่วยกะเทาะและเชื่อมพาร์ทรูปสั้นเข้ากับ URL ไอพีกลางให้ถูกต้องสมบูรณ์
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

  // 🎯 ฟังก์ชันรวบรวมข้อมูลหมวดหมู่และรายการอาหารทีเดียวพร้อมแยกกลุ่ม
  Future<void> _loadAllMenuData() async {
    if (widget.restaurantModel.username == null) return;

    try {
      // 1. ดึงประเภทหมวดหมู่เมนูทั้งหมดของร้านนี้
      final categories = await _menuService.getTypeMenuByRestaurant(
        widget.restaurantModel.username!,
      );

      // 2. ดึงรายการเมนูทั้งหมดมาจัดกลุ่มลง Map ตามประเภทไอดี
      for (var cat in categories) {
        if (cat.typemenuId != null) {
          final menuData = await _menuService.getMenusByTypeMenu(
            widget.restaurantModel.username!,
            cat.typemenuId!,
          );

          // 🌟 คัดกรองเอาเฉพาะเมนูที่มีสถานะพร้อมขาย (status == true) มาให้ผู้ใช้ส่องดู
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
      print("Error fetching user menus data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🎯 ฟังก์ชันสำหรับแสดง Popup แจ้งเตือนความปลอดภัยแบบสวยงาม
  void _showLoginWarningDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text(
                "เข้าสู่ระบบเพื่อสั่งอาหาร",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          content: const Text(
            "กรุณาเข้าสู่ระบบสมาชิกก่อน เพื่อสัมผัสความอร่อยและเริ่มสั่งอาหารกับทางเราได้ทันที",
            style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "ไว้ทีหลัง",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginMember()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
              ),
              child: const Text(
                "เข้าสู่ระบบ",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: CircleAvatar(
          backgroundColor: Colors.black38,
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
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

                              // 🎯 แก้ไขจุดสำคัญ: ปรับปรุง "CSS บล็อกสีแถบ" ให้เป็นเหลืองนวล อักษรดำ Indicator ดำตามสั่งกริบๆ
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
                                onTap: _showLoginWarningDialog,
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
                                    onPressed: _showLoginWarningDialog,
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
