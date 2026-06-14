// features/member/edit_order_member.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/menu_addon_detail_model.dart';
import 'package:flutter_app/data/services/menu/menu_addon_service.dart';
import 'package:flutter_app/features/member/cart_manager_member.dart';
import 'package:flutter_app/core/network/dio_client.dart'; // 🎯 ดึงตัวแปรไอพีกลางสากลเข้ามาจัดการความชัวร์ของรูปภาพ

class EditOrderMember extends StatefulWidget {
  final CartItem cartItem;

  const EditOrderMember({super.key, required this.cartItem});

  @override
  State<EditOrderMember> createState() => _EditOrderMemberState();
}

class _EditOrderMemberState extends State<EditOrderMember> {
  int _quantity = 1;
  final TextEditingController _noteController = TextEditingController();

  final MenuAddonService _addonService = MenuAddonService();
  List<MenuAddonDetailModel> _allAddons = [];
  bool _isLoading = true;

  // สำหรับเก็บรายการ Add-on ที่ผู้ใช้เลือกจิ้ม (Key: ID ของตัวเลือกย่อย, Value: วัตถุข้อมูล)
  final Map<int, MenuAddonDetailModel> _selectedAddons = {};

  @override
  void initState() {
    super.initState();
    // 🎯 ดึงข้อมูลเก่าจากตะกร้าเดิมมาตั้งต้นกางบนหน้าจออีดิต
    _quantity = widget.cartItem.quantity;
    _noteController.text = widget.cartItem.note;

    for (var addon in widget.cartItem.selectedAddons) {
      if (addon.addonDetailId != null) {
        _selectedAddons[addon.addonDetailId!] = addon;
      }
    }
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
    if (widget.cartItem.menu.menuId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    final addons = await _addonService.getAddonsByMenuId(
      widget.cartItem.menu.menuId!,
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
    int basePrice = widget.cartItem.menu.price?.toInt() ?? 0;

    // คำนวณราคา Add-on ทั้งหมดตามโครงสร้างพิมพ์เขียวที่คุณ Kaito ตั้งไว้
    double addonTotalPrice = 0;
    _selectedAddons.forEach((id, detail) {
      addonTotalPrice += detail.addonPrice ?? 0;
    });

    int totalPrice = (basePrice + addonTotalPrice.toInt()) * _quantity;

    String? rawMenuImage = widget.cartItem.menu.menuImage;

    // 🌟 ดึงผ่านฟังก์ชันต่อพาร์ทไอพีกลางสากล ปรับภาพอาหารในหน้าแก้ไขให้ขึ้นจอได้ถูกต้อง
    String finalMenuUrl = _getFinalImageUrl(rawMenuImage);

    final groupedAddons = _groupAddons();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.orange),
        title: const Text(
          "แก้ไขรายการอาหาร",
          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // 🎯 ปุ่มลบเมนูออกจากตะกร้า (ไอคอนถังขยะสีแดงเด่นชัด เจน UX ที่เหมาะสมที่สุด)
          IconButton(
            icon: const Icon(
              Icons.delete_forever_outlined,
              color: Colors.redAccent,
              size: 28,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text("💥 ลบรายการอาหาร?"),
                    content: Text(
                      "คุณต้องการยกเลิกและลบเมนู '${widget.cartItem.menu.menuName}' นี้ออกจากตะกร้าใช่หรือไม่?",
                    ),
                    actions: [
                      TextButton(
                        child: const Text(
                          "ยกเลิก",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      TextButton(
                        child: const Text(
                          "ลบรายการ",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // ปิด Dialog เตือน
                          Navigator.pop(
                            context,
                            "REMOVE",
                          ); // ดีดขากลับส่งสัญญาณไฟแดง "REMOVE" ไปหาหน้าบิวย่อย
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // 🎯 ปรับดีไซน์จุดที่ 1: เพิ่มกล่องแสดงรูปภาพอาหารขนาดใหญ่พร้อมขอบมนแบบหน้า AddOrder
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: finalMenuUrl.isNotEmpty
                            ? Image.network(
                                Uri.encodeFull(finalMenuUrl),
                                width: 260,
                                height: 260,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholderIcon(),
                              )
                            : _buildPlaceholderIcon(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 🎯 ปรับดีไซน์จุดที่ 2: ปรับ Layout ชื่ออาหารและป้ายราคาหนาสีส้มสะดุดตา
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.cartItem.menu.menuName ?? "ไม่มีชื่อเมนู",
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          "฿$basePrice",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Text(
                      widget.cartItem.menu.description ??
                          "ไม่มีคำอธิบายสำหรับรายการเมนูนี้",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // =========================================================
                    // ส่วนยิงวาดกลุ่มข้อมูล Add-on แบบ Dynamic ตามแบบฉบับดีไซน์ AddOrder
                    // =========================================================
                    if (groupedAddons.isNotEmpty) ...[
                      ...groupedAddons.entries.map((entry) {
                        String groupName = entry.key;
                        List<MenuAddonDetailModel> items = entry.value;

                        bool isRequired =
                            items.first.menuAddonGroup?.isRequired ?? false;
                        int maxSelect =
                            items.first.menuAddonGroup?.maxSelect ?? 1;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            ...items.map(
                              (addonDetail) =>
                                  _buildAddonItemOption(addonDetail, maxSelect),
                            ),
                            const SizedBox(height: 20),
                          ],
                        );
                      }),
                    ],

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
                        hintText: "ตัวอย่างเช่น ไม่เอาผัก, เผ็ดน้อย อื่นๆ",
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
      // 🎯 ปรับดีไซน์จุดที่ 3: ยกเครื่อง Bottom Bar แผงลอยตัวเลขสรุปราคาและกลุ่มปุ่มบันทึกสีนีออนเขียวสากล
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
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      "รวมราคา  ",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "$totalPrice บาท",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 28),
                      onPressed: () {
                        if (_quantity > 1) setState(() => _quantity--);
                      },
                    ),
                    Text(
                      "$_quantity",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 28),
                      onPressed: () => setState(() => _quantity++),
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

                  // 🎯 จัดเตรียมประกอบโมเดลใหม่ส่งดีดกลับไปเขียนทับลิสต์สรุปบิล
                  final updatedItem = CartItem(
                    menu: widget.cartItem.menu,
                    selectedAddons: _selectedAddons.values.toList(),
                    quantity: _quantity,
                    note: _noteController.text,
                    addonPrice: addonTotalPrice.toInt(),
                    totalPrice: totalPrice,
                  );

                  Navigator.pop(context, updatedItem);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF76FF03,
                  ), // ✅ สีเขียวนีออนสว่างสากลเข้าธีมกริบ ๆ
                  foregroundColor: Colors.black,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  "บันทึกการแก้ไข",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันวาดตัวเลือกรายการ Addon พร้อมกรอบสี่เหลี่ยม/วงกลมตรวจจับเงื่อนไข maxSelect
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

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 260,
      height: 260,
      color: Colors.orange.shade50,
      child: const Icon(Icons.fastfood, size: 64, color: Colors.orange),
    );
  }
}
