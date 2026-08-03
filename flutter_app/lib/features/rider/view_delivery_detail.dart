// features/rider/view_delivery_detail.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/order_model.dart';
import 'package:flutter_app/data/models/order_detail_model.dart';
import 'package:flutter_app/data/services/order_service.dart';
import 'package:flutter_app/features/rider/map_delivery.dart';

class ViewDeliveryDetail extends StatefulWidget {
  final OrderModel orderModel;

  const ViewDeliveryDetail({super.key, required this.orderModel});

  @override
  State<ViewDeliveryDetail> createState() => _ViewDeliveryDetailState();
}

class _ViewDeliveryDetailState extends State<ViewDeliveryDetail> {
  final OrderService _orderService = OrderService();
  bool _isUpdating = false;

  // ตั้งค่าเริ่มต้นสถานะใน Dropdown
  String _selectedStatus = 'Delivering';

  // 🎯 สถานะจริงของออเดอร์จากฝั่งร้านค้า/ระบบ ใช้ตัดสินใจว่าไรเดอร์
  // จะอัปเดตสถานะได้หรือยัง (แยกจาก _selectedStatus ที่ใช้กับ Dropdown เท่านั้น)
  late String _orderStatus;

  // ร้านค้ายังไม่กดรับออเดอร์ → ล็อกไว้ก่อน อัปเดตอะไรไม่ได้
  bool get _isWaitingRestaurant => _orderStatus == 'WaitingRestaurant';
  // จัดส่งสำเร็จแล้ว → จบงานแล้ว ไม่ต้องอัปเดตต่อ
  bool get _isCompleted => _orderStatus == 'Success';
  // ร้านค้ารับออเดอร์แล้ว (หรือสถานะอื่นที่ไม่ใช่ 2 อย่างข้างบน) → ไรเดอร์อัปเดตได้
  bool get _canUpdateStatus => !_isWaitingRestaurant && !_isCompleted;

  @override
  void initState() {
    super.initState();
    // 🎯 เก็บสถานะดิบไว้ก่อน ถ้าไม่มีค่ามาเลยให้ถือว่ายังรอร้านค้ารับออเดอร์
    // (ปลอดภัยกว่าเดิมที่ default ไปเป็น 'Delivering' ซึ่งจะปล่อยให้ไรเดอร์
    // กดอัปเดตได้ทั้งที่ร้านอาจจะยังไม่ได้กดรับจริงๆ)
    _orderStatus = widget.orderModel.orderStatus ?? 'WaitingRestaurant';

    // ดึงสถานะปัจจุบันของออเดอร์มาตั้งเป็นค่าเริ่มต้นให้ Dropdown
    // (Dropdown มีแค่ 2 ตัวเลือกนี้ ใช้ตอนร้านรับออเดอร์แล้วเท่านั้น)
    if (_orderStatus == 'Delivering' || _orderStatus == 'Success') {
      _selectedStatus = _orderStatus;
    } else {
      _selectedStatus = 'Delivering';
    }
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;
    final String baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/') ? "$baseUrl$rawPath" : "$baseUrl/$rawPath";
  }

  // ── 🎯 ฟังก์ชันอัปเดตสถานะออเดอร์จริงผ่าน API ──
  Future<void> _updateOrderStatus() async {
    // 🎯 กันไว้อีกชั้น เผื่อมีการเรียกฟังก์ชันนี้ทั้งที่ UI ควรถูกล็อกอยู่
    if (_isUpdating || !_canUpdateStatus) return;
    setState(() => _isUpdating = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );

    try {
      final int orderId = widget.orderModel.orderId ?? 0;

      // 🎯 เปิดใช้งานการเรียก API อัปเดตสถานะ
      await _orderService.updateOrderStatus(orderId, _selectedStatus);

      if (!mounted) return;
      Navigator.pop(context); // ปิด Loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("อัปเดตสถานะการจัดส่งสำเร็จ!"),
          backgroundColor: Colors.green,
        ),
      );

