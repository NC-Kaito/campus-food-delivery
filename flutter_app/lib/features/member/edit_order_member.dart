// features/member/edit_order_member.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/option_model.dart';
import 'package:flutter_app/data/models/menu_option_group_model.dart';
import 'package:flutter_app/data/services/menu/menu_option_service.dart';
import 'package:flutter_app/features/member/cart_manager_member.dart';
import 'package:flutter_app/core/network/dio_client.dart';

class EditOrderMember extends StatefulWidget {
  final CartItem cartItem;

  const EditOrderMember({super.key, required this.cartItem});

  @override
  State<EditOrderMember> createState() => _EditOrderMemberState();
}

class _EditOrderMemberState extends State<EditOrderMember> {
  int _quantity = 1;
  final TextEditingController _noteController = TextEditingController();

  final MenuOptionService _optionService = MenuOptionService();

  List<OptionGroupModel> _optionGroups = [];
  List<OptionModel> _allOptions = [];
  bool _isLoading = true;

  // เก็บ Option ที่ผู้ใช้เลือก โดยใช้ optionId เป็น key
  final Map<int, OptionModel> _selectedOptions = {};

  // เก็บชื่อกลุ่มของแต่ละ Option เพื่อใช้จัดการ Single Choice
  final Map<int, String> _optionGroupNameById = {};

  @override
  void initState() {
    super.initState();

    _quantity = widget.cartItem.quantity;
    _noteController.text = widget.cartItem.note;

    // โหลด Option ที่เลือกไว้เดิม
    for (final option in widget.cartItem.selectedAddons) {
      final int? optionId = option.optionId;
      if (optionId != null) {
        _selectedOptions[optionId] = option;
      }
    }

    _loadMenuOptions();
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

  Future<void> _loadMenuOptions() async {
    final int? menuId = widget.cartItem.menu.menuId;

    if (menuId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final groups = await _optionService.getOptionsByMenuId(menuId);

      if (!mounted) return;

      final List<OptionModel> options = [];
      final Map<int, String> groupNameByOptionId = {};

      for (final group in groups) {
        final String groupName =
            group.optionGroupName?.trim().isNotEmpty == true
            ? group.optionGroupName!.trim()
            : "ตัวเลือกเสริม";

        for (final option in group.options ?? <OptionModel>[]) {
          options.add(option);

          if (option.optionId != null) {
            groupNameByOptionId[option.optionId!] = groupName;
          }
        }
      }

      setState(() {
        _optionGroups = groups;
        _allOptions = options;
        _optionGroupNameById
          ..clear()
          ..addAll(groupNameByOptionId);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _optionGroups = [];
        _allOptions = [];
        _optionGroupNameById.clear();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("ไม่สามารถโหลดตัวเลือกอาหารได้: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Map<String, List<OptionModel>> _groupOptions() {
    final Map<String, List<OptionModel>> grouped = {};

    for (final option in _allOptions) {
      final int? optionId = option.optionId;

      final String groupName = optionId != null
          ? (_optionGroupNameById[optionId] ?? "ตัวเลือกเสริม")
          : "ตัวเลือกเสริม";

      grouped.putIfAbsent(groupName, () => []);
      grouped[groupName]!.add(option);
    }

    return grouped;
  }

  bool _isMultipleChoice(String groupName) {
    for (final group in _optionGroups) {
      final String currentName =
          group.optionGroupName?.trim().isNotEmpty == true
          ? group.optionGroupName!.trim()
          : "ตัวเลือกเสริม";

      if (currentName == groupName) {
        return group.isMultipleChoice ?? false;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final int basePrice = widget.cartItem.menu.price?.toInt() ?? 0;

    double optionTotalPrice = 0;
    for (final option in _selectedOptions.values) {
      optionTotalPrice += option.optionPrice ?? 0;
    }

    final int totalPrice = (basePrice + optionTotalPrice.toInt()) * _quantity;

    final String? rawMenuImage = widget.cartItem.menu.menuImage;
    final String finalMenuUrl = _getFinalImageUrl(rawMenuImage);

    final groupedOptions = _groupOptions();

    final String? description =
        (widget.cartItem.menu.description?.trim().isNotEmpty == true)
        ? widget.cartItem.menu.description
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
                  Icons.delete_forever_outlined,
                  color: Colors.redAccent,
                  size: 22,
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
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
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
                              Navigator.pop(context);
                              Navigator.pop(context, "REMOVE");
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
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
                                    widget.cartItem.menu.menuName ??
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
                            if (groupedOptions.isNotEmpty) ...[
                              ...groupedOptions.entries
                                  .toList()
                                  .asMap()
                                  .entries
                                  .map((mapEntry) {
                                    final bool isFirstGroup = mapEntry.key == 0;
                                    final entry = mapEntry.value;

                                    final String groupName = entry.key;
                                    final List<OptionModel> items = entry.value;
                                    final bool isMultipleChoice =
                                        _isMultipleChoice(groupName);

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                        (option) =>
                                                            _buildOptionItem(
                                                              option,
                                                              isMultipleChoice,
                                                              groupName,
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
                              if (_quantity > 1) {
                                setState(() => _quantity--);
                              }
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
                  final List<OptionModel> finalSelectedOptions =
                      _selectedOptions.values.toList();

                  final updatedItem = CartItem(
                    menu: widget.cartItem.menu,
                    selectedAddons: finalSelectedOptions,
                    quantity: _quantity,
                    note: _noteController.text,
                    addonPrice: optionTotalPrice.toInt(),
                    totalPrice: totalPrice,
                    unitPrice: basePrice,
                    isExtraPrice: false,
                  );

                  Navigator.pop(context, updatedItem);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B300),
                  foregroundColor: Colors.white,
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

  Widget _buildOptionItem(
    OptionModel option,
    bool isMultipleChoice,
    String groupName,
  ) {
    final int id = option.optionId ?? 0;
    final bool isSelected = _selectedOptions.containsKey(id);

    final String title = option.optionName?.trim().isNotEmpty == true
        ? option.optionName!.trim()
        : "ไม่มีชื่อ";

    final int price = option.optionPrice?.toInt() ?? 0;

    return InkWell(
      onTap: () {
        if (id == 0) return;

        setState(() {
          if (isSelected) {
            _selectedOptions.remove(id);
          } else {
            // Single Choice: เลือกได้ 1 ตัวเลือกต่อ 1 กลุ่ม
            if (!isMultipleChoice) {
              _selectedOptions.removeWhere(
                (key, value) => _optionGroupNameById[key] == groupName,
              );
            }

            _selectedOptions[id] = option;
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

  Widget _buildPlaceholderBanner() {
    return Container(
      width: double.infinity,
      height: 400,
      color: Colors.orange.shade50,
      child: const Icon(Icons.fastfood, size: 80, color: Colors.orange),
    );
  }
}
