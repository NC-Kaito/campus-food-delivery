// features/member/list_menu_member.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/data/models/type_menu_model.dart';
import 'package:flutter_app/data/services/menu/menu_service.dart';
import 'package:flutter_app/features/member/add_order_member.dart';
import 'package:flutter_app/features/member/cart_manager_member.dart';
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

  final int _maxCurrySelect = 3;
  final List<MenuModel> _selectedCurries = [];
  bool _isExtraRice = false;
  int _curryQty = 1;

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

  void _addMenuCurryToCart(double total, String note) {
    // 1. ดึงกับข้าวตัวแรกที่เลือกมาเป็นตัวแทนเมนูหลัก เพื่อให้โครงสร้าง CartItem ทำงานได้ปกติ
    final MenuModel mainCurryMenu = _selectedCurries.first;

    // 2. คำนวณราคาต่อจาน (ราคาต่อหน่วย) แปลงเป็น int ให้ตรงกับโมเดล CartItem
    final int pricePerUnit = (total / _curryQty).toInt();

    // 3. 🌟 เรียกใช้ CartManager เพื่อบันทึกข้อมูลลงตะกร้าส่วนกลางทันที
    CartManager().addToCart(
      CartItem(
        menu: mainCurryMenu,
        selectedAddons: const [], // ข้าวราดแกงจานนี้ไม่มี Addon ปกติ
        selectedCurries: List.from(
          _selectedCurries,
        ), // 🎯 ส่งลิสต์กับข้าวทั้งหมด [แกง1, แกง2, แกง4] เข้าเลนนี้
        quantity: _curryQty,
        note: note, // เก็บรายละเอียดเมนูราดแกงและตัวเลือกเสริมข้าวไว้ในช่องโน้ต
        addonPrice: 0,
        totalPrice:
            pricePerUnit, // ราคาต่อจานที่รวมยอดคำนวณส่วนต่างแล้ว (เช่น 30 หรือ 35 บาท)

        unitPrice:
            pricePerUnit, // สำหรับข้าวราดแกง ราคาเริ่มต้นต่อหน่วยก็น่าจะเป็น pricePerUnit ที่คำนวณมาแล้ว
        isExtraPrice: false,
      ),
    );

    // 4. แสดง Dialog แจ้งเตือนผู้ใช้ว่าเพิ่มลงตะกร้าสำเร็จแล้วเหมือนเดิม
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
              Navigator.pop(ctx); // ปิด Dialog

              // 🎯 ล้างค่าหน้าจอ (Reset State) กลับเป็นค่าเริ่มต้น เพื่อให้พร้อมกดสั่งจานใหม่ต่อ
              setState(() {
                _selectedCurries.clear();
                _isExtraRice = false;
                _curryQty = 1;
              });

              // 🚀 แถมให้: กดย้อนกลับไปหน้าก่อนหน้า (เช่น หน้ารวมเมนู) เพื่อให้ผู้ใช้เลือกสั่งอย่างอื่นต่อได้เลย
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
                                  isScrollable: shouldScroll,
                                  tabAlignment: shouldScroll
                                      ? TabAlignment.start
                                      : TabAlignment.fill,
                                  labelColor: Colors.black,
                                  unselectedLabelColor: Colors.black54,
                                  indicatorColor: Colors.black,
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
                          return _buildCurrySpecialLayout(currentMenus);
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

  Widget _buildCurrySpecialLayout(List<MenuModel> curryItems) {
    if (curryItems.isEmpty) {
      return const Center(
        child: Text(
          "ไม่มีเมนูกับข้าวพร้อมจำหน่ายในขณะนี้",
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      );
    }

    final int selectCount = _selectedCurries.length;

    double basePrice = 0;
    if (selectCount == 1) {
      basePrice = 20;
    } else if (selectCount == 2) {
      basePrice = 25;
    } else if (selectCount >= 3) {
      basePrice = 30;
    }

    final double extraCurryPrice = _selectedCurries.fold(
      0.0,
      (sum, curry) => sum + (curry.price ?? 0.0),
    );

    final double optionPrice = _isExtraRice ? 10.0 : 0.0;

    final double unitPrice = basePrice + extraCurryPrice + optionPrice;
    final double totalPrice = unitPrice * _curryQty;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start),
                ),

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
                                IgnorePointer(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.black.withOpacity(0.06),
                                        width: 1,
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
                            (curry.price != null && curry.price! > 0)
                                ? "เมนูพิเศษ +${curry.price!.toStringAsFixed(0)} บาท"
                                : "รวมในราคาฐานแล้ว",
                            style: TextStyle(
                              color: (curry.price != null && curry.price! > 0)
                                  ? Colors.orange.shade800
                                  : Colors.grey.shade500,
                              fontSize: 12,
                              fontWeight:
                                  (curry.price != null && curry.price! > 0)
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        value: isSelected,
                        onChanged:
                            (!isAvailable ||
                                (!isSelected &&
                                    _selectedCurries.length >= _maxCurrySelect))
                            ? null
                            : (bool? value) {
                                setState(() {
                                  if (isSelected) {
                                    _selectedCurries.removeWhere(
                                      (element) =>
                                          element.menuId == curry.menuId,
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
              ],
            ),
          ),
        ),

        // ═══════════════════════════════════════════════
        // 🎯 Bottom bar — ปรับให้แสดง "จำนวน" + "ราคารวม" คู่กัน
        //    ในสไตล์เดียวกับหน้า AddOrderMember
        // ═══════════════════════════════════════════════
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
              // ── ตัวเลือก "เพิ่มปริมาณข้าวสวย" ──────────────────
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
                    "+10 บาท",
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _isExtraRice,
                  onChanged: (val) =>
                      setState(() => _isExtraRice = val ?? false),
                ),
              ),
              const SizedBox(height: 16),

              // ── แถวจำนวน (ซ้าย) + ราคารวม (ขวา) — สไตล์เดียวกับ AddOrderMember ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ─── ฝั่งซ้าย: จำนวนที่สั่ง ───────────────
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
                                color: _curryQty > 1
                                    ? Colors.black87
                                    : Colors.grey.shade400,
                              ),
                              onPressed: _curryQty > 1
                                  ? () => setState(() => _curryQty--)
                                  : null,
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
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 24,
                                color: Colors.black87,
                              ),
                              onPressed: () => setState(() => _curryQty++),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // ─── ฝั่งขวา: ราคารวม ──────────────────────
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

              // ── ปุ่มเพิ่มลงตะกร้า เต็มความกว้าง ──────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: _selectedCurries.isEmpty
                      ? null
                      : () {
                          final curriesNames = _selectedCurries
                              .map((c) => c.menuName ?? "-")
                              .join(', ');

                          final additions = _isExtraRice ? 'เพิ่มข้าว' : '';

                          final finalNote =
                              "ราดแกง: [$curriesNames] "
                              "${additions.isNotEmpty ? '($additions)' : ''}";

                          _addMenuCurryToCart(totalPrice, finalNote);
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
