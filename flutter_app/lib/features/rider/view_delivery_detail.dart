// features/rider/view_delivery_detail.dart
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
  State<ViewDeliveryDetail> createState() => _ViewDeliveryDetailState();
}

class _ViewDeliveryDetailState extends State<ViewDeliveryDetail> {
  final OrderService _orderService = OrderService();
  bool _isUpdating = false;
  late String _currentStatus;

  GoogleMapController? _mapController;

  final Color primaryGreen = const Color(0xFF00B300);
  final Color accentGreen = const Color(0xFF64F02D);

  Set<Polyline> _polylines = {};
  String _drivingDistance = "กำลังคำนวณ...";
  String _drivingDuration = "...";

  final String googleMapsApiKey = "ใส่_API_KEY_ของคุณที่นี่";

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.orderModel.orderStatus ?? "";
    _calculateDrivingRoute();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  int _getCurrentRiderStep() {
    final status = _currentStatus
        .trim()
        .toLowerCase(); // 🎯 อ่านจากตัวแปร State

    if (status.isEmpty ||
        status == "waitingrider" ||
        status == "waitingrestaurant" ||
        status == "pending") {
      return 1;
    } else if (status == "preparing" ||
        status == "cooking" ||
        status == "foodready") {
      return 2;
    } else if (status == "goingtorestaurant" ||
        status == "going" ||
        status == "riderarrived") {
      return 3;
    } else if (status == "delivery" ||
        status == "delivering" ||
        status == "ontheway" ||
        status == "pickedup") {
      return 4;
    } else if (status == "arrived" || status == "reached") {
      return 5;
    } else if (status == "success" ||
        status == "completed" ||
        status == "reviewsuccess" ||
        status == "delivered") {
      return 6;
    }
    return 1;
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
                color: primaryGreen,
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
      final y = dt.year + 543;
      final hr = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return "$d/$m/$y $hr:$min น.";
    } catch (e) {
      return rawDate.toString();
    }
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.grey.shade100,
      child: Icon(Icons.fastfood_rounded, color: primaryGreen, size: 30),
    );
  }

  Widget _buildCustomerCard() {
    final member = widget.orderModel.member;
    String memberFullName = "ไม่ระบุชื่อลูกค้า";
    if (member != null) {
      final String firstName = member.firstname ?? "";
      final String lastName = member.lastname ?? "";
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        memberFullName = "$firstName $lastName".trim();
      }
    }

    String phone = member?.phone ?? member?.phone ?? "ไม่ระบุเบอร์ติดต่อ";
    String profileImg = _getFinalImageUrl(member?.profileimg);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: primaryGreen.withOpacity(0.15),
            backgroundImage: profileImg.isNotEmpty
                ? NetworkImage(profileImg)
                : null,
            child: profileImg.isEmpty
                ? Icon(Icons.person_rounded, size: 30, color: primaryGreen)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ข้อมูลลูกค้า",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  memberFullName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.phone_rounded, size: 14, color: primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      phone,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
          canIncreaseQty =
              (menu['canIncreaseQuantity'] ??
                  menu['allowQuantity'] ??
                  menu['isMultiple']) ==
              true;
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
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
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
                  height: 3,
                  color: isFirst
                      ? Colors.transparent
                      : (isCompleted ? primaryGreen : Colors.grey.shade300),
                ),
              ),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isCompleted ? primaryGreen : Colors.grey.shade300,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted
                        ? const Color(0xFF008000)
                        : Colors.grey.shade400,
                    width: 1,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 3,
                  color: isLast
                      ? Colors.transparent
                      : (isLineCompleted ? primaryGreen : Colors.grey.shade300),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: isCompleted ? Colors.black87 : Colors.grey.shade500,
              fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmActionDialog(
    String title,
    String content,
    String nextStatus,
    String successMsg,
  ) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.help_outline_rounded, color: primaryGreen, size: 28),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: Text(
          content,
          style: const TextStyle(fontSize: 14.5, height: 1.5),
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
              backgroundColor: primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "ยืนยัน",
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
      _updateStatus(nextStatus, successMsg);
    }
  }

  Future<void> _updateStatus(String nextStatus, String successMessage) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          Center(child: CircularProgressIndicator(color: primaryGreen)),
    );

    try {
      int orderId = widget.orderModel.orderId ?? 0;
      await _orderService.updateOrderStatus(orderId, nextStatus);

      if (!mounted) return;
      Navigator.pop(context); // ปิด Dialog โหลด

      // 🎯 อัปเดตตัวแปร State เพื่อเปลี่ยนหน้าตา UI ทันที
      setState(() {
        _currentStatus = nextStatus;
        _isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
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

  Widget _buildBottomPanel(int currentStep) {
    if (currentStep <= 0) return const SizedBox.shrink();

    String buttonText = "";
    String nextStatus = "";
    String successMsg = "";
    String dialogTitle = "";
    String dialogContent = "";
    IconData buttonIcon = Icons.hourglass_empty_rounded;
    bool isButtonEnabled = true;

    if (currentStep == 1) {
      buttonText = "รอร้านค้ายืนยันออเดอร์";
      isButtonEnabled = false;
      buttonIcon = Icons.access_time_rounded;
    } else if (currentStep == 2) {
      buttonText = "กำลังไปรับออเดอร์";
      nextStatus = "goingtorestaurant";
      successMsg = "อัปเดตสถานะ: กำลังเดินทางไปร้านอาหาร";
      dialogTitle = "ยืนยันการเดินทาง";
      dialogContent = "คุณกำลังออกเดินทางไปรับอาหารที่ร้านค้าใช่หรือไม่?";
      buttonIcon = Icons.directions_bike_rounded;
    } else if (currentStep == 3) {
      buttonText = "รับอาหารแล้ว (เริ่มจัดส่ง)";
      nextStatus = "delivery";
      successMsg = "อัปเดตสถานะ: เริ่มจัดส่งอาหารให้ลูกค้า";
      dialogTitle = "ยืนยันรับอาหาร";
      dialogContent =
          "คุณได้รับอาหารจากร้านค้าเรียบร้อยแล้ว และพร้อมออกเดินทางไปส่งให้ลูกค้าใช่หรือไม่?";
      buttonIcon = Icons.delivery_dining_rounded;
    } else if (currentStep == 4) {
      buttonText = "ถึงที่หมายแล้ว";
      nextStatus = "arrived";
      successMsg = "อัปเดตสถานะ: ถึงที่หมายแล้ว";
      dialogTitle = "ยืนยันถึงที่หมาย";
      dialogContent = "คุณเดินทางมาถึงจุดส่งอาหารของลูกค้าแล้วใช่หรือไม่?";
      buttonIcon = Icons.location_on_rounded;
    } else if (currentStep == 5) {
      buttonText = "จัดส่งสำเร็จ (รอลูกค้ายืนยัน)";
      nextStatus = "delivered";
      successMsg = "อัปเดตสถานะ: รอลูกค้ายืนยันรับอาหาร";
      dialogTitle = "ยืนยันการจัดส่งสำเร็จ";
      dialogContent =
          "คุณได้ส่งมอบอาหารให้ลูกค้าเรียบร้อยแล้วใช่หรือไม่?\n\n(เมื่อกดยืนยัน ระบบจะส่งแจ้งเตือนให้ลูกค้ายืนยันการรับในแอป)";
      buttonIcon = Icons.check_circle_outline_rounded;
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4FBF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryGreen.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimelineDot(
                    "รอร้านค้า\nยืนยัน",
                    currentStep >= 1,
                    currentStep >= 3,
                    isFirst: true,
                  ),
                  _buildTimelineDot(
                    "กำลัง\nไปรับ",
                    currentStep >= 3,
                    currentStep >= 4,
                  ),
                  _buildTimelineDot(
                    "กำลัง\nจัดส่ง",
                    currentStep >= 4,
                    currentStep >= 5,
                  ),
                  _buildTimelineDot(
                    "ถึงที่\nหมาย",
                    currentStep >= 5,
                    currentStep >= 6,
                  ),
                  _buildTimelineDot(
                    "จัดส่ง\nสำเร็จ",
                    currentStep >= 6,
                    false,
                    isLast: true,
                  ),
                ],
              ),
            ),
            if (currentStep < 6) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: (isButtonEnabled && !_isUpdating)
                      ? () => _confirmActionDialog(
                          dialogTitle,
                          dialogContent,
                          nextStatus,
                          successMsg,
                        )
                      : null,
                  icon: Icon(
                    buttonIcon,
                    color: isButtonEnabled ? Colors.black : Colors.white,
                  ),
                  label: Text(
                    buttonText,
                    style: TextStyle(
                      color: isButtonEnabled ? Colors.black : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isButtonEnabled
                        ? accentGreen
                        : Colors.grey.shade400,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                ),
              ),
            ],
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
    final String formattedDate = _formatDateTime(order.orderdate);
    final int currentStep = _getCurrentRiderStep();

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
                      style: TextStyle(color: primaryGreen),
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
                    Icons.calendar_today_rounded,
                    size: 15,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "สั่งซื้อเมื่อ: $formattedDate",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _buildCustomerCard(),
            const SizedBox(height: 20),
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
                      color: primaryGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _drivingDuration != "..."
                          ? "≈ $_drivingDistance ($_drivingDuration)"
                          : _drivingDistance,
                      style: TextStyle(
                        color: primaryGreen,
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
                      color: primaryGreen,
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
                    color: primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomPanel(currentStep),
    );
  }
}
