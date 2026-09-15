// features/restaurant/view_order_restaurant.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/order_model.dart';
import 'package:flutter_app/data/models/order_detail_model.dart';
import 'package:flutter_app/data/services/in_app_notification_service.dart';
import 'package:flutter_app/data/services/order_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ViewOrderRestaurant extends StatefulWidget {
  final OrderModel orderModel;

  const ViewOrderRestaurant({super.key, required this.orderModel});

  @override
  State<ViewOrderRestaurant> createState() => _ViewOrderRestaurantState();
}

class _ViewOrderRestaurantState extends State<ViewOrderRestaurant> {
  final OrderService _orderService = OrderService();
  GoogleMapController? _miniMapController;

  final Color primaryGreen = const Color(0xFF00B300);
  final Color accentGreen = const Color(0xFF64F02D);
  static const Color _danger = Color(0xFFE53935);

  bool _isUpdating = false;

  @override
  void dispose() {
    _miniMapController?.dispose();
    super.dispose();
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;
    final String baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/')
        ? baseUrl + rawPath
        : baseUrl + '/' + rawPath;
  }

  String _formatDateTime(dynamic rawDate) {
    if (rawDate == null || rawDate.toString().isEmpty) return "ไม่ระบุเวลา";
    try {
      DateTime dt;
      if (rawDate is DateTime) {
        dt = rawDate.toLocal();
      } else {
        dt = DateTime.parse(rawDate.toString()).toLocal();
      }
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = (dt.year + 543).toString();
      final hr = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return d + "/" + m + "/" + y + " " + hr + ":" + min + " น.";
    } catch (e) {
      return rawDate.toString();
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(30),
                    color: Colors.white,
                    child: const Text(
                      "ไม่สามารถโหลดรูปภาพได้",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          color: isDangerMessage ? _danger : primaryGreen,
        ),
      ),
    );

