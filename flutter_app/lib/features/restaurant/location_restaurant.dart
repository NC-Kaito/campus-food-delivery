import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as toolkit;

class LocationRestaurant extends StatefulWidget {
  final LatLng? initialLocation;

  const LocationRestaurant({super.key, this.initialLocation});

  @override
  State<LocationRestaurant> createState() => _LocationRestaurantState();
}

class _LocationRestaurantState extends State<LocationRestaurant> {
  GoogleMapController? _mapController;
  LatLng? _restaurantPos; // เก็บพิกัดทำเลที่ตั้งของร้านค้า

  // ✅ พิกัดแนวรั้วแม่โจ้ ควบคุมความปลอดภัยให้อยู่ในเขตพื้นที่
  final List<LatLng> _mjuFencePoints = [
    const LatLng(18.900653539070035, 99.00634349683372),
    const LatLng(18.90263618143217, 99.01050279812455),
    const LatLng(18.90174914656481, 99.01110207454354),
    const LatLng(18.90176431136493, 99.01120729143554),
    const LatLng(18.90081914893105, 99.01189945568586),
    const LatLng(18.901256377296036, 99.01255351998293),
    const LatLng(18.90107780250031, 99.01346753219514),
    const LatLng(18.900493883981, 99.0139235822802),
    const LatLng(18.90014940597669, 99.014790902551),
    const LatLng(18.89894110044976, 99.015589537462),
    const LatLng(18.899897537404627, 99.01646848963492),
    const LatLng(18.89959332976484, 99.01795228007023),
    const LatLng(18.89857197602754, 99.0184504551624),
    const LatLng(18.897050665798588, 99.0196024784849),
    const LatLng(18.89630835058682, 99.02077138147786),
    const LatLng(18.89475043271507, 99.02199122925754),
    const LatLng(18.893322834802163, 99.02265749474628),
    const LatLng(18.890450662133077, 99.02260785668284),
    const LatLng(18.891475227448694, 99.01900316977134),
    const LatLng(18.89282252776603, 99.01147943920455),
    const LatLng(18.893466687330644, 99.01039289860074),
    const LatLng(18.900655890821426, 99.00632808093258),
  ];

  static const LatLng _mjuCenter = LatLng(18.8920, 99.0145);

  @override
  void initState() {
    super.initState();
    // ดึงค่าพิกัดเก่าที่มีในฐานข้อมูลมาปักหมุดคอยไว้ก่อน
    _restaurantPos = widget.initialLocation;
  }

  // ตรวจสอบพิกัดว่าอยู่ในแนวรั้ว ม.แม่โจ้ ไหม
  bool _isInsideFence(LatLng tappedPoint) {
    var polygon = _mjuFencePoints
        .map((p) => toolkit.LatLng(p.latitude, p.longitude))
        .toList();
    var point = toolkit.LatLng(tappedPoint.latitude, tappedPoint.longitude);
    return toolkit.PolygonUtil.containsLocation(point, polygon, false);
  }

  void _onMapTap(LatLng position) {
    if (_isInsideFence(position)) {
      setState(() {
        _restaurantPos = position;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '📍 พิกัดร้านค้าต้องตั้งอยู่ภายในเขตมหาวิทยาลัยแม่โจ้เท่านั้นครับ',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ระบุพิกัดตั้งร้านค้า',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 🗺️ ตัวแผนที่หลัก
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _restaurantPos ?? _mjuCenter,
              zoom: 16,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTap,
            markers: _restaurantPos == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId('restaurant_location'),
                      position: _restaurantPos!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                      infoWindow: const InfoWindow(
                        title: 'ตำแหน่งร้านค้าของคุณ',
                      ),
                    ),
                  },
            polygons: {
              Polygon(
                polygonId: const PolygonId("mju_restaurant_fence"),
                points: _mjuFencePoints,
                fillColor: Colors.green.withOpacity(
                  0.15,
                ), // สีเขียวจางๆ คลุมแนวรั้วมหาลัย
                strokeColor: Colors.green.withOpacity(0.6),
                strokeWidth: 2,
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),

          // 🔘 ส่วนควบคุมบาร์สไลด์ด้านล่างแสดงพิกัดและปุ่มกดยืนยัน
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: 30,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "แตะบนแผนที่เพื่อปักหมุดทำเลที่ตั้งร้าน",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_restaurantPos != null) ...[
                    Text(
                      "พิกัดร้าน: ${_restaurantPos!.latitude.toStringAsFixed(6)}, ${_restaurantPos!.longitude.toStringAsFixed(6)}",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF5DF232,
                          ), // สีเขียวประจำฝั่งร้านค้า
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          // ส่งพิกัดกลับไปบันทึกที่หน้า Profile
                          Navigator.pop(context, _restaurantPos);
                        },
                        child: const Text(
                          "ยืนยันตำแหน่งร้านค้านี้",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ] else
                    const Text(
                      "กรุณาปักหมุดในขอบเขตสีเขียว (ภายใน ม.)",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
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
