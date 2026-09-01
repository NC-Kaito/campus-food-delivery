// features/member/list_menu_member.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/data/models/type_menu_model.dart';
import 'package:flutter_app/data/services/menu/menu_service.dart';
import 'package:flutter_app/data/models/menu_addon_detail_model.dart';
import 'package:flutter_app/data/services/menu/menu_addon_service.dart';
import 'package:flutter_app/features/member/add_order_member.dart';
import 'package:flutter_app/features/member/cart_manager_member.dart';
import 'package:flutter_app/features/member/navbar_member.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/restaurant_opening_hour_model.dart';

class ListMenuMember extends StatefulWidget {
  final RestaurantModel restaurantModel;
  const ListMenuMember({super.key, required this.restaurantModel});

  @override
  State<ListMenuMember> createState() => _ListMenuMemberState();
}

class _ListMenuMemberState extends State<ListMenuMember>
    with TickerProviderStateMixin {
  final MenuService _menuService = MenuService();
  final MenuAddonService _addonService = MenuAddonService();

  TabController? _tabController;

  bool _isLoading = true;
  List<TypeMenuModel> _typeMenus = [];
  final Map<int, List<MenuModel>> _categoryMenus = {};

  String? restaurantimage;
  String? restaurantname = "กำลังโหลด...";

  // ── ส่วนจัดการข้าวราดแกง ──
  final int _maxCurrySelect = 3;
  final List<MenuModel> _selectedCurries = [];
  bool _isExtraRice = false;
  int _curryQty = 1;

  List<MenuAddonDetailModel> _curryAddons = [];
  final Map<int, int> _curryAddonQuantities = {};
  final Map<int, MenuAddonDetailModel> _curryAddonModelsIndex = {};

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

  // 🎯 ฟังก์ชันจัดรูปเวลา
  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // 🎯 ฟังก์ชันจัดกลุ่มวันและเวลาเปิด-ปิดให้อ่านง่าย
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

  // 🎯 ฟังก์ชันเช็กว่าปัจจุบันร้านเปิดอยู่หรือไม่
  bool _isCurrentlyOpen() {
    final item = widget.restaurantModel;
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

  // 🎯 ฟังก์ชันเด้ง Alert เมื่อร้านปิดทำการ
  void _showClosedWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_clock_outlined, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text(
                "ร้านค้าปิดให้บริการ",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            "ขออภัย ร้านค้าอยู่นอกเวลาทำการ หรือกำลังปิดให้บริการชั่วคราว จึงไม่สามารถสั่งอาหารได้ในขณะนี้",
            style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "ดูเมนูต่อ",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
              ),
              child: const Text(
                "กลับหน้าหลัก",
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

  void _addMenuCurryToCart(
    double total,
    String note,
    List<MenuAddonDetailModel> addons,
    int addonPrice,
    int unitPrice,
  ) {
    final MenuModel mainCurryMenu = _selectedCurries.isNotEmpty
        ? _selectedCurries.first
        : MenuModel(menuName: "ข้าวเปล่า", price: 20.0);

    CartManager().addToCart(
      CartItem(
        menu: mainCurryMenu,
        selectedAddons: addons,
        selectedCurries: List.from(_selectedCurries),
        quantity: _curryQty,
        note: note,
        addonPrice: addonPrice,
        totalPrice: total.toInt(),
        unitPrice: unitPrice,
        isExtraPrice: false,
      ),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.shopping_basket, color: Colors.green),
            SizedBox(width: 8),
            Text("เพิ่มลงตะกร้าแล้ว"),
          ],
        ),
        content: Text(
          "💰 ราคารวม: ฿${total.toStringAsFixed(0)} บาท\n"
          "🔢 จำนวน: $_curryQty จาน\n"
          "📝 รายละเอียด:\n$note",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _selectedCurries.clear();
                _curryAddonQuantities.clear();
                _isExtraRice = false;
                _curryQty = 1;
              });
              Navigator.pop(context);
            },
            child: const Text(
              "ตกลง",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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

      for (var cat in categories) {
        if (cat.typemenuName != null &&
            cat.typemenuName!.contains("ข้าวราดแกง")) {
          try {
            final addonGroups = await _addonService.getAddonGroupsByRestaurant(
              widget.restaurantModel.username!,
            );

            _curryAddons.clear();
            _curryAddonModelsIndex.clear();

            for (var group in addonGroups) {
              if (group.status != false && group.details != null) {
                for (var detail in group.details!) {
                  if (detail.status != false) {
                    detail.menuAddonGroup = group;
                    _curryAddons.add(detail);

                    if (detail.addonDetailId != null) {
                      _curryAddonModelsIndex[detail.addonDetailId!] = detail;
                    }
                  }
                }
              }
            }
          } catch (e) {
            debugPrint("Error fetching restaurant addons: $e");
          }
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

  Map<String, List<MenuAddonDetailModel>> _groupCurryAddons() {
    Map<String, List<MenuAddonDetailModel>> grouped = {};
    for (var addon in _curryAddons) {
      String groupName =
          addon.menuAddonGroup?.addonGroupName ?? "ตัวเลือกเสริม";
      if (!grouped.containsKey(groupName)) {
        grouped[groupName] = [];
      }
      grouped[groupName]!.add(addon);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final bool isRestaurantOpen = _isCurrentlyOpen();
    final bool shouldScroll = _typeMenus.length > 3;

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
                                    color: Color.fromARGB(255, 5, 86, 151),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // 🎯 แสดงวันเวลาเปิดปิดร้านใต้ชื่อร้าน
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 16,
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
                              ),

                              if (!isRestaurantOpen)
                                Container(
                                  margin: const EdgeInsets.only(top: 14),
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  color: Colors.red.shade50,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.lock_clock_outlined,
                                        color: Colors.red.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "ขณะนี้ร้านปิดให้บริการชั่วคราว",
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 14),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.orange.shade200,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: TabBar(
                                  controller: _tabController!,
                                  isScrollable: shouldScroll,
                                  tabAlignment: shouldScroll
                                      ? TabAlignment.start
                                      : TabAlignment.fill,
                                  labelColor: Colors.deepOrange,
                                  unselectedLabelColor: Colors.black54,
                                  indicatorColor: Colors.deepOrange,
                                  indicatorWeight: 3,
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  dividerColor: Colors.transparent,
                                  labelStyle: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  unselectedLabelStyle: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  labelPadding: shouldScroll
                                      ? const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        )
                                      : EdgeInsets.zero,
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

                        if (type.typemenuName != null &&
                            type.typemenuName!.contains("ข้าวราดแกง")) {
                          return _buildCurrySpecialLayout(
                            currentMenus,
                            isRestaurantOpen,
                          );
                        }

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
                            final isAvailable = menu.status ?? true;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isAvailable
                                    ? const Color(0xFFF0F4E8)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  if (!isRestaurantOpen) {
                                    _showClosedWarningDialog();
                                    return;
                                  }

                                  if (!isAvailable) {
                                    return;
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AddOrderMember(menuModel: menu),
                                    ),
                                  );
                                },
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
                                                  color: Colors.black
                                                      .withOpacity(0.5),
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
                                      IconButton(
                                        onPressed: () {
                                          if (!isRestaurantOpen) {
                                            _showClosedWarningDialog();
                                            return;
                                          }
                                          if (!isAvailable) {
                                            return;
                                          }
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AddOrderMember(
                                                    menuModel: menu,
                                                  ),
                                            ),
                                          );
                                        },
                                        icon: Icon(
                                          Icons.add_circle,
                                          color:
                                              (isAvailable && isRestaurantOpen)
                                              ? const Color(0xFF4CAF50)
                                              : Colors.grey.shade400,
                                          size: 36,
                                        ),
                                      ),
                                    ],
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

  Widget _buildCurryAddonItemOption(
    MenuAddonDetailModel detail,
    bool isMultipleChoice,
    bool isRestaurantOpen,
  ) {
    int id = detail.addonDetailId ?? 0;
    int currentQty = _curryAddonQuantities[id] ?? 0;
    bool isSelected = currentQty > 0;

    String title = detail.addonMenu?.addonName ?? "ไม่มีชื่อ";
    int price = detail.addonPrice?.toInt() ?? 0;
    int currentGroupId = detail.menuAddonGroup?.addonGroupId ?? 0;

    void handleFrontTap() {
      if (!isRestaurantOpen) {
        _showClosedWarningDialog();
        return;
      }
      setState(() {
        if (isSelected) {
          _curryAddonQuantities.remove(id);
        } else {
          if (!isMultipleChoice) {
            _curryAddonQuantities.removeWhere((key, value) {
              final model = _curryAddonModelsIndex[key];
              return model?.menuAddonGroup?.addonGroupId == currentGroupId;
            });
            _curryAddonQuantities[id] = 1;
          } else {
            _curryAddonQuantities[id] = 1;
          }
        }
      });
    }

    void handlePlusTap() {
      if (!isRestaurantOpen) {
        _showClosedWarningDialog();
        return;
      }
      setState(() {
        _curryAddonQuantities[id] = currentQty + 1;
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              InkWell(
                onTap: handleFrontTap,
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: isMultipleChoice
                            ? BoxShape.rectangle
                            : BoxShape.circle,
                        borderRadius: isMultipleChoice
                            ? BorderRadius.circular(4)
                            : null,
                        border: Border.all(
                          color: isRestaurantOpen
                              ? Colors.black
                              : Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: isMultipleChoice
                                      ? BoxShape.rectangle
                                      : BoxShape.circle,
                                  borderRadius: isMultipleChoice
                                      ? BorderRadius.circular(2)
                                      : null,
                                  color: isRestaurantOpen
                                      ? Colors.orange
                                      : Colors.grey,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        color: isRestaurantOpen
                            ? Colors.black87
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "(+$price)",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (isMultipleChoice)
            Container(
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: Icon(
                      Icons.remove,
                      size: 16,
                      color: (isSelected && isRestaurantOpen)
                          ? Colors.black87
                          : Colors.grey.shade300,
                    ),
                    onPressed: () {
                      if (!isRestaurantOpen) {
                        _showClosedWarningDialog();
                        return;
                      }
                      if (isSelected) {
                        setState(() {
                          if (_curryAddonQuantities[id]! <= 1) {
                            _curryAddonQuantities.remove(id);
                          } else {
                            _curryAddonQuantities[id] =
                                _curryAddonQuantities[id]! - 1;
                          }
                        });
                      }
                    },
                  ),
                  Container(
                    alignment: Alignment.center,
                    width: 20,
                    child: Text(
                      "$currentQty",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: (isSelected && isRestaurantOpen)
                            ? Colors.black87
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: Icon(
                      Icons.add,
                      size: 16,
                      color: (isSelected && isRestaurantOpen)
                          ? Colors.black87
                          : Colors.grey.shade300,
                    ),
                    onPressed: () {
                      if (!isRestaurantOpen) {
                        _showClosedWarningDialog();
                        return;
                      }
                      if (isSelected) {
                        handlePlusTap();
                      }
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrySpecialLayout(
    List<MenuModel> curryItems,
    bool isRestaurantOpen,
  ) {
    if (curryItems.isEmpty) {
      return const Center(
        child: Text(
          "ไม่มีเมนูกับข้าวพร้อมจำหน่ายในขณะนี้",
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      );
    }

    final int selectCount = _selectedCurries.length;
    final groupedAddons = _groupCurryAddons();

    double basePrice = 0;
    if (selectCount == 1) {
      basePrice = 30;
    } else if (selectCount == 2) {
      basePrice = 35;
    } else if (selectCount >= 3) {
      basePrice = 40;
    }

    final double totalSurchargePrice = _selectedCurries.fold(
      0.0,
      (sum, curry) => sum + (curry.price ?? 0.0),
    );

    final double optionPrice = (selectCount > 0 && _isExtraRice) ? 5.0 : 0.0;

    double addonTotalPrice = 0;
    _curryAddonQuantities.forEach((id, qty) {
      final model = _curryAddonModelsIndex[id];
      if (model != null) {
        addonTotalPrice += (model.addonPrice ?? 0) * qty;
      }
    });

    final double unitPrice =
        basePrice + totalSurchargePrice + optionPrice + addonTotalPrice;
    final double totalPrice = unitPrice * _curryQty;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 20,
                      color: Colors.black87,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "เลือกกับข้าวที่ต้องการราดหน้า",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(top: 8),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: curryItems.length,
                  itemBuilder: (context, index) {
                    final curry = curryItems[index];
                    final isAvailable = curry.status ?? true;
                    final isSelected = _selectedCurries.any(
                      (element) => element.menuId == curry.menuId,
                    );
                    final imgUrl = _getFinalImageUrl(
                      curry.menuImage ?? (curry as dynamic).imageUrl,
                    );

                    final double storedPrice = curry.price ?? 0.0;
                    final bool isSpecialItem = storedPrice > 0.0;
                    final double displayItemPrice = storedPrice + 5.0;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: !isAvailable
                            ? Colors.grey.shade50
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF4CAF50)
                              : Colors.grey.shade200,
                          width: isSelected ? 2.0 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? const Color(0xFF4CAF50).withOpacity(0.06)
                                : Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CheckboxListTile(
                        activeColor: const Color(0xFF4CAF50),
                        checkboxShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        secondary: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 85,
                            height: 85,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                imgUrl.isNotEmpty
                                    ? Image.network(
                                        Uri.encodeFull(imgUrl),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _buildPlaceholderIcon(),
                                      )
                                    : _buildPlaceholderIcon(),
                                if (!isAvailable)
                                  Container(
                                    color: Colors.black.withOpacity(0.4),
                                    child: const Center(
                                      child: Text(
                                        "หมด",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        title: Text(
                          curry.menuName ?? "ไม่มีชื่อกับข้าว",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isAvailable ? Colors.black87 : Colors.grey,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            isSpecialItem
                                ? "เมนูพิเศษ +${displayItemPrice.toStringAsFixed(0)} บาท"
                                : "รวมในราคาฐานแล้ว",
                            style: TextStyle(
                              color: isSpecialItem
                                  ? Colors.orange.shade800
                                  : Colors.grey.shade500,
                              fontSize: 12,
                              fontWeight: isSpecialItem
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        value: isSelected,
                        onChanged: (bool? value) {
                          if (!isRestaurantOpen) {
                            _showClosedWarningDialog();
                            return;
                          }
                          if (!isAvailable ||
                              (!isSelected &&
                                  _selectedCurries.length >= _maxCurrySelect)) {
                            return;
                          }

                          setState(() {
                            if (isSelected) {
                              _selectedCurries.removeWhere(
                                (element) => element.menuId == curry.menuId,
                              );
                            } else {
                              _selectedCurries.add(curry);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),

                if (groupedAddons.isNotEmpty) ...[
                  const Divider(thickness: 1, height: 32),
                  ...groupedAddons.entries.toList().asMap().entries.map((
                    mapEntry,
                  ) {
                    final isFirstGroup = mapEntry.key == 0;
                    final entry = mapEntry.value;

                    String groupName = entry.key;
                    List<MenuAddonDetailModel> items = entry.value;

                    bool isMultipleChoice =
                        items.first.menuAddonGroup?.is_multiple_choice ?? false;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isFirstGroup)
                          Divider(
                            height: 24,
                            thickness: 1,
                            color: Colors.grey[300],
                          )
                        else
                          const SizedBox(height: 8),

                        Text(
                          groupName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                width: 2,
                                color: const Color(0xFF76FF03),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  children: items
                                      .map(
                                        (addonDetail) =>
                                            _buildCurryAddonItemOption(
                                              addonDetail,
                                              isMultipleChoice,
                                              isRestaurantOpen,
                                            ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: CheckboxListTile(
                  activeColor: const Color(0xFF4CAF50),
                  dense: true,
                  checkboxShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  title: const Text(
                    "เพิ่มปริมาณข้าวสวย",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    "+5 บาท",
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _isExtraRice,
                  onChanged: (val) {
                    if (!isRestaurantOpen) {
                      _showClosedWarningDialog();
                      return;
                    }
                    setState(() => _isExtraRice = val ?? false);
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "จำนวนที่สั่ง",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.remove_circle_outline,
                                size: 24,
                                color: (_curryQty > 1 && isRestaurantOpen)
                                    ? Colors.black87
                                    : Colors.grey.shade400,
                              ),
                              onPressed: () {
                                if (!isRestaurantOpen) {
                                  _showClosedWarningDialog();
                                  return;
                                }
                                if (_curryQty > 1) {
                                  setState(() => _curryQty--);
                                }
                              },
                            ),
                            SizedBox(
                              width: 28,
                              child: Text(
                                "$_curryQty",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.add_circle_outline,
                                size: 24,
                                color: isRestaurantOpen
                                    ? Colors.black87
                                    : Colors.grey.shade400,
                              ),
                              onPressed: () {
                                if (!isRestaurantOpen) {
                                  _showClosedWarningDialog();
                                  return;
                                }
                                setState(() => _curryQty++);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "จำนวน $_curryQty จาน",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: "ราคารวม  ",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            TextSpan(
                              text: "฿${totalPrice.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRestaurantOpen
                        ? const Color(0xFF4CAF50)
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: () {
                    if (!isRestaurantOpen) {
                      _showClosedWarningDialog();
                      return;
                    }

                    if (_selectedCurries.isEmpty) {
                      return;
                    }

                    final List<MenuAddonDetailModel> finalSelectedAddonsList =
                        [];
                    _curryAddonQuantities.forEach((id, qty) {
                      final model = _curryAddonModelsIndex[id];
                      if (model != null && qty > 0) {
                        for (int i = 0; i < qty; i++) {
                          finalSelectedAddonsList.add(model);
                        }
                      }
                    });

                    final curriesNames = _selectedCurries
                        .map((c) => c.menuName ?? "-")
                        .join(', ');
                    final additions = _isExtraRice ? 'เพิ่มข้าว' : '';

                    String finalNote =
                        "ราดแกง: [$curriesNames] ${additions.isNotEmpty ? '($additions)' : ''}";

                    _addMenuCurryToCart(
                      totalPrice,
                      finalNote,
                      finalSelectedAddonsList,
                      addonTotalPrice.toInt(),
                      (basePrice + totalSurchargePrice + optionPrice).toInt(),
                    );
                  },
                  child: const Text(
                    "เพิ่มลงตะกร้า",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 36),
    );
  }
}
