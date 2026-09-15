// features/rider/view_review_rider.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/order_model.dart';
import 'package:flutter_app/data/models/review_model.dart';
import 'package:flutter_app/data/services/member/member_service.dart';
import 'package:flutter_app/core/network/dio_client.dart';

class ViewReviewRider extends StatefulWidget {
  final OrderModel orderModel;
  const ViewReviewRider({super.key, required this.orderModel});

  @override
  State<ViewReviewRider> createState() => _ViewReviewRiderState();
}

class _ViewReviewRiderState extends State<ViewReviewRider> {
  final MemberService memberService = MemberService();

  ReviewSubmitModel? _reviewData;
  bool _isLoading = true;
  bool _isItemsExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchReviewData();
  }

  Future<void> _fetchReviewData() async {
    try {
      if (widget.orderModel.orderId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final review = await memberService.getReviewByOrderId(
        widget.orderModel.orderId!,
      );
      if (mounted) {
        setState(() {
          _reviewData = review;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("โหลดข้อมูลรีวิวไม่สำเร็จ: " + e.toString());
      if (mounted) setState(() => _isLoading = false);
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

  Widget _buildPlaceholderIcon({
    double size = 65,
    IconData icon = Icons.fastfood_rounded,
  }) {
    return Container(
      width: size,
      height: size,
      color: Colors.orange.shade50,
      child: Icon(icon, color: Colors.orange, size: size * 0.5),
    );
  }

  Widget _buildStarRating(int rating) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(5, (index) {
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Icon(
            index < rating ? Icons.star_rounded : Icons.star_border_rounded,
            color: Colors.orange,
            size: 40,
          ),
        );
      }),
    );
  }

  Widget _buildTagIfTrue(String label, bool? isSelected) {
    if (isSelected != true) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 🎯 ปรับปรุง UI ให้เหมือน Member (เพิ่มขีดสีส้ม และพื้นหลังเทาอ่อน)
  Widget _buildProOrderItemCard(dynamic item) {
    List<dynamic> rawCurries = [];
    try {
      if (item.orderDetailCurries != null &&
          item.orderDetailCurries!.isNotEmpty) {
        rawCurries = item.orderDetailCurries!;
      } else if (item.toJson()['orderDetailCurries'] != null) {
        rawCurries = item.toJson()['orderDetailCurries'];
      } else if (item.toJson()['orderdetailcurries'] != null) {
        rawCurries = item.toJson()['orderdetailcurries'];
      }
    } catch (_) {}

    final bool isCurryDish = rawCurries.isNotEmpty;

    String displayMenuName = "รายการเมนู";
    try {
      displayMenuName = item.menuNameAtOrder?.isNotEmpty == true
          ? item.menuNameAtOrder
          : (item.menu?.menuName ?? "รายการเมนู");
    } catch (_) {
      try {
        displayMenuName = item.menu?.menuName ?? "รายการเมนู";
      } catch (_) {}
    }

    if (isCurryDish && !displayMenuName.contains("ข้าวราดแกง")) {
      displayMenuName =
          "ข้าวราดแกง (" + rawCurries.length.toString() + " อย่าง)";
    }

    List<Map<String, dynamic>> curriesList = [];
    for (var e in rawCurries) {
      String name = '';
      String img = '';
      double price = 0.0;
      if (e is Map) {
        final menuMap = (e['menu'] is Map) ? e['menu'] as Map : e;
        name =
            (menuMap['menuname'] ??
                    menuMap['menuName'] ??
                    menuMap['name'] ??
                    '')
                .toString();
        img =
            (menuMap['imageurl'] ??
                    menuMap['imageUrl'] ??
                    menuMap['menuimage'] ??
                    menuMap['menuImage'] ??
                    '')
                .toString();
        price = (e['priceAtOrder'] ?? e['priceatorder'] ?? 0.0).toDouble();
      } else {
        try {
          name =
              ((e as dynamic).menu?.menuName ??
                      (e as dynamic).menu?.menuname ??
                      '')
                  .toString();
          img =
              ((e as dynamic).menu?.menuImage ??
                      (e as dynamic).menu?.imageurl ??
                      '')
                  .toString();
          price = ((e as dynamic).priceAtOrder ?? 0.0).toDouble();
        } catch (_) {}
      }
      if (name.isNotEmpty) {
        curriesList.add({'name': name, 'image': img, 'price': price});
      }
    }

    List<dynamic> rawAddons = [];
    try {
      if (item.addons != null && item.addons.isNotEmpty) {
        rawAddons = item.addons;
      } else if (item.toJson()['addons'] != null) {
        rawAddons = item.toJson()['addons'];
      }
    } catch (_) {}

    Map<String, Map<String, dynamic>> groupedAddons = {};
    for (var addon in rawAddons) {
      String name = '';
      double price = 0.0;
      int qty = 1;

      if (addon is Map) {
        name =
            addon['addonNameAtOrder'] ??
            addon['menuAddonDetail']?['addonMenu']?['addonName'] ??
            addon['addonMenu']?['addonName'] ??
            addon['name'] ??
            addon['addonName'] ??
            '';
        price =
            (addon['priceAtOrder'] ??
                    addon['menuAddonDetail']?['addonPrice'] ??
                    0.0)
                .toDouble();
        qty = (addon['addonQty'] ?? addon['addon_qty'] ?? 1).toInt();
      } else {
        try {
          name = addon.addonNameAtOrder?.isNotEmpty == true
              ? addon.addonNameAtOrder
              : (addon.menuAddonDetail?.addonMenu?.addonName ?? '');
        } catch (_) {}
        if (name.isEmpty) {
          try {
            name = addon.addonName ?? '';
          } catch (_) {}
        }
        try {
          price =
              (addon.priceAtOrder ?? addon.menuAddonDetail?.addonPrice ?? 0.0)
                  .toDouble();
        } catch (_) {}
        try {
          qty = (addon.addonQty ?? 1).toInt();
        } catch (_) {}
      }

      if (name.isNotEmpty) {
        if (groupedAddons.containsKey(name)) {
          groupedAddons[name]!['qty'] =
              (groupedAddons[name]!['qty'] as int) + qty;
          groupedAddons[name]!['canIncreaseQty'] = true;
        } else {
          groupedAddons[name] = {
            'qty': qty,
            'unitPrice': price,
            'canIncreaseQty': qty > 1,
          };
        }
      }
    }

    double totalItemPrice = 0.0;
    try {
      totalItemPrice = (item.subTotal ?? 0.0).toDouble();
    } catch (_) {}

    int qty = 1;
    try {
      qty = (item.qty ?? 1).toInt();
    } catch (_) {}

    if (totalItemPrice <= 0) {
      double addonsSum = 0.0;
      for (var addon in groupedAddons.values) {
        addonsSum += (addon['unitPrice'] as double) * (addon['qty'] as int);
      }
      double curriesSum = 0.0;
      for (var curry in curriesList) {
        curriesSum += (curry['price'] as double);
      }
      double basePrice = 0.0;
      try {
        basePrice =
            (item.priceAtOrder > 0
                    ? item.priceAtOrder
                    : (item.menu?.price ?? 0.0))
                .toDouble();
      } catch (_) {}
      totalItemPrice = (basePrice + curriesSum + addonsSum) * qty;
    }

    String rawMenuUrl = '';
    try {
      rawMenuUrl = item.menu?.menuImage ?? '';
    } catch (_) {}
    if (rawMenuUrl.isEmpty && curriesList.isNotEmpty) {
      rawMenuUrl = curriesList.first['image'] as String;
    }
    final String finalMenuUrl = _getFinalImageUrl(rawMenuUrl);
    final bool hasAddons = groupedAddons.isNotEmpty || curriesList.isNotEmpty;

    String note = "";
    try {
      note = item.note ?? "";
    } catch (_) {}

    // 🎯 เริ่มตกแต่ง UI การ์ด
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // พื้นหลังสีเทาอ่อนเหมือน Member
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isCurryDish || finalMenuUrl.isEmpty
                  ? _buildPlaceholderIcon(size: 70)
                  : Image.network(
                      Uri.encodeFull(finalMenuUrl),
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderIcon(size: 70),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          displayMenuName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        totalItemPrice.toStringAsFixed(0) + " บาท",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  const SizedBox(height: 8),

                  if (hasAddons) ...[
                    const Text(
                      "รายการเพิ่มเติม",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                    const SizedBox(height: 6),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 3.5,
                            decoration: BoxDecoration(
                              color: Colors
                                  .orange, // 🎯 เส้นขีดของ Rider เป็นสีส้ม
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var curry in curriesList)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            curry['name'] as String,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        const Text(
                                          "1 จำนวน",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                for (var entry in groupedAddons.entries)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            entry.key,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        if (entry.value['canIncreaseQty'] ==
                                                true ||
                                            (entry.value['qty'] as int) > 1)
                                          RichText(
                                            text: TextSpan(
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black87,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text:
                                                      (entry.value['qty']
                                                              as int)
                                                          .toString() +
                                                      " ",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const TextSpan(text: "จำนวน"),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (note.isNotEmpty) ...[
                    Text(
                      "หมายเหตุ: " + note,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],

                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      qty.toString() + " จำนวน",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
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

  @override
  Widget build(BuildContext context) {
    String memberFullName = "ไม่ระบุชื่อลูกค้า";
    String finalImgUrl = "";

    if (widget.orderModel.member != null) {
      final String firstName = widget.orderModel.member?.firstname ?? "";
      final String lastName = widget.orderModel.member?.lastname ?? "";
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        memberFullName = firstName + " " + lastName.trim();
      }
      final String? rawImgPath = widget.orderModel.member?.profileimg ?? "";
      finalImgUrl = _getFinalImageUrl(rawImgPath);
    }

    final String orderIdStr = (widget.orderModel.orderId ?? 0)
        .toString()
        .padLeft(6, '0');

    final int displayRating = _reviewData?.riderrating ?? 5;

    final String displayComment =
        (_reviewData?.commentrider != null &&
            _reviewData!.commentrider!.isNotEmpty)
        ? _reviewData!.commentrider!
        : "ลูกค้าไม่ได้ให้ความคิดเห็นเพิ่มเติม";

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF00B300),
          ),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text(
          "รีวิวการจัดส่ง",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.orange.shade800,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "ข้อมูลลูกค้า และรายการที่สั่ง",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: finalImgUrl.isEmpty
                                  ? _buildPlaceholderIcon(
                                      size: 50,
                                      icon: Icons.person_rounded,
                                    )
                                  : Image.network(
                                      Uri.encodeFull(finalImgUrl),
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    memberFullName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "ออเดอร์: K" + orderIdStr,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(color: Colors.grey.shade200, thickness: 1.5),
                        const SizedBox(height: 12),

                        if (widget.orderModel.items.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: widget.orderModel.items.length > 1
                                      ? () {
                                          setState(() {
                                            _isItemsExpanded =
                                                !_isItemsExpanded;
                                          });
                                        }
                                      : null,
                                  child: AnimatedSize(
                                    duration: const Duration(milliseconds: 350),
                                    curve: Curves.easeInOutCubic,
                                    alignment: Alignment.topCenter,
                                    child: Column(
                                      children: [
                                        if (!_isItemsExpanded) ...[
                                          Stack(
                                            children: [
                                              _buildProOrderItemCard(
                                                widget.orderModel.items.first,
                                              ),
                                              if (widget
                                                      .orderModel
                                                      .items
                                                      .length >
                                                  1)
                                                Positioned(
                                                  bottom: 0,
                                                  left: 0,
                                                  right: 0,
                                                  height: 50,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                        colors: [
                                                          Colors.grey.shade50
                                                              .withOpacity(0.0),
                                                          Colors.grey.shade50,
                                                        ],
                                                        stops: const [0.0, 0.8],
                                                      ),
                                                    ),
                                                    alignment:
                                                        Alignment.bottomCenter,
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 8,
                                                        ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          "เพิ่มเติม",
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors
                                                                .grey
                                                                .shade500,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Icon(
                                                          Icons
                                                              .keyboard_arrow_down_rounded,
                                                          size: 16,
                                                          color: Colors
                                                              .grey
                                                              .shade500,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ] else ...[
                                          ...widget.orderModel.items
                                              .asMap()
                                              .entries
                                              .map((entry) {
                                                return Column(
                                                  children: [
                                                    _buildProOrderItemCard(
                                                      entry.value,
                                                    ),
                                                    if (entry.key <
                                                        widget
                                                                .orderModel
                                                                .items
                                                                .length -
                                                            1)
                                                      Divider(
                                                        height: 1,
                                                        thickness: 1,
                                                        indent: 16,
                                                        endIndent: 16,
                                                        color: Colors
                                                            .grey
                                                            .shade200,
                                                      ),
                                                  ],
                                                );
                                              }),
                                          if (widget.orderModel.items.length >
                                              1)
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.only(
                                                bottom: 12,
                                                top: 4,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "ซ่อน",
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                          Colors.grey.shade500,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    Icons
                                                        .keyboard_arrow_up_rounded,
                                                    size: 16,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.star_rounded,
                          color: Colors.green.shade800,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "คะแนนที่ได้รับจากลูกค้า",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "ความพึงพอใจต่อการจัดส่งของคุณ",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildStarRating(displayRating),

                        const SizedBox(height: 16),
                        const Text(
                          "คำชม / Tag จากลูกค้า",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            _buildTagIfTrue(
                              'ส่งเร็ว ⚡',
                              _reviewData?.deliverySpeed,
                            ),
                            _buildTagIfTrue(
                              'รักษาสภาพอาหารดี 🍱',
                              _reviewData?.foodCondition,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Text(
                          "ความคิดเห็นเพิ่มเติม",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300!),
                          ),
                          child: Text(
                            displayComment,
                            style: TextStyle(
                              color:
                                  (_reviewData?.commentrider != null &&
                                      _reviewData!.commentrider!.isNotEmpty)
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
