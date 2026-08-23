import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/order_model.dart';
import 'package:flutter_app/data/models/review_model.dart';
import 'package:flutter_app/data/services/member/member_service.dart';
import 'package:flutter_app/core/network/dio_client.dart';

import 'package:flutter_app/features/member/cart_manager_member.dart';
import 'package:flutter_app/features/member/list_order_member.dart';
import 'package:flutter_app/features/member/profile_member.dart';
import 'package:flutter_app/data/services/order_service.dart';
import 'package:flutter_app/global_data.dart';

class MemberReview extends StatefulWidget {
  final OrderModel order;
  const MemberReview({super.key, required this.order});

  @override
  State<MemberReview> createState() => _MemberReviewState();
}

class _MemberReviewState extends State<MemberReview> {
  int _restaurantRating = 0;
  int _riderRating = 0;

  final TextEditingController _restaurantCommentController =
      TextEditingController();
  final TextEditingController _riderCommentController = TextEditingController();

  // เซ็ตเก็บสถานะการเลือกแท็ก
  final Set<String> _selectedRestaurantTags = {};
  final Set<String> _selectedRiderTags = {};

  final Color primaryGreen = const Color(0xFF64F02D);

  final MemberService memberService = MemberService();
  bool _isSubmitting = false;

  bool _isItemsExpanded = false;

