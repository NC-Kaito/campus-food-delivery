// features/member/home_member.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/member_model.dart';
import 'package:flutter_app/features/member/cart_manager_member.dart';
import 'package:flutter_app/features/member/list_confirm_order_member.dart';
import 'package:flutter_app/features/member/list_menu_member.dart';
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
import 'package:flutter_app/data/models/restaurant_opening_hour_model.dart';

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

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // สรุปเวลาเปิด-ปิดทั้งสัปดาห์ จัดกลุ่มวันที่เวลาเหมือนกันติดกันไว้ด้วยกัน
  String _getGroupedOpeningHoursText(List<RestaurantOpeningHourModel>? hours) {
    if (hours == null || hours.isEmpty) return "ไม่ระบุเวลาเปิด-ปิด";

    const dayAbbr = {
      RestaurantDayOfWeek.monday: "จ",
      RestaurantDayOfWeek.tuesday: "อ",
      RestaurantDayOfWeek.wednesday: "พ",
      RestaurantDayOfWeek.thursday: "พฤ",
      RestaurantDayOfWeek.friday: "ศ",
      RestaurantDayOfWeek.saturday: "ส",
      RestaurantDayOfWeek.sunday: "อา",
    };

    // เรียงให้ครบ จ-อา เสมอ ถ้าวันไหนไม่มีข้อมูลให้ถือว่าปิด
    final ordered = RestaurantDayOfWeek.values.map((d) {
      return hours.firstWhere(
        (h) => h.dayOfWeek == d,
        orElse: () => RestaurantOpeningHourModel(
          dayOfWeek: d,
          opentime: const TimeOfDay(hour: 0, minute: 0),
          closetime: const TimeOfDay(hour: 0, minute: 0),
          closed: true,
        ),
      );
    }).toList();

    final List<String> groups = [];
    int i = 0;
    while (i < ordered.length) {
      final start = ordered[i];
      int j = i;
      while (j + 1 < ordered.length &&
          ordered[j + 1].closed == start.closed &&
          ordered[j + 1].opentime.hour == start.opentime.hour &&
          ordered[j + 1].opentime.minute == start.opentime.minute &&
          ordered[j + 1].closetime.hour == start.closetime.hour &&
          ordered[j + 1].closetime.minute == start.closetime.minute) {
        j++;
      }
      final label = (i == j)
          ? dayAbbr[ordered[i].dayOfWeek]!
          : "${dayAbbr[ordered[i].dayOfWeek]}-${dayAbbr[ordered[j].dayOfWeek]}";

      groups.add(
        start.closed
            ? "$label ปิด"
            : "$label ${_formatTime(start.opentime)}-${_formatTime(start.closetime)}",
      );

      i = j + 1;
    }
    return groups.join(", ");
  }

  // บอกเวลาเปิด-ปิดของ "วันนี้" โดยเฉพาะ ไว้โชว์ในบรรทัดเวลา
  String _getTodayHoursText(List<RestaurantOpeningHourModel>? hours) {
    if (hours == null || hours.isEmpty) return "ไม่ระบุเวลา";

    final todayEnum = RestaurantDayOfWeek.values[DateTime.now().weekday - 1];
    final today = hours.firstWhere(
      (h) => h.dayOfWeek == todayEnum,
      orElse: () => RestaurantOpeningHourModel(
        dayOfWeek: todayEnum,
        opentime: const TimeOfDay(hour: 0, minute: 0),
        closetime: const TimeOfDay(hour: 0, minute: 0),
        closed: true,
      ),
    );

    if (today.closed) return "วันนี้ปิด";
    return "${_formatTime(today.opentime)} - ${_formatTime(today.closetime)} น.";
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;

    final String baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/') ? "$baseUrl$rawPath" : "$baseUrl/$rawPath";
  }

  // 🎯 ฟังก์ชันช่วย: เรียก setState เปล่าๆ เพื่อรีเฟรช badge ตะกร้า
  // ใช้หลัง Navigator.push กลับมา เผื่อผู้ใช้ไปเพิ่ม/ลบของในตะกร้าจากหน้าอื่นมา
  void _refreshCartBadge() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 จำนวนรายการทั้งหมดในตะกร้า (นับเป็น "รายการ" ไม่ใช่ผลรวมจำนวนจาน)
    final int cartItemCount = CartManager().items.length;

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
                // 🎯 เพิ่ม badgeCount ให้ปุ่มตะกร้า + รีเฟรชหลังกลับมาจากหน้าตะกร้า
                _buildNavItem(Icons.shopping_basket, "ตะกร้าอาหาร", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ListOrderMember(),
                    ),
                  ).then((_) => _refreshCartBadge());
                }, badgeCount: cartItemCount),
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
    int badgeCount = 0, // 🎯 เพิ่มพารามิเตอร์ใหม่: จำนวนที่จะโชว์บน badge
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🎯 ห่อไอคอนด้วย Stack เพื่อวาง badge ตัวเลขไว้มุมขวาบน
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isActive ? const Color(0xFF64F02D) : Colors.grey,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
          // 🎯 เปิดหน้าเมนูร้านค้า แล้วรีเฟรช badge ตะกร้าหลังกลับมา
          // เผื่อผู้ใช้ไปเพิ่มของลงตะกร้าจากหน้านี้
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListMenuMember(restaurantModel: item),
            ),
          ).then((_) => _refreshCartBadge());
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
                          _getGroupedOpeningHoursText(item.openingHours),
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
                              _getTodayHoursText(item.openingHours),
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
