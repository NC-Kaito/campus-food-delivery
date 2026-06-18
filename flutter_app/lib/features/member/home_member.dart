// features/member/home_member.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/member_model.dart';
import 'package:flutter_app/features/member/list_confirm_order_member.dart';
import 'package:flutter_app/features/member/list_order_member.dart';
import 'package:flutter_app/features/member/navbar_member.dart';
import 'package:flutter_app/features/member/profile_member.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/data/services/restaurant/type_restaurant_service.dart';
import 'package:flutter_app/data/services/menu/menu_service.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/type_restaurant_model.dart';
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/features/member/view_restaurant_member.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/global_data.dart'; // 🎯 ดึง GlobalData เพื่อเช็กโปรไฟล์สมาชิก

class HomeMember extends StatefulWidget {
  const HomeMember({super.key});

  @override
  State<HomeMember> createState() => _HomeMemberState();
}

class _HomeMemberState extends State<HomeMember> {
  final TextEditingController searchController = TextEditingController();
  final RestaurantService _restaurantService = RestaurantService();
  final TypeRestaurantService typeRestaurantService = TypeRestaurantService();
  final MenuService _menuService = MenuService();

  List<RestaurantModel> _results = [];
  List<TypeRestaurantModel> typeList = [];
  Map<String, List<MenuModel>> _restaurantMenusIndex = {};

  bool _isLoading = true;
  String? selectedType;
  int? _selectedTypeId;

