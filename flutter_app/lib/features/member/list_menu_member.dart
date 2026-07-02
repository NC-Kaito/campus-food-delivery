// features/member/list_menu_member.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/data/models/type_menu_model.dart';
import 'package:flutter_app/data/services/menu/menu_service.dart';
import 'package:flutter_app/features/member/add_order_member.dart';
import 'package:flutter_app/features/member/navbar_member.dart';
import 'package:flutter_app/core/network/dio_client.dart';

class ListMenuMember extends StatefulWidget {
  final RestaurantModel restaurantModel;
  const ListMenuMember({super.key, required this.restaurantModel});

  @override
  State<ListMenuMember> createState() => _ListMenuMemberState();
}

class _ListMenuMemberState extends State<ListMenuMember>
    with TickerProviderStateMixin {
  final MenuService _menuService = MenuService();
  TabController? _tabController;

  bool _isLoading = true;
  List<TypeMenuModel> _typeMenus = [];
  final Map<int, List<MenuModel>> _categoryMenus = {};

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

  Future<void> _loadAllMenuData() async {
    if (widget.restaurantModel.username == null) return;

    try {
      final categories = await _menuService.getTypeMenuByRestaurant(
        widget.restaurantModel.username!,
      );

      for (var cat in categories) {
        if (cat.typemenuId != null) {
          final menuData = await _menuService.getMenusByTypeMenu(
            widget.restaurantModel.username!,
            cat.typemenuId!,
          );

          // 🎯 ปลดล็อก: โชว์เมนูทั้งหมด รวมถึงเมนูที่หมด (status == false) ด้วย
          _categoryMenus[cat.typemenuId!] = menuData.toList();
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
      debugPrint("Error fetching member menus data: $e");
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
      appBar: const NavbarMember(title: ""),
      body: Column(
        children: [
          Expanded(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
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
                                  labelPadding: EdgeInsets.symmetric(
                                    horizontal:
                                        MediaQuery.of(context).size.width / 12,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemBuilder: (context, index) {
                            final menu = currentMenus[index];
                            String? rawMenuImage =
                                menu.menuImage ?? (menu as dynamic).imageUrl;
                            String finalMenuUrl = _getFinalImageUrl(
                              rawMenuImage,
                            );

                            // 🎯 เช็กสถานะว่ามีของหรือไม่
                            final isAvailable = menu.status ?? true;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                // 🎯 การ์ดสีเทาเมื่อเมนูหมด
                                color: isAvailable
                                    ? const Color(0xFFF0F4E8)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // 1. รูปภาพ
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        width: 110,
                                        height: 110,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            finalMenuUrl.isNotEmpty
                                                ? Image.network(
                                                    Uri.encodeFull(
                                                      finalMenuUrl,
                                                    ),
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) =>
                                                        _buildPlaceholderIcon(),
                                                  )
                                                : _buildPlaceholderIcon(),

                                            // 🎯 Overlay สีดำ + ป้ายหมด
                                            if (!isAvailable)
                                              Container(
                                                color: Colors.black.withOpacity(
                                                  0.5,
                                                ),
                                                child: Center(
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red
                                                          .withOpacity(0.9),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      "หมด",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 15),

                                    // 2. ข้อความชื่อและราคา
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            menu.menuName ?? "ไม่มีชื่อเมนู",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              // 🎯 ดรอปสีตัวอักษรลง ไม่มีเส้นขีดทับ
                                              color: isAvailable
                                                  ? Colors.black
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "ราคา ${menu.price?.toStringAsFixed(0) ?? '0'} บาท",
                                            style: TextStyle(
                                              color: isAvailable
                                                  ? Colors.green
                                                  : Colors.grey.shade600,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // 3. ปุ่มบวกสำหรับ Member
                                    IconButton(
                                      // 🎯 ถ้าหมด กดไม่ได้ (null) สีกระดุมเทา
                                      onPressed: isAvailable
                                          ? () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      AddOrderMember(
                                                        menuModel: menu,
                                                      ),
                                                ),
                                              );
                                            }
                                          : null,
                                      icon: Icon(
                                        Icons.add_circle,
                                        color: isAvailable
                                            ? const Color(0xFF4CAF50)
                                            : Colors.grey.shade400,
                                        size: 36,
                                      ),
                                    ),
                                  ],
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
      color: Colors.grey[200],
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 36),
    );
  }
}
