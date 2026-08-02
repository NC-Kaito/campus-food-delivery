// features/member/add_order_member.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/menu_addon_detail_model.dart';
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/data/services/menu/menu_addon_service.dart';
import 'package:flutter_app/features/member/cart_manager_member.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/features/member/view_order_member.dart';

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

  // 🎯 เก็บจำนวนที่เลือกของแต่ละ Add-on (Key: addonDetailId, Value: จำนวนชิ้น)
  final Map<int, int> _addonQuantities = {};
  // 🎯 เก็บวัตถุข้อมูล Add-on ตัวจริงไว้ใช้อ้างอิงราคาและชื่อ
  final Map<int, MenuAddonDetailModel> _addonModelsIndex = {};

  bool _useExtraPrice = false;

  @override
  void initState() {
    super.initState();
    _loadMenuAddons();
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;

    final String baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/') ? "$baseUrl$rawPath" : "$baseUrl/$rawPath";
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
      for (var addon in addons) {
        if (addon.addonDetailId != null) {
          _addonModelsIndex[addon.addonDetailId!] = addon;
        }
      }
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

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
    final bool hasExtraPriceOption = extraPriceValue > 0;

    int basePrice = (hasExtraPriceOption && _useExtraPrice)
        ? extraPriceValue
        : normalPrice;

    double addonTotalPrice = 0;
    _addonQuantities.forEach((id, qty) {
      final model = _addonModelsIndex[id];
      if (model != null) {
        addonTotalPrice += (model.addonPrice ?? 0) * qty;
      }
    });

    int totalPrice = (basePrice + addonTotalPrice.toInt()) * _quantity;
    String finalMenuUrl = _getFinalImageUrl(widget.menuModel.menuImage);
    final groupedAddons = _groupAddons();
    final String? description =
        (widget.menuModel.description?.trim().isNotEmpty == true)
        ? widget.menuModel.description
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
                SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 350),
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
                            const SizedBox(height: 40),
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
                            _addonQuantities.containsKey(item.addonDetailId) &&
                            _addonQuantities[item.addonDetailId]! > 0,
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

                  final List<MenuAddonDetailModel> finalSelectedAddonsList = [];
                  _addonQuantities.forEach((id, qty) {
                    final model = _addonModelsIndex[id];
                    if (model != null && qty > 0) {
                      for (int i = 0; i < qty; i++) {
                        finalSelectedAddonsList.add(model);
                      }
                    }
                  });

                  final cartItem = CartItem(
                    menu: widget.menuModel,
                    selectedAddons: finalSelectedAddonsList,
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
                        storeUsername:
                            widget.menuModel.restaurant?.username ?? '',
                        storeName:
                            widget.menuModel.restaurant?.restaurantName ??
                            'ออเดอร์ของคุณ',
                        storeItems: CartManager().items,
                        isFromAddOrder: true,
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
    int currentQty = _addonQuantities[id] ?? 0;
    bool isSelected = currentQty > 0;

    String title = detail.addonMenu?.addonName ?? "ไม่มีชื่อ";
    int price = detail.addonPrice?.toInt() ?? 0;
    int currentGroupId = detail.menuAddonGroup?.addonGroupId ?? 0;

    // คำนวณจำนวนรวมทั้งหมดที่ถูกเลือกไปแล้วในกลุ่มแอดออนนี้
    // (รวมทั้งจากการติ๊กตัวหน้าและจากสเต็ปเปอร์ + / - ของทุกตัวในกลุ่มเดียวกัน)
    int currentSelectedInGroupCount = 0;
    _addonQuantities.forEach((key, qty) {
      final model = _addonModelsIndex[key];
      if (model != null &&
          model.menuAddonGroup?.addonGroupId == currentGroupId) {
        currentSelectedInGroupCount += qty;
      }
    });

    // 🎯 โควตาของกลุ่มนี้เต็มแล้วหรือยัง (ไม่ว่าจะมาจากตัวเดียวที่เพิ่มจำนวน
    // จนครบ หรือติ๊กหลายตัวรวมกันจนครบก็ตาม)
    bool isGroupQuotaFull = currentSelectedInGroupCount >= maxSelect;
    // 🎯 ตัวที่ "ยังไม่ถูกเลือก" จะถูกล็อกทันทีเมื่อโควตาของกลุ่มเต็มแล้ว
    bool isAlternativeItemDisabled = isGroupQuotaFull && !isSelected;

    // ── ติ๊ก/ยกเลิกติ๊กตัวหน้า ──────────────────────────────────────
    // ถ้าโดนล็อกอยู่ (โควตาเต็มและยังไม่ได้เลือกตัวนี้) ให้เด้งแจ้งเตือน
    // แทนที่จะปล่อยให้กดแล้วไม่มีอะไรเกิดขึ้นเฉยๆ
    void handleFrontTap() {
      if (isAlternativeItemDisabled) {
        _showMaxSelectWarning(maxSelect);
        return;
      }
      setState(() {
        if (isSelected) {
          _addonQuantities.remove(id);
        } else {
          if (maxSelect == 1) {
            _addonQuantities.removeWhere((key, value) {
              final model = _addonModelsIndex[key];
              return model?.menuAddonGroup?.addonGroupId == currentGroupId;
            });
            _addonQuantities[id] = 1;
          } else {
            _addonQuantities[id] = 1;
          }
        }
      });
    }

    // ── กดปุ่ม "+" เพิ่มจำนวนของตัวเลือกนี้ ────────────────────────
    // ต้องติ๊กตัวหน้าก่อนเสมอ (ไม่ติ๊ก = ปุ่มนี้กดไม่ได้เลยจริงๆ) และถ้า
    // โควตาของกลุ่มเต็มแล้ว (ไม่ว่าจะเต็มเพราะตัวอื่นหรือตัวเอง) ให้เตือน
    void handlePlusTap() {
      if (isGroupQuotaFull) {
        _showMaxSelectWarning(maxSelect);
        return;
      }
      setState(() {
        _addonQuantities[id] = currentQty + 1;
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── ฝั่งซ้าย: ปุ่มติ๊กหน้าสุด + ข้อความ + ราคา ──
          Row(
            children: [
              InkWell(
                // 🎯 กดได้เสมอ แต่ข้างในจะดักเช็คเองว่าล็อกอยู่หรือเปล่า
                // เพื่อให้แจ้งเตือนได้แทนที่จะเงียบไปเฉยๆ ตอนโดนล็อก
                onTap: handleFrontTap,
                child: Row(
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
                        border: Border.all(
                          color: isAlternativeItemDisabled
                              ? Colors.grey.shade300
                              : Colors.black,
                          width: 1.5,
                        ),
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
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        color: isAlternativeItemDisabled
                            ? Colors.grey.shade400
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // 🎯 [SWAPPED] ย้ายราคาบวกเพิ่มมาอยู่ฝั่งซ้ายต่อท้ายชื่ออาหารทันทีตามสั่ง
              Text(
                "(+$price)",
                style: TextStyle(
                  fontSize: 14,
                  color: isAlternativeItemDisabled
                      ? Colors.grey.shade300
                      : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // ── ฝั่งขวา: แผงปุ่มสเต็ปเปอร์เพิ่ม/ลดจำนวน (แสดงเฉพาะกลุ่มที่มี maxSelect > 1) ──
          if (maxSelect > 1)
            Container(
              height: 32,
              decoration: BoxDecoration(
                color: isAlternativeItemDisabled
                    ? Colors.grey.shade100
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isAlternativeItemDisabled
                      ? Colors.grey.shade200
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  // ปุ่มลบชิ้นย่อย (กดลดจำนวนลง)
                  // 🎯 ถ้ายังไม่ติ๊กตัวหน้า (ไม่ได้เลือก) ปุ่มนี้กดไม่ได้จริงๆ
                  // (ไม่ต้องแจ้งเตือน เพราะไม่มีอะไรให้ลดอยู่แล้ว)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: Icon(
                      Icons.remove,
                      size: 16,
                      color: isSelected ? Colors.black87 : Colors.grey.shade300,
                    ),
                    onPressed: isSelected
                        ? () {
                            setState(() {
                              if (_addonQuantities[id]! <= 1) {
                                _addonQuantities.remove(id);
                              } else {
                                _addonQuantities[id] =
                                    _addonQuantities[id]! - 1;
                              }
                            });
                          }
                        : null,
                  ),

                  // ตัวเลขแสดงจำนวนปัจจุบัน
                  Container(
                    alignment: Alignment.center,
                    width: 20,
                    child: Text(
                      "$currentQty",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.black87
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),

                  // ปุ่มบวกชิ้นย่อย
                  // 🎯 ยังไม่ติ๊กตัวหน้า = กดไม่ได้เลยจริงๆ (onPressed: null)
                  // ติ๊กแล้วแต่โควตากลุ่มเต็ม = กดได้แต่จะเด้งแจ้งเตือนแทน
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: Icon(
                      Icons.add,
                      size: 16,
                      color: (isSelected && !isGroupQuotaFull)
                          ? Colors.black87
                          : Colors.grey.shade300,
                    ),
                    onPressed: isSelected ? handlePlusTap : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showMaxSelectWarning(int maxSelect) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("⛔ เลือกได้สูงสุด $maxSelect รายการเท่านั้นครับ"),
        backgroundColor: Colors.amber[800],
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
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

  Widget _buildPlaceholderBanner() {
    return Container(
      width: double.infinity,
      height: 400,
      color: Colors.orange.shade50,
      child: const Icon(Icons.fastfood, size: 80, color: Colors.orange),
    );
  }
}
