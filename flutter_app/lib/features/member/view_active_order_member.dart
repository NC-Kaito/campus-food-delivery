// features/member/view_confirm_order_member.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/member_model.dart';
import 'package:flutter_app/data/models/order_detail_model.dart';
import 'package:flutter_app/data/models/order_model.dart';
import 'package:flutter_app/data/services/member/member_service.dart';
import 'package:flutter_app/data/services/order_service.dart';
import 'package:flutter_app/global_data.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/features/member/cancel_order_member.dart';
import 'package:flutter_app/features/member/member_review.dart';
import 'package:flutter_app/features/member/view_review.dart';
import 'package:flutter_app/features/member/view_receipt_order.dart';

class ViewActiveOrderMember extends StatefulWidget {
  final OrderModel order;

  const ViewActiveOrderMember({super.key, required this.order});

  @override
  State<ViewActiveOrderMember> createState() => _ViewConfirmOrderMemberState();
}

class _ViewConfirmOrderMemberState extends State<ViewActiveOrderMember> {
  GoogleMapController? _miniMapController;

  String _loggedInMemberName = "กำลังโหลด...";
  String _loggedInMemberPhone = "กำลังโหลด...";

  final MemberService memberService = MemberService();
  final OrderService _orderService = OrderService();
  final Color primaryGreen = const Color(0xFF00B300);

  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentMemberProfile();
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;

