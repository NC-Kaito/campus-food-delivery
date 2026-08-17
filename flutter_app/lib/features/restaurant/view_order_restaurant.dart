// features/restaurant/view_order_restaurant.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/order_model.dart';
import 'package:flutter_app/data/models/order_detail_model.dart';
import 'package:flutter_app/data/services/order_service.dart';
import 'package:flutter_app/features/restaurant/restaurant_navbar.dart';

class ViewOrderRestaurant extends StatefulWidget {
  final OrderModel orderModel;

  const ViewOrderRestaurant({super.key, required this.orderModel});

  @override
  State<ViewOrderRestaurant> createState() => _ViewOrderRestaurantState();
}

class _ViewOrderRestaurantState extends State<ViewOrderRestaurant> {
  final OrderService _orderService = OrderService();

  static const Color _primary = Color(0xFF16A34A);
  static const Color _primaryDark = Color(0xFF0F7A38);
  static const Color _accent = Color(0xFFEA7C1E);
  static const Color _danger = Color(0xFFE53935);

  bool _isUpdating = false;

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;
    final String baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/') ? "$baseUrl$rawPath" : "$baseUrl/$rawPath";
  }

  // ── 🎯 ฟังก์ชันหลักฟังก์ชันเดียวสำหรับจัดการสถานะทั้งหมด ──
  Future<void> _updateOrderStatus(
    String newStatus,
    String successMessage, {
    bool isDangerMessage = false,
  }) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          color: isDangerMessage ? _danger : _primary,
        ),
      ),
    );

    try {
      final int orderId = widget.orderModel.orderId ?? 0;

      // เอาคอมเมนต์ออกเพื่อใช้งาน API จริงได้เลยนะครับ
      // await _orderService.updateOrderStatus(orderId, newStatus);

      // จำลองการรอ API สักนิดให้ดูเป็นธรรมชาติครับ
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: isDangerMessage ? _danger : _primary,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      setState(() => _isUpdating = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🚨 ไม่สามารถอัปเดตสถานะได้: $e"),
          backgroundColor: _danger,
        ),
      );
    }
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 65,
      height: 65,
      color: Colors.orange.shade50,
      child: const Icon(Icons.fastfood_rounded, color: Colors.orange, size: 30),
    );
  }

  // ── 🎯 การ์ดรายการอาหารปรับแต่งใหม่ (เหมือนหน้า ViewOrderMember) ──
  Widget _buildOrderItemCard(OrderDetailModel item) {
    // 1. ตรวจสอบว่าเป็นข้าวราดแกงหรือไม่
    final bool isCurryDish =
        (item.orderDetailCurries != null &&
        item.orderDetailCurries!.isNotEmpty);

    int curryCount = isCurryDish ? item.orderDetailCurries!.length : 0;
    String displayMenuName = item.menu?.menuName ?? "รายการเมนู";
    if (isCurryDish) {
      displayMenuName = "ข้าวราดแกง ($curryCount อย่าง)";
    }

    // 2. ดึงรายการกับข้าวทั้งหมดพร้อมรูปภาพ
    List<Map<String, String>> curriesList = [];
    if (isCurryDish) {
      for (var e in item.orderDetailCurries!) {
        if (e is Map<String, dynamic>) {
          final menuMap = (e['menu'] is Map<String, dynamic>)
              ? e['menu'] as Map<String, dynamic>
              : e;

          String name = (menuMap['menuname'] ?? menuMap['menuName'] ?? '')
              .toString();
          String img = (menuMap['menuimage'] ?? menuMap['menuImage'] ?? '')
              .toString();

          if (name.isNotEmpty) {
            curriesList.add({'name': name, 'image': img});
          }
        }
      }
    }

    // 3. จัดกลุ่มและนับจำนวน Add-on ที่เลือกมาทั้งหมด (เช่น ไข่ดาว x2)
    Map<String, int> addonCounts = {};
    for (var addon in item.addons) {
      String name = '';
      if (addon.menuAddonDetail != null &&
          addon.menuAddonDetail!.addonMenu != null) {
        name = addon.menuAddonDetail!.addonMenu!.addonName ?? '';
      }
      if (name.isNotEmpty) {
        addonCounts[name] = (addonCounts[name] ?? 0) + 1;
      }
    }

    // 4. คำนวณราคาต่อหน่วย
    int finalPricePerUnit = 0;
    final int baseMenuPrice = item.menu?.price?.toInt() ?? 0;

    if (isCurryDish) {
      int curriesSum = 0;
      for (var curry in item.orderDetailCurries!) {
        if (curry is Map<String, dynamic>) {
          final num? price = curry['priceAtOrder'] as num?;
          curriesSum += (price ?? 0).toInt();
        }
      }
      int addonsSum = 0;
      for (var addon in item.addons) {
        addonsSum +=
            (addon.priceAtOrder ?? addon.menuAddonDetail?.addonPrice ?? 0)
                .toInt();
      }
      finalPricePerUnit =
          (baseMenuPrice > 0 ? baseMenuPrice : 0) + curriesSum + addonsSum;
    } else {
      int addonsSum = 0;
      for (var addon in item.addons) {
        addonsSum +=
            (addon.priceAtOrder ?? addon.menuAddonDetail?.addonPrice ?? 0)
                .toInt();
      }
      finalPricePerUnit = baseMenuPrice + addonsSum;
    }

    final String finalMenuUrl = _getFinalImageUrl(item.menu?.menuImage);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: _primary, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
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
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "ราคา $finalPricePerUnit บาท",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // แสดงผลกับข้าวทุกอย่างแบบ Badge พร้อมรูปภาพย่อย
                  if (curriesList.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6.0,
                      runSpacing: 6.0,
                      children: curriesList.map((curry) {
                        String rawCurryImage = curry['image'] ?? '';
                        String finalCurryUrl = _getFinalImageUrl(rawCurryImage);

                        return Container(
                          padding: const EdgeInsets.only(
                            left: 2,
                            right: 8,
                            top: 2,
                            bottom: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.green.shade200),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  color: Colors.grey.shade200,
                                  child: finalCurryUrl.isNotEmpty
                                      ? Image.network(
                                          Uri.encodeFull(finalCurryUrl),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                Icons.fastfood_rounded,
                                                size: 12,
                                                color: Colors.grey,
                                              ),
                                        )
                                      : const Icon(
                                          Icons.fastfood_rounded,
                                          size: 12,
                                          color: Colors.grey,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                curry['name'] ?? "ไม่มีชื่อ",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.green.shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // แสดงผล Add-on แบบ Badge สีส้ม พร้อมรวมจำนวน (เช่น ไข่ดาว x2)
                  if (addonCounts.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6.0,
                      runSpacing: 6.0,
                      children: addonCounts.entries.map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
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
                                Icons.add_circle_rounded,
                                size: 14,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                entry.value > 1
                                    ? "${entry.key} x${entry.value}"
                                    : entry.key,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.orange.shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  if (item.note.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      "หมายเหตุ: ${item.note}",
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "จำนวน ${item.qty}",
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.orderModel;

    final int rawOrderId = order.orderId ?? 0;
    final String orderId = rawOrderId.toString().padLeft(6, '0');
    final String currentStatus = order.orderStatus ?? "WaitingRestaurant";

    // ── ข้อมูลลูกค้า ──
    String customerName = "ไม่ระบุชื่อผู้รับ";
    String customerPhone = order.member?.phone ?? "-";
    String customerImgUrl = _getFinalImageUrl(order.member?.profileimg);

    if (order.member != null) {
      final String fn = order.member?.firstname ?? "";
      final String ln = order.member?.lastname ?? "";
      if (fn.isNotEmpty || ln.isNotEmpty) {
        customerName = "$fn $ln".trim();
      }
    }

    // ── ข้อมูลไรเดอร์ ──
    final bool hasRider = order.rider != null;
    String riderName = hasRider
        ? "${order.rider?.firstName ?? ''} ${order.rider?.lastName ?? ''}"
              .trim()
        : "กำลังค้นหาไรเดอร์...";
    String riderPhone = hasRider ? (order.rider?.phone ?? "-") : "-";
    String vehiclePlate = hasRider ? (order.rider?.vehiclePlate ?? "-") : "-";
    String riderImgUrl = _getFinalImageUrl(order.rider?.studentCardImage);

    // ── เวลาสั่งซื้อ ──
    String orderTimeText = "--:--";
    if (order.orderdate != null) {
      final DateTime dateTime = order.orderdate!;
      orderTimeText =
          "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} น.";
    }

    double deliveryFee = order.deliveryFee;
    double totalPrice = order.totalPrice;
    double foodSubtotal = totalPrice - deliveryFee;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const RestaurantNavbar(title: "รายละเอียดออเดอร์"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── เลขที่ออเดอร์และเวลา ──
            Center(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    const TextSpan(
                      text: "หมายเลขคำสั่งซื้อ : ",
                      style: TextStyle(color: Colors.black87),
                    ),
                    TextSpan(
                      text: "K$orderId",
                      style: const TextStyle(color: _accent),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "เวลาสั่งซื้อ: $orderTimeText",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 16),

            // ── 👤 บล็อกข้อมูลลูกค้า ──
            const Text(
              "ลูกค้า",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.orange.withOpacity(0.15),
                    backgroundImage: customerImgUrl.isNotEmpty
                        ? NetworkImage(customerImgUrl)
                        : null,
                    child: customerImgUrl.isEmpty
                        ? const Icon(Icons.person, color: _accent)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "เบอร์โทร: $customerPhone",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (order.addressDetail.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Text(
                  "สถานที่จัดส่ง: ${order.addressDetail}",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── 🏍️ บล็อกข้อมูลไรเดอร์ ──
            const Text(
              "ผู้จัดส่ง",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors
                    .black, // 🎯 แก้ไขสีตรงนี้ให้เป็น Colors.black แล้วครับ
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _primary.withOpacity(0.15),
                    backgroundImage: riderImgUrl.isNotEmpty
                        ? NetworkImage(riderImgUrl)
                        : null,
                    child: riderImgUrl.isEmpty
                        ? const Icon(Icons.two_wheeler, color: _primary)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          riderName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: hasRider
                                ? Colors.black87
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "เบอร์โทร: $riderPhone  |  ทะเบียนรถ: $vehiclePlate",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 16),

            // ── 🍱 รายการอาหาร ──
            const Text(
              "รายการสั่งซื้อ",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              itemBuilder: (context, index) {
                return _buildOrderItemCard(order.items[index]);
              },
            ),
            const SizedBox(height: 12),

            // ── 💰 สรุปยอดเงินของร้าน ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "รวมยอดเงิน",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "${foodSubtotal.toStringAsFixed(0)} บาท",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),

      // ── 🎯 ปุ่มกดอัปเดตสถานะสำหรับร้านค้า ──
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: _buildActionButtonByStatus(currentStatus),
          ),
        ),
      ),
    );
  }

  // 🎯 สลับปุ่มกดตามสถานะออเดอร์
  Widget _buildActionButtonByStatus(String status) {
    if (status == "WaitingRestaurant") {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isUpdating
                  ? null
                  : () => _updateOrderStatus(
                      "Reject",
                      "ปฏิเสธออเดอร์เรียบร้อยแล้วครับ",
                      isDangerMessage: true,
                    ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _danger,
                side: const BorderSide(color: _danger, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                "ปฏิเสธ",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isUpdating
                  ? null
                  : () => _updateOrderStatus(
                      "Accept",
                      "รับออเดอร์สำเร็จ! เริ่มปรุงอาหารแล้ว 👨‍🍳",
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                "รับออเดอร์",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    } else if (status == "delivery") {
      return ElevatedButton(
        onPressed: _isUpdating
            ? null
            : () => _updateOrderStatus(
                "Delivering",
                "ทำอาหารเสร็จแล้ว! แจ้งไรเดอร์มารับอาหาร 🍱🛵",
              ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF64FF20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: const Text(
          "ทำอาหารเสร็จแล้ว (พร้อมส่ง)",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Text(
          "ออเดอร์นี้อยู่ระหว่างจัดส่ง / เสร็จสิ้นแล้ว",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }
}