      // ส่ง true กลับไปเพื่อให้หน้า List สั่งรีเฟรชข้อมูล
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      setState(() => _isUpdating = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("ไม่สามารถอัปเดตสถานะได้: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.orderModel;

    // การจัดการตัวเลขและข้อมูล
    final String orderIdStr = (order.orderId ?? 0).toString().padLeft(6, '0');
    final String customerName =
        "${order.member?.firstname ?? ''} ${order.member?.lastname ?? ''}"
            .trim()
            .isEmpty
        ? "ไม่ระบุชื่อลูกค้า"
        : "${order.member?.firstname ?? ''} ${order.member?.lastname ?? ''}";
    final String customerPhone = order.member?.phone ?? "ไม่ระบุเบอร์โทร";

    final String restaurantName =
        order.restaurant?.restaurantName ?? "ไม่ระบุชื่อร้าน";

    final String dropoffLocation = order.addressDetail.isNotEmpty
        ? order.addressDetail
        : "ไม่ระบุสถานที่ส่ง";

    // การคำนวณราคา
    final double deliveryFee = order.deliveryFee;
    final double totalPrice = order.totalPrice;
    final double foodSubtotal = totalPrice - deliveryFee;

    return Scaffold(
      backgroundColor: Colors.white,
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
          "รายละเอียดการจัดส่ง",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── เลขที่ออเดอร์ + ป้ายสถานะ ──
            Center(
              child: Column(
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        const TextSpan(
                          text: "เลขที่ออเดอร์ : ",
                          style: TextStyle(color: Colors.orange),
                        ),
                        TextSpan(
                          text: "K$orderIdStr",
                          style: const TextStyle(color: Color(0xFF53D726)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusChip(),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── ข้อมูลลูกค้า ──
            const Text(
              "ข้อมูลลูกค้า",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_circle_outlined,
                        size: 36,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ชื่อผู้รับสินค้า",
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              customerName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.phone_in_talk_outlined,
                        size: 36,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "เบอร์โทรศัพท์",
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              customerPhone,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(thickness: 1, color: Colors.black12),
            const SizedBox(height: 12),

            // ── จุดรับ-ส่ง ──
            // 🎯 เปลี่ยนเป็น Row เพื่อเพิ่มปุ่มดูแผนที่ทางขวา
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "จุดรับ - ส่ง",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MapDelivery(orderModel: widget.orderModel),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.map_outlined,
                          size: 16,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "ดูแผนที่",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 4),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    // 🎯 ปรับความสูงเส้นเชื่อมให้สั้นลง เพราะเอาข้อความสถานที่ออกไป 1 บรรทัด
                    Container(
                      width: 2,
                      height: 45,
                      color: Colors.grey.shade300,
                    ),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFF53D726),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "จุดรับอาหาร",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // 🎯 เอาบรรทัด สถานที่ : พิกัดตามแอปพลิเคชัน ออกไป
                      Text(
                        "ร้านค้า : $restaurantName",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        "จุดส่งอาหาร",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "รายละเอียด / สถานที่ : $dropoffLocation",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(thickness: 1, color: Colors.black12),
            const SizedBox(height: 12),

            // ── รายการสินค้า ──
            Text(
              "รายการสินค้า : $restaurantName",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ...order.items.map((item) => _buildOrderItemCard(item)).toList(),

            const SizedBox(height: 8),

            // ── ยอดรวม ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "ยอดจ่ายให้ร้านค้า",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: "${foodSubtotal.toStringAsFixed(0)} ",
                        style: const TextStyle(color: Colors.black),
                      ),
                      const TextSpan(
                        text: "บาท",
                        style: TextStyle(color: Colors.orange),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "ยอดรับจากลูกค้า (รวมค่าส่ง)",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF53D726),
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: "${totalPrice.toStringAsFixed(0)} ",
                        style: const TextStyle(color: Colors.black),
                      ),
                      const TextSpan(
                        text: "บาท",
                        style: TextStyle(color: Color(0xFF53D726)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(thickness: 1, color: Colors.black12),
            const SizedBox(height: 12),

            // ── สถานะการจัดส่ง ──
            const Text(
              "อัปเดตสถานะการจัดส่ง",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // 🎯 สลับ UI ตามสถานะจริงของออเดอร์:
            // - ร้านยังไม่รับ (WaitingRestaurant) → โชว์ข้อความรอ ล็อกทุกอย่าง
            // - จัดส่งสำเร็จแล้ว (Success)         → โชว์ข้อความจบงาน ไม่ต้องอัปเดตต่อ
            // - นอกนั้น (ร้านรับแล้ว/กำลังจัดส่ง)    → โชว์ Dropdown + ปุ่มอัปเดตตามปกติ
            if (_isWaitingRestaurant)
              _buildWaitingRestaurantNotice()
            else if (_isCompleted)
              _buildCompletedNotice()
            else
              _buildStatusUpdateControls(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ป้ายเล็กๆ ใต้เลขที่ออเดอร์ บอกสถานะปัจจุบันให้เห็นชัดตั้งแต่บนสุด
  Widget _buildStatusChip() {
    late final Color color;
    late final IconData icon;
    late final String label;

    if (_isWaitingRestaurant) {
      color = Colors.grey.shade600;
      icon = Icons.hourglass_top_rounded;
      label = "รอร้านค้ายืนยันรับออเดอร์";
    } else if (_isCompleted) {
      color = const Color(0xFF53D726);
      icon = Icons.check_circle_rounded;
      label = "จัดส่งสำเร็จแล้ว";
    } else {
      color = Colors.orange;
      icon = Icons.delivery_dining_rounded;
      label = "ร้านค้ารับออเดอร์แล้ว · กำลังจัดส่ง";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 ร้านค้ายังไม่กดรับออเดอร์ → ล็อกส่วนอัปเดตสถานะทั้งหมด ไรเดอร์ทำอะไรไม่ได้
  Widget _buildWaitingRestaurantNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hourglass_top_rounded, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "รอร้านค้ายืนยันรับออเดอร์",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "ร้านค้ายังไม่กดรับออเดอร์นี้ ไรเดอร์จะยังอัปเดตสถานะการ"
                  "จัดส่งไม่ได้จนกว่าร้านค้าจะยืนยันรับก่อนครับ",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 จัดส่งสำเร็จแล้ว → ไม่มีอะไรให้อัปเดตต่อ โชว์สรุปจบงานแทน
  Widget _buildCompletedNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF53D726).withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF53D726).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF53D726)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "ออเดอร์นี้จัดส่งสำเร็จเรียบร้อยแล้ว ไม่ต้องอัปเดตสถานะเพิ่มเติม",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 ร้านค้ารับออเดอร์แล้ว → ไรเดอร์อัปเดตสถานะได้ตามปกติ (ของเดิม)
  Widget _buildStatusUpdateControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatus,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.black87,
                size: 28,
              ),
              isExpanded: true,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedStatus = newValue;
                  });
                }
              },
              items: const [
                DropdownMenuItem(
                  value: 'Delivering',
                  child: Text('รับอาหารแล้ว / กำลังจัดส่ง'),
                ),
                DropdownMenuItem(
                  value: 'Success',
                  child: Text('จัดส่งสำเร็จเรียบร้อย'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ── ปุ่มอัปเดตสถานะ ──
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isUpdating ? null : _updateOrderStatus,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64FF20),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isUpdating
                ? const CircularProgressIndicator(color: Colors.black87)
                : const Text(
                    "บันทึกสถานะ",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItemCard(OrderDetailModel item) {
    final bool isCurryDish =
        (item.orderDetailCurries != null &&
        item.orderDetailCurries!.isNotEmpty);

    String displayMenuName = item.menu?.menuName ?? "รายการอาหาร";
    if (isCurryDish) {
      displayMenuName = "ข้าวราดแกง (${item.orderDetailCurries!.length} อย่าง)";
    }

    String curriesText = "";
    if (isCurryDish) {
      curriesText = item.orderDetailCurries!
          .map((e) {
            if (e is Map<String, dynamic>) {
              final menuMap = e['menu'] as Map<String, dynamic>?;
              return (menuMap?['menuname'] ?? menuMap?['menuName'] ?? '')
                  .toString();
            }
            return '';
          })
          .where((name) => name.isNotEmpty)
          .join(", ");
    }

    String addonText = item.addons
        .map((addon) => addon.menuAddonDetail?.addonMenu?.addonName ?? '')
        .where((name) => name.isNotEmpty)
        .join(", ");

    int finalPricePerUnit;
    if (isCurryDish) {
      int curriesSum = 0;
      for (var curry in item.orderDetailCurries!) {
        if (curry is Map<String, dynamic>) {
          final num? price = curry['priceAtOrder'] as num?;
          curriesSum += (price ?? 0).toInt();
        }
      }
      final int riceBasePrice = item.menu?.price?.toInt() ?? 0;
      finalPricePerUnit = riceBasePrice + curriesSum;
    } else {
      int addonsSum = 0;
      for (var addon in item.addons) {
        addonsSum +=
            (addon.priceAtOrder ?? addon.menuAddonDetail?.addonPrice ?? 0)
                .toInt();
      }
      final int baseMenuPrice = item.menu?.price?.toInt() ?? 0;
      finalPricePerUnit = baseMenuPrice + addonsSum;
    }

    final String imageUrl = _getFinalImageUrl(item.menu?.menuImage);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 90,
            decoration: const BoxDecoration(
              color: Color(0xFF53D726),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 65,
                height: 65,
                color: Colors.grey.shade200,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        Uri.encodeFull(imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.fastfood, color: Colors.grey),
                      )
                    : const Icon(Icons.fastfood, color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayMenuName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (curriesText.isNotEmpty)
                    Text(
                      "กับข้าว: $curriesText",
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.green.shade700,
                      ),
                    ),
                  if (addonText.isNotEmpty)
                    Text(
                      "เพิ่มเติม: $addonText",
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  if (item.note.isNotEmpty)
                    Text(
                      "หมายเหตุ: ${item.note}",
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "ราคา $finalPricePerUnit บาท",
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        "x${item.qty}",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
