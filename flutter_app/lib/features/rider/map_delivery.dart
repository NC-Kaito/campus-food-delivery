// features/rider/map_delivery.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_app/data/models/order_model.dart';
import 'dart:math' show min, max;

class MapDelivery extends StatefulWidget {
  final OrderModel orderModel;

  const MapDelivery({super.key, required this.orderModel});

  @override
  State<MapDelivery> createState() => _MapDeliveryState();
}

class _MapDeliveryState extends State<MapDelivery> {
  GoogleMapController? _mapController;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  String _drivingDistance = "กำลังคำนวณ...";
  String _drivingDuration = "...";
  bool _isLoadingRoute = true;

  // 🚨 ข้อสำคัญ: นำ API Key ของ Google Maps ที่เปิดใช้งาน Directions API มาใส่ตรงนี้
  final String googleMapsApiKey = "ใส่_API_KEY_ของคุณที่นี่";

  @override
  void initState() {
    super.initState();
    _setupMapData();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _setupMapData() {
    final order = widget.orderModel;
    final double? restaurantLat = order.restaurant?.latitude;
    final double? restaurantLng = order.restaurant?.longitude;
    final double customerLat = order.latitude;
    final double customerLng = order.longitude;

    if (restaurantLat != null && restaurantLng != null) {
      // 1. สร้างหมุด (Markers)
      _markers = {
        Marker(
          markerId: const MarkerId('pickup_location'),
          position: LatLng(restaurantLat, restaurantLng),
          infoWindow: InfoWindow(
            title: 'จุดรับ: ${order.restaurant?.restaurantName ?? "ร้านค้า"}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
        Marker(
          markerId: const MarkerId('dropoff_location'),
          position: LatLng(customerLat, customerLng),
          infoWindow: const InfoWindow(title: 'จุดส่ง: ลูกค้า'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };

      // 2. ดึงเส้นทางจาก Google Directions API
      _calculateDrivingRoute(
        LatLng(restaurantLat, restaurantLng),
        LatLng(customerLat, customerLng),
      );
    } else {
      setState(() {
        _isLoadingRoute = false;
        _drivingDistance = "ไม่พบพิกัดร้านค้า";
      });
    }
  }

  // ── ฟังก์ชันดึงเส้นทาง ──
  Future<void> _calculateDrivingRoute(LatLng origin, LatLng destination) async {
    final String originStr = "${origin.latitude},${origin.longitude}";
    final String destStr = "${destination.latitude},${destination.longitude}";
    final String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=$originStr&destination=$destStr&key=$googleMapsApiKey&language=th";

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
                polylineId: const PolylineId("delivery_route"),
                color: Colors.blueAccent, // สีเส้นทาง
                width: 6,
                points: polylineCoordinates,
                jointType: JointType.round,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
              ),
            );
            _isLoadingRoute = false;
          });
        }
      } else {
        setState(() {
          _drivingDistance = "ไม่สามารถคำนวณเส้นทางได้";
          _isLoadingRoute = false;
        });
      }
    } catch (e) {
      setState(() {
        _drivingDistance = "ข้อผิดพลาดในการโหลดเส้นทาง";
        _isLoadingRoute = false;
      });
      debugPrint("Error fetching directions: $e");
    }
  }

  // ── ฟังก์ชันถอดรหัสเส้นทาง ──
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

  // ── ปรับกล้องให้เห็นทั้ง 2 จุด ──
  void _setMapBounds() {
    if (_mapController == null || _markers.length < 2) return;

    final order = widget.orderModel;
    final double? restaurantLat = order.restaurant?.latitude;
    final double? restaurantLng = order.restaurant?.longitude;
    final double customerLat = order.latitude;
    final double customerLng = order.longitude;

    if (restaurantLat == null || restaurantLng == null) return;

    double minLat = min(restaurantLat, customerLat);
    double maxLat = max(restaurantLat, customerLat);
    double minLng = min(restaurantLng, customerLng);
    double maxLng = max(restaurantLng, customerLng);

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 60.0), // Padding 60
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.orderModel;

    // ตั้งค่าเริ่มต้นกล้องไปที่ร้านค้า หรือพิกัดเริ่มต้นถ้าไม่มี
    final initialTarget =
        (order.restaurant?.latitude != null &&
            order.restaurant?.longitude != null)
        ? LatLng(order.restaurant!.latitude!, order.restaurant!.longitude!)
        : const LatLng(18.8920, 99.0145); // พิกัดสำรอง (ม.แม่โจ้)

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.orange),
        title: const Text(
          "แผนที่จัดส่ง",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // ── ตัวแผนที่ ──
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 15.0,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _setMapBounds();
            },
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // ── การ์ดสรุปข้อมูลเส้นทาง (ด้านบน) ──
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.storefront,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.restaurant?.restaurantName ?? "ร้านค้า",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, top: 4, bottom: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(
                        Icons.more_vert,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.addressDetail.isNotEmpty
                              ? order.addressDetail
                              : "จุดส่งลูกค้า",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── การ์ดระยะทาง/เวลา (ด้านล่าง) ──
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoadingRoute)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  else ...[
                    const Icon(
                      Icons.directions_bike_rounded,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "$_drivingDistance  •  $_drivingDuration",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── ปุ่มหาตำแหน่งปัจจุบัน (My Location) ──
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'myLocationBtn',
              backgroundColor: Colors.white,
              mini: true,
              onPressed: () {
                // TODO: ใส่ฟังก์ชันขอพิกัด Geolocator.getCurrentPosition() ตามที่เคยแนะนำไปก่อนหน้านี้
              },
              child: const Icon(Icons.my_location, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
