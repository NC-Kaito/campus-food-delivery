// features/member/add_order_member.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/option_model.dart';
import 'package:flutter_app/data/models/menu_option_group_model.dart';
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/data/services/menu/menu_option_service.dart';
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

  List<OptionGroupModel> _optionGroups = [];
  List<OptionModel> _allOptions = [];
  bool _isLoading = true;

  // 🎯 สีเขียวหลักของระบบ
  static const Color _primaryGreen = Color(0xFF00B300);

  // 🎯 เก็บจำนวนที่เลือกของแต่ละ Option (Key: optionId, Value: จำนวนชิ้น)
  final Map<int, int> _optionQuantities = {};

  // 🎯 เก็บข้อมูล Option จริงไว้อ้างอิงราคาและชื่อ
  final Map<int, OptionModel> _optionModelsIndex = {};

  // 🎯 ใช้ผูก Option กับกลุ่ม เพื่อควบคุม Single / Multiple Choice
  final Map<String, OptionGroupModel> _groupModelsIndex = {};
  final Map<int, String> _optionGroupNameById = {};

  @override
  void initState() {
    super.initState();
    _loadMenuAddons();
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;

    final String baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/')
        ? baseUrl + rawPath
        : baseUrl + '/' + rawPath;
  }

  Future<void> _loadMenuAddons() async {
    final int? menuId = widget.menuModel.menuId;

    if (menuId == null) {
      if (mounted) {
        setState(() {
          _optionGroups = [];
          _allOptions = [];
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      // ใช้ endpoint ใหม่ของระบบ Option โดยตรง
      // GET /v1/menu/{menuId}/options
      final response = await DioClient.dio.get('/v1/menu/$menuId/options');

      if (response.statusCode != 200 || response.data is! List) {
        throw Exception('ไม่สามารถโหลด OptionGroup ของเมนูได้');
      }

      final List rawGroups = response.data as List;
      final List<OptionGroupModel> groups = [];

      for (final rawGroup in rawGroups) {
        if (rawGroup is! Map) continue;

        final Map<String, dynamic> groupJson = Map<String, dynamic>.from(
          rawGroup,
        );

        // รองรับทั้งชื่อ field ที่ backend ส่งออกมา และชื่อที่ Model ใช้
        groupJson['optiongroupid'] =
            groupJson['optiongroupid'] ?? groupJson['optionGroupId'];
        groupJson['optiongroupname'] =
            groupJson['optiongroupname'] ??
            groupJson['optionGroupName'] ??
            'ตัวเลือก';
        groupJson['is_required'] =
            groupJson['is_required'] ?? groupJson['isRequired'] ?? false;
        groupJson['is_multiple_choice'] =
            groupJson['is_multiple_choice'] ??
            groupJson['isMultipleChoice'] ??
            false;

        final dynamic rawOptions = groupJson['options'];
        final List<Map<String, dynamic>> normalizedOptions = [];

        if (rawOptions is List) {
          for (final rawOption in rawOptions) {
            if (rawOption is! Map) continue;

            final Map<String, dynamic> optionJson = Map<String, dynamic>.from(
              rawOption,
            );

            final dynamic optionId =
                optionJson['optionid'] ?? optionJson['optionId'];
            if (optionId == null) continue;

            optionJson['optionid'] = optionId is num
                ? optionId.toInt()
                : int.tryParse(optionId.toString());
            optionJson['optionname'] =
                optionJson['optionname'] ??
                optionJson['optionName'] ??
                'ไม่มีชื่อ';

            final dynamic optionPrice =
                optionJson['optionprice'] ?? optionJson['optionPrice'] ?? 0;
            optionJson['optionprice'] = optionPrice is num
                ? optionPrice.toDouble()
                : double.tryParse(optionPrice.toString()) ?? 0.0;

            normalizedOptions.add(optionJson);
          }
        }

        groupJson['options'] = normalizedOptions;

        groups.add(OptionGroupModel.fromJson(groupJson));
      }

      if (!mounted) return;

      setState(() {
        _optionGroups = groups;
        _allOptions = [];
        _optionModelsIndex.clear();
        _groupModelsIndex.clear();
        _optionGroupNameById.clear();
        _optionQuantities.clear();

        for (final group in groups) {
          final String groupName = (group.optionGroupName ?? 'ตัวเลือก').trim();

          _groupModelsIndex[groupName] = group;

          final List<OptionModel> options = (group.options ?? [])
              .whereType<OptionModel>()
              .where((option) => option.optionId != null)
              .toList();

          for (final option in options) {
            _allOptions.add(option);
            _optionModelsIndex[option.optionId!] = option;
            _optionGroupNameById[option.optionId!] = groupName;
          }

          // Single choice: ให้เลือกตัวเลือกแรกที่ราคา 0 เป็นค่าเริ่มต้น
          if (options.isNotEmpty && !group.isMultipleChoice) {
            OptionModel? defaultOption;

            for (final option in options) {
              if ((option.optionPrice ?? 0) == 0) {
                defaultOption = option;
                break;
              }
            }

            defaultOption ??= options.first;

            if (defaultOption.optionId != null) {
              _optionQuantities[defaultOption.optionId!] = 1;
            }
          }
        }

        _isLoading = false;
      });

      debugPrint(
        'โหลด OptionGroup/Option สำเร็จ: '
        '${groups.length} กลุ่ม / ${_allOptions.length} ตัวเลือก',
      );
    } catch (e) {
      debugPrint('Error loading OptionGroup/Option: $e');

      if (!mounted) return;

      setState(() {
        _optionGroups = [];
        _allOptions = [];
        _optionModelsIndex.clear();
        _groupModelsIndex.clear();
        _optionGroupNameById.clear();
        _optionQuantities.clear();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Map<String, List<OptionModel>> _groupOptions() {
    final Map<String, List<OptionModel>> grouped = {};

    for (final group in _optionGroups) {
      final String groupName = (group.optionGroupName ?? "ตัวเลือก").trim();

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

  @override
  Widget build(BuildContext context) {
    final int basePrice = widget.menuModel.price?.toInt() ?? 0;

    double addonTotalPrice = 0;
    _optionQuantities.forEach((id, qty) {
      final model = _optionModelsIndex[id];
      if (model != null) {
        addonTotalPrice += (model.optionPrice ?? 0) * qty;
      }
    });

    int totalPrice = (basePrice + addonTotalPrice.toInt()) * _quantity;
    String finalMenuUrl = _getFinalImageUrl(widget.menuModel.menuImage);
    final groupedAddons = _groupOptions();
    final String? description =
        (widget.menuModel.description?.trim().isNotEmpty == true)
        ? widget.menuModel.description
        : null;

    final bool isCurryDish = (widget.menuModel.menuName ?? '').contains(
      "ข้าวราดแกง",
    );

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
        actions: const [],
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
                                  basePrice == 0
                                      ? "ราคาปกติ"
                                      : "฿" + basePrice.toString(),
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
                            if (groupedAddons.isNotEmpty) ...[
                              ...groupedAddons.entries
                                  .toList()
                                  .asMap()
                                  .entries
                                  .map((mapEntry) {
                                    final isFirstGroup = mapEntry.key == 0;
                                    final entry = mapEntry.value;

                                    String groupName = entry.key;
                                    final List<OptionModel> items = entry.value;
                                    final bool isMultipleChoice =
                                        _groupModelsIndex[entry.key]
                                            ?.isMultipleChoice ??
                                        false;

                                    // 🎯 สำหรับข้าวราดแกง เปลี่ยนชื่อกลุ่ม "รายการเพิ่มเติม" หรือ "ตัวเลือก" เป็น "รายการ"
                                    String displayGroupName = groupName;
                                    if (isCurryDish &&
                                        (groupName == "รายการเพิ่มเติม" ||
                                            groupName == "ตัวเลือก" ||
                                            groupName.contains("เพิ่มเติม"))) {
                                      displayGroupName = "รายการ";
                                    }

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
                                          displayGroupName,
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
                                                color: _primaryGreen,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  children: items
                                                      .map(
                                                        (addonDetail) =>
                                                            _buildOptionItem(
                                                              addonDetail,
                                                              isMultipleChoice,
                                                              entry.key,
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
                              _quantity.toString(),
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
                      "จำนวน " + _quantity.toString() + " รายการ",
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
                            text: "฿" + totalPrice.toString(),
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
                  // 🎯 1. ดักการตรวจสอบ: บังคับเลือกตัวเลือกที่เป็นแบบ Radio (Single Choice)
                  final List<OptionModel> finalSelectedOptionsList = [];
                  final groupedOptionsForCheck = _groupOptions();

                  bool isValid = true;
                  String missingGroupName = "";

                  // เช็กทีละกลุ่ม
                  for (final entry in groupedOptionsForCheck.entries) {
                    final String groupName = entry.key;
                    final List<OptionModel> items = entry.value;

                    final bool isMultipleChoice =
                        _groupModelsIndex[groupName]?.isMultipleChoice ?? false;

                    // ถ้าเป็น Single Choice ต้องเลือกอย่างน้อย 1 ตัว
                    if (!isMultipleChoice) {
                      final bool hasSelectedInGroup = items.any(
                        (option) =>
                            option.optionId != null &&
                            (_optionQuantities[option.optionId!] ?? 0) > 0,
                      );

                      if (!hasSelectedInGroup) {
                        isValid = false;
                        missingGroupName = groupName;
                        break;
                      }
                    }
                  }

                  if (!isValid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "กรุณาเลือกในหมวดหมู่ '$missingGroupName' ",
                        ),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                    return;
                  }

                  // ถ้าผ่านแล้ว ค่อยนำ Option ที่เลือกลงตะกร้า
                  _optionQuantities.forEach((id, qty) {
                    final model = _optionModelsIndex[id];

                    if (model != null && qty > 0) {
                      for (int i = 0; i < qty; i++) {
                        finalSelectedOptionsList.add(model);
                      }
                    }
                  });

                  final cartItem = CartItem(
                    menu: widget.menuModel,
                    selectedAddons: finalSelectedOptionsList,
                    quantity: _quantity,
                    note: _noteController.text.trim(),
                    addonPrice: addonTotalPrice.toInt(),
                    totalPrice: totalPrice,
                    unitPrice: basePrice,
                    isExtraPrice: false,
                  );

                  CartManager().addToCart(cartItem);

                  final String currentStoreUsername =
                      widget.menuModel.restaurant?.username ?? '';
                  final List<CartItem> currentStoreItems = CartManager().items
                      .whereType<CartItem>()
                      .where(
                        (item) =>
                            item.menu.restaurant?.username ==
                            currentStoreUsername,
                      )
                      .toList();
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
                        storeUsername: currentStoreUsername,
                        storeName:
                            widget.menuModel.restaurant?.restaurantName ??
                            'ออเดอร์ของคุณ',
                        storeItems:
                            currentStoreItems, // 🎯 ส่งไปแค่ของร้านนี้ร้านเดียว!
                        isFromAddOrder: true,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
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

  Widget _buildOptionItem(
    OptionModel option,
    bool isMultipleChoice,
    String groupName,
  ) {
    final int id = option.optionId ?? 0;
    final int currentQty = _optionQuantities[id] ?? 0;
    final bool isSelected = currentQty > 0;

    final String title = option.optionName ?? "ไม่มีชื่อ";
    final int price = (option.optionPrice ?? 0).toInt();

    void handleFrontTap() {
      setState(() {
        if (isSelected) {
          _optionQuantities.remove(id);
        } else {
          if (!isMultipleChoice) {
            _optionQuantities.removeWhere((key, value) {
              return _optionGroupNameById[key] == groupName;
            });
          }

          _optionQuantities[id] = 1;
        }
      });
    }

    void handlePlusTap() {
      setState(() {
        _optionQuantities[id] = currentQty + 1;
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
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
                        Expanded(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  price == 0 ? "(ราคาปกติ)" : "(+$price)",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
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
                              if (_optionQuantities[id]! <= 1) {
                                _optionQuantities.remove(id);
                              } else {
                                _optionQuantities[id] =
                                    _optionQuantities[id]! - 1;
                              }
                            });
                          }
                        : null,
                  ),
                  SizedBox(
                    width: 20,
                    child: Text(
                      currentQty.toString(),
                      textAlign: TextAlign.center,
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
                    onPressed: isSelected ? handlePlusTap : null,
                  ),
                ],
              ),
            ),
        ],
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
