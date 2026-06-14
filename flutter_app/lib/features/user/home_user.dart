// features/user/home_user.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/features/member/login_member.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/data/services/restaurant/type_restaurant_service.dart';
import 'package:flutter_app/data/services/menu/menu_service.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/type_restaurant_model.dart';
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/features/user/view_restaurant_user.dart';
import 'package:flutter_app/core/network/dio_client.dart';

class HomeUser extends StatefulWidget {
  const HomeUser({super.key});

  @override
  State<HomeUser> createState() => _HomeUserState();
}

class _HomeUserState extends State<HomeUser> {
  final TextEditingController searchController = TextEditingController();
  final RestaurantService _restaurantService = RestaurantService();
  final TypeRestaurantService _typeRestaurantService = TypeRestaurantService();
  final MenuService _menuService = MenuService();

  List<RestaurantModel> _results = [];
  List<TypeRestaurantModel> typeList = [];
  Map<String, List<MenuModel>> _restaurantMenusIndex = {};

  bool _isLoading = true;
  String? selectedType;
  int? _selectedTypeId;

  final menuTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Colors.green[700],
  );

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    await fetchTypes();
    await _loadResults("");
  }

  Future<void> fetchTypes() async {
    try {
      final types = await _typeRestaurantService.getAllTypeRestaurant();
      setState(() {
        typeList = types;
      });
    } catch (e) {
      print("เกิดข้อผิดพลาด ไม่สามารถโหลดข้อมูลประเภทร้านค้าได้: $e");
    }
  }

  Future<void> _loadResults(String keyword) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    _restaurantMenusIndex.clear();

    var data = await _restaurantService.searchRestaurant(keyword);

    if (_selectedTypeId != null) {
      data = data.where((r) => r.typerestaurantId == _selectedTypeId).toList();
    }

    for (var rest in data) {
      if (rest.username != null) {
        try {
          final menus = await _menuService.getMenusByRestaurant(rest.username!);
          _restaurantMenusIndex[rest.username!] = menus;
        } catch (e) {
          _restaurantMenusIndex[rest.username!] = [];
        }
      }
    }

    if (mounted) {
      setState(() {
        _results = data;
        _isLoading = false;
      });
    }
  }

  String _getOpenDayText(int? bitwiseValue) {
    if (bitwiseValue == null || bitwiseValue == 0) return "ไม่ระบุวันเปิด";
    if (bitwiseValue == 127) return "เปิดทุกวัน";

    final dayMap = {
      1: "อา.",
      2: "จ.",
      4: "อ.",
      8: "พ.",
      16: "พฤ.",
      32: "ศ.",
      64: "ส.",
    };

    List<String> days = [];
    dayMap.forEach((key, value) {
      if ((bitwiseValue & key) != 0) days.add(value);
    });

    return "เปิดวัน: ${days.join(', ')}";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors
          .grey[50], // ปรับสีพื้นหลังของแอปให้ดรอปลงเล็กน้อยเพื่อให้ตัว Card สีขาวเด่นขึ้น
      appBar: AppBar(
        title: const Text(
          "CAMPUS EAT",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Campus Food Delivery",
                  style: TextStyle(
                    color: Colors.green[800],
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: searchController,
                        onFieldSubmitted: (value) => _loadResults(value),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.green,
                          ),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    searchController.clear();
                                    _loadResults("");
                                  },
                                )
                              : null,
                          hintText: "ค้นหาชื่อร้านค้า หรือเมนูอาหาร...",
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(
                              color: Colors.green,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: IconButton(
                        onPressed: () => _loadResults(searchController.text),
                        icon: const Icon(Icons.search, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.category, color: Colors.green),
                    labelText: "ประเภทธุรกิจ/ร้านค้า",
                    labelStyle: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 10,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(
                        color: Colors.green,
                        width: 1.5,
                      ),
                    ),
                  ),
                  hint: const Text("เลือกประเภทอาหาร"),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text("ทั้งหมด"),
                    ),
                    ...typeList.map((TypeRestaurantModel type) {
                      return DropdownMenuItem<String>(
                        value: type.name,
                        child: Text(type.name ?? "ไม่ระบุ"),
                      );
                    }),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedType = newValue;
                      try {
                        _selectedTypeId = typeList
                            .firstWhere((e) => e.name == newValue)
                            .id;
                      } catch (e) {
                        _selectedTypeId = null;
                      }
                    });
                    _loadResults(searchController.text);
                  },
                ),
              ],
            ),
          ),

          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.manage_search, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      searchController.text.trim().isEmpty &&
                              selectedType == null
                          ? "ร้านค้าทั้งหมดในระบบ มีจำนวน ${_results.length} แห่ง"
                          : "พบร้านค้า ${_results.length} แห่ง จากการกรองข้อมูลล่าสุด",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  )
                : _results.isEmpty
                ? const Center(
                    child: Text(
                      "ไม่พบข้อมูลร้านค้าหรือเมนูที่ระบุ",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      return _buildRestaurantCard(context, _results[index]);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.home, color: Colors.green),
                    Text("หน้าหลัก", style: menuTextStyle),
                  ],
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginMember(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(50),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person, color: Colors.green),
                      Text("เข้าสู่ระบบ", style: menuTextStyle),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(BuildContext context, RestaurantModel item) {
    final String finalImageUrl = _getFinalImageUrl(item.restaurantImage);

    final String keyword = searchController.text.trim().toLowerCase();
    final List<MenuModel> storeMenus =
        _restaurantMenusIndex[item.username] ?? [];

    final List<MenuModel> matchedMenus = storeMenus
        .where(
          (m) =>
              keyword.isNotEmpty &&
              (m.menuName ?? "").toLowerCase().contains(keyword),
        )
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // 🎯 แก้ไขจุดสำคัญ 1: ลงเส้นขอบสีเทาอ่อนความหนา 1.0 ครอบคลุมมิติการ์ดทั้งหมดเพื่อไม่ให้กลืนไปกับ Background ของแอป
        border: Border.all(color: Colors.grey.shade300, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewRestaurantUser(restaurant: item),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(
                  15,
                ), // ปรับลงมาเล็กน้อยให้เข้าล็อกกรอบ Border.all ด้านบนพอดี
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: finalImageUrl.isNotEmpty
                    ? Image.network(
                        finalImageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.green,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.restaurant,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.restaurant,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.restaurantName ?? "ร้านอาหาร",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _getOpenDayText(item.openDay),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_filled,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${item.openTime?.substring(0, 5)} - ${item.closeTime?.substring(0, 5)} น.",
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "• เปิดอยู่",
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 🌟 ส่วนแผงเมนูอาหารที่เสิร์ชเจอ: กางกล่องเหลืองพาสเทล พร้อมขอบตัดโค้งรับฐานการ์ดล่างสุด
            if (matchedMenus.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFC8).withOpacity(0.5),
                  borderRadius: const BorderRadius.only(
                    // 🎯 แก้ไขจุดสำคัญ 2: ปรับแต่งให้ขอบล่างโค้งมนรับกับกรอบสี่เหลี่ยมด้านนอกได้อย่างพอเหมาะพอดี
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.fastfood, size: 16, color: Colors.orange),
                        SizedBox(width: 6),
                        Text(
                          "เมนูที่ตรงกับคำค้นหาของคุณ:",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...matchedMenus.map((menu) {
                      final String finalMenuImgUrl = _getFinalImageUrl(
                        menu.menuImage,
                      );

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 45,
                                height: 45,
                                child: finalMenuImgUrl.isNotEmpty
                                    ? Image.network(
                                        Uri.encodeFull(finalMenuImgUrl),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.fastfood,
                                            size: 20,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.fastfood,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                menu.menuName ?? "-",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Text(
                              "฿${menu.price?.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