    try {
      final int orderId = widget.orderModel.orderId ?? 0;
      await _orderService.updateOrderStatus(orderId, newStatus);

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: isDangerMessage ? _danger : primaryGreen,
          duration: const Duration(seconds: 2),
        ),
      );

      // แจ้งเตือนภายในฝั่งร้านค้าทันทีเมื่อกด "รับออเดอร์" สำเร็จ
      if (newStatus.toLowerCase() == 'goingtorestaurant') {
        InAppNotificationService.showTopBanner(
          title: 'รับออเดอร์สำเร็จ 👨‍🍳',
          message: 'ออเดอร์ #${orderId} ถูกยืนยันแล้ว และเริ่มเตรียมอาหาร',
          icon: Icons.restaurant_rounded,
          color: primaryGreen,
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      setState(() => _isUpdating = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🚨 ไม่สามารถอัปเดตสถานะได้: " + e.toString()),
          backgroundColor: _danger,
        ),
      );
    }
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.orange.shade50,
      child: const Icon(Icons.fastfood_rounded, color: Colors.orange, size: 30),
    );
  }

  Widget _buildTimelineDot(
    String label,
    bool isCompleted,
    bool isLineCompleted, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  color: isFirst
                      ? Colors.transparent
                      : (isCompleted
                            ? const Color(0xFF00B300)
                            : Colors.grey.shade300),
                ),
              ),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF00B300)
                      : Colors.grey.shade300,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted
                        ? const Color(0xFF2E7D32)
                        : Colors.grey.shade400,
                    width: 1,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 4,
                  color: isLast
                      ? Colors.transparent
                      : (isLineCompleted
                            ? const Color(0xFF00B300)
                            : Colors.grey.shade300),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: isCompleted ? Colors.black87 : Colors.grey.shade500,
              fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 ดึงข้อมูลรายการอาหารจาก Snapshot
  Widget _buildOrderItemCard(OrderDetailModel item) {
    List<dynamic> rawCurries = item.orderDetailCurries ?? [];
    final bool isCurryDish = rawCurries.isNotEmpty;

    // 🎯 ดึงชื่อเมนูจาก Snapshot
    String displayMenuName = item.menuNameAtOrder.isNotEmpty
        ? item.menuNameAtOrder
        : (item.menu?.menuName ?? "รายการเมนู");

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

    // 🎯 ดึงชื่อและราคา Add-on จาก Snapshot
    Map<String, Map<String, dynamic>> groupedAddons = {};
    for (var addon in item.addons) {
      String name = addon.addonNameAtOrder.isNotEmpty
          ? addon.addonNameAtOrder
          : (addon.menuAddonDetail?.addonMenu?.addonName ?? '');

      double price = addon.priceAtOrder;
      int qty = addon.addonQty ?? 1;

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

    // 🎯 ราคารวมของรายการนี้ (subtotal)
    double totalItemPrice = item.subTotal;
    if (totalItemPrice <= 0) {
      double addonsSum = 0.0;
      for (var addon in groupedAddons.values) {
        addonsSum += (addon['unitPrice'] as double) * (addon['qty'] as int);
      }
      double curriesSum = 0.0;
      for (var curry in curriesList) {
        curriesSum += (curry['price'] as double);
      }
      double basePrice = item.priceAtOrder > 0
          ? item.priceAtOrder
          : (item.menu?.price ?? 0.0);
      totalItemPrice = (basePrice + curriesSum + addonsSum) * item.qty;
    }

    String rawMenuUrl = item.menu?.menuImage ?? '';
    if (rawMenuUrl.isEmpty && curriesList.isNotEmpty) {
      rawMenuUrl = curriesList.first['image'] as String;
    }
    final String finalMenuUrl = _getFinalImageUrl(rawMenuUrl);
    final bool hasAddons = groupedAddons.isNotEmpty || curriesList.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
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
                  ? _buildPlaceholderIcon()
                  : Image.network(
                      Uri.encodeFull(finalMenuUrl),
                      width: 70,
                      height: 70,
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
                              color: primaryGreen,
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

                  if (item.note.isNotEmpty) ...[
                    Text(
                      "หมายเหตุ: " + item.note,
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
                      item.qty.toString() + " จำนวน",
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
    final order = widget.orderModel;

    final int rawOrderId = order.orderId ?? 0;
    final String orderId = rawOrderId.toString().padLeft(6, '0');
    final String currentStatus = (order.orderStatus ?? "").trim().toLowerCase();

    final bool isIssueReported = currentStatus == "issue_reported";
    final bool isCanceled =
        currentStatus == "cancel" ||
        currentStatus == "cancelled" ||
        currentStatus == "reject";

    int currentStep = 1;
    if (currentStatus == "waitingrestaurant" || currentStatus == "pending") {
      currentStep = 2;
    } else if (currentStatus == "goingtorestaurant" ||
        currentStatus == "going" ||
        currentStatus == "rideraccepted" ||
        currentStatus == "riderarrived") {
      currentStep = 3;
    } else if (currentStatus == "delivery" ||
        currentStatus == "delivering" ||
        currentStatus == "ontheway" ||
        currentStatus == "pickedup") {
      currentStep = 4;
    } else if (currentStatus == "arrived" || currentStatus == "reached") {
      currentStep = 5;
    } else if (currentStatus == "delivered" ||
        currentStatus == "success" ||
        currentStatus == "completed" ||
        currentStatus == "reviewsuccess") {
      currentStep = 6;
    }

    String customerName = "ไม่ระบุชื่อผู้รับ";
    String customerPhone = order.member?.phone ?? "-";
    String customerImgUrl = _getFinalImageUrl(order.member?.profileimg);

    if (order.member != null) {
      final String fn = order.member?.firstname ?? "";
      final String ln = order.member?.lastname ?? "";
      if (fn.isNotEmpty || ln.isNotEmpty) {
        customerName = (fn + " " + ln).trim();
      }
    }

    final bool hasRider = order.rider != null;
    String riderName = hasRider
        ? ((order.rider?.firstName ?? '') + " " + (order.rider?.lastName ?? ''))
              .trim()
        : "กำลังค้นหาไรเดอร์...";
    String riderPhone = hasRider ? (order.rider?.phone ?? "-") : "-";
    String vehiclePlate = hasRider ? (order.rider?.vehiclePlate ?? "-") : "-";
    String riderImgUrl = _getFinalImageUrl(order.rider?.studentCardImage);

    String cancelImageUrl = "";
    if (order.cancelimage != null && order.cancelimage!.isNotEmpty) {
      cancelImageUrl = _getFinalImageUrl(order.cancelimage);
    }

    final String formattedDate = _formatDateTime(order.orderdate);

    double deliveryFee = order.deliveryFee;
    double totalPrice = order.totalPrice;
    double foodSubtotal = totalPrice - deliveryFee;

    LatLng deliveryLocation = LatLng(order.latitude, order.longitude);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryGreen),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text(
          "รายละเอียดออเดอร์",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              // 🎯 เปลี่ยนจาก RichText เป็น Text.rich เพื่อดึงฟอนต์หลักมาใช้
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    const TextSpan(
                      text: "เลขที่ออเดอร์ : ",
                      style: TextStyle(color: Colors.black87),
                    ),
                    TextSpan(
                      text: "K" + orderId,
                      style: TextStyle(color: primaryGreen),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 15,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "สั่งซื้อเมื่อ: " + formattedDate,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── 1. กล่องแจ้งปัญหา ──
            if (isIssueReported) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50, // 🎯 เปลี่ยนจาก orange เป็น red
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.red.shade200,
                  ), // 🎯 เปลี่ยนเป็น red
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.support_agent_rounded,
                          color:
                              Colors.red.shade700, // 🎯 เปลี่ยนไอคอนเป็นสีแดง
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "มีการแจ้งปัญหาออเดอร์นี้\nกรุณาตรวจสอบรายละเอียดอาหาร",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors
                                  .red
                                  .shade800, // 🎯 เปลี่ยนข้อความแจ้งเตือนเป็นสีแดง
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.black87,
                        ),
                        children: [
                          const TextSpan(
                            text: "สาเหตุ / รายละเอียด: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: order.cancelDetail ?? 'ไม่มีข้อมูลระบุ',
                          ),
                        ],
                      ),
                    ),

                    if (cancelImageUrl.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        "รูปภาพหลักฐานจากลูกค้า:",
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showImageDialog(cancelImageUrl),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Image.network(
                                cancelImageUrl,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: double.infinity,
                                      height: 120,
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                              ),
                              Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.zoom_in,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      "แตะเพื่อดูภาพขยาย",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            // ── 2. กล่องยกเลิกคำสั่งซื้อ ──
            if (isCanceled) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cancel_rounded,
                          color: Colors.red.shade700,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "คำสั่งซื้อนี้ถูกยกเลิกแล้ว",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.black87,
                        ),
                        children: [
                          const TextSpan(
                            text: "สาเหตุการยกเลิก: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text:
                                order.cancelDetail ??
                                (currentStatus == 'reject'
                                    ? 'ร้านค้าปฏิเสธการรับคำสั่งซื้อ'
                                    : 'ไม่มีผู้จัดส่งรับงานภายในเวลาที่กำหนด'),
                          ),
                        ],
                      ),
                    ),

                    if (cancelImageUrl.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        "รูปภาพหลักฐานการยกเลิก:",
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showImageDialog(cancelImageUrl),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Image.network(
                                cancelImageUrl,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: double.infinity,
                                      height: 120,
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                              ),
                              Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.zoom_in,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      "แตะเพื่อดูภาพขยาย",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── 3. Timeline สถานะ 6 ระดับ ──
            if (!isCanceled && !isIssueReported) ...[
              const Text(
                "สถานะคำสั่งซื้อ",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFBFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimelineDot(
                      "ค้นหาผู้จัดส่ง",
                      currentStep >= 1,
                      currentStep >= 2,
                      isFirst: true,
                    ),
                    _buildTimelineDot(
                      "ร้านรับออเดอร์",
                      currentStep >= 2,
                      currentStep >= 3,
                    ),
                    _buildTimelineDot(
                      "ไปรับออเดอร์",
                      currentStep >= 3,
                      currentStep >= 4,
                    ),
                    _buildTimelineDot(
                      "กำลังจัดส่ง",
                      currentStep >= 4,
                      currentStep >= 5,
                    ),
                    _buildTimelineDot(
                      "ถึงที่หมายแล้ว",
                      currentStep >= 5,
                      currentStep >= 6,
                    ),
                    _buildTimelineDot(
                      "จัดส่งสำเร็จ",
                      currentStep >= 6,
                      currentStep >= 7,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 16),

            // ── 4. ข้อมูลลูกค้า ──
            const Text(
              "ข้อมูลลูกค้า",
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
                        ? const Icon(Icons.person, color: Colors.orange)
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
                          "เบอร์โทร: " + customerPhone,
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

            // ── 5. ผู้จัดส่ง ──
            // ── 5. ผู้จัดส่ง ──
            const Text(
              "ผู้จัดส่ง",
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
                  // 🎯 แก้ไขส่วนนี้ให้แสดงรูปภาพโปรไฟล์ไรเดอร์ถ้ามี
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child:
                        hasRider &&
                            order.rider!.profileImage != null &&
                            order.rider!.profileImage!.isNotEmpty
                        ? Image.network(
                            _getFinalImageUrl(order.rider!.profileImage),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 50,
                                  height: 50,
                                  color: primaryGreen.withOpacity(0.15),
                                  child: Icon(
                                    Icons.two_wheeler,
                                    color: primaryGreen,
                                    size: 26,
                                  ),
                                ),
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            color: primaryGreen.withOpacity(0.15),
                            child: Icon(
                              Icons.two_wheeler,
                              color: primaryGreen,
                              size: 26,
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
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
                        const SizedBox(height: 4),
                        Text(
                          "เบอร์โทร: " +
                              riderPhone +
                              "  |  ทะเบียนรถ: " +
                              vehiclePlate,
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

            // ── 6. ตำแหน่งที่อยู่จัดส่งของลูกค้า ──
            Row(
              children: [
                const Text(
                  "ตำแหน่งที่อยู่จัดส่งของลูกค้า",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.location_on, color: primaryGreen, size: 22),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: deliveryLocation,
                    zoom: 16.0,
                  ),
                  onMapCreated: (controller) => _miniMapController = controller,
                  zoomControlsEnabled: false,
                  zoomGesturesEnabled: false,
                  scrollGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  markers: {
                    Marker(
                      markerId: const MarkerId('restaurant_delivery_pos'),
                      position: deliveryLocation,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                      infoWindow: InfoWindow(
                        title: "จุดจัดส่ง: " + customerName,
                      ),
                    ),
                  },
                ),
              ),
            ),

            if (order.addressDetail.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "จุดสังเกต / รายละเอียดที่อยู่:",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.addressDetail,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 16),

            // ── 7. รายการอาหาร ──
            const Text(
              "รายการอาหาร",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "รวมยอดเงินของร้าน",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  foodSubtotal.toStringAsFixed(0) + " บาท",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),

      bottomNavigationBar: isIssueReported || isCanceled
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: _buildActionButtonByStatus(
                    order.orderStatus ?? "WaitingRestaurant",
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildActionButtonByStatus(String status) {
    final statusLower = status.toLowerCase();

    if (statusLower == "waitingrestaurant" || statusLower == "pending") {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isUpdating
                  ? null
                  : () => _updateOrderStatus(
                      "reject",
                      "ปฏิเสธออเดอร์เรียบร้อย",
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
                      "goingToRestaurant",
                      "รับออเดอร์สำเร็จ! เริ่มปรุงอาหารแล้ว 👨‍🍳",
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
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
    } else if (statusLower == "goingtorestaurant" ||
        statusLower == "going" ||
        statusLower == "preparing" ||
        statusLower == "cooking" ||
        statusLower == "foodready") {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFE8FCD0),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: primaryGreen.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.soup_kitchen_rounded, color: primaryGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              "รับออเดอร์แล้ว (กำลังรอไรเดอร์มารับอาหาร 🛵)",
              style: TextStyle(
                color: primaryGreen,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
