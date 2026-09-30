// features/restaurant/home_restaurant.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/menu_option_group_model.dart';
import 'package:flutter_app/data/models/option_model.dart';
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/type_menu_model.dart';
import 'package:flutter_app/data/services/menu/menu_option_service.dart';
import 'package:flutter_app/data/services/menu/menu_service.dart';
import 'package:flutter_app/data/services/menu/type_menu_service.dart';
import 'package:flutter_app/data/services/order_status_monitor.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/data/services/order_service.dart';
import 'package:flutter_app/features/restaurant/add_addon.dart';
import 'package:flutter_app/features/restaurant/add_menu.dart';
import 'package:flutter_app/features/restaurant/edit_option.dart';
import 'package:flutter_app/features/restaurant/edit_menu.dart';
import 'package:flutter_app/features/restaurant/restaurant_navbar.dart';
import 'package:flutter_app/features/restaurant/review_restaurant.dart';
import 'package:flutter_app/features/restaurant/list_order_restaurant.dart';
import 'package:flutter_app/features/restaurant/account_management.dart';
import 'package:flutter_app/global_data.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class HomeRestaurant extends StatefulWidget {
  const HomeRestaurant({super.key});

  @override
  State<HomeRestaurant> createState() => _HomeRestaurantState();
}

class _HomeRestaurantState extends State<HomeRestaurant>
    with TickerProviderStateMixin {
  static const Color _primary = Color(0xFF16A34A);
  static const Color _primaryDark = Color(0xFF0F7A38);
  static const Color _accent = Color(0xFFEA7C1E);
  static const Color _bg = Color(0xFFF5F6F8);
  static const Color _textDark = Color(0xFF1E1E24);
  static const Color _textMuted = Color(0xFF8A8D93);
  static const Color _danger = Color(0xFFE53935);
  static const Color _reviewYellow = Color(0xFFF5B301);

  final RestaurantService restaurantService = RestaurantService();
  final MenuService menuService = MenuService();
  final TypeMenuService typeMenuService = TypeMenuService();
  final MenuOptionService _optionService = MenuOptionService();
  final OrderService _orderService = OrderService();

  RestaurantModel? restaurantModel;
  TabController? _tabController;

  String? restaurantimage;
  String? restaurantname = "กำลังโหลด...";

  List<TypeMenuModel> typeMenus = [];
  Map<int, List<MenuModel>> categoryMenus = {};
  Map<int, bool> categoryLoading = {};

  int _mainTabIndex = 0;

  bool _isLoadingOptions = false;
  bool _optionsLoaded = false;
  List<_OptionGroupAggregate> _optionGroups = [];
  final Map<int, bool> _groupEnabled = {};
  final Map<int, bool> _groupExpanded = {};

  final Map<int, int> _menuAddonGroupCounts = {};

  Timer? _autoRefreshTimer;
  int _newOrderCount = 0;

  final GlobalKey _profileKey = GlobalKey();
  TutorialCoachMark? tutorialCoachMark;

  String _selectedFilter = '7days';
  String _previousFilter = '7days';
  DateTimeRange? _selectedDateRange;
  List<Map<String, dynamic>> _incomeData = [];
  bool _isLoadingIncome = true;

  bool _showCurryPriceCard = false;

  bool _isEditingCurryPrice = false;
  double? _curryPrice1;
  double? _curryPrice2;
  double? _curryPrice3;
  int? _curryTypeMenuId;
  bool _isLoadingCurryPrice = false;
  bool _isSavingCurryPrice = false;
  final TextEditingController _curryPrice1Controller = TextEditingController();
  final TextEditingController _curryPrice2Controller = TextEditingController();
  final TextEditingController _curryPrice3Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadRestaurantData();
    _fetchNewOrderCount();
    _startAutoRefresh();

    OrderStatusMonitor().startMonitoring();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _tabController?.dispose();
    _curryPrice1Controller.dispose();
    _curryPrice2Controller.dispose();
    _curryPrice3Controller.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) _fetchNewOrderCount();
    });
  }

  bool _isCurrentlyOpen() {
    return restaurantModel?.statusOpen == true;
  }

  // ร้านข้าวราดแกงใช้หน้าเมนูแบบพิเศษ:
  // - ไม่แสดงแถบประเภทเมนู
  // - ไม่แสดงเมนูจัดการกลุ่มตัวเลือก
  // - สามารถกำหนดราคามาตรฐานได้ก่อนเพิ่มเมนู
  // ร้านข้าวราดแกง: ตรวจจากประเภทเมนูที่ backend ส่งมา
  // ไม่บังคับว่าต้องมีเพียง 1 ประเภท และยังตรวจได้แม้ยังไม่มีเมนูในหมวดนั้น
  bool _isRiceCurryRestaurant = false;

  Future _fetchNewOrderCount() async {
    try {
      final waitingOrders = await _orderService.getWaitingOrdersByRestaurant(
        GlobalData.usernameRestaurant,
      );

      int count = waitingOrders.length;

      if (mounted && _newOrderCount != count) {
        setState(() {
          _newOrderCount = count;
        });
      }
    } catch (e) {
      debugPrint("Background order fetch error: " + e.toString());
    }
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;
    final String baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/')
        ? baseUrl + rawPath
        : baseUrl + '/' + rawPath;
  }

  Future loadRestaurantData() async {
    final rest = await restaurantService.getRestaurantByUsername(
      GlobalData.usernameRestaurant,
    );

    if (rest != null) {
      if (!mounted) return;

      setState(() {
        restaurantModel = rest;
        restaurantimage = rest.restaurantImage;
        restaurantname = rest.restaurantName;
        // Reset ก่อนโหลดประเภทจริงของร้าน
        _isRiceCurryRestaurant = false;
      });

      // ตรวจจากประเภทของร้านค้า
      await _loadRestaurantType();

      // ร้านข้าวราดแกงต้องหา TypeMenu จากตาราง TypeMenu โดยตรง
      // ไม่อาศัยการมี Menu ก่อน เพราะร้านสามารถตั้งราคาได้ก่อนเพิ่มเมนู
      if (_isRiceCurryRestaurant) {
        await _loadCurryTypeMenuId();
      } else {
        _curryTypeMenuId = null;
      }

      if (!mounted) return;
      await loadTypeMenus();
    }
  }

  Future<void> _loadRestaurantType() async {
    final int? restaurantTypeId = restaurantModel?.typerestaurantId;
    if (restaurantTypeId == null) return;

    try {
      final response = await DioClient.dio.get('/v1/typerestaurant');

      if (response.statusCode != 200 || response.data is! List) {
        return;
      }

      final List data = response.data as List;

      for (final raw in data) {
        if (raw is! Map) continue;

        final dynamic rawId =
            raw['typerestaurantId'] ?? raw['typerestaurant_id'];
        final int? id = rawId is num ? rawId.toInt() : int.tryParse('$rawId');

        if (id != restaurantTypeId) continue;

        final String typeName =
            (raw['typerestaurantName'] ??
                    raw['typerestaurant_name'] ??
                    raw['name'] ??
                    '')
                .toString()
                .trim();

        if (!mounted) return;

        setState(() {
          _isRiceCurryRestaurant = typeName.contains('ข้าวราดแกง');
        });

        debugPrint(
          'Restaurant type: $typeName | isRiceCurryRestaurant=$_isRiceCurryRestaurant',
        );
        return;
      }
    } catch (e) {
      debugPrint('ไม่สามารถตรวจสอบประเภทร้านค้าได้: $e');

      // fallback: ถ้า endpoint ประเภทร้านใช้ไม่ได้
      // ยังลองตรวจจาก TypeMenu เพื่อไม่ให้ระบบเดิมเสีย
      try {
        final menuTypes = await menuService.getTypeMenuByRestaurant(
          restaurantModel!.username!,
        );

        final bool fallback = menuTypes.any(
          (type) => (type.typemenuName?.trim() ?? '').contains('ข้าวราดแกง'),
        );

        if (mounted) {
          setState(() => _isRiceCurryRestaurant = fallback);
        }
      } catch (_) {
        // ปล่อยค่าเดิมเป็น false หากตรวจไม่ได้ทั้งสองทาง
      }
    }
  }

  Future loadTypeMenus() async {
    if (restaurantModel == null) return;

    final data = await menuService.getTypeMenuByRestaurant(
      restaurantModel!.username!,
    );

    // ตรวจจากประเภทร้านที่โหลดไว้แล้ว
    // ไม่ใช้ TypeMenu เป็นตัวตัดสินหลักอีกต่อไป
    final bool isRiceCurry = _isRiceCurryRestaurant;

    final List<MapEntry<TypeMenuModel, List<MenuModel>>> entries =
        await Future.wait<MapEntry<TypeMenuModel, List<MenuModel>>>(
          data.where((t) => t.typemenuId != null).map((type) async {
            final typeId = type.typemenuId!;
            try {
              final menuData = await menuService.getMenusByTypeMenu(
                restaurantModel!.username!,
                typeId,
              );
              return MapEntry<TypeMenuModel, List<MenuModel>>(
                type,
                List<MenuModel>.from(menuData),
              );
            } catch (e) {
              return MapEntry<TypeMenuModel, List<MenuModel>>(
                type,
                <MenuModel>[],
              );
            }
          }),
        );

    // ร้านทั่วไป: แสดงเฉพาะหมวดที่มีเมนู
    // ร้านข้าวราดแกง: ถ้ามี TypeMenu อยู่ ให้เก็บไว้แม้เมนูในหมวดนั้นจะยังว่าง
    final validEntries = isRiceCurry
        ? entries
        : entries.where((e) => e.value.isNotEmpty).toList();

    final newController = TabController(
      length: validEntries.isEmpty ? 1 : validEntries.length,
      vsync: this,
    );

    _tabController?.dispose();

    setState(() {
      _menuAddonGroupCounts.clear();
      _isRiceCurryRestaurant = isRiceCurry;
      typeMenus = validEntries.map((e) => e.key).toList();
      categoryMenus
        ..clear()
        ..addEntries(
          validEntries.map((e) => MapEntry(e.key.typemenuId!, e.value)),
        );
      categoryLoading
        ..clear()
        ..addEntries(
          validEntries.map((e) => MapEntry(e.key.typemenuId!, false)),
        );
      _tabController = newController;
    });

    // ไม่หา _curryTypeMenuId จาก Menu อีกต่อไป
    // เพราะร้านอาจยังไม่มี Menu ขณะตั้งราคาครั้งแรก

    final allMenus = validEntries.expand((e) => e.value).toList();
    _loadAddonCountsFor(allMenus);

    if (_isRiceCurryRestaurant) {
      await _loadCurryPrice();
    } else {
      _curryPrice1 = null;
      _curryPrice2 = null;
      _curryPrice3 = null;
    }
  }

  void _rebuildTabController({int? removedIndex}) {
    final int oldIndex = _tabController?.index ?? 0;
    _tabController?.dispose();

    final int length = typeMenus.isEmpty ? 1 : typeMenus.length;
    int newIndex = oldIndex;
    if (removedIndex != null && removedIndex < oldIndex) {
      newIndex = oldIndex - 1;
    }
    newIndex = newIndex.clamp(0, length - 1);

    _tabController = TabController(
      length: length,
      vsync: this,
      initialIndex: newIndex,
    );
  }

  Future loadMenusByType(int typeMenuId) async {
    if (restaurantModel == null) return;

    setState(() {
      categoryLoading[typeMenuId] = true;
    });

    try {
      final menuData = await menuService.getMenusByTypeMenu(
        restaurantModel!.username!,
        typeMenuId,
      );

      if (menuData.isEmpty) {
        final removedIndex = typeMenus.indexWhere(
          (t) => t.typemenuId == typeMenuId,
        );
        setState(() {
          categoryMenus.remove(typeMenuId);
          categoryLoading.remove(typeMenuId);
          if (removedIndex != -1) typeMenus.removeAt(removedIndex);
          _rebuildTabController(removedIndex: removedIndex);
        });
      } else {
        setState(() {
          categoryMenus[typeMenuId] = menuData;
          categoryLoading[typeMenuId] = false;

          for (var m in menuData) {
            if (m.menuId != null) _menuAddonGroupCounts.remove(m.menuId);
          }
        });

        _loadAddonCountsFor(menuData);
      }
    } catch (e) {
      setState(() {
        categoryLoading[typeMenuId] = false;
      });
    }
  }

  Future _loadAddonCountsFor(List menus) async {
    final idsToLoad = menus
        .where(
          (m) =>
              m.menuId != null && !_menuAddonGroupCounts.containsKey(m.menuId),
        )
        .map((m) => m.menuId!)
        .toSet()
        .toList();

    if (idsToLoad.isEmpty) return;

    final results = await Future.wait(
      idsToLoad.map((id) async {
        try {
          final groups = await _optionService.getOptionsByMenuId(id);
          final groupIds = groups
              .map((group) => group.optionGroupId)
              .whereType<int>()
              .toSet();
          return MapEntry(id, groupIds.length);
        } catch (e) {
          return MapEntry(id, 0);
        }
      }),
    );

    if (!mounted) return;
    setState(() {
      for (final entry in results) {
        _menuAddonGroupCounts[entry.key] = entry.value;
      }
    });
  }

  Future _loadCurryTypeMenuId() async {
    try {
      final allTypes = await typeMenuService.getAllTypeMenu();

      TypeMenuModel? curryType;

      for (final type in allTypes) {
        final name = (type.typemenuName ?? '').trim();
        if (name.contains('ข้าวราดแกง') || name.contains('ข้าวแกง')) {
          curryType = type;
          break;
        }
      }

      // Fallback: ถ้าไม่เจอใน getAllTypeMenu ให้เช็กจากหมวดหมู่ของร้านที่มีอยู่
      if (curryType == null && restaurantModel?.username != null) {
        final restTypes = await menuService.getTypeMenuByRestaurant(
          restaurantModel!.username!,
        );
        for (final type in restTypes) {
          final name = (type.typemenuName ?? '').trim();
          if (name.contains('ข้าวราดแกง') || name.contains('ข้าวแกง')) {
            curryType = type;
            break;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _curryTypeMenuId = curryType?.typemenuId;
      });
    } catch (e) {
      debugPrint('โหลด TypeMenu ข้าวราดแกงไม่สำเร็จ: $e');
    }
  }

  Future _loadCurryPrice() async {
    final String? username = restaurantModel?.username;

    if (!_isRiceCurryRestaurant || username == null) {
      return;
    }

    if (mounted) {
      setState(() => _isLoadingCurryPrice = true);
    }

    try {
      // 🎯 ส่ง _curryTypeMenuId ?? 0 เพื่อให้ดึงราคาได้แม้ยังไม่ได้ผูก typeMenuId
      final data = await menuService.getCurryPrice(
        restaurantId: username,
        typeMenuId: _curryTypeMenuId ?? 0,
      );

      if (!mounted) return;

      setState(() {
        _curryPrice1 = data?['price'];
        _curryPrice2 = data?['price2'];
        _curryPrice3 = data?['price3'];
        _isLoadingCurryPrice = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCurryPrice = false);
      debugPrint('โหลดราคาข้าวราดแกงไม่สำเร็จ: $e');
    }
  }

  Future _confirmCurryPrice() async {
    final price1 = _parseCurryPrice(_curryPrice1Controller.text);
    final price2 = _parseCurryPrice(_curryPrice2Controller.text);
    final price3 = _parseCurryPrice(_curryPrice3Controller.text);

    if (price1 == null || price2 == null || price3 == null) {
      _showErrorSnackBar(
        "กรุณากรอกราคา 1, 2 และ 3 อย่างให้ครบ และมากกว่า 0 บาท",
      );
      return;
    }

    final String? username = restaurantModel?.username;

    if (username == null) {
      _showErrorSnackBar("ไม่พบข้อมูลร้านค้า กรุณาลองใหม่อีกครั้ง");
      return;
    }

    // ลองโหลดอีกรอบถ้ายังเป็น null
    if (_curryTypeMenuId == null) {
      await _loadCurryTypeMenuId();
    }

    if (mounted) {
      setState(() => _isSavingCurryPrice = true);
    }

    try {
      // 🎯 หากยังไม่มีประเภทเมนูข้าวราดแกงใน DB ให้ส่ง 0 ไปเพื่อให้ Backend สร้างให้อัตโนมัติ
      await menuService.saveCurryPrice(
        restaurantId: username,
        typeMenuId: _curryTypeMenuId ?? 0,
        price: price1,
        price2: price2,
        price3: price3,
      );

      if (!mounted) return;

      setState(() {
        _curryPrice1 = price1;
        _curryPrice2 = price2;
        _curryPrice3 = price3;
        _isEditingCurryPrice = false;
        _isSavingCurryPrice = false;
      });

      _showSuccessSnackBar("บันทึกราคามาตรฐานเรียบร้อย");

      // โหลด TypeMenuId และรายการเมนูใหม่เพื่ออัปเดตข้อมูลล่าสุดจากฐานข้อมูล
      await _loadCurryTypeMenuId();
      await loadTypeMenus();
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSavingCurryPrice = false);
      _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future toggleStatus(int typeMenuId, int index) async {
    final currentMenus = categoryMenus[typeMenuId];
    if (currentMenus == null || currentMenus.isEmpty) return;

    final menu = currentMenus[index];
    if (menu.menuId == null) return;

    final newStatus = !(menu.status ?? true);

    setState(() {
      categoryMenus[typeMenuId]![index].status = newStatus;
    });

    try {
      await menuService.updateMenuStatus(menu.menuId!, newStatus);
    } catch (e) {
      setState(() {
        categoryMenus[typeMenuId]![index].status = !newStatus;
      });
      if (mounted) {
        _showErrorSnackBar("ไม่สามารถอัปเดตสถานะได้");
      }
    }
  }

  Future goToEditMenu(int typeMenuId, MenuModel menu) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditMenu(menuModel: menu)),
    );
    await loadMenusByType(typeMenuId);
  }

  Future _goToEditOptionGroup(_OptionGroupAggregate agg) async {
    final bool isMultipleChoice = agg.group.isMultipleChoice;
    final List<OptionModel> options = agg.items.values.toList();

    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAddon(
          groupId: agg.group.optionGroupId,
          groupName: agg.group.optionGroupName,
          isMultipleChoice: isMultipleChoice,
          groupStatus: _groupEnabled[agg.group.optionGroupId ?? -1] ?? true,
          details: options,
        ),
      ),
    );

    if (updated == true) {
      _optionsLoaded = false;
      await _loadOptionGroups();
    }
  }

  Future confirmDeleteMenu(int typeMenuId, MenuModel menu) async {
    final confirmed = await _showConfirmDialog(
      title: "ลบเมนูนี้?",
      message: 'ต้องการลบ "' + (menu.menuName ?? '') + '" ใช่หรือไม่',
    );

    if (confirmed != true || menu.menuId == null) return;

    try {
      await menuService.deleteMenu({'menuid': menu.menuId});
      await loadMenusByType(typeMenuId);
      _showSuccessSnackBar("ลบเมนูสำเร็จ");
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString().replaceAll("Exception: ", "");

        if (errorMsg.contains("กำลังดำเนินการอยู่")) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.warning_rounded, color: _danger, size: 28),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "ไม่สามารถลบได้",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Text(
                errorMsg,
                style: const TextStyle(fontSize: 14.5, height: 1.4),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: _danger),
                  child: const Text(
                    "ตกลง",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          _showErrorSnackBar("เกิดข้อผิดพลาด: " + errorMsg);
        }
      }
    }
  }

  // 🎯 ดัก Error จอแดง ตรงการลบตัวเลือก
  Future confirmDeleteOptionGroup(_OptionGroupAggregate agg) async {
    final groupId = agg.group.optionGroupId;
    if (groupId == null) return;

    int usedCount = 0;
    try {
      usedCount = await _optionService.getMenuCountUsingOptionGroup(groupId);
    } catch (_) {
      usedCount = 0;
    }

    final confirmed = await _showConfirmDialog(
      title: "ยืนยันการลบตัวเลือก",
      itemName: agg.group.optionGroupName ?? '',
      usedCount: usedCount,
    );

    if (confirmed != true) return;

    try {
      final success = await _optionService.deleteOptionGroup(groupId);
      if (success) {
        _optionsLoaded = false;
        await _loadOptionGroups();

        if (mounted) {
          await loadRestaurantData();
        }

        if (mounted) {
          _showSuccessSnackBar("ลบกลุ่มตัวเลือกสำเร็จ");
        }
      } else if (mounted) {
        _showErrorSnackBar("ไม่สามารถลบตัวเลือกได้");
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();

        // 🎯 ดักจับ Error ที่ Backend ตอบกลับมาเป็น Plain text ทำให้เกิดการแปลผลผิดพลาด
        if (errorMsg.contains("กำลังดำเนินการอยู่") ||
            errorMsg.contains("type 'String' is not a subtype of type 'int'")) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.warning_rounded, color: _danger, size: 28),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "ไม่สามารถลบได้",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: const Text(
                "ไม่สามารถลบตัวเลือกได้ เนื่องจากร้านมีออเดอร์ที่กำลังดำเนินการอยู่ครับ",
                style: TextStyle(fontSize: 14.5, height: 1.4),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: _danger),
                  child: const Text(
                    "ตกลง",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          _showErrorSnackBar(errorMsg.replaceFirst('Exception: ', ''));
        }
      }
    }
  }

  // 🎯 ฟังก์ชันสำหรับสลับสถานะเปิด/ปิดของ Option Group
  Future _toggleOptionGroupStatusUI(int groupId, bool currentStatus) async {
    final newStatus = !currentStatus;

    // อัปเดต UI ทันทีเพื่อให้ดูเร็ว (Optimistic UI)
    setState(() {
      _groupEnabled[groupId] = newStatus;
    });

    try {
      final success = await _optionService.toggleOptionGroupStatus(
        groupId,
        newStatus,
      );
      if (!success) throw Exception("อัปเดตไม่สำเร็จ");
    } catch (e) {
      // ถ้า Error คืนค่ากลับเป็นเหมือนเดิม
      setState(() {
        _groupEnabled[groupId] = currentStatus;
      });
      if (mounted) {
        _showErrorSnackBar("ไม่สามารถอัปเดตสถานะได้");
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
        elevation: 4,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Future _showConfirmDialog({
    required String title,
    String? message,
    String? itemName,
    int usedCount = 0,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _danger.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: _danger,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 8),

              if (usedCount > 0)
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: "มี "),
                      TextSpan(
                        text: usedCount.toString() + " รายการ",
                        style: const TextStyle(
                          color: _accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(
                        text:
                            " ที่ใช้ตัวเลือกนี้อยู่\nคุณต้องการลบทิ้งใช่หรือไม่?",
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: _textMuted),
                )
              else
                Text(
                  message ?? 'ต้องการลบ "' + (itemName ?? '') + '" ใช่หรือไม่',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: _textMuted),
                ),

              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textMuted,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "ยกเลิก",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _danger,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "ลบ",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future _loadOptionGroups() async {
    if (_isLoadingOptions) return;
    setState(() => _isLoadingOptions = true);

    try {
      final groups = await _optionService.getOptionGroupsByRestaurant(
        GlobalData.usernameRestaurant,
      );

      if (!mounted) return;

      setState(() {
        _optionGroups = groups.map((group) {
          final agg = _OptionGroupAggregate(group);

          final rawOptions = group.options;
          if (rawOptions is List) {
            for (final rawOption in rawOptions) {
              if (rawOption is! OptionModel) continue;

              final int itemKey = rawOption.optionId ?? rawOption.hashCode;

              agg.items.putIfAbsent(itemKey, () => rawOption);
            }
          }

          return agg;
        }).toList();

        for (final agg in _optionGroups) {
          final int? gid = agg.group.optionGroupId;

          if (gid != null) {
            // OptionGroupModel ไม่มี status จึงเก็บสถานะไว้ใน UI state
            _groupEnabled.putIfAbsent(gid, () => true);
            _groupExpanded[gid] = false;
          }
        }

        _isLoadingOptions = false;
        _optionsLoaded = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingOptions = false);
        _showErrorSnackBar("โหลดกลุ่มตัวเลือกไม่สำเร็จ: " + e.toString());
      }
    }
  }

  Future _loadIncomeData() async {
    setState(() => _isLoadingIncome = true);

    DateTime start;
    DateTime end;
    DateTime now = DateTime.now();
    DateTime todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
    DateTime todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (_selectedFilter == 'today') {
      start = todayStart;
      end = todayEnd;
    } else if (_selectedFilter == '3days') {
      start = todayStart.subtract(const Duration(days: 3));
      end = todayEnd;
    } else if (_selectedFilter == '7days') {
      start = todayStart.subtract(const Duration(days: 7));
      end = todayEnd;
    } else if (_selectedFilter == '1month') {
      start = DateTime(now.year, now.month - 1, now.day);
      end = todayEnd;
    } else if (_selectedFilter == '3months') {
      start = DateTime(now.year, now.month - 3, now.day);
      end = todayEnd;
    } else if (_selectedFilter == '6months') {
      start = DateTime(now.year, now.month - 6, now.day);
      end = todayEnd;
    } else if (_selectedFilter == 'custom' && _selectedDateRange != null) {
      start = _selectedDateRange!.start;
      end = DateTime(
        _selectedDateRange!.end.year,
        _selectedDateRange!.end.month,
        _selectedDateRange!.end.day,
        23,
        59,
        59,
      );
    } else {
      start = todayStart.subtract(const Duration(days: 7));
      end = todayEnd;
    }

    try {
      final data = await _orderService.getRestaurantIncomeByDateRange(
        GlobalData.usernameRestaurant,
        start,
        end,
      );

      if (mounted) {
        setState(() {
          _incomeData = data;
          _isLoadingIncome = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingIncome = false);
    }
  }

  Future _pickDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange:
          _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      setState(() {
        _selectedFilter = 'custom';
        _selectedDateRange = pickedRange;
      });
      _loadIncomeData();
    } else {
      setState(() {
        _selectedFilter = _previousFilter;
      });
    }
  }

  String _formatDate(DateTime date) {
    return date.day.toString() +
        "/" +
        date.month.toString() +
        "/" +
        (date.year + 543).toString();
  }

  String _getMonthNameThai(String monthStr) {
    const months = [
      "ม.ค.",
      "ก.พ.",
      "มี.ค.",
      "เม.ย.",
      "พ.ค.",
      "มิ.ย.",
      "ก.ค.",
      "ส.ค.",
      "ก.ย.",
      "ต.ค.",
      "พ.ย.",
      "ธ.ค.",
    ];
    int m = int.tryParse(monthStr) ?? 1;
    return months[m - 1];
  }

  Future _onSelectMainTab(int index) async {
    if (_showCurryPriceCard) {
      setState(() {
        _showCurryPriceCard = false;
        _isEditingCurryPrice = false;
      });
    }

    if (_isRiceCurryRestaurant && index == 1) return;
    if (_mainTabIndex == index) return;

    // ร้านข้าวราดแกงไม่มีหน้า "กลุ่มตัวเลือก"
    if (_isRiceCurryRestaurant && index == 1) return;

    if (_mainTabIndex == index) return;
    setState(() {
      _mainTabIndex = index;
      _groupExpanded.updateAll((key, value) => false);
    });
    if (index == 1 && !_optionsLoaded) {
      while (categoryLoading.values.any((v) => v == true)) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
      await _loadOptionGroups();
    } else if (index == 2) {
      await _loadIncomeData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String finalImageUrl = _getFinalImageUrl(restaurantimage);

    if (_tabController == null) {
      return const Scaffold(
        appBar: RestaurantNavbar(title: ""),
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: _bg,
          extendBodyBehindAppBar: true,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SizedBox(
                            height: 300,
                            width: double.infinity,
                            child: finalImageUrl.isNotEmpty
                                ? Image.network(
                                    Uri.encodeFull(finalImageUrl),
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _buildPlaceholderBackground(),
                                  )
                                : _buildPlaceholderBackground(),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 90,
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0),
                                      Colors.black.withOpacity(0.18),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -1,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 30,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(28),
                                  topRight: Radius.circular(28),
                                ),
                              ),
                            ),
                          ),

                          const Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: RestaurantNavbar(title: ""),
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
                              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      restaurantname ?? "-",
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: _textDark,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Builder(
                                    builder: (context) {
                                      final isOpen = _isCurrentlyOpen();
                                      final statusColor = isOpen
                                          ? _primaryDark
                                          : const Color.fromARGB(
                                              255,
                                              181,
                                              60,
                                              0,
                                            );
                                      final statusBg = isOpen
                                          ? _primary.withOpacity(0.12)
                                          : Colors.grey.shade200;

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusBg,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: isOpen
                                                ? _primary.withOpacity(0.18)
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 7,
                                              height: 7,
                                              decoration: BoxDecoration(
                                                color: statusColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              isOpen
                                                  ? "ร้านเปิดอยู่"
                                                  : "ร้านปิดอยู่",
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
                            ),
                            const SizedBox(height: 16),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: _buildQuickActionsRow(),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_mainTabIndex == 0 && !_isRiceCurryRestaurant)
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
                                      tabs: typeMenus.isEmpty
                                          ? [const Tab(text: 'ไม่มีประเภท')]
                                          : typeMenus
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

            body: _mainTabIndex == 0
                ? (_isRiceCurryRestaurant
                      ? (_showCurryPriceCard
                            ? _buildCurryPriceBody()
                            : _buildRiceCurryMenuBody())
                      : TabBarView(
                          controller: _tabController!,
                          children: typeMenus.isEmpty
                              ? [
                                  const Center(
                                    child: Text(
                                      "ไม่มีข้อมูลเมนู",
                                      style: TextStyle(color: _textMuted),
                                    ),
                                  ),
                                ]
                              : typeMenus.map((type) {
                                  final typeId = type.typemenuId!;
                                  final isTabLoading =
                                      categoryLoading[typeId] ?? true;
                                  final currentMenus =
                                      categoryMenus[typeId] ?? [];

                                  if (isTabLoading) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: _primary,
                                      ),
                                    );
                                  }

                                  if (currentMenus.isEmpty) {
                                    return const Center(
                                      child: Text(
                                        "ไม่มีเมนูในหมวดหมู่นี้",
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: _textMuted,
                                        ),
                                      ),
                                    );
                                  }

                                  return RefreshIndicator(
                                    color: _primary,
                                    onRefresh: () => loadMenusByType(typeId),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            16,
                                            16,
                                            16,
                                            4,
                                          ),
                                          child: Text(
                                            currentMenus.length.toString() +
                                                " รายการ",
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: _textMuted,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: ListView.separated(
                                            padding: const EdgeInsets.fromLTRB(
                                              16,
                                              8,
                                              16,
                                              90,
                                            ),
                                            physics:
                                                const AlwaysScrollableScrollPhysics(),
                                            itemCount:
                                                currentMenus.length +
                                                (_showCurryPriceCard ? 1 : 0),
                                            separatorBuilder: (_, __) =>
                                                const SizedBox(height: 12),
                                            itemBuilder: (context, i) {
                                              if (_showCurryPriceCard &&
                                                  i == 0) {
                                                return _buildCurryPriceCard();
                                              }

                                              final index = _showCurryPriceCard
                                                  ? i - 1
                                                  : i;
                                              final menu = currentMenus[index];
                                              final isAvailable =
                                                  menu.status ?? true;
                                              final finalMenuImgUrl =
                                                  _getFinalImageUrl(
                                                    menu.menuImage,
                                                  );

                                              return _buildMenuCard(
                                                typeId: typeId,
                                                index: index,
                                                menu: menu,
                                                isAvailable: isAvailable,
                                                finalMenuImgUrl:
                                                    finalMenuImgUrl,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                        ))
                : _mainTabIndex == 1
                ? _buildOptionGroupsBody()
                : _buildSalesDashboardBody(),
          ),

          bottomNavigationBar:
              (_mainTabIndex == 2 ||
                  (_isRiceCurryRestaurant && _showCurryPriceCard))
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [_primary, _primaryDark],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: () async {
                            if (_mainTabIndex == 0) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddMenu(),
                                ),
                              );
                              await loadRestaurantData();
                            } else {
                              final saved = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddAddon(),
                                ),
                              );
                              if (saved == true) {
                                _optionsLoaded = false;
                                await _loadOptionGroups();
                              }
                            }
                          },
                          icon: Icon(
                            _mainTabIndex == 0
                                ? Icons.add_rounded
                                : Icons.add_rounded,
                            size: 22,
                          ),
                          label: Text(
                            _mainTabIndex == 0
                                ? "เพิ่มเมนู"
                                : "เพิ่มกลุ่มตัวเลือก",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),

        // 🎯 จุดเป้าหมายล่องหน สำหรับ Tutorial ชี้ไปที่ไอคอนโปรไฟล์มุมขวาบน
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 16,
          width: 45,
          height: 45,
          child: IgnorePointer(
            child: Container(
              key: _profileKey, // ผูกคีย์ที่นี่
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRiceCurryMenuBody() {
    if (typeMenus.isEmpty) {
      return const Center(
        child: Text("ไม่มีข้อมูลเมนู", style: TextStyle(color: _textMuted)),
      );
    }

    final TypeMenuModel curryType = typeMenus.firstWhere(
      (type) => (type.typemenuName?.trim() ?? '').contains('ข้าวราดแกง'),
      orElse: () => typeMenus.first,
    );
    final int typeId = curryType.typemenuId!;
    final bool isLoading = categoryLoading[typeId] ?? true;
    final List<MenuModel> currentMenus = categoryMenus[typeId] ?? [];

    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    if (currentMenus.isEmpty) {
      return RefreshIndicator(
        color: _primary,
        onRefresh: () => loadMenusByType(typeId),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Center(
              child: Text(
                "ยังไม่มีเมนูข้าวราดแกง",
                style: TextStyle(fontSize: 15, color: _textMuted),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: () => loadMenusByType(typeId),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                const Text(
                  "เมนูข้าวราดแกง",
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                  ),
                ),
                const Spacer(),
                Text(
                  currentMenus.length.toString() + " รายการ",
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: currentMenus.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final menu = currentMenus[index];
                final isAvailable = menu.status ?? true;
                final finalMenuImgUrl = _getFinalImageUrl(menu.menuImage);

                return _buildMenuCard(
                  typeId: typeId,
                  index: index,
                  menu: menu,
                  isAvailable: isAvailable,
                  finalMenuImgUrl: finalMenuImgUrl,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurryPriceBody() {
    // ราคามาตรฐานของร้านข้าวราดแกงต้องกำหนดได้ แม้ยังไม่มี Menu
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [_buildCurryPriceCard()],
    );
  }

  void _prepareCurryPriceControllers() {
    String valueOf(double? value) {
      if (value == null || value <= 0) return "";
      return value.toStringAsFixed(0);
    }

    _curryPrice1Controller.text = valueOf(_curryPrice1);
    _curryPrice2Controller.text = valueOf(_curryPrice2);
    _curryPrice3Controller.text = valueOf(_curryPrice3);
  }

  double? _parseCurryPrice(String value) {
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  void _startEditingCurryPrice() {
    _prepareCurryPriceControllers();
    setState(() {
      _isEditingCurryPrice = true;
    });
  }

  void _cancelEditingCurryPrice() {
    _prepareCurryPriceControllers();
    setState(() {
      _isEditingCurryPrice = false;
    });
  }

  Widget _buildCurryPriceRow({
    required String label,
    required double? value,
    required TextEditingController controller,
  }) {
    String fmt(double? v) => (v == null || v <= 0)
        ? "ยังไม่ได้กำหนด"
        : "${v.toStringAsFixed(0)} บาท";

    if (!_isEditingCurryPrice) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: _primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _primary.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
            ),
            Text(
              fmt(value),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: value == null || value <= 0 ? _textMuted : _primary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: "กรอกราคา",
                suffixText: "บาท",
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _primary, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurryPriceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _primary.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.price_change_rounded,
                  color: _primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "ราคามาตรฐานข้าวราดแกง",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
              ),
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  setState(() {
                    _isEditingCurryPrice = false;
                    _showCurryPriceCard = false;
                  });
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 20, color: _textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_isLoadingCurryPrice)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: CircularProgressIndicator(
                  color: _primary,
                  strokeWidth: 2.5,
                ),
              ),
            )
          else ...[
            // แสดงราคาได้แม้ยังไม่มีเมนู
            _buildCurryPriceRow(
              label: "1 อย่าง",
              value: _curryPrice1,
              controller: _curryPrice1Controller,
            ),
            const SizedBox(height: 8),
            _buildCurryPriceRow(
              label: "2 อย่าง",
              value: _curryPrice2,
              controller: _curryPrice2Controller,
            ),
            const SizedBox(height: 8),
            _buildCurryPriceRow(
              label: "3 อย่าง",
              value: _curryPrice3,
              controller: _curryPrice3Controller,
            ),
            const SizedBox(height: 10),

            Text(
              _isEditingCurryPrice
                  ? "กำหนดราคามาตรฐานของร้านได้เลย แม้ยังไม่มีเมนูข้าวราดแกง"
                  : "สามารถกำหนดราคาก่อนเพิ่มเมนูข้าวราดแกงได้",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            if (!_isEditingCurryPrice)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _startEditingCurryPrice,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    side: BorderSide(
                      color: _primary.withOpacity(0.55),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 19),
                  label: const Text(
                    "แก้ไข",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _cancelEditingCurryPrice,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textMuted,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "ยกเลิก",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSavingCurryPrice
                          ? null
                          : _confirmCurryPrice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isSavingCurryPrice
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 19),
                      label: Text(
                        _isSavingCurryPrice ? "กำลังบันทึก..." : "ยืนยัน",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required int typeId,
    required int index,
    required MenuModel menu,
    required bool isAvailable,
    required String finalMenuImgUrl,
  }) {
    final bool isRiceCurry = _isRiceCurryRestaurant;

    final double storedPrice = menu.price ?? 0.0;
    final bool shouldShowPrice = !isRiceCurry || (storedPrice != 0.0);
    final double displayPrice = storedPrice;

    final int? menuId = menu.menuId;
    final int addonCount = menuId != null
        ? (_menuAddonGroupCounts[menuId] ?? 0)
        : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.white : const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 0.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 84,
              height: 84,
              child: finalMenuImgUrl.isNotEmpty
                  ? Image.network(
                      Uri.encodeFull(finalMenuImgUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderImage(),
                    )
                  : _placeholderImage(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        menu.menuName ?? "-",
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildInlineStatusButton(
                      isAvailable: isAvailable,
                      onTap: () => toggleStatus(typeId, index),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                if (!isRiceCurry && shouldShowPrice)
                  Text(
                    "ราคา " + displayPrice.toStringAsFixed(0) + " บาท",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    if (!isRiceCurry)
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.layers_outlined,
                              size: 14,
                              color: addonCount > 0
                                  ? Colors.blueAccent
                                  : _textMuted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                addonCount > 0
                                    ? "มี " +
                                          addonCount.toString() +
                                          " กลุ่มตัวเลือก"
                                    : "ไม่มีตัวเลือก",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: addonCount > 0
                                      ? Colors.blueAccent
                                      : _textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Spacer(),

                    const SizedBox(width: 8),
                    _buildIconAction(
                      icon: Icons.edit_rounded,
                      color: _accent,
                      onTap: () => goToEditMenu(typeId, menu),
                    ),
                    const SizedBox(width: 16),
                    _buildIconAction(
                      icon: Icons.delete_outline_rounded,
                      color: _danger,
                      onTap: () => confirmDeleteMenu(typeId, menu),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceChip(String label, double? price) {
    final bool hasPrice = price != null && price > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: hasPrice ? _primary.withOpacity(0.08) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasPrice ? _primary.withOpacity(0.18) : Colors.grey.shade300,
        ),
      ),
      child: Text(
        hasPrice ? "$label ${price.toStringAsFixed(0)}฿" : "$label -",
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: hasPrice ? _primary : _textMuted,
        ),
      ),
    );
  }

  Widget _buildIconAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 19, color: color),
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAction(
            icon: Icons.receipt_long_rounded,
            label: "เมนู",
            iconColor: (_mainTabIndex == 0 && !_showCurryPriceCard)
                ? _primary
                : _primary,
            active: _mainTabIndex == 0 && !_showCurryPriceCard,
            onTap: () => _onSelectMainTab(0),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _isRiceCurryRestaurant
              ? _buildQuickAction(
                  icon: Icons.price_change_rounded,
                  label: "ตั้งค่าราคา",
                  iconColor: (_mainTabIndex == 0 && _showCurryPriceCard)
                      ? _primary
                      : _primary,
                  active: _mainTabIndex == 0 && _showCurryPriceCard,
                  onTap: () {
                    if (_showCurryPriceCard) {
                      setState(() {
                        _isEditingCurryPrice = false;
                        _showCurryPriceCard = false;
                      });
                    } else {
                      _prepareCurryPriceControllers();
                      setState(() {
                        _mainTabIndex = 0;
                        _showCurryPriceCard = true;
                      });
                    }
                  },
                )
              : _buildQuickAction(
                  icon: Icons.playlist_add_check_rounded,
                  label: "กลุ่มตัวเลือก",
                  iconColor: _mainTabIndex == 1 ? _primary : _textDark,
                  active: _mainTabIndex == 1,
                  onTap: () => _onSelectMainTab(1),
                ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildQuickActionWithBadge(
            icon: Icons.list_alt_rounded,
            label: "ออเดอร์",
            iconColor: _accent,
            active: false,
            badgeCount: _newOrderCount,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ListOrderRestaurant()),
            ).then((_) => _fetchNewOrderCount()),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildQuickAction(
            icon: Icons.point_of_sale_rounded,
            label: "ยอดขาย",
            iconColor: _mainTabIndex == 2 ? _primary : Colors.teal.shade700,
            active: _mainTabIndex == 2,
            onTap: () => _onSelectMainTab(2),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildQuickAction(
            icon: Icons.star_rounded,
            label: "รีวิว",
            iconColor: _reviewYellow,
            active: false,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReviewRestaurant()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color iconColor,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        decoration: BoxDecoration(
          color: active ? _primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? _primary.withOpacity(0.5) : Colors.grey.shade300,
            width: active ? 1.4 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: active ? _primary : _textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionWithBadge({
    required IconData icon,
    required String label,
    required Color iconColor,
    required bool active,
    required VoidCallback onTap,
    required int badgeCount,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        decoration: BoxDecoration(
          color: active ? _primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? _primary.withOpacity(0.5) : Colors.grey.shade300,
            width: active ? 1.4 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 20, color: iconColor),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : badgeCount.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: active ? _primary : _textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionGroupsBody() {
    if (_isLoadingOptions) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    if (_optionGroups.isEmpty) {
      return const Center(
        child: Text(
          "ยังไม่มีตัวเลือก",
          style: TextStyle(fontSize: 15, color: _textMuted),
        ),
      );
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: () {
        _optionsLoaded = false;
        return _loadOptionGroups();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              _optionGroups.length.toString() + " กลุ่ม",
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _textMuted,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _optionGroups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildOptionGroupCard(_optionGroups[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesDashboardBody() {
    bool isGroupByMonth = false;
    if (_selectedFilter == '3months' || _selectedFilter == '6months') {
      isGroupByMonth = true;
    } else if (_selectedFilter == 'custom' && _selectedDateRange != null) {
      if (_selectedDateRange!.end.difference(_selectedDateRange!.start).inDays >
          31) {
        isGroupByMonth = true;
      }
    }

    List<Map<String, dynamic>> displayTableData = [];
    if (isGroupByMonth) {
      Map<String, Map<String, dynamic>> monthlyMap = {};
      for (var item in _incomeData) {
        try {
          List parts = item['date'].toString().split('/');
          if (parts.length == 3) {
            String monthName = _getMonthNameThai(parts[1]);
            int yearTH = int.parse(parts[2]);
            String monthYear = monthName + " " + yearTH.toString();

            if (!monthlyMap.containsKey(monthYear)) {
              monthlyMap[monthYear] = {
                "date": monthYear,
                "rounds": 0,
                "amount": 0.0,
              };
            }
            monthlyMap[monthYear]!["rounds"] += (item['rounds'] as num).toInt();
            monthlyMap[monthYear]!["amount"] += (item['amount'] as num)
                .toDouble();
          }
        } catch (_) {}
      }
      displayTableData = monthlyMap.values.toList();
    } else {
      displayTableData = List<Map<String, dynamic>>.from(_incomeData);
    }

    final double totalAmount = _incomeData.fold(
      0.0,
      (sum, item) => sum + (item['amount'] as num).toDouble(),
    );
    final int totalRounds = _incomeData.fold(
      0,
      (sum, item) => sum + (item['rounds'] as num).toInt(),
    );

    String dateRangeText = "";
    if (_selectedFilter == 'custom' && _selectedDateRange != null) {
      if (_selectedDateRange!.start.isAtSameMomentAs(_selectedDateRange!.end)) {
        dateRangeText = _formatDate(_selectedDateRange!.start);
      } else {
        dateRangeText =
            _formatDate(_selectedDateRange!.start) +
            " - " +
            _formatDate(_selectedDateRange!.end);
      }
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: _loadIncomeData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                spreadRadius: 2,
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "สรุปยอดขาย",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _textDark,
                            ),
                          ),
                          if (dateRangeText.isNotEmpty &&
                              _selectedFilter == 'custom')
                            Text(
                              dateRangeText,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton(
                          value: _selectedFilter,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: _primary,
                          ),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _primary,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'today',
                              child: Text('วันนี้'),
                            ),
                            DropdownMenuItem(
                              value: '3days',
                              child: Text('3 วันย้อนหลัง'),
                            ),
                            DropdownMenuItem(
                              value: '7days',
                              child: Text('7 วันย้อนหลัง'),
                            ),
                            DropdownMenuItem(
                              value: '1month',
                              child: Text('1 เดือนย้อนหลัง'),
                            ),
                            DropdownMenuItem(
                              value: '3months',
                              child: Text('3 เดือนย้อนหลัง'),
                            ),
                            DropdownMenuItem(
                              value: '6months',
                              child: Text('6 เดือนย้อนหลัง'),
                            ),
                            DropdownMenuItem(
                              value: 'custom',
                              child: Text('เลือกช่วงเวลาเอง...'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              if (val == 'custom') {
                                _previousFilter = _selectedFilter;
                                _pickDateRange();
                              } else {
                                setState(() {
                                  _selectedFilter = val;
                                });
                                _loadIncomeData();
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 16,
                                color: _primary,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                "ยอดขายทั้งหมด",
                                style: TextStyle(
                                  color: _textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "฿ " + totalAmount.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: _textDark,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 50,
                      width: 1.5,
                      color: Colors.grey.shade200,
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.receipt_long_rounded,
                                size: 16,
                                color: _accent,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                "ออเดอร์สำเร็จ",
                                style: TextStyle(
                                  color: _textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                totalRounds.toString(),
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: _textDark,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                "ออเดอร์",
                                style: TextStyle(
                                  color: _textMuted,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade100)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  child: _isLoadingIncome
                      ? const Padding(
                          padding: EdgeInsets.all(30.0),
                          child: Center(
                            child: CircularProgressIndicator(color: _primary),
                          ),
                        )
                      : displayTableData.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: Center(
                            child: Text(
                              "ไม่มีประวัติยอดขายสำเร็จในช่วงเวลานี้",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            Container(
                              color: Colors.grey.shade50,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      isGroupByMonth ? 'เดือน' : 'วันที่',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    flex: 2,
                                    child: Text(
                                      'จำนวนออเดอร์',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    flex: 2,
                                    child: Text(
                                      'ยอดขาย (฿)',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...displayTableData.map((data) {
                              final double amount = (data['amount'] as num)
                                  .toDouble();
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.grey.shade100,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        data['date'].toString(),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        data['rounds'].toString(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        amount.toStringAsFixed(0),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: _primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionMetaBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleExpandButton({
    required bool expanded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: _primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: AnimatedRotation(
          turns: expanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _primary,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildOptionGroupCard(_OptionGroupAggregate agg) {
    final int groupId = agg.group.optionGroupId ?? -1;
    final bool enabled = _groupEnabled[groupId] ?? true;
    final bool expanded = _groupExpanded[groupId] ?? false;
    final bool isMultipleChoice = agg.group.isMultipleChoice;
    final List<OptionModel> items = agg.items.values.toList();

    return GestureDetector(
      onTap: () {
        setState(() {
          bool wasExpanded = expanded;
          _groupExpanded.updateAll((key, value) => false);
          _groupExpanded[groupId] = !wasExpanded;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: enabled ? Colors.white : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 0.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              agg.group.optionGroupName ?? "ไม่มีชื่อกลุ่ม",
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: enabled ? _textDark : Colors.black38,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              items.length.toString() + " ตัวเลือกย่อย",
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 🎯 แทรกปุ่มเปิด-ปิดตรงนี้ครับ!
                      _buildInlineStatusButton(
                        isAvailable: enabled,
                        onTap: () =>
                            _toggleOptionGroupStatusUI(groupId, enabled),
                      ),
                      const SizedBox(width: 12),

                      _buildCircleExpandButton(
                        expanded: expanded,
                        onTap: () {
                          setState(() {
                            bool wasExpanded = expanded;
                            _groupExpanded.updateAll((key, value) => false);
                            _groupExpanded[groupId] = !wasExpanded;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildOptionMetaBadge(
                        icon: isMultipleChoice
                            ? Icons.check_box_outlined
                            : Icons.radio_button_checked_rounded,
                        label: isMultipleChoice
                            ? "เลือกได้หลายอย่าง"
                            : "เลือกได้ 1 อย่าง",
                        color: _accent,
                      ),
                      const Spacer(),
                      _buildIconAction(
                        icon: Icons.edit_rounded,
                        color: _accent,
                        onTap: () => _goToEditOptionGroup(agg),
                      ),
                      const SizedBox(width: 16),
                      _buildIconAction(
                        icon: Icons.delete_outline_rounded,
                        color: _danger,
                        onTap: () => confirmDeleteOptionGroup(agg),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (expanded && items.isNotEmpty) ...[
              Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 14, 12),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: _primary.withOpacity(0.7),
                        width: 3,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 10),
                  child: Column(
                    children: [
                      for (int i = 0; i < items.length; i++) ...[
                        _buildOptionItemRow(items[i]),
                        if (i < items.length - 1) const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItemRow(OptionModel option) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              option.optionName ?? "ไม่มีชื่อ",
              style: const TextStyle(
                fontSize: 14,
                color: _textDark,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            "ราคา " + (option.optionPrice?.toInt() ?? 0).toString() + " บาท",
            style: const TextStyle(fontSize: 13, color: _textMuted),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 32),
    );
  }

  Widget _buildPlaceholderBackground() {
    return Container(
      color: _primary.withOpacity(0.85),
      child: const Icon(
        Icons.storefront_rounded,
        size: 72,
        color: Colors.white,
      ),
    );
  }

  Widget _buildInlineStatusButton({
    required bool isAvailable,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 58,
      height: 26,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isAvailable ? _primary : _danger,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isAvailable ? _primary : _danger).withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: isAvailable ? Alignment.centerRight : Alignment.centerLeft,
        children: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(
                left: isAvailable ? 0 : 13,
                right: isAvailable ? 13 : 0,
              ),
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    ),
  );
}

class _OptionGroupAggregate {
  final OptionGroupModel group;
  final Map<int, OptionModel> items = {};

  _OptionGroupAggregate(this.group);
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
