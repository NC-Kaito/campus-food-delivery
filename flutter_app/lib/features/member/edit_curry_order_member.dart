// features/member/edit_curry_order_member.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/data/models/option_model.dart';
import 'package:flutter_app/data/models/menu_option_group_model.dart';
import 'package:flutter_app/data/services/menu/menu_option_service.dart';
import 'package:flutter_app/data/services/menu/menu_service.dart';
import 'package:flutter_app/features/member/cart_manager_member.dart';
import 'package:flutter_app/core/network/dio_client.dart';

class EditCurryOrderMember extends StatefulWidget {
  final CartItem cartItem;
  final String storeUsername;

  const EditCurryOrderMember({
    super.key,
    required this.cartItem,
    required this.storeUsername,
  });

  @override
  State<EditCurryOrderMember> createState() => _EditCurryOrderMemberState();
}

class _EditCurryOrderMemberState extends State<EditCurryOrderMember> {
  final MenuService _menuService = MenuService();
  final MenuOptionService _optionService = MenuOptionService();

  bool _isLoading = true;
  List<MenuModel> _allCurryItems = [];

  final int _maxCurrySelect = 3;
  double? _curryPrice1;
  double? _curryPrice2;
  double? _curryPrice3;

  List<MenuModel> _selectedCurries = [];
  bool _isExtraRice = false;
  int _curryQty = 1;

  List<OptionGroupModel> _optionGroups = [];
  List<OptionModel> _curryOptions = [];
  final Map<int, int> _curryOptionQuantities = {};
  final Map<String, OptionGroupModel> _groupModelsIndex = {};

  final Map<int, String> _optionGroupNameById = {};
  final Map<int, OptionModel> _curryOptionModelsIndex = {};

  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 🎯 ดึงข้อมูลเดิมจากตะกร้ามาตั้งค่าเริ่มต้น
    _curryQty = widget.cartItem.quantity;

    // เช็ค "เพิ่มข้าว" เฉพาะบรรทัดแรก (ส่วนที่ระบบ gen) กันไปชนกับข้อความที่ลูกค้าพิมพ์เอง
    final String firstLine = widget.cartItem.note.split('\n').first;
    _isExtraRice = firstLine.contains('เพิ่มข้าว');

    _selectedCurries = List<MenuModel>.from(widget.cartItem.selectedCurries);

    // แกะข้อความ note เดิมออกมา (ตัดส่วนที่ระบบ gen ให้ออก)
    if (widget.cartItem.note.contains("เพิ่มเติม: ")) {
      _noteController.text = widget.cartItem.note
          .split("เพิ่มเติม: ")
          .last
          .trim();
    }

    // ดึง Option เดิมที่เลือกไว้
    for (final option in widget.cartItem.selectedAddons) {
      final int? optionId = option.optionId;
      if (optionId != null) {
        _curryOptionQuantities[optionId] =
            (_curryOptionQuantities[optionId] ?? 0) + 1;
      }
    }

    _loadData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final categories = await _menuService.getTypeMenuByRestaurant(
        widget.storeUsername,
      );
      int? curryTypeId;

      for (final cat in categories) {
        if (cat.typemenuName != null &&
            cat.typemenuName!.contains("ข้าวราดแกง")) {
          curryTypeId = cat.typemenuId;
          break;
        }
      }

