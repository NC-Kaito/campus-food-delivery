// features/member/view_confirm_order_member.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/member_model.dart';
import 'package:flutter_app/data/models/order_detail_model.dart';
import 'package:flutter_app/data/models/order_model.dart';
import 'package:flutter_app/data/services/member/member_service.dart';
import 'package:flutter_app/global_data.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_app/core/network/dio_client.dart';

class ViewConfirmOrderMember extends StatefulWidget {
  final OrderModel order;

  const ViewConfirmOrderMember({super.key, required this.order});

  @override
  State<ViewConfirmOrderMember> createState() => _ViewConfirmOrderMemberState();
}

class _ViewConfirmOrderMemberState extends State<ViewConfirmOrderMember> {
  GoogleMapController? _miniMapController;

  String _loggedInMemberName = "กำลังโหลด...";
  String _loggedInMemberPhone = "กำลังโหลด...";

  final MemberService memberService = MemberService();

  final Color primaryGreen = const Color(0xFF64F02D);

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

  // 🎯 ไอคอนฝั่งซ้ายปรับเป็นสีส้มเข้าโทนกัน
  Widget _buildPlaceholderIcon() {
    return Container(
      width: 65,
      height: 65,
      color: Colors.orange.shade50,
      child: const Icon(Icons.fastfood_rounded, color: Colors.orange, size: 30),
    );
  }

  Widget _buildOrderItemCard(OrderDetailModel item) {
    // 🎯 1. ดึงรายการกับข้าวจากหลายๆ รูปแบบคีย์ที่เป็นไปได้ (ป้องกันคีย์ไม่ตรง)
    List<dynamic> rawCurries = [];
    if (item.orderDetailCurries != null &&
        item.orderDetailCurries!.isNotEmpty) {
      rawCurries = item.orderDetailCurries!;
    } else if ((item as dynamic).toJson()['orderDetailCurries'] != null) {
      rawCurries = (item as dynamic).toJson()['orderDetailCurries'];
    } else if ((item as dynamic).toJson()['orderdetailcurries'] != null) {
      rawCurries = (item as dynamic).toJson()['orderdetailcurries'];
    }

    final bool isCurryDish = rawCurries.isNotEmpty;
    String displayMenuName = item.menu?.menuName ?? "รายการเมนู";
    if (isCurryDish) {
      displayMenuName = "ข้าวราดแกง (${rawCurries.length} อย่าง)";
    }

    // แกะรายชื่อและรูปกับข้าว
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

        if (name.isNotEmpty) {
          curriesList.add({'name': name, 'image': img});
        }
      }
    }

    // 🎯 2. ดึงรายการ Add-on จากทุกช่องทางที่เป็นไปได้ พร้อมนับจำนวน (เช่น ไข่ดาว x3)
    List<dynamic> rawAddons = [];
    if (item.addons.isNotEmpty) {
      rawAddons = item.addons;
    } else if ((item as dynamic).toJson()['addons'] != null) {
      rawAddons = (item as dynamic).toJson()['addons'];
    }

    Map<String, int> addonCounts = {};
    for (var addon in rawAddons) {
      String name = '';
      if (addon is Map) {
        name =
            addon['menuAddonDetail']?['addonMenu']?['addonName'] ??
            addon['addonMenu']?['addonName'] ??
            addon['name'] ??
            '';
      } else {
        name = addon.menuAddonDetail?.addonMenu?.addonName ?? '';
      }

      if (name.isNotEmpty) {
        addonCounts[name] = (addonCounts[name] ?? 0) + 1;
      }
    }

    // 🎯 3. คำนวณราคาต่อหน่วย
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
          p = addon.priceAtOrder ?? addon.menuAddonDetail?.addonPrice;
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
          p = addon.priceAtOrder ?? addon.menuAddonDetail?.addonPrice;
        }
        addonsSum += (p ?? 0).toInt();
      }
      finalPricePerUnit = baseMenuPrice + addonsSum;
    }

    final String finalMenuUrl = _getFinalImageUrl(item.menu?.menuImage);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: primaryGreen, width: 4)),
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

                  // แสดงผลกับข้าวทุกอย่างแบบ Badge พร้อมรูปภาพ
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

                  // แสดงผล Add-on แบบ Badge สีส้ม พร้อมรวมจำนวน (เช่น ไข่ดาว x3)
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
                            ? const Color(0xFF64F02D)
                            : Colors.grey.shade300),
                ),
              ),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF64F02D)
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
                            ? const Color(0xFF64F02D)
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
              fontSize: 11,
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

    if (status.contains("waitingrestaurant") || status.contains("cooking")) {
      currentStep = 2;
    } else if (status.contains("delivery") || status.contains("pickedup")) {
      currentStep = 3;
    } else if (status.contains("success") || status.contains("completed")) {
      currentStep = 4;
    }

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
            const SizedBox(height: 24),

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
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
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
                    "รอผู้จัดส่ง\nรับงาน",
                    currentStep >= 1,
                    currentStep >= 2,
                    isFirst: true,
                  ),
                  _buildTimelineDot(
                    "รอร้านค้า\nยืนยัน",
                    currentStep >= 2,
                    currentStep >= 3,
                  ),
                  _buildTimelineDot(
                    "กำลังจัดส่ง",
                    currentStep >= 3,
                    currentStep >= 4,
                  ),
                  _buildTimelineDot(
                    "จัดส่ง\nสำเร็จ",
                    currentStep >= 4,
                    currentStep >= 5,
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
    );
  }
}
