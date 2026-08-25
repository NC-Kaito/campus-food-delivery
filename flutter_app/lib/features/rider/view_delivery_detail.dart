import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/order_model.dart';
import 'package:flutter_app/data/models/order_detail_model.dart';
import 'package:flutter_app/data/services/order_service.dart';
import 'package:flutter_app/global_data.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';
import 'dart:math' show min, max;

class ViewDeliveryDetail extends StatefulWidget {
  final OrderModel orderModel;

  const ViewDeliveryDetail({super.key, required this.orderModel});

  @override
  State<ViewDeliveryDetail> createState() => _ViewWaitingPickupOrderState();
}

class _ViewWaitingPickupOrderState extends State<ViewDeliveryDetail> {
  final OrderService _orderService = OrderService();
  bool _isUpdating = false;

  GoogleMapController? _mapController;
  final Color primaryOrange = Colors.orange;

  Set<Polyline> _polylines = {};
  String _drivingDistance = "กำลังคำนวณ...";
  String _drivingDuration = "...";

  // 🎯 ตัวแปรเก็บค่าสถานะที่เลือกจาก Dropdown
  String? _selectedNextStatus;

  final String googleMapsApiKey = "ใส่_API_KEY_ของคุณที่นี่";

  @override
  void initState() {
    super.initState();
    _calculateDrivingRoute();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // 🎯 ฟังก์ชันดึงสถานะปัจจุบัน เพื่อบังคับว่าไรเดอร์อยู่ Step ไหน (เหลือ 2 Step)
  int _getCurrentRiderStep() {
    final status = (widget.orderModel.orderStatus ?? "").trim().toLowerCase();

    // Step 0: ออเดอร์กำลังเตรียม หรือไรเดอร์กำลังไปรับอาหาร
    // สถานะถัดไปที่ต้องทำ -> "รับอาหารแล้ว (เริ่มจัดส่ง)"
    if (status.contains("waitingrestaurant") ||
        status.contains("waitingrider") ||
        status.contains("goingtorestaurant") ||
        status.contains("riderarrived") ||
        status.contains("preparing") ||
        status.contains("cooking") ||
        status.contains("foodready")) {
      return 0;
    }
    // Step 1: ไรเดอร์รับอาหารแล้ว กำลังนำไปส่งลูกค้า
    // สถานะถัดไปที่ต้องทำ -> "จัดส่งสำเร็จ"
    else if (status.contains("delivery") ||
        status.contains("delivering") ||
        status.contains("ontheway") ||
        status.contains("pickedup")) {
      return 1;
    }
    // Step 2: จัดส่งสำเร็จแล้ว
    else if (status.contains("success") || status.contains("completed")) {
      return 2;
    }
    return -1; // อื่นๆ หรือยกเลิก
  }

  Future<void> _calculateDrivingRoute() async {
    final order = widget.orderModel;
    final double? restaurantLat = order.restaurant?.latitude;
    final double? restaurantLng = order.restaurant?.longitude;

    if (restaurantLat == null || restaurantLng == null) {
      setState(() => _drivingDistance = "ไม่พบพิกัดร้านค้า");
      return;
    }

    final String origin = "$restaurantLat,$restaurantLng";
    final String destination = "${order.latitude},${order.longitude}";
    final String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$googleMapsApiKey&language=th";

    try {
      Response response = await Dio().get(url);
      final data = response.data;

      if (data['status'] == 'OK') {
        final route = data['routes'][0];
        final leg = route['legs'][0];

        final distanceText = leg['distance']['text'];
        final durationText = leg['duration']['text'];

        final encodedPolyline = route['overview_polyline']['points'];
        List<LatLng> polylineCoordinates = _decodePolyline(encodedPolyline);

        if (mounted) {
          setState(() {
            _drivingDistance = distanceText;
            _drivingDuration = durationText;
            _polylines.add(
              Polyline(
                polylineId: const PolylineId("driving_route"),
                color: primaryOrange,
                width: 5,
                points: polylineCoordinates,
                jointType: JointType.round,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
              ),
            );
          });
        }
      } else {
        setState(() => _drivingDistance = "ไม่สามารถคำนวณเส้นทางได้");
      }
    } catch (e) {
      setState(() => _drivingDistance = "ข้อผิดพลาดในการโหลดเส้นทาง");
      debugPrint("Error fetching directions: $e");
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble()));
    }
    return poly;
  }

  void _setMapBounds(LatLng pos1, LatLng pos2) {
    if (_mapController == null) return;

    double minLat = min(pos1.latitude, pos2.latitude);
    double maxLat = max(pos1.latitude, pos2.latitude);
    double minLng = min(pos1.longitude, pos2.longitude);
    double maxLng = max(pos1.longitude, pos2.longitude);

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.0));
    });
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;
    final String baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/') ? "$baseUrl$rawPath" : "$baseUrl/$rawPath";
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 65,
      height: 65,
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

    List<Map<String, String>> curriesList = [];
    for (var e in rawCurries) {
      String name = '';
      String img = '';

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
                    menuMap['image'] ??
                    '')
                .toString();
      } else {
        try {
          name = (e.menu?.menuName ?? e.menu?.menuname ?? e.name ?? '')
              .toString();
          img =
              (e.menu?.menuImage ??
                      e.menu?.imageurl ??
                      e.menu?.imageUrl ??
                      e.image ??
                      '')
                  .toString();
        } catch (_) {}
      }

      if (name.isNotEmpty) {
        curriesList.add({'name': name, 'image': img});
      }
    }

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

    int finalPricePerUnit = 0;
    final int baseMenuPrice = item.menu?.price?.toInt() ?? 0;

    if (isCurryDish) {
      int curriesSum = 0;
      for (var curry in rawCurries) {
        if (curry is Map) {
          final num? price = curry['priceAtOrder'] ?? curry['priceatorder'];
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

    String rawMenuUrl = item.menu?.menuImage ?? '';
    if (rawMenuUrl.isEmpty && curriesList.isNotEmpty) {
      rawMenuUrl = curriesList.first['image'] ?? '';
    }
    final String finalMenuUrl = _getFinalImageUrl(rawMenuUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: primaryOrange, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: finalMenuUrl.isNotEmpty
                  ? Image.network(
                      Uri.encodeFull(finalMenuUrl),
                      width: 65,
                      height: 65,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderIcon(),
                    )
                  : _buildPlaceholderIcon(),
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

  Future<void> _updateStatus(String nextStatus, String successMessage) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );

    try {
      int orderId = widget.orderModel.orderId ?? 0;
      await _orderService.updateOrderStatus(orderId, nextStatus);

      if (!mounted) return;
      Navigator.pop(context); // ปิด Loading Dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.pop(context, true); // กลับไปหน้าก่อนหน้าและรีเฟรช
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      setState(() => _isUpdating = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🚨 อัปเดตสถานะไม่สำเร็จ: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🎯 สร้าง Widget แถบ Dropdown ให้เลือกสถานะ (เหลือ 2 ขั้นตอน)
  Widget _buildBottomStatusDropdown() {
    final int currentStep = _getCurrentRiderStep();

    // ถ้าออเดอร์สำเร็จแล้วหรือถูกยกเลิก ไม่ต้องแสดงแถบจัดการสถานะ
    if (currentStep < 0 || currentStep >= 2) {
      return const SizedBox.shrink();
    }

    // ตัวเลือกสถานะของไรเดอร์ (เหลือแค่ 2 สถานะ)
    final List<Map<String, dynamic>> statusOptions = [
      {
        'value': 'delivery',
        'label': '1. รับอาหารแล้ว (เริ่มจัดส่ง)',
        'step': 0,
      },
      {'value': 'Success', 'label': '2. จัดส่งสำเร็จ', 'step': 1},
    ];

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dropdown เลือกสถานะ (ตัวที่ไม่ได้คิวจะถูก Disabled)
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "อัปเดตสถานะถัดไป",
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              value: _selectedNextStatus,
              hint: const Text("กดเพื่อเลือกสถานะ"),
              items: statusOptions.map((option) {
                // 🎯 ล็อกให้กดได้เฉพาะ Step ถัดไปเท่านั้น! (ข้ามและย้อนกลับไม่ได้)
                final bool isEnabled = (option['step'] == currentStep);
                return DropdownMenuItem<String>(
                  value: option['value'],
                  enabled: isEnabled,
                  child: Text(
                    option['label'],
                    style: TextStyle(
                      color: isEnabled ? Colors.black87 : Colors.grey.shade400,
                      fontWeight: isEnabled
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedNextStatus = val;
                });
              },
            ),
            const SizedBox(height: 12),

            // ปุ่มกดยืนยันบันทึกข้อมูล
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_isUpdating || _selectedNextStatus == null)
                    ? null
                    : () {
                        String successMsg = "อัปเดตสถานะสำเร็จ";
                        if (_selectedNextStatus == "delivery") {
                          successMsg = "อัปเดตสถานะ: กำลังเดินทางไปส่งลูกค้า ";
                        } else if (_selectedNextStatus == "success") {
                          successMsg = "จัดส่งสำเร็จเรียบร้อย ";
                        }

                        _updateStatus(_selectedNextStatus!, successMsg);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: _isUpdating
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "บันทึกการเปลี่ยนสถานะ",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
    final String restaurantName =
        order.restaurant?.restaurantName ?? "ไม่ระบุชื่อร้าน";

    final double? restaurantLat = order.restaurant?.latitude;
    final double? restaurantLng = order.restaurant?.longitude;
    final bool hasRestaurantLocation =
        restaurantLat != null && restaurantLng != null;
    final LatLng? restaurantLocation = hasRestaurantLocation
        ? LatLng(restaurantLat, restaurantLng)
        : null;

    String memberFullName = "ไม่ระบุชื่อผู้รับ";
    if (order.member != null) {
      final String firstName = order.member?.firstname ?? "";
      final String lastName = order.member?.lastname ?? "";
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        memberFullName = "$firstName $lastName".trim();
      }
    }

    double deliveryFee = order.deliveryFee;
    double totalPrice = order.totalPrice;
    double subtotalPrice = totalPrice - deliveryFee;

    LatLng deliveryLocation = LatLng(order.latitude, order.longitude);

    String orderTimeText = "--:--";
    if (order.orderdate != null) {
      final DateTime dateTime = order.orderdate!;
      orderTimeText =
          "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} น.";
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryOrange),
        title: const Text(
          "รายละเอียดออเดอร์",
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
                      text: "K$orderId",
                      style: TextStyle(color: primaryOrange),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
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
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "เส้นทางจัดส่ง",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (restaurantLocation != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _drivingDuration != "..."
                          ? "≈ $_drivingDistance ($_drivingDuration)"
                          : _drivingDistance,
                      style: TextStyle(
                        color: primaryOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (restaurantLocation != null)
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: restaurantLocation,
                      zoom: 14.0,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _setMapBounds(restaurantLocation, deliveryLocation);
                    },
                    zoomControlsEnabled: false,
                    scrollGesturesEnabled: true,
                    polylines: _polylines,
                    markers: {
                      Marker(
                        markerId: const MarkerId('restaurant_pos'),
                        position: restaurantLocation,
                        infoWindow: const InfoWindow(title: 'ร้านค้า'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueOrange,
                        ),
                      ),
                      Marker(
                        markerId: const MarkerId('delivery_pos'),
                        position: deliveryLocation,
                        infoWindow: const InfoWindow(title: 'ลูกค้า'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ),
                      ),
                    },
                  ),
                ),
              )
            else
              Text(
                "ไม่พบตำแหน่งร้านค้าในระบบ",
                style: TextStyle(fontSize: 13.5, color: Colors.grey[600]),
              ),

            const SizedBox(height: 20),
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Icon(
                      Icons.storefront_rounded,
                      color: primaryOrange,
                      size: 24,
                    ),
                    Container(
                      height: 30,
                      width: 2,
                      color: Colors.grey.shade300,
                    ),
                    Icon(
                      Icons.location_on,
                      color: Colors.red.shade500,
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "รับที่ร้าน",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      Text(
                        restaurantName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "ส่งให้ลูกค้า",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      Text(
                        memberFullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (order.addressDetail.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "จุดสังเกต / รายละเอียดที่อยู่:",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.addressDetail,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
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
              itemCount: order.items.length,
              itemBuilder: (context, index) {
                return _buildOrderItemCard(order.items[index]);
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
                    color: primaryOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),

      // 🎯 แสดง Dropdown Bar อัปเดตสถานะ (2 สถานะ)
      bottomNavigationBar: _buildBottomStatusDropdown(),
    );
  }
}