  final OrderService _orderService = OrderService();
  int _activeOrderCount = 0;
  final TextStyle menuTextStyle = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Color(0xFF64F02D),
  );

  @override
  void initState() {
    super.initState();
    _fetchActiveOrderCount();
  }

  @override
  void dispose() {
    _restaurantCommentController.dispose();
    _riderCommentController.dispose();
    super.dispose();
  }

  Future<void> _fetchActiveOrderCount() async {
    try {
      String username = GlobalData.usernameMember.trim();
      if (username.isEmpty) return;

      final history = await _orderService.getConfirmOrdersByMember(username);

      int count = 0;
      for (var order in history) {
        final status = (order.orderStatus ?? '').toLowerCase();
        if (status != 'success' &&
            status != 'completed' &&
            status != 'cancel' &&
            status != 'cancelled') {
          count++;
        }
      }

      if (mounted) {
        setState(() {
          _activeOrderCount = count;
        });
      }
    } catch (e) {
      debugPrint("เกิดข้อผิดพลาดในการโหลดจำนวนออเดอร์: $e");
    }
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

  Widget _buildStarRating(int currentRating, Function(int) onRatingChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            onRatingChanged(index + 1);
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(
              index < currentRating
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              color: Colors.orange,
              size: 40,
            ),
          ),
        );
      }),
    );
  }

  // Widget สำหรับแสดงแท็ก เลือกแล้วเป็นสีส้ม ยังไม่เลือกเป็นสีเทา
  Widget _buildSuggestionTags(List<String> tags, Set<String> selectedTags) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: tags.map((tag) {
        bool isSelected = selectedTags.contains(tag);
        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedTags.remove(tag);
              } else {
                selectedTags.add(tag);
              }
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProOrderItemCard(dynamic item) {
    List<dynamic> rawCurries = [];
    if (item.orderDetailCurries != null &&
        item.orderDetailCurries!.isNotEmpty) {
      rawCurries = item.orderDetailCurries!;
    } else if (item.toJson()['orderDetailCurries'] != null) {
      rawCurries = item.toJson()['orderDetailCurries'];
    } else if (item.toJson()['orderdetailcurries'] != null) {
      rawCurries = item.toJson()['orderdetailcurries'];
    }

    final bool isCurryDish = rawCurries.isNotEmpty;
    String displayMenuName = item.menu?.menuName ?? "รายการเมนู";
    if (isCurryDish) {
      displayMenuName = "ข้าวราดแกง (${rawCurries.length} อย่าง)";
    }

    List<Map<String, String>> curriesList = [];
    for (var e in rawCurries) {
      if (e is Map<String, dynamic>) {
        final menuMap = (e['menu'] is Map<String, dynamic>)
            ? e['menu'] as Map<String, dynamic>
            : e;
        String name =
            (menuMap['menuname'] ??
                    menuMap['menuName'] ??
                    menuMap['name'] ??
                    '')
                .toString();
        String img =
            (menuMap['menuimage'] ??
                    menuMap['menuImage'] ??
                    menuMap['image'] ??
                    '')
                .toString();
        if (name.isNotEmpty) curriesList.add({'name': name, 'image': img});
      }
    }

    List<dynamic> rawAddons = [];
    if (item.addons != null && item.addons.isNotEmpty) {
      rawAddons = item.addons;
    } else if (item.toJson()['addons'] != null) {
      rawAddons = item.toJson()['addons'];
    }

    Map<String, int> addonCounts = {};
    for (var addon in rawAddons) {
      String name = '';
      if (addon is Map) {
        name =
            addon['menuAddonDetail']?['addonMenu']?['addonName'] ??
            addon['addonMenu']?['addonName'] ??
            addon['name'] ??
            addon['addonName'] ??
            '';
      } else {
        try {
          name = addon.menuAddonDetail?.addonMenu?.addonName ?? '';
        } catch (_) {}
        if (name.isEmpty) {
          try {
            name = addon.addonName ?? '';
          } catch (_) {}
        }
      }
      if (name.isNotEmpty) addonCounts[name] = (addonCounts[name] ?? 0) + 1;
    }

    int finalPricePerUnit = 0;
    final int baseMenuPrice = item.menu?.price?.toInt() ?? 0;

    if (isCurryDish) {
      int curriesSum = 0;
      for (var curry in rawCurries) {
        if (curry is Map<String, dynamic>) {
          final num? price = curry['priceAtOrder'] ?? curry['priceatorder'];
          curriesSum += (price ?? 0).toInt();
        }
      }
      int addonsSum = 0;
      for (var addon in rawAddons) {
        num? p = 0;
        if (addon is Map) {
          p = addon['priceAtOrder'] ?? addon['menuAddonDetail']?['addonPrice'];
        } else {
          try {
            p = addon.priceAtOrder;
          } catch (_) {}
          if (p == null) {
            try {
              p = addon.menuAddonDetail?.addonPrice;
            } catch (_) {}
          }
        }
        addonsSum += (p ?? 0).toInt();
      }
      finalPricePerUnit =
          (baseMenuPrice > 0 ? baseMenuPrice : 0) + curriesSum + addonsSum;
    } else {
      int addonsSum = 0;
      for (var addon in rawAddons) {
        num? p = 0;
        if (addon is Map) {
          p = addon['priceAtOrder'] ?? addon['menuAddonDetail']?['addonPrice'];
        } else {
          try {
            p = addon.priceAtOrder;
          } catch (_) {}
          if (p == null) {
            try {
              p = addon.menuAddonDetail?.addonPrice;
            } catch (_) {}
          }
        }
        addonsSum += (p ?? 0).toInt();
      }
      finalPricePerUnit = baseMenuPrice + addonsSum;
    }

    final String finalMenuUrl = _getFinalImageUrl(item.menu?.menuImage);
    int qty = item.qty ?? 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isCurryDish || finalMenuUrl.isEmpty
                ? _buildPlaceholderIcon()
                : Image.network(
                    Uri.encodeFull(finalMenuUrl),
                    width: 65,
                    height: 65,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholderIcon(),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayMenuName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "ราคา $finalPricePerUnit บาท",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                if (curriesList.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 6.0,
                    children: curriesList.map((curry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_circle,
                              size: 14,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              curry['name'] ?? "ไม่มีชื่อ",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                if (addonCounts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 6.0,
                    children: addonCounts.entries.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_circle,
                              size: 14,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              entry.value > 1
                                  ? "${entry.key} x${entry.value}"
                                  : entry.key,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "จำนวน $qty",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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

  Future<void> _handleSubmitReview() async {
    if (_restaurantRating == 0 || _riderRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("กรุณาให้คะแนนทั้งร้านค้าและผู้จัดส่งก่อนส่งประเมิน"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.order.orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "เกิดข้อผิดพลาด: ไม่พบรหัสคำสั่งซื้อ ไม่สามารถส่งประเมินได้",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final review = ReviewSubmitModel(
        orderid: widget.order.orderId!,
        restaurantrating: _restaurantRating,
        riderrating: _riderRating,
        cleanliness: _selectedRestaurantTags.contains('ถูกสุขลักษณะ'),
        tasteRating: _selectedRestaurantTags.contains('รสชาติดี'),
        deliverySpeed: _selectedRiderTags.contains('ส่งเร็ว'),
        foodCondition: _selectedRiderTags.contains('รักษาสภาพอาหารดี'),
        commentrestaurant: _restaurantCommentController.text.trim().isEmpty
            ? null
            : _restaurantCommentController.text.trim(),
        commentrider: _riderCommentController.text.trim().isEmpty
            ? null
            : _riderCommentController.text.trim(),
      );

      // 1. ส่งข้อมูลรีวิว
      await memberService.addReview(review);

      // 2. 🎯 อัปเดตสถานะออเดอร์เป็น reviewSuccess
      await _orderService.updateOrderStatus(
        widget.order.orderId!,
        "reviewSuccess",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("ส่งคำติชมสำเร็จ ขอบคุณที่ร่วมประเมินครับ 🎉"),
          backgroundColor: Colors.green,
        ),
      );
      // ส่งค่ากลับไปเพื่อให้หน้าก่อนหน้ารู้ว่ารีวิวเสร็จแล้ว จะได้รีเฟรชข้อมูล
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isActive = false,
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isActive ? const Color(0xFF64F02D) : Colors.grey,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              label,
              style: menuTextStyle.copyWith(
                color: isActive ? const Color(0xFF64F02D) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String storeName =
        widget.order.restaurant?.restaurantName ??
        widget.order.restaurantUsername ??
        "ไม่ระบุชื่อร้านค้า";
    String finalStoreImage = _getFinalImageUrl(
      widget.order.restaurant?.restaurantImage,
    );

    String riderFirstName = widget.order.rider?.firstName ?? "";
    String riderLastName = widget.order.rider?.lastName ?? "";
    String riderFullName = riderFirstName.isEmpty && riderLastName.isEmpty
        ? "ไม่ระบุชื่อผู้จัดส่ง"
        : "$riderFirstName $riderLastName".trim();
    String finalRiderImage = _getFinalImageUrl(
      widget.order.rider?.studentCardImage,
    );

    final int cartItemCount = CartManager().items.length;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.orange,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "ประเมินความพึงพอใจ",
          style: TextStyle(
            color: Colors.orange,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey[200], height: 1.0),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.storefront_rounded,
                          color: Colors.orange.shade800,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "ให้คะแนนร้านค้า",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: finalStoreImage.isEmpty
                            ? _buildPlaceholderIcon(
                                size: 50,
                                icon: Icons.store_rounded,
                              )
                            : Image.network(
                                Uri.encodeFull(finalStoreImage),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholderIcon(
                                      size: 50,
                                      icon: Icons.store_rounded,
                                    ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          storeName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (widget.order.items != null &&
                      widget.order.items!.isNotEmpty)
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
                            onTap: widget.order.items!.length > 1
                                ? () {
                                    setState(() {
                                      _isItemsExpanded = !_isItemsExpanded;
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
                                          widget.order.items!.first,
                                        ),
                                        if (widget.order.items!.length > 1)
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            height: 50,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.grey.shade50
                                                        .withOpacity(0.0),
                                                    Colors.grey.shade50,
                                                  ],
                                                  stops: const [0.0, 0.8],
                                                ),
                                              ),
                                              alignment: Alignment.bottomCenter,
                                              padding: const EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "เพิ่มเติม",
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
                                                        .keyboard_arrow_down_rounded,
                                                    size: 16,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ] else ...[
                                    ...widget.order.items!.asMap().entries.map((
                                      entry,
                                    ) {
                                      return Column(
                                        children: [
                                          _buildProOrderItemCard(entry.value),
                                          if (entry.key <
                                              widget.order.items!.length - 1)
                                            Divider(
                                              height: 1,
                                              thickness: 1,
                                              indent: 16,
                                              endIndent: 16,
                                              color: Colors.grey.shade200,
                                            ),
                                        ],
                                      );
                                    }),
                                    if (widget.order.items!.length > 1)
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
                                                color: Colors.grey.shade500,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.keyboard_arrow_up_rounded,
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

                  const SizedBox(height: 16),

                  const Text(
                    "รสชาติอาหารเป็นอย่างไรบ้าง?",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildStarRating(_restaurantRating, (rating) {
                    setState(() {
                      _restaurantRating = rating;
                    });
                  }),
                  const SizedBox(height: 16),

                  const Text(
                    "ความคิดเห็นเพิ่มเติมให้ร้านค้า",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _buildSuggestionTags([
                    'ถูกสุขลักษณะ',
                    'รสชาติดี',
                  ], _selectedRestaurantTags),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _restaurantCommentController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: "กรอกความประทับใจ หรือข้อเสนอแนะ...",
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        borderSide: const BorderSide(
                          color: Colors.orange,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

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
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.moped_rounded,
                          color: Colors.green.shade800,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "ให้คะแนนผู้จัดส่ง",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: finalRiderImage.isEmpty
                            ? _buildPlaceholderIcon(
                                size: 50,
                                icon: Icons.person_rounded,
                              )
                            : Image.network(
                                Uri.encodeFull(finalRiderImage),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholderIcon(
                                      size: 50,
                                      icon: Icons.person_rounded,
                                    ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          riderFullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "การจัดส่งและบริการเป็นอย่างไรบ้าง?",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildStarRating(_riderRating, (rating) {
                    setState(() {
                      _riderRating = rating;
                    });
                  }),
                  const SizedBox(height: 16),

                  const Text(
                    "ความคิดเห็นเพิ่มเติมให้ผู้จัดส่ง",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _buildSuggestionTags([
                    'ส่งเร็ว',
                    'รักษาสภาพอาหารดี',
                  ], _selectedRiderTags),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _riderCommentController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText:
                          "คำชมเล็กๆ น้อยๆ ช่วยเป็นกำลังใจให้ไรเดอร์ได้นะ...",
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        borderSide: const BorderSide(
                          color: Colors.orange,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27.0),
                  ),
                  elevation: 0,
                  shadowColor: primaryGreen.withOpacity(0.4),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black87,
                        ),
                      )
                    : const Text(
                        "รีวิว",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.home, "หน้าหลัก", () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                }),
                _buildNavItem(Icons.shopping_basket, "ตะกร้าอาหาร", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ListOrderMember(),
                    ),
                  );
                }, badgeCount: cartItemCount),
                _buildNavItem(
                  Icons.list_alt,
                  "คำสั่งซื้อ",
                  () {
                    Navigator.pop(context);
                  },
                  isActive: true,
                  badgeCount: _activeOrderCount,
                ),
                _buildNavItem(Icons.person, "โปรไฟล์", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileMember(),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
