import 'dart:math' show min, max;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapRider extends StatefulWidget {
  final LatLng deliveryLocation;
  final LatLng? restaurantLocation;
  final String addressDetail;
  final String customerName;
  final String customerPhone;
  final Set<Polyline>? polylines; // 🎯 รับข้อมูลเส้นทางที่วาดไว้แล้วมาแสดงผล

  const GoogleMapRider({
    super.key,
    required this.deliveryLocation,
    this.restaurantLocation,
    required this.addressDetail,
    required this.customerName,
    required this.customerPhone,
    this.polylines, // 🎯 เพิ่มตรงนี้ครับ
  });

  @override
  State<GoogleMapRider> createState() => _GoogleMapRiderState();
}

class _GoogleMapRiderState extends State<GoogleMapRider> {
  GoogleMapController? _mapController;
  final Color primaryGreen = const Color(0xFF00B300);

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // 🎯 ฟังก์ชันสำหรับซูมกล้องให้ครอบคลุมทั้งร้านค้าและลูกค้า
  void _setMapBounds() {
    if (_mapController == null || widget.restaurantLocation == null) return;

    double minLat = min(
      widget.restaurantLocation!.latitude,
      widget.deliveryLocation.latitude,
    );
    double maxLat = max(
      widget.restaurantLocation!.latitude,
      widget.deliveryLocation.latitude,
    );
    double minLng = min(
      widget.restaurantLocation!.longitude,
      widget.deliveryLocation.longitude,
    );
    double maxLng = max(
      widget.restaurantLocation!.longitude,
      widget.deliveryLocation.longitude,
    );

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70.0));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('แผนที่จุดจัดส่ง'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryGreen),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.deliveryLocation,
                zoom: 15.0,
              ),
              onMapCreated: (controller) {
                _mapController = controller;

                if (widget.restaurantLocation != null) {
                  _setMapBounds();
                }

                // 🎯 สั่งให้ป้ายชื่อของฝั่งลูกค้าเด้งขึ้นมาโชว์ทันทีที่เปิดหน้าแผนที่
                Future.delayed(const Duration(milliseconds: 500), () {
                  _mapController?.showMarkerInfoWindow(
                    const MarkerId('delivery_spot'),
                  );
                });
              },
              polylines: widget.polylines ?? {}, // 🎯 วาดเส้นทางลงบนแผนที่
              markers: {
                Marker(
                  markerId: const MarkerId('delivery_spot'),
                  position: widget.deliveryLocation,
                  infoWindow: const InfoWindow(title: 'จุดส่งอาหารให้ลูกค้า'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
                ),
                if (widget.restaurantLocation != null)
                  Marker(
                    markerId: const MarkerId('restaurant_spot'),
                    position: widget.restaurantLocation!,
                    infoWindow: const InfoWindow(
                      title: 'จุดรับอาหาร (ร้านค้า)',
                    ), // 🎯 ป้ายฝั่งร้านค้า
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueOrange,
                    ),
                  ),
              },
              // 🎯 โชว์ตำแหน่งปัจจุบันของเรา (Rider) เป็นจุดสีฟ้า
              myLocationEnabled: true,
              // 🎯 มีปุ่มให้กดเลื่อนกล้องมาหาตำแหน่งตัวเองด้วยครับ
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
            ),
          ),

          // ── แผงข้อมูลลูกค้าด้านล่าง ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: primaryGreen, size: 28),
                      const SizedBox(width: 8),
                      const Text(
                        "ข้อมูลจุดจัดส่ง",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.customerName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: 14,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.customerPhone,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, color: Colors.black12),
                        ),
                        Text(
                          "รายละเอียดที่อยู่ / จุดสังเกต:",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.addressDetail.isNotEmpty
                              ? widget.addressDetail
                              : "ไม่ได้ระบุรายละเอียด",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "ปิดแผนที่",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                    ),
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
