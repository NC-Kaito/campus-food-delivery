// features/member/add_order_member.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/menu_addon_detail_model.dart';
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/data/services/menu/menu_addon_service.dart';
import 'package:flutter_app/features/member/cart_manager_member.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/features/member/view_order_member.dart'; // 🎯 ดึงตัวแปรไอพีกลางสากลเข้ามาจัดการความชัวร์ของรูปภาพ

class AddOrderMember extends StatefulWidget {
  final MenuModel menuModel;

  const AddOrderMember({super.key, required this.menuModel});

  @override
  State<AddOrderMember> createState() => _AddOrderMemberState();
}

class _AddOrderMemberState extends State<AddOrderMember> {
  int _quantity = 1;
  final TextEditingController _noteController = TextEditingController();

  final MenuAddonService _addonService = MenuAddonService();
  List<MenuAddonDetailModel> _allAddons = [];
  bool _isLoading = true;

  // สำหรับเก็บรายการ Add-on ที่ผู้ใช้เลือกจิ้ม (Key: ID ของตัวเลือกย่อย, Value: วัตถุข้อมูล)
  final Map<int, MenuAddonDetailModel> _selectedAddons = {};

  // ── สถานะเลือกราคาปกติ/พิเศษ ──
  bool _useExtraPrice = false;

  @override
  void initState() {
    super.initState();
    _loadMenuAddons();
  }

  // 🎯 ฟังก์ชันสากลช่วยกะเทาะและเชื่อมพาร์ทรูปสั้นเข้ากับ URL ไอพีกลางให้ถูกต้องสมบูรณ์
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

