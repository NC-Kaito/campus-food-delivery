// features/user/home_user.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/type_restaurant_model.dart';
import 'package:flutter_app/features/admin/list_restaurant.dart';
import 'package:flutter_app/features/member/login_member.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/data/services/restaurant/type_restaurant_service.dart';
import 'package:flutter_app/data/services/menu/menu_service.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/features/user/list_menu_user.dart';
import 'package:flutter_app/features/user/view_restaurant_user.dart';
import 'package:flutter_app/data/models/restaurant_opening_hour_model.dart';
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
  Set<int> _selectedTypeIds = {};

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

    if (_selectedTypeIds.isNotEmpty) {
      data = data
          .where((r) => _selectedTypeIds.contains(r.typerestaurantId))
          .toList();
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

  // 🎯 [FIXED] จัดกลุ่มวันเวลาเปิด-ปิดทำการ (ถ้า hour.open == true คือวันนั้นเปิดร้าน)
  String _getGroupedOpeningHoursText(List<RestaurantOpeningHourModel>? hours) {
    if (hours == null || hours.isEmpty || hours.every((h) => !h.open)) {
      return "ปิดทำการทุกวัน / ไม่ระบุเวลาทำการ";
    }

    const shortDayNames = {
      RestaurantDayOfWeek.monday: "จ.",
      RestaurantDayOfWeek.tuesday: "อ.",
      RestaurantDayOfWeek.wednesday: "พ.",
      RestaurantDayOfWeek.thursday: "พฤ.",
      RestaurantDayOfWeek.friday: "ศ.",
      RestaurantDayOfWeek.saturday: "ส.",
      RestaurantDayOfWeek.sunday: "อา.",
    };

    final Map<String, List<String>> timeGroups = {};

    for (var d in RestaurantDayOfWeek.values) {
      final hour = hours.firstWhere(
        (h) => h.dayOfWeek == d,
        orElse: () => RestaurantOpeningHourModel(
          dayOfWeek: d,
          opentime: const TimeOfDay(hour: 0, minute: 0),
          closetime: const TimeOfDay(hour: 0, minute: 0),
          open: false,
        ),
      );

      // 🎯 ร้านเปิดทำการในวันนี้ (open == true)
      if (hour.open) {
        final String timeString =
            "${_formatTime(hour.opentime)} - ${_formatTime(hour.closetime)} น.";
        if (!timeGroups.containsKey(timeString)) {
          timeGroups[timeString] = [];
        }
        timeGroups[timeString]!.add(shortDayNames[d]!);
      }
    }

    if (timeGroups.isEmpty) return "ปิดทำการทุกวัน";

    final List<String> resultLines = [];
    timeGroups.forEach((time, daysList) {
      resultLines.add("${daysList.join(', ')} ($time)");
    });

    return resultLines.join(" | ");
  }

  // 🎯 [FIXED] แสดงเวลาเปิด-ปิดของวันนี้โดยเฉพาะ
  String _getTodayHoursText(List<RestaurantOpeningHourModel>? hours) {
    if (hours == null || hours.isEmpty) return "ไม่ระบุเวลาทำการ";

    final todayEnum = RestaurantDayOfWeek.values[DateTime.now().weekday - 1];
    final today = hours.firstWhere(
      (h) => h.dayOfWeek == todayEnum,
      orElse: () => RestaurantOpeningHourModel(
        dayOfWeek: todayEnum,
        opentime: const TimeOfDay(hour: 8, minute: 0),
        closetime: const TimeOfDay(hour: 18, minute: 0),
        open: false,
      ),
    );

    // 🎯 ถ้า !today.open ( open == false ) แปลว่าวันนี้ปิดทำการ
    if (!today.open) return "วันนี้ร้านปิดทำการ";
    return "${_formatTime(today.opentime)} - ${_formatTime(today.closetime)} น.";
  }

  // 🎯 [FIXED] ตรวจสอบสถานะเปิดอยู่จริง ณ เวลาปัจจุบัน
  bool _isCurrentlyOpen(RestaurantModel item) {
    if (item.statusOpen == false) return false;

    final hours = item.openingHours;
    if (hours == null || hours.isEmpty) return false;

    final todayEnum = RestaurantDayOfWeek.values[DateTime.now().weekday - 1];
    final today = hours.firstWhere(
      (h) => h.dayOfWeek == todayEnum,
      orElse: () => RestaurantOpeningHourModel(
        dayOfWeek: todayEnum,
        opentime: const TimeOfDay(hour: 0, minute: 0),
        closetime: const TimeOfDay(hour: 0, minute: 0),
        open: false,
      ),
    );

    if (!today.open) return false;

    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final openMinutes = today.opentime.hour * 60 + today.opentime.minute;
    final closeMinutes = today.closetime.hour * 60 + today.closetime.minute;

    if (openMinutes <= closeMinutes) {
      return nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
    }
    return nowMinutes >= openMinutes || nowMinutes <= closeMinutes;
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
            height: 150,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/member_home.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
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
                              color: Color(0xFF64F02D),
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
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF64F02D),
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
                final int? typeId = isAllTab ? null : typeList[index - 1].id;
                final String? typeName = isAllTab
                    ? null
                    : typeList[index - 1].name;

                final bool isSelected = isAllTab
                    ? _selectedTypeIds.isEmpty
                    : _selectedTypeIds.contains(typeId);

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
                        _selectedTypeIds.clear();
                      } else if (selected) {
                        _selectedTypeIds.add(typeId!);
                      } else {
                        _selectedTypeIds.remove(typeId);
                      }
                    });
                    _loadResults(searchController.text);
                  },
                );
              }),
            ),
          ),
          const SizedBox(height: 10),

          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                searchController.text.trim().isEmpty && _selectedTypeIds.isEmpty
                    ? "🏪 ร้านค้าพร้อมเสิร์ฟทั้งหมด (${_results.length} ร้าน)"
                    : "🔍 พบร้านค้าเด็ดตรงตามเงื่อนไข ${_results.length} ร้าน",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
            ),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF64F02D)),
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
                  ),
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
                      Builder(
                        builder: (context) {
                          final bool isOpen = _isCurrentlyOpen(item);
                          final Color statusColor = isOpen
                              ? const Color(0xFF2E7D32)
                              : Colors.grey.shade600;
                          final Color statusBg = isOpen
                              ? primaryGreen.withOpacity(0.15)
                              : Colors.grey.shade200;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isOpen ? "เปิดอยู่" : "ปิดอยู่",
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── แถววันทำการภาพรวมทั้งสัปดาห์ ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── แถวเวลาของวันนี้โดยเฉพาะ ──
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
                                fontWeight: FontWeight.bold,
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