  // 🎯 คุมโทนสีตัวอักษรของปุ่มเมนูแถบล่างให้เป็นสีเขียวใหม่สปอร์ต #64F02D
  final menuTextStyle = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Color(0xFF64F02D),
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
      final types = await typeRestaurantService.getAllTypeRestaurant();
      setState(() => typeList = types);
    } catch (e) {
      debugPrint("เกิดข้อผิดพลาด ไม่สามารถโหลดข้อมูลประเภทร้านค้าได้: $e");
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
    return rawPath.startsWith('/') ? "$baseUrl$rawPath" : "$baseUrl/$rawPath";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF9FBF7,
      ), // สีเบสเขียวอ่อนสบายตาแบบแอปเดลิเวอรีสากล
      // 🌟 คงไว้ตามกฎ: เรียกใช้งานแอปบาร์ของ Member ด้านบนสุดตามฟังก์ชั่นหลัก
      appBar: const NavbarMember(title: "หน้าหลัก"),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🛑 ส่วนบน: แผงเสิร์ชข้อมูลลอยตัวพร้อมมิติเงา BoxShadow คมชัด
          Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            color: Colors.transparent,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 16,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: searchController,
                          onFieldSubmitted: (value) => _loadResults(value),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(
                                0xFF64F02D,
                              ), // 🎯 ใช้สีเขียวใหม่สปอร์ต
                            ),
                            suffixIcon: searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.cancel_rounded,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      searchController.clear();
                                      _loadResults("");
                                    },
                                  )
                                : null,
                            hintText: "ค้นหาร้านอาหาร หรือเมนูแสนอร่อย...",
                            hintStyle: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // ปุ่มค้นหาวงกลมพร้อมใส่เงาเรืองแสงมีมิติมินิมอล
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(
                          0xFF64F02D,
                        ), // 🎯 ใช้สีเขียวสปอร์ตตัวแรง
                        child: IconButton(
                          onPressed: () => _loadResults(searchController.text),
                          icon: const Icon(
                            Icons.search,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 🛑 ส่วนตรงกลาง: แถบหมวดหมู่อาหาร Chip แนวนอน สไลด์เลือกข้างได้
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8.0, top: 4.0),
            child: Text(
              "ประเภทร้านค้า",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: typeList.length + 1,
              itemBuilder: (context, index) {
                final bool isAllTab = index == 0;
                final String? typeName = isAllTab
                    ? null
                    : typeList[index - 1].name;
                final bool isSelected =
                    (isAllTab && selectedType == null) ||
                    (selectedType == typeName);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    showCheckmark:
                        false, // 🎯 เอาเครื่องหมายเช็คถูกออก สไตล์คลีนตาแบบที่ต้องการคราบบบ
                    avatar: Icon(
                      isAllTab
                          ? Icons.all_inclusive_rounded
                          : Icons.local_dining_rounded,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF64F02D),
                    ),
                    label: Text(isAllTab ? "ทั้งหมด" : typeName ?? ""),
                    selected: isSelected,
                    selectedColor: const Color(
                      0xFF64F02D,
                    ), // 🎯 พ่นสีเขียวใหม่ตอนเลือกใช้งาน
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : const Color(0xFF64F02D).withOpacity(0.3),
                    ),
                    onSelected: (bool selected) {
                      setState(() {
                        if (isAllTab) {
                          selectedType = null;
                          _selectedTypeId = null;
                        } else {
                          selectedType = typeName;
                          _selectedTypeId = typeList[index - 1].id;
                        }
                      });
                      _loadResults(searchController.text);
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // แสดงสแตมป์สรุปยอดผลการค้นหาจำนวนร้านค้า
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                searchController.text.trim().isEmpty && selectedType == null
                    ? "🏪 ร้านอาหารพร้อมเสิร์ฟทั้งหมด (${_results.length} ร้าน)"
                    : "🔍 พบร้านค้าเด็ดตรงตามเงื่อนไข ${_results.length} ร้าน",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
            ),

          // 🛑 ส่วนล่าง: โซนกางการ์ดแสดงผลรายชื่อร้านอาหารทั้งหมด
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF64F02D),
                    ), // 🎯 วงเวียนโหลดสีเขียวใหม่
                  )
                : _results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 70,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "ไม่พบข้อมูลร้านค้าหรือเมนูที่ระบุ",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24, top: 4),
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
                _buildNavItem(Icons.home, "หน้าหลัก", () {
                  searchController.clear();
                  setState(() {
                    selectedType = null;
                    _selectedTypeId = null;
                  });
                  _loadResults("");
                }, isActive: true),
                _buildNavItem(Icons.shopping_basket, "ตะกร้าอาหาร", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ListOrderMember(),
                    ),
                  );
                }),
                _buildNavItem(Icons.list_alt, "คำสั่งซื้อ", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ListConfirmOrderMember(),
                    ),
                  );
                }),
                _buildNavItem(Icons.person, "โปรไฟล์", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileMember(),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? const Color(0xFF64F02D) : Colors.grey),
            Text(
              label,
              style: menuTextStyle.copyWith(
                color: isActive ? const Color(0xFF64F02D) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🏪 วาดการ์ดร้านค้าเวอร์ชั่นยกเครื่องสไตล์เดลิเวอรีพรีเมียม
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewRestaurantMember(restaurant: item),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนภาพของร้านอาหาร
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 8.5,
                child: finalImageUrl.isNotEmpty
                    ? Image.network(
                        finalImageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[100],
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(
                                  0xFF64F02D,
                                ), // 🎯 วงเวียนโหลดสีเขียวใหม่
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[100],
                          child: const Icon(
                            Icons.restaurant_rounded,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[100],
                        child: const Icon(
                          Icons.restaurant_rounded,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
              ),
            ),
            // รายละเอียดของร้านอาหาร
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.restaurantName ?? "ร้านอาหาร",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2A2A2A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF64F02D).withOpacity(
                            0.12,
                          ), // สีเขียวพาสเทลจางๆ สไตล์เปิดร้าน
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "• เปิดอยู่",
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _getOpenDayText(item.openDay),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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
                        Icons.alarm_on_rounded,
                        size: 14,
                        color: Color(0xFF64F02D),
                      ), // 🎯 ไอคอนนาฬิกาสีเขียวใหม่
                      const SizedBox(width: 6),
                      Text(
                        "${item.openTime?.substring(0, 5)} - ${item.closeTime?.substring(0, 5)} น.",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // แผงเมนูอาหารที่ค้นหาเจอ
            if (matchedMenus.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.04),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border(
                    top: BorderSide(color: Colors.orange.shade50, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.saved_search_rounded,
                          size: 18,
                          color: Colors.orange.shade800,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "เมนูที่ตรงกับคำค้นหา",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...matchedMenus.map((menu) {
                      final String finalMenuImgUrl = _getFinalImageUrl(
                        menu.menuImage,
                      );

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(
                                width: 38,
                                height: 38,
                                child: finalMenuImgUrl.isNotEmpty
                                    ? Image.network(
                                        Uri.encodeFull(finalMenuImgUrl),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey[100],
                                          child: const Icon(
                                            Icons.fastfood,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey[100],
                                        child: const Icon(
                                          Icons.fastfood,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                menu.menuName ?? "-",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Text(
                              "฿${menu.price?.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(
                                  0xFF64F02D,
                                ), // 🎯 ราคาสีเขียวใหม่สปอร์ต
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