  Future<void> _loadMenuAddons() async {
    if (widget.menuModel.menuId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    final addons = await _addonService.getAddonsByMenuId(
      widget.menuModel.menuId!,
    );

    if (!mounted) return;

    setState(() {
      _allAddons = addons;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // ฟังก์ชันช่วยจัดหมวดหมู่ข้อมูลกลุ่ม Addon เพื่อเตรียมวาด UI
  Map<String, List<MenuAddonDetailModel>> _groupAddons() {
    Map<String, List<MenuAddonDetailModel>> grouped = {};
    for (var addon in _allAddons) {
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
    final int normalPrice = widget.menuModel.price?.toInt() ?? 0;
    final int extraPriceValue = widget.menuModel.extraprice?.toInt() ?? 0;
    // มีราคาพิเศษให้เลือกก็ต่อเมื่อ extraprice ถูกตั้งไว้และมากกว่า 0
    final bool hasExtraPriceOption = extraPriceValue > 0;

    int basePrice = (hasExtraPriceOption && _useExtraPrice)
        ? extraPriceValue
        : normalPrice;

    // เปลี่ยนมาใช้ฟิลด์ .addonprice (ตัว p เล็ก) ในการคำนวณราคารวมทั้งหมด
    double addonTotalPrice = 0;
    _selectedAddons.forEach((id, detail) {
      addonTotalPrice += detail.addonPrice ?? 0;
    });

    int totalPrice = (basePrice + addonTotalPrice.toInt()) * _quantity;

    String? rawMenuImage = widget.menuModel.menuImage;

    // 🌟 ดึงผ่านฟังก์ชันต่อพาร์ทไอพีกลางสากล ปรับภาพอาหารจานเดี่ยวให้ขึ้นจอคมชัด
    String finalMenuUrl = _getFinalImageUrl(rawMenuImage);

    final groupedAddons = _groupAddons();

    final String? description =
        (widget.menuModel.description?.trim().isNotEmpty == true)
        ? widget.menuModel.description
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true, // 🎯 ให้ Body ทะลุขึ้นไปหลัง AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // 🎯 ปรับให้โปร่งใสเพื่อโชว์ภาพ
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black38,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.orange,
                  size: 22,
                ),
                onPressed: () {},
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(
                  Icons.account_circle_outlined,
                  color: Colors.orange,
                  size: 22,
                ),
                onPressed: () {},
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Stack(
              children: [
                // 🎯 1. ภาพพื้นหลังเต็มความกว้าง (ถอดแบบ ViewMenu)
                SizedBox(
                  width: double.infinity,
                  height: 400,
                  child: finalMenuUrl.isNotEmpty
                      ? Image.network(
                          Uri.encodeFull(finalMenuUrl),
                          width: double.infinity,
                          height: 400,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderBanner(),
                        )
                      : _buildPlaceholderBanner(),
                ),

                // 🎯 2. ส่วนเนื้อหาเลื่อนได้ (ถอดแบบ ViewMenu)
                SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 350), // ดันให้เห็นรูปภาพด้านบน
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(28),
                            topRight: Radius.circular(28),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.menuModel.menuName ??
                                        "ไม่มีชื่อเมนู",
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  "฿$basePrice",
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),

                            // ═══════════════════════════════════════════════
                            // 🎯 ตัวเลือกราคา: ปกติ / พิเศษ (โชว์เฉพาะเมนูที่มี extraprice)
                            // ═══════════════════════════════════════════════
                            if (hasExtraPriceOption) ...[
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildPriceOptionCard(
                                      label: "ราคาปกติ",
                                      price: normalPrice,
                                      isSelected: !_useExtraPrice,
                                      onTap: () => setState(
                                        () => _useExtraPrice = false,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildPriceOptionCard(
                                      label: "ราคาพิเศษ",
                                      price: extraPriceValue,
                                      isSelected: _useExtraPrice,
                                      onTap: () =>
                                          setState(() => _useExtraPrice = true),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            if (description != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  height: 1.5,
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // =========================================================
                            // ส่วนยิงวาดกลุ่มข้อมูล Add-on แบบ Dynamic
                            // 🎯 ปรับแต่งเส้นสีเขียวด้านข้างให้เหมือน ViewMenu
                            // =========================================================
                            if (groupedAddons.isNotEmpty) ...[
                              ...groupedAddons.entries.toList().asMap().entries.map((
                                mapEntry,
                              ) {
                                final isFirstGroup = mapEntry.key == 0;
                                final entry = mapEntry.value;

                                String groupName = entry.key;
                                List<MenuAddonDetailModel> items = entry.value;

                                bool isRequired =
                                    items.first.menuAddonGroup?.isRequired ??
                                    false;
                                int maxSelect =
                                    items.first.menuAddonGroup?.maxSelect ?? 1;

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

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          groupName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          isRequired
                                              ? "จำเป็น (สูงสุด $maxSelect)"
                                              : "ไม่จำเป็น (สูงสุด $maxSelect)",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isRequired
                                                ? Colors.orange[400]
                                                : Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // 🎯 IntrinsicHeight + Row ให้เส้นเขียวยาวคลุมทุก item ในกลุ่ม
                                    IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
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
                                                        _buildAddonItemOption(
                                                          addonDetail,
                                                          maxSelect,
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

                            const SizedBox(height: 10),
                            const Text(
                              "ระบุเพิ่มเติม",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _noteController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText:
                                    "ตัวอย่างเช่น ไม่เอาผัก, เผ็ดน้อย อื่นๆ",
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                                contentPadding: const EdgeInsets.all(16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 40,
                            ), // พื้นที่เผื่อแผงล่างสุด
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: 30,
          top: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                              color: _quantity > 1
                                  ? Colors.black87
                                  : Colors.grey.shade400,
                            ),
                            onPressed: () {
                              if (_quantity > 1) setState(() => _quantity--);
                            },
                          ),
                          SizedBox(
                            width: 28,
                            child: Text(
                              "$_quantity",
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
                            onPressed: () => setState(() => _quantity++),
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
                      "จำนวน $_quantity รายการ",
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
                            text: "฿$totalPrice",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
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
                onPressed: () {
                  for (var entry in groupedAddons.entries) {
                    String groupName = entry.key;
                    List<MenuAddonDetailModel> items = entry.value;
                    bool isRequired =
                        items.first.menuAddonGroup?.isRequired ?? false;

                    if (isRequired) {
                      bool hasSelection = items.any(
                        (item) =>
                            _selectedAddons.containsKey(item.addonDetailId),
                      );
                      if (!hasSelection) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "⚠️ กรุณาเลือกรายการเสริมในหัวข้อ '$groupName'",
                            ),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                    }
                  }

                  final cartItem = CartItem(
                    menu: widget.menuModel,
                    selectedAddons: _selectedAddons.values.toList(),
                    quantity: _quantity,
                    note: _noteController.text,
                    addonPrice: addonTotalPrice.toInt(),
                    totalPrice: totalPrice,
                    unitPrice: basePrice,
                    isExtraPrice: hasExtraPriceOption && _useExtraPrice,
                  );

                  CartManager().addToCart(cartItem);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("เพิ่มลงในตะกร้าเรียบร้อยแล้ว"),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewOrderMember(
                        // 🎯 ใส่ข้อมูลร้านค้า (คุณอาจจะต้องดึงจาก widget.menuModel หรือตัวแปรที่เก็บไว้)
                        storeUsername:
                            widget.menuModel.restaurant?.username ?? '',
                        storeName:
                            widget.menuModel.restaurant?.restaurantName ??
                            'ออเดอร์ของคุณ',
                        storeItems: CartManager().items,
                        isFromAddOrder:
                            true, // 🌟 ส่งค่า true ไปเพื่อปลดล็อกปุ่ม "สั่งอาหารต่อ"[cite: 4]
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF76FF03),
                  foregroundColor: Colors.black,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  "ใส่ตะกร้า",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddonItemOption(MenuAddonDetailModel detail, int maxSelect) {
    int id = detail.addonDetailId ?? 0;
    bool isSelected = _selectedAddons.containsKey(id);

    String title = detail.addonMenu?.addonName ?? "ไม่มีชื่อ";
    int price = detail.addonPrice?.toInt() ?? 0;
    int currentGroupId = detail.menuAddonGroup?.addonGroupId ?? 0;

    int currentSelectedInGroupCount = _selectedAddons.values
        .where(
          (element) => element.menuAddonGroup?.addonGroupId == currentGroupId,
        )
        .length;

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedAddons.remove(id);
          } else {
            if (maxSelect == 1) {
              _selectedAddons.removeWhere(
                (key, value) =>
                    value.menuAddonGroup?.addonGroupId == currentGroupId,
              );
              _selectedAddons[id] = detail;
            } else {
              if (currentSelectedInGroupCount >= maxSelect) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "⛔ เลือกได้สูงสุด $maxSelect รายการเท่านั้นครับ",
                    ),
                    backgroundColor: Colors.amber[800],
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                _selectedAddons[id] = detail;
              }
            }
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: maxSelect == 1
                        ? BoxShape.circle
                        : BoxShape.rectangle,
                    borderRadius: maxSelect == 1
                        ? null
                        : BorderRadius.circular(4),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: maxSelect == 1
                                  ? BoxShape.circle
                                  : BoxShape.rectangle,
                              borderRadius: maxSelect == 1
                                  ? null
                                  : BorderRadius.circular(2),
                              color: Colors.orange,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 15)),
              ],
            ),
            Text(
              "+$price",
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceOptionCard({
    required String label,
    required int price,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey.shade300,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 18,
              color: isSelected ? Colors.orange : Colors.grey[400],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.orange[800] : Colors.black87,
                    ),
                  ),
                  Text(
                    "฿$price",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.orange : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎯 ใช้ Banner กว้างเต็มจอสำหรับตอนไม่มีรูป
  Widget _buildPlaceholderBanner() {
    return Container(
      width: double.infinity,
      height: 400,
      color: Colors.orange.shade50,
      child: const Icon(Icons.fastfood, size: 80, color: Colors.orange),
    );
  }
}
