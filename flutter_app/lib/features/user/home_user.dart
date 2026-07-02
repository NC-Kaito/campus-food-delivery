// features/user/home_user.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/features/admin/list_restaurant.dart';
import 'package:flutter_app/features/member/login_member.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/data/services/restaurant/type_restaurant_service.dart';
import 'package:flutter_app/data/services/menu/menu_service.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/type_restaurant_model.dart';
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/features/user/list_menu_user.dart';
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

  // 🎯 ปรับแต่งสีข้อความเมนูแถบล่างให้เป็นสีเขียวใหม่ #64F02D
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
      final types = await _typeRestaurantService.getAllTypeRestaurant();
      setState(() {
        typeList = types;
      });
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
    if (rawPath.startsWith('/')) {
      return "$baseUrl$rawPath";
    } else {
      return "$baseUrl/$rawPath";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF7),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 150, // ปรับความสูงตามความเหมาะสม
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/member_home.png'),
                fit: BoxFit.cover, // ปรับให้ภาพเต็มพื้นที่
              ),
            ),
          ),
          // 🛑 ส่วนบน: แผงเสิร์ชข้อมูลดีไซน์สวยหรู
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
                              ), // 🎯 2. เปลี่ยนสีไอคอนแว่นขยายเสิร์ชบาร์เป็นเขียวใหม่
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
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              0.2,
                            ), // สีของเงาและความจาง
                            spreadRadius: 1, // การกระจายของเงา
                            blurRadius: 6, // ความเบลอของเงา
                            offset: const Offset(
                              0,
                              3,
                            ), // ตำแหน่งเงาในแนวแกน X และ Y (X: 0, Y: 3 คือเงาลงด้านล่าง)
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(
                          0xFF64F02D,
                        ), // 🎯 3. เปลี่ยนสีพื้นหลังปุ่มวงกลมแว่นขยายขวาเป็นเขียวใหม่
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

          // 🛑 2. บาร์แนวนอนยอดฮิต
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(typeList.length + 1, (index) {
                final bool isAllTab = index == 0;
                final String? typeName = isAllTab
                    ? null
                    : typeList[index - 1].name;
                final bool isSelected =
                    (isAllTab && selectedType == null) ||
                    (selectedType == typeName);

                return ChoiceChip(
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 0,
                  ),
                  avatar: Icon(
                    isAllTab
                        ? Icons.all_inclusive_rounded
                        : Icons.local_dining_rounded,
                    size: 15,
                    color: isSelected ? Colors.white : const Color(0xFF64F02D),
                  ),
                  label: Text(isAllTab ? "ทั้งหมด" : typeName ?? ""),
                  selected: isSelected,
                  selectedColor: const Color(0xFF64F02D),
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
                );
              }),
            ),
          ),
          const SizedBox(height: 10),

          // แสดงสแตมป์สรุปยอดผลการค้นหา
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                searchController.text.trim().isEmpty && selectedType == null
                    ? "🏪 ร้านค้าพร้อมเสิร์ฟทั้งหมด (${_results.length} ร้าน)"
                    : "🔍 พบร้านค้าเด็ดตรงตามเงื่อนไข ${_results.length} ร้าน",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
            ),

          // 🛑 3. โซนแสดงผลร้านค้าทั้งหมด
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF64F02D),
                    ), // 🎯 6. เปลี่ยนสีวงเวียนโหลดเป็นเขียวใหม่
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomAppBar(
          color: Colors.white,
          elevation: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.home_rounded,
                    color: Color(0xFF64F02D),
                    size: 26,
                  ), // 🎯 7. เปลี่ยนสีไอคอนหน้าหลักแท็บล่างเป็นเขียวใหม่
                  const SizedBox(height: 2),
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
                    Icon(
                      Icons.person_pin_rounded,
                      color: Colors.grey.shade400,
                      size: 26,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "เข้าสู่ระบบ",
                      style: menuTextStyle.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

    // 🎯 คุมโทนเฉดสีเขียวหลักประจำโปรเจกต์ 0xFF64F02D
    final Color primaryGreen = const Color(0xFF64F02D);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListMenuUser(restaurantModel: item),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── ส่วนภาพของร้านอาหาร ───────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
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
                                color: Colors.grey[50],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: primaryGreen,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey[50],
                                  child: Icon(
                                    Icons.storefront_rounded,
                                    color: Colors.grey.shade400,
                                    size: 45,
                                  ),
                                ),
                          )
                        : Container(
                            color: Colors.grey[50],
                            child: Icon(
                              Icons.storefront_rounded,
                              color: Colors.grey.shade400,
                              size: 45,
                            ),
                          ),
                  ),
                ),

                // ป้ายแท็กประเภทหมวดหมู่ร้านค้า
                if (item.typerestaurantName != null &&
                    item.typerestaurantName!.isNotEmpty)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(10),
                        // 🎯 ✅ แก้ไขแล้ว: ลบ blurRadius ออกจาก BoxDecoration
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.restaurant_menu_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${item.typerestaurantName}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // ─── รายละเอียดของร้านอาหาร ───────────────────────────
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
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: primaryGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        // 🎯 ✅ แก้ไขแล้ว: ลบ const หน้า Row ออก และย้ายมาใส่ตัวที่รองรับแทน
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2E7D32),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              "เปิดอยู่",
                              style: TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 15,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getOpenDayText(item.openDay),
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: primaryGreen,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${item.openTime?.substring(0, 5)} - ${item.closeTime?.substring(0, 5)} น.",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (item.phone != null && item.phone!.isNotEmpty)
                        Expanded(
                          flex: 5,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.phone_in_talk_rounded,
                                size: 15,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "${item.phone}",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // ─── แผงเมนูอาหารที่ค้นหาเจอ ─────────────────
            if (matchedMenus.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.03),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade100, width: 1.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: Colors.grey.shade800,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "เมนูที่ตรงกับคำค้นหา",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...matchedMenus.map((menu) {
                      final String finalMenuImgUrl = _getFinalImageUrl(
                        menu.menuImage,
                      );

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 42,
                                height: 42,
                                child: finalMenuImgUrl.isNotEmpty
                                    ? Image.network(
                                        Uri.encodeFull(finalMenuImgUrl),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey[100],
                                          child: const Icon(
                                            Icons.fastfood_rounded,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey[100],
                                        child: const Icon(
                                          Icons.fastfood_rounded,
                                          size: 18,
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
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Text(
                              "฿${menu.price?.toStringAsFixed(0)}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: primaryGreen,
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