      if (curryTypeId != null) {
        _allCurryItems = await _menuService.getMenusByTypeMenu(
          widget.storeUsername,
          curryTypeId,
        );

        // 🎯 ดึงราคามาตรฐาน 1/2/3 อย่างของร้านนี้ (เหมือนในหน้า ListMenuMember)
        try {
          final prices = await _menuService.getCurryPrice(
            restaurantId: widget.storeUsername,
            typeMenuId: curryTypeId,
          );
          _curryPrice1 = (prices?['price'] as num?)?.toDouble();
          _curryPrice2 = (prices?['price2'] as num?)?.toDouble();
          _curryPrice3 = (prices?['price3'] as num?)?.toDouble();
        } catch (e) {
          debugPrint("ไม่สามารถโหลดราคามาตรฐานข้าวราดแกงได้: $e");
        }

        final optionGroups = await _optionService.getOptionGroupsByRestaurant(
          widget.storeUsername,
        );

        _optionGroups = optionGroups;
        _curryOptions = [];
        _curryOptionModelsIndex.clear();
        _groupModelsIndex.clear();
        _optionGroupNameById.clear();

        for (final group in optionGroups) {
          final String groupName = (group.optionGroupName ?? 'ตัวเลือกเสริม')
              .trim();
          _groupModelsIndex[groupName] = group;

          final options = group.options ?? [];
          for (final option in options) {
            if (option is OptionModel && option.optionId != null) {
              _curryOptions.add(option);
              _curryOptionModelsIndex[option.optionId!] = option;
              _optionGroupNameById[option.optionId!] = groupName;
            }
          }
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading curries: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;
    final String baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/') ? "$baseUrl$rawPath" : "$baseUrl/$rawPath";
  }

  Map<String, List<OptionModel>> _groupCurryOptions() {
    final Map<String, List<OptionModel>> grouped = {};

    for (final group in _optionGroups) {
      final String groupName = (group.optionGroupName ?? 'ตัวเลือกเสริม')
          .trim();
      final List<OptionModel> options = (group.options ?? [])
          .whereType<OptionModel>()
          .where((option) => option.optionId != null)
          .toList();

      if (options.isNotEmpty) {
        grouped[groupName] = options;
      }
    }

    return grouped;
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 36),
    );
  }

  Widget _buildCurryOptionItem(
    OptionModel option,
    bool isMultipleChoice,
    String groupName,
  ) {
    final int id = option.optionId ?? 0;
    final int currentQty = _curryOptionQuantities[id] ?? 0;
    final bool isSelected = currentQty > 0;

    final String title = option.optionName ?? 'ไม่มีชื่อ';
    final int price = (option.optionPrice ?? 0).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _curryOptionQuantities.remove(id);
                    } else {
                      if (!isMultipleChoice) {
                        _curryOptionQuantities.removeWhere((key, value) {
                          return _optionGroupNameById[key] == groupName;
                        });
                        _curryOptionQuantities[id] = 1;
                      } else {
                        _curryOptionQuantities[id] = 1;
                      }
                    }
                  });
                },
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
                        border: Border.all(color: Colors.black, width: 1.5),
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
                                  color: Colors.orange,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
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
                      color: isSelected ? Colors.black87 : Colors.grey.shade300,
                    ),
                    onPressed: isSelected
                        ? () {
                            setState(() {
                              if (_curryOptionQuantities[id]! <= 1) {
                                _curryOptionQuantities.remove(id);
                              } else {
                                _curryOptionQuantities[id] =
                                    _curryOptionQuantities[id]! - 1;
                              }
                            });
                          }
                        : null,
                  ),
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
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: Icon(
                      Icons.add,
                      size: 16,
                      color: isSelected ? Colors.black87 : Colors.grey.shade300,
                    ),
                    onPressed: isSelected
                        ? () => setState(
                            () => _curryOptionQuantities[id] = currentQty + 1,
                          )
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    final int selectCount = _selectedCurries.length;
    final groupedOptions = _groupCurryOptions();

    double basePrice = 0;
    if (selectCount == 1) {
      basePrice = _curryPrice1 ?? 0.0;
    } else if (selectCount == 2) {
      basePrice = _curryPrice2 ?? 0.0;
    } else if (selectCount >= 3) {
      basePrice = _curryPrice3 ?? 0.0;
    }

    // 🎯 ไม่นำ curry.price ของแต่ละเมนูมาบวกซ้ำ ใช้เฉพาะราคา 1/2/3 อย่างของร้าน
    final double optionPrice = (selectCount > 0 && _isExtraRice) ? 5.0 : 0.0;

    double addonTotalPrice = 0;
    _curryOptionQuantities.forEach((id, qty) {
      final model = _curryOptionModelsIndex[id];
      if (model != null) {
        addonTotalPrice += (model.optionPrice ?? 0).toDouble() * qty;
      }
    });

    final double unitPrice = basePrice + optionPrice + addonTotalPrice;
    final double totalPrice = unitPrice * _curryQty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "แก้ไขข้าวราดแกง",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_forever_outlined,
              color: Colors.redAccent,
              size: 24,
            ),
            onPressed: () {
              Navigator.pop(context, "REMOVE");
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
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
                    itemCount: _allCurryItems.length,
                    itemBuilder: (context, index) {
                      final curry = _allCurryItems[index];
                      final bool isAvailable = curry.status ?? true;
                      final bool isSelected = _selectedCurries.any(
                        (element) => element.menuId == curry.menuId,
                      );
                      final String imgUrl = _getFinalImageUrl(curry.menuImage);

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
                        ),
                        child: CheckboxListTile(
                          activeColor: const Color(0xFF4CAF50),
                          checkboxShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          secondary: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 85,
                              height: 85,
                              child: imgUrl.isNotEmpty
                                  ? Image.network(
                                      Uri.encodeFull(imgUrl),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _buildPlaceholderIcon(),
                                    )
                                  : _buildPlaceholderIcon(),
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
                              "รวมในราคาข้าวราดแกงแล้ว",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          value: isSelected,
                          onChanged:
                              (!isAvailable ||
                                  (!isSelected &&
                                      _selectedCurries.length >=
                                          _maxCurrySelect))
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

                  if (groupedOptions.isNotEmpty) ...[
                    const Divider(thickness: 1, height: 32),
                    ...groupedOptions.entries.toList().asMap().entries.map((
                      mapEntry,
                    ) {
                      final isFirstGroup = mapEntry.key == 0;
                      final entry = mapEntry.value;
                      final String groupName = entry.key;
                      final List<OptionModel> items = entry.value;
                      final bool isMultipleChoice =
                          _groupModelsIndex[groupName]?.isMultipleChoice ??
                          false;

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
                          Column(
                            children: items
                                .map(
                                  (option) => _buildCurryOptionItem(
                                    option,
                                    isMultipleChoice,
                                    groupName,
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                    }),
                  ],

                  const SizedBox(height: 16),
                  const Text(
                    "รายละเอียดเพิ่มเติม",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: "เช่น ไม่ใส่ผัก, เผ็ดน้อย",
                      fillColor: Colors.grey.shade100,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
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
                    title: const Text(
                      "เพิ่มปริมาณข้าวสวย",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: const Text(
                      "+5 บาท",
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _isExtraRice,
                    onChanged: (val) =>
                        setState(() => _isExtraRice = val ?? false),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "จำนวน",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "ราคารวม",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "฿${totalPrice.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
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
                      backgroundColor: const Color(0xFF4CAF50),
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: _selectedCurries.isEmpty
                        ? null
                        : () {
                            final List<OptionModel> finalSelectedOptionsList =
                                [];
                            _curryOptionQuantities.forEach((id, qty) {
                              final model = _curryOptionModelsIndex[id];
                              if (model != null && qty > 0) {
                                for (int i = 0; i < qty; i++) {
                                  finalSelectedOptionsList.add(model);
                                }
                              }
                            });

                            final String curriesNames = _selectedCurries
                                .map((c) => c.menuName ?? "-")
                                .join(', ');
                            final String additions = _isExtraRice
                                ? 'เพิ่มข้าว'
                                : '';
                            final String extraNote = _noteController.text
                                .trim();

                            String finalNote =
                                "ราดแกง: [$curriesNames]${additions.isNotEmpty ? '($additions)' : ''}"
                                    .trim();
                            if (extraNote.isNotEmpty) {
                              finalNote += "\nเพิ่มเติม: $extraNote";
                            }

                            final MenuModel mainCurryMenu =
                                _selectedCurries.first;

                            final updatedItem = CartItem(
                              menu: mainCurryMenu,
                              selectedAddons: finalSelectedOptionsList,
                              selectedCurries: List<MenuModel>.from(
                                _selectedCurries,
                              ),
                              quantity: _curryQty,
                              note: finalNote,
                              addonPrice: addonTotalPrice.toInt(),
                              totalPrice: totalPrice.toInt(),
                              unitPrice: unitPrice.toInt(),
                              isExtraPrice: false,
                            );

                            Navigator.pop(context, updatedItem);
                          },
                    child: const Text(
                      "บันทึกการแก้ไข",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
