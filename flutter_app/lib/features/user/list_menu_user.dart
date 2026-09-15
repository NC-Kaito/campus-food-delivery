import 'dart:async';
// features/member/list_menu_user.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/data/models/type_menu_model.dart';
import 'package:flutter_app/data/models/restaurant_opening_hour_model.dart';
import 'package:flutter_app/data/services/menu/menu_service.dart';
// import 'package:flutter_app/features/member/login_member.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/main_login.dart';

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
  List<TypeMenuModel> _typeMenus = [];
  final Map<int, List<MenuModel>> _categoryMenus = {};

  String? restaurantimage;
  String? restaurantname = "กำลังโหลด...";

  // ─── 🎯 ส่วนเสริม State สำหรับ Logic ร้านข้าวแกง ──────────────────
  final int _maxCurrySelect = 3;
  final List<MenuModel> _selectedCurries = [];
  bool _isExtraRice = false;
  int _curryQty = 1;
  Timer? _statusRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAllMenuData();
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _statusRefreshTimer?.cancel();
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
      debugPrint("Error fetching user menus data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                  MaterialPageRoute(builder: (context) => const MainLogin()),
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

  // ─── 🎯 ส่วนเสริมสุ่มแจ้งเตือนข้อมูลตะกร้าข้าวแกง ──────────────────
  void _showMockCurryCartDialog(double total, String note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.shopping_basket, color: Colors.green),
            SizedBox(width: 8),
            Text("ระบบรับข้อมูลข้าวแกง"),
          ],
        ),
        content: Text(
          "💰 ราคารวม: ฿${total.toStringAsFixed(0)} บาท\n🔢 จำนวน: $_curryQty จาน\n📝 ข้อมูลที่บันทึกใน Note:\n\"$note\"",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _selectedCurries.clear();
                _isExtraRice = false;
                _curryQty = 1;
              });
            },
            child: const Text("ตกลง"),
          ),
        ],
      ),
    );
  }

  // 🎨 UI ถูกปรับให้มีโครงสร้างและสไตล์เดียวกับหน้า Member
  // โดยคงพฤติกรรมของ User เดิม: การกดเพิ่มเมนู/เพิ่มลงตะกร้าจะเรียก Login Warning
  @override
  Widget build(BuildContext context) {
    final bool isRestaurantOpen = _isCurrentlyOpen(widget.restaurantModel);

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
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF4CAF50),
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
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
                                      errorBuilder: (_, __, ___) => Image.asset(
                                        'assets/images/default_restaurant.png',
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Container(
                                      color: const Color(0xFFF2F2F2),
                                      child: const Center(
                                        child: Icon(
                                          Icons.image_outlined,
                                          size: 80,
                                          color: Colors.grey,
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
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 12, 24, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        restaurantname ?? '-',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
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
                                        color: isRestaurantOpen
                                            ? Colors.green.shade100
                                            : Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: isRestaurantOpen
                                                  ? Colors.green.shade700
                                                  : Colors.red.shade700,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            isRestaurantOpen
                                                ? 'เปิดอยู่'
                                                : 'ปิดชั่วคราว',
                                            style: TextStyle(
                                              color: isRestaurantOpen
                                                  ? Colors.green.shade700
                                                  : Colors.red.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                if ((widget.restaurantModel.openingHours ?? [])
                                    .isNotEmpty)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 18,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _getGroupedOpeningHoursText(
                                            widget.restaurantModel.openingHours,
                                          ),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade700,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                if ((widget.restaurantModel.openingHours ?? [])
                                    .isNotEmpty)
                                  const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone_in_talk_outlined,
                                      size: 18,
                                      color: Colors.orange.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.restaurantModel.phone ?? '-',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyTabBarDelegate(
                      height: 50.0,
                      child: Container(
                        color: Colors.white,
                        child: Column(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(
                                      top: 6,
                                      bottom: 6,
                                      right: 8,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4CAF50),
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'รายการอาหาร',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: TabBar(
                                      controller: _tabController!,
                                      isScrollable: true,
                                      tabAlignment: TabAlignment.start,
                                      labelColor: Colors.orange.shade700,
                                      unselectedLabelColor:
                                          Colors.grey.shade500,
                                      indicatorColor: Colors.orange.shade700,
                                      indicatorWeight: 3,
                                      indicatorSize: TabBarIndicatorSize.tab,
                                      dividerColor: Colors.transparent,
                                      labelPadding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      labelStyle: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      unselectedLabelStyle: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      tabs: _typeMenus.isEmpty
                                          ? [const Tab(text: 'ไม่มีประเภท')]
                                          : _typeMenus
                                                .map(
                                                  (type) => Tab(
                                                    text: type.typemenuName,
                                                  ),
                                                )
                                                .toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(height: 1, color: Colors.grey.shade200),
                          ],
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController!,
                children: _typeMenus.isEmpty
                    ? [const Center(child: Text('ไม่มีข้อมูลเมนู'))]
                    : _typeMenus.map((type) {
                        final typeId = type.typemenuId!;
                        final currentMenus = _categoryMenus[typeId] ?? [];

                        if (type.typemenuName != null &&
                            type.typemenuName!.contains('ข้าวราดแกง')) {
                          return _buildCurrySpecialLayout(currentMenus);
                        }

                        if (currentMenus.isEmpty) {
                          return const Center(
                            child: Text(
                              'ไม่มีเมนูพร้อมจำหน่ายในหมวดหมู่นี้',
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
                            final rawMenuImage = menu.menuImage;
                            final finalMenuUrl = _getFinalImageUrl(
                              rawMenuImage,
                            );
                            final isAvailable = menu.status ?? true;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isAvailable
                                    ? Colors.white
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isAvailable
                                      ? const Color.fromARGB(
                                          255,
                                          17,
                                          156,
                                          70,
                                        ).withOpacity(0.28)
                                      : Colors.grey.shade300,
                                  width: 1,
                                ),
                                boxShadow: isAvailable
                                    ? [
                                        BoxShadow(
                                          color: const Color.fromARGB(
                                            255,
                                            0,
                                            0,
                                            0,
                                          ).withOpacity(0.5),
                                          spreadRadius: 1,
                                          blurRadius: 0,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
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
                                                      'หมด',
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
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            menu.menuName ?? 'ไม่มีชื่อเมนู',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: isAvailable
                                                  ? Colors.black
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'ราคา ${menu.price?.toStringAsFixed(0) ?? '0'} บาท',
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
                                    IconButton(
                                      onPressed: isAvailable
                                          ? _showLoginWarningDialog
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

  Widget _buildCurrySpecialLayout(List<MenuModel> curryItems) {
    if (curryItems.isEmpty) {
      return const Center(
        child: Text(
          'ไม่มีเมนูกับข้าวพร้อมจำหน่ายในขณะนี้',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      );
    }

    // หน้ารายการข้าวราดแกงสำหรับ User:
    // แสดงเฉพาะเมนูเท่านั้น ไม่มี checkbox / เพิ่มข้าว / จำนวน / ปุ่มสั่ง
    // เมื่อแตะเมนู ให้แสดง Popup เข้าสู่ระบบ
    return ListView.builder(
      itemCount: curryItems.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemBuilder: (context, index) {
        final curry = curryItems[index];
        final finalMenuUrl = _getFinalImageUrl(curry.menuImage);
        final bool isAvailable = curry.status ?? true;
        final double price = curry.price ?? 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isAvailable ? Colors.white : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAvailable
                  ? const Color.fromARGB(255, 17, 156, 70).withOpacity(0.28)
                  : Colors.grey.shade300,
              width: 1,
            ),
            boxShadow: isAvailable
                ? [
                    BoxShadow(
                      color: const Color.fromARGB(
                        255,
                        0,
                        0,
                        0,
                      ).withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _showLoginWarningDialog,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
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
                                  Uri.encodeFull(finalMenuUrl),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildPlaceholderIcon(),
                                )
                              : _buildPlaceholderIcon(),
                          if (!isAvailable)
                            Container(
                              color: Colors.black.withOpacity(0.5),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'หมด',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          curry.menuName ?? 'ไม่มีชื่อกับข้าว',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isAvailable
                                ? Colors.black87
                                : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ราคา ${price.toStringAsFixed(0)} บาท',
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _getGroupedOpeningHoursText(List<RestaurantOpeningHourModel>? hours) {
    if (hours == null || hours.isEmpty || hours.every((h) => !h.open)) {
      return 'ปิดทำการทุกวัน / ไม่ระบุเวลาทำการ';
    }

    const shortDayNames = {
      RestaurantDayOfWeek.monday: 'จ.',
      RestaurantDayOfWeek.tuesday: 'อ.',
      RestaurantDayOfWeek.wednesday: 'พ.',
      RestaurantDayOfWeek.thursday: 'พฤ.',
      RestaurantDayOfWeek.friday: 'ศ.',
      RestaurantDayOfWeek.saturday: 'ส.',
      RestaurantDayOfWeek.sunday: 'อา.',
    };

    final Map<String, List<String>> timeGroups = {};

    for (final day in RestaurantDayOfWeek.values) {
      final hour = hours.firstWhere(
        (h) => h.dayOfWeek == day,
        orElse: () => RestaurantOpeningHourModel(
          dayOfWeek: day,
          opentime: const TimeOfDay(hour: 0, minute: 0),
          closetime: const TimeOfDay(hour: 0, minute: 0),
          open: false,
        ),
      );

      if (hour.open) {
        final timeString =
            '${_formatTime(hour.opentime)} - ${_formatTime(hour.closetime)} น.';
        timeGroups.putIfAbsent(timeString, () => []).add(shortDayNames[day]!);
      }
    }

    if (timeGroups.isEmpty) return 'ปิดทำการทุกวัน';

    final resultLines = <String>[];
    timeGroups.forEach((time, days) {
      resultLines.add('${days.join(', ')} ($time)');
    });
    return resultLines.join(' | ');
  }

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

    // รองรับร้านที่เปิดข้ามเที่ยงคืน เช่น 18:00 - 02:00
    return nowMinutes >= openMinutes || nowMinutes <= closeMinutes;
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 36),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyTabBarDelegate({required this.child, required this.height});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(height: height, child: child);
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
