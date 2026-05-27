import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as toolkit;

class LocationOrderMember extends StatefulWidget {
  const LocationOrderMember({super.key});

  @override
  State<LocationOrderMember> createState() => _LocationOrderMemberState();
}

class _LocationOrderMemberState extends State<LocationOrderMember> {
  GoogleMapController? _mapController;
  LatLng? _deliveryPos; // เก็บพิกัดตำแหน่งจัดส่งอาหารของ Member

  // ✅ พิกัดแนวรั้วแม่โจ้ ดึงมาคุ้มครองความปลอดภัยระบบส่งอาหารในเขตพื้นที่
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
        _deliveryPos = position;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📍 ระบบส่งเฉพาะในเขตมหาวิทยาลัยแม่โจ้เท่านั้นคราบบบ'),
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
        title: const Text('ระบุตำแหน่งจัดส่งอาหาร'),
        backgroundColor:
            Colors.orange, // ปรับสีธีมหัวแอปเป็นโทนส้มของฝั่งผู้ซื้อ
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _mjuCenter,
              zoom: 16,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTap,
            markers: _deliveryPos == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId('delivery_location'),
                      position: _deliveryPos!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ), // หมุดส้มสไตล์สั่งซื้อ
                      infoWindow: const InfoWindow(
                        title: 'ตำแหน่งจัดส่งของคุณ',
                      ),
                    ),
                  },
            polygons: {
              Polygon(
                polygonId: const PolygonId("mju_delivery_fence"),
                points: _mjuFencePoints,
                fillColor: Colors.green.withOpacity(
                  0.15,
                ), // สีเขียวจางๆ คลุมแนวรั้วมหาลัย
                strokeColor: Colors.green.withOpacity(0.6),
                strokeWidth: 2,
              ),
            },
            myLocationEnabled: true,
          ),

          // ส่วนควบคุมสไลด์บาร์ด้านล่างเพื่อแสดงพิกัดและปุ่มกดยืนยันออเดอร์
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
                    "แตะบนแผนที่เพื่อปักหมุดจุดรับอาหาร",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_deliveryPos != null) ...[
                    Text(
                      "พิกัดรับของ: ${_deliveryPos!.latitude.toStringAsFixed(6)}, ${_deliveryPos!.longitude.toStringAsFixed(6)}",
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
                            0xFF5CFF33,
                          ), // สีเขียวสว่างสดใสตามสไตล์ปุ่มตะกร้าสั่งอาหารของคุณ
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          // 🎯 ส่งออบเจกต์พิกัด LatLng กลับคืนไปยังหน้ารวมสรุปบิลคำสั่งซื้อ
                          Navigator.pop(context, _deliveryPos);
                        },
                        child: const Text(
                          "ยืนยันตำแหน่งจัดส่งนี้",
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