    final String baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/') ? "$baseUrl$rawPath" : "$baseUrl/$rawPath";
  }

  Future<void> _loadCurrentMemberProfile() async {
    try {
      String username = GlobalData.usernameMember;
      MemberModel mModel = await memberService.getMemberByUsername(username);

      if (mounted) {
        setState(() {
          _loggedInMemberName =
              "${mModel.firstname ?? ''} ${mModel.lastname ?? ''}".trim();
          if (_loggedInMemberName.isEmpty) {
            _loggedInMemberName = mModel.username ?? "ไม่ระบุชื่อ";
          }
          _loggedInMemberPhone = mModel.phone ?? "ไม่ระบุเบอร์โทร";
        });
      }
    } catch (e) {
      debugPrint("Error loading member profile: $e");
      if (mounted) {
        setState(() {
          _loggedInMemberName = "ไม่สามารถดึงข้อมูลได้";
          _loggedInMemberPhone = "ไม่ระบุเบอร์โทร";
        });
      }
    }
  }

  @override
  void dispose() {
    _miniMapController?.dispose();
    super.dispose();
  }

  // 🎯 ฟังก์ชันคำนวณช่วงเวลาที่จะได้รับอาหาร (+25 ถึง +40 นาที จากเวลาสั่งซื้อ)
  String _getEstimatedTimeRange(dynamic rawDate) {
    if (rawDate == null) return "25 - 40 นาที";
    try {
      DateTime dt;
      if (rawDate is DateTime) {
        dt = rawDate.toLocal();
      } else {
        dt = DateTime.tryParse(rawDate.toString())?.toLocal() ?? DateTime.now();
      }
      DateTime minTime = dt.add(const Duration(minutes: 25));
      DateTime maxTime = dt.add(const Duration(minutes: 40));

      String minHour = minTime.hour.toString().padLeft(2, '0');
      String minMinute = minTime.minute.toString().padLeft(2, '0');
      String maxHour = maxTime.hour.toString().padLeft(2, '0');
      String maxMinute = maxTime.minute.toString().padLeft(2, '0');

      return "$minHour:$minMinute - $maxHour:$maxMinute น.";
    } catch (e) {
      return "25 - 40 นาที";
    }
  }

  // 🎯 แปลงวันที่และเวลาแบบไทย
  String _formatThaiDateTime(dynamic rawDate) {
    if (rawDate == null) return "-";
    DateTime d;
    if (rawDate is DateTime) {
      d = rawDate.toLocal();
    } else {
      d = DateTime.tryParse(rawDate.toString())?.toLocal() ?? DateTime.now();
    }
    final months = [
      "ม.ค.",
      "ก.พ.",
      "มี.ค.",
      "เม.ย.",
      "พ.ค.",
      "มิ.ย.",
      "ก.ค.",
      "ส.ค.",
      "ก.ย.",
      "ต.ค.",
      "พ.ย.",
      "ธ.ค.",
    ];
    final year = d.year + 543;
    final hr = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return "${d.day} ${months[d.month - 1]} $year เวลา $hr:$min น.";
  }

  Future<void> _confirmOrderReceived() async {
    if (_isConfirming) return;
    setState(() => _isConfirming = true);

    try {
      int orderId = widget.order.orderId ?? 0;
      await _orderService.updateOrderStatus(orderId, "Success");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🎉 ยืนยันการรับอาหารสำเร็จ! ขอบคุณที่ใช้บริการครับ"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isConfirming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🚨 เกิดข้อผิดพลาด ไม่สามารถยืนยันได้: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openReceiptPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewReceiptOrder(
          order: widget.order,
          memberName: _loggedInMemberName,
          memberPhone: _loggedInMemberPhone,
        ),
      ),
    );
  }

  Future<void> _confirmReportIssue() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.help_outline_rounded,
              color: Colors.orange.shade700,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              "ยืนยันการแจ้งปัญหา",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        content: const Text(
          "คุณต้องการแจ้งปัญหา 'อาหารไม่ตรงกับออเดอร์' ใช่หรือไม่?\n\n(คุณจำเป็นต้องถ่ายรูปอาหารที่ได้รับผิดเพื่อใช้เป็นหลักฐานในการตรวจสอบ)",
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "ยกเลิก",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "ใช่, ดำเนินการต่อ",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CancelOrderMember(orderId: widget.order.orderId ?? 0),
        ),
      ).then((result) {
        if (result == true) {
          Navigator.pop(context, true);
        }
      });
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

  Widget _buildOrderItemCard(OrderDetailModel item) {
    List<dynamic> rawCurries = [];
    if (item.orderDetailCurries != null &&
        item.orderDetailCurries!.isNotEmpty) {
      rawCurries = item.orderDetailCurries!;
    } else {
      try {
        final jsonItem = (item as dynamic).toJson();
        rawCurries =
            jsonItem['orderDetailCurries'] ??
            jsonItem['orderdetailcurries'] ??
            [];
      } catch (_) {}
    }

    final bool isCurryDish = rawCurries.isNotEmpty;
    String displayMenuName = item.menu?.menuName ?? "รายการเมนู";
    if (isCurryDish) {
      displayMenuName = "ข้าวราดแกง (${rawCurries.length} อย่าง)";
    }

    List<Map<String, dynamic>> curriesList = [];
    for (var e in rawCurries) {
      String name = '';
      String img = '';
      int price = 0;

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
        price = (e['priceAtOrder'] ?? e['priceatorder'] ?? 0).toInt();
      } else {
        try {
          name =
              ((e as dynamic).menu?.menuName ??
                      (e as dynamic).menu?.menuname ??
                      (e as dynamic).name ??
                      '')
                  .toString();
          img =
              ((e as dynamic).menu?.menuImage ??
                      (e as dynamic).menu?.imageurl ??
                      (e as dynamic).menu?.imageUrl ??
                      (e as dynamic).image ??
                      '')
                  .toString();
          price = ((e as dynamic).priceAtOrder ?? 0).toInt();
        } catch (_) {}
      }

      if (name.isNotEmpty) {
        curriesList.add({'name': name, 'image': img, 'price': price});
      }
    }

    List<dynamic> rawAddons = [];
    if (item.addons.isNotEmpty) {
      rawAddons = item.addons;
    } else {
      try {
        rawAddons = (item as dynamic).toJson()['addons'] ?? [];
      } catch (_) {}
    }

    Map<String, Map<String, dynamic>> groupedAddons = {};
    for (var addon in rawAddons) {
      String name = '';
      int price = 0;
      int qty = 1;
      bool canIncreaseQty = false;

      if (addon is Map) {
        name =
            addon['menuAddonDetail']?['addonMenu']?['addonName'] ??
            addon['addonMenu']?['addonName'] ??
            addon['name'] ??
            '';
        price =
            (addon['priceAtOrder'] ??
                    addon['menuAddonDetail']?['addonPrice'] ??
                    0)
                .toInt();
        qty = (addon['addonQty'] ?? addon['addon_qty'] ?? 1).toInt();

        final dynamic menu =
            addon['menuAddonDetail']?['addonMenu'] ??
            addon['addonMenu'] ??
            addon['menuAddon'];

        if (menu != null) {
          if (menu['canIncreaseQuantity'] != null) {
            canIncreaseQty = menu['canIncreaseQuantity'] == true;
          } else if (menu['allowQuantity'] != null) {
            canIncreaseQty = menu['allowQuantity'] == true;
          } else if (menu['isMultiple'] != null) {
            canIncreaseQty = menu['isMultiple'] == true;
          } else if (menu['isQuantity'] != null) {
            canIncreaseQty = menu['isQuantity'] == true;
          } else if (menu['maxQuantity'] != null) {
            canIncreaseQty = (menu['maxQuantity'] as num) > 1;
          } else if (menu['maxQty'] != null) {
            canIncreaseQty = (menu['maxQty'] as num) > 1;
          } else if (menu['addonType'] != null) {
            final typeStr = menu['addonType'].toString().toLowerCase();
            canIncreaseQty =
                !typeStr.contains('radio') && !typeStr.contains('single');
          }
        }
      } else {
        try {
          name = (addon as dynamic).menuAddonDetail?.addonMenu?.addonName ?? '';
          price =
              ((addon as dynamic).priceAtOrder ??
                      (addon as dynamic).menuAddonDetail?.addonPrice ??
                      0)
                  .toInt();
          qty = ((addon as dynamic).addonQty ?? 1).toInt();

          final dynamic menu =
              (addon as dynamic).menuAddonDetail?.addonMenu ??
              (addon as dynamic).addonMenu;

          if (menu != null) {
            if (menu.canIncreaseQuantity != null) {
              canIncreaseQty = menu.canIncreaseQuantity == true;
            } else if (menu.allowQuantity != null) {
              canIncreaseQty = menu.allowQuantity == true;
            } else if (menu.isMultiple != null) {
              canIncreaseQty = menu.isMultiple == true;
            } else if (menu.maxQuantity != null) {
              canIncreaseQty = (menu.maxQuantity as num) > 1;
            }
          }
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
            'canIncreaseQty': canIncreaseQty,
          };
        }
      }
    }

    int totalItemPrice = 0;
    int addonsSum = 0;
    for (var addon in groupedAddons.values) {
      addonsSum += (addon['unitPrice'] as int) * (addon['qty'] as int);
    }

    try {
      final jsonItem = (item as dynamic).toJson();
      var rawSubtotal = jsonItem['subtotal'] ?? jsonItem['subTotal'];
      if (rawSubtotal != null) {
        totalItemPrice = (rawSubtotal as num).toInt();
      }
    } catch (_) {}

    if (totalItemPrice == 0) {
      int baseMenuPrice = item.menu?.price?.toInt() ?? 0;
      if (baseMenuPrice == 0) {
        try {
          final jsonItem = (item as dynamic).toJson();
          baseMenuPrice = (jsonItem['menu']?['price'] ?? 0).toInt();
        } catch (_) {}
      }
      int curriesSum = 0;
      for (var curry in curriesList) {
        curriesSum += curry['price'] as int;
      }
      int baseUnitNoAddonPrice = baseMenuPrice + curriesSum;
      totalItemPrice = (baseUnitNoAddonPrice + addonsSum) * item.qty;
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
                        "$totalItemPrice บาท",
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
                                                      "${entry.value['qty']} ",
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
                      "หมายเหตุ: ${item.note}",
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
                      "${item.qty} จำนวน",
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

  @override
  Widget build(BuildContext context) {
    double deliveryFee = widget.order.deliveryFee;
    double totalPrice = widget.order.totalPrice;
    double subtotalPrice = totalPrice - deliveryFee;

    LatLng deliveryLocation = LatLng(
      widget.order.latitude,
      widget.order.longitude,
    );

    String status = (widget.order.orderStatus ?? "").toLowerCase();

    int currentStep = 1;

    if (status.contains("waitingrestaurant") ||
        status.contains("cooking") ||
        status.contains("preparing")) {
      currentStep = 2;
    } else if (status.contains("rideraccepted") ||
        status.contains("riderarrived") ||
        status.contains("goingtorestaurant") ||
        status.contains("going")) {
      currentStep = 3;
    } else if (status.contains("delivery") ||
        status.contains("delivering") ||
        status.contains("ontheway") ||
        status.contains("pickedup")) {
      currentStep = 4;
    } else if (status.contains("arrived") || status.contains("reached")) {
      currentStep = 5;
    } else if (status.contains("delivered") ||
        status.contains("success") ||
        status.contains("completed") ||
        status.contains("reviewsuccess")) {
      currentStep = 6;
    }

    final bool isCanceled =
        status.contains("cancel") || status.contains("issue_reported");
    final bool isCompleted =
        status == 'success' ||
        status == 'completed' ||
        status == 'reviewsuccess';
    final bool isReviewed = status == 'reviewsuccess';
    final bool isWaitingConfirm = status == 'delivered';

    // 🎯 แยกสถานะจัดส่งเรียบร้อยแล้ว (delivered, success, completed, reviewsuccess)
    final bool isDeliveredOrFinished = isWaitingConfirm || isCompleted;
    // 🎯 ออเดอร์ที่อยู่ระหว่างดำเนินการจัดส่งจริง (ยังไม่ส่งถึงมือลูกค้า)
    final bool isOngoing = !isDeliveredOrFinished && !isCanceled;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryGreen),
        title: const Text(
          "รายละเอียดคำสั่งซื้อ",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: RichText(
                text: TextSpan(
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
                      text:
                          "K${widget.order.orderId?.toString().padLeft(6, '0') ?? '000000'}",
                      style: TextStyle(color: primaryGreen),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 🎯 1. แสดงกล่องประมาณการเวลา (เฉพาะออเดอร์ที่ยังจัดส่งไม่เสร็จ)
            if (isOngoing) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8FCD0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryGreen.withOpacity(0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.timer_outlined,
                        color: primaryGreen,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "ประมาณการเวลาที่จะได้รับอาหาร",
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                _getEstimatedTimeRange(widget.order.orderdate),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.green.shade900,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "(25 - 40 นาที)",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 🎯 2. สลับมาแสดงกล่องวันเวลาที่จัดส่งเสร็จสิ้น (เมื่อส่งสำเร็จแล้ว/รอยืนยัน/รอรีวิว)
            if (isDeliveredOrFinished) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryGreen.withOpacity(0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: primaryGreen,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "จัดส่งอาหารสำเร็จเรียบร้อยแล้ว",
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatThaiDateTime(widget.order.orderdate),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            const Text(
              "จัดส่งโดย",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.order.rider != null)
              Row(
                children: [
                  const Icon(
                    Icons.delivery_dining,
                    size: 40,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ชื่อ : ${widget.order.rider!.firstName ?? ''} ${widget.order.rider!.lastName ?? ''}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "เบอร์โทรศัพท์ : ${widget.order.rider!.phone ?? '-'}",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  Icon(Icons.hourglass_empty, size: 30, color: primaryGreen),
                  const SizedBox(width: 12),
                  Text(
                    "สถานะ: กำลังรอผู้จัดส่งรับงาน...",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 16),

            const Text(
              "สถานะคำสั่งซื้อ",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),

            if (isCanceled)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: status.contains("cancel")
                      ? Colors.red.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: status.contains("cancel")
                        ? Colors.red.shade200
                        : Colors.orange.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          status.contains("cancel")
                              ? Icons.cancel_rounded
                              : Icons.support_agent_rounded,
                          color: status.contains("cancel")
                              ? Colors.red.shade700
                              : Colors.orange.shade700,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            status.contains("cancel")
                                ? "คำสั่งซื้อนี้ถูกยกเลิกแล้ว"
                                : "มีการแจ้งปัญหาออเดอร์นี้\nกรุณาติดต่อร้านค้าเพื่อเคลียร์ปัญหา",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: status.contains("cancel")
                                  ? Colors.red.shade700
                                  : Colors.orange.shade800,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (status.contains("cancel")) ...[
                      const SizedBox(height: 8),
                      Text(
                        "สาเหตุ: ${widget.order.cancelDetail ?? 'ไม่มีผู้จัดส่งรับงานภายในเวลาที่กำหนด'}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Colors.black12),
                    const SizedBox(height: 12),
                    const Text(
                      "ข้อมูลติดต่อร้านค้า:",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.storefront_rounded,
                          size: 20,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.order.restaurant?.restaurantName ??
                                "ไม่ระบุชื่อร้าน",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_in_talk_rounded,
                          size: 20,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.order.restaurant?.phone ?? "ไม่ระบุเบอร์โทร",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
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
            const SizedBox(height: 24),

            const Text(
              "ข้อมูลผู้สั่งซื้อ",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 28,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ชื่อผู้รับ",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _loggedInMemberName,
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
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.phone_in_talk_outlined,
                        size: 28,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "เบอร์โทรศัพท์",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _loggedInMemberPhone,
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
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 16),

            Row(
              children: [
                const Text(
                  "ที่อยู่จัดส่ง",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      markerId: const MarkerId('history_delivery_pos'),
                      position: deliveryLocation,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                    ),
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.order.addressDetail.isNotEmpty) ...[
              Text(
                "จุดสังเกต / รายละเอียดที่อยู่:",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.order.addressDetail,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 16),

            const Text(
              "รายการอาหาร",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.order.items.length,
              itemBuilder: (context, index) {
                return _buildOrderItemCard(widget.order.items[index]);
              },
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "ราคารวมสินค้า",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  "${subtotalPrice.toStringAsFixed(0)} บาท",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "ค่าจัดส่ง",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  "${deliveryFee.toStringAsFixed(0)} บาท",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "ยอดรวมทั้งสิ้น",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "${totalPrice.toStringAsFixed(0)} บาท",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: () {
        if (isCanceled) {
          return null;
        }

        if (isWaitingConfirm) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isConfirming ? null : _confirmOrderReceived,
                      icon: _isConfirming
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                            ),
                      label: Text(
                        _isConfirming
                            ? "กำลังยืนยัน..."
                            : "ยืนยันได้รับอาหารแล้ว",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _confirmReportIssue,
                      icon: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                      ),
                      label: const Text(
                        "แจ้งปัญหาอาหาร (ได้ไม่ครบ/ผิด)",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (isCompleted) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isReviewed)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MemberReview(order: widget.order),
                            ),
                          ).then((result) {
                            if (result == true) Navigator.pop(context, true);
                          });
                        },
                        icon: const Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "รีวิวคำสั่งซื้อ",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  if (!isReviewed) const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _openReceiptPage,
                      icon: const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.blue,
                      ),
                      label: const Text(
                        "ใบเสร็จคำสั่งซื้อ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.blue, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.blue.shade50,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return null;
      }(),
    );
  }
}
