import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as toolkit;

class TestMap extends StatefulWidget {
  const TestMap({super.key});

  @override
  State<TestMap> createState() => _TestMapState();
}

class _TestMapState extends State<TestMap> {
  GoogleMapController? _mapController;
  LatLng? _shopPos; // เก็บพิกัดร้านค้าที่จะเลือก

  // ✅ พิกัดแนวรั้วแม่โจ้ตามที่คุณได้ค่ามา
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
        _shopPos = position;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📍 กรุณาเลือกตำแหน่งภายในเขตมหาวิทยาลัยเท่านั้น'),
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
        title: const Text('เลือกตำแหน่งที่ตั้งร้าน'),
        backgroundColor: Colors.green,
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
            markers: _shopPos == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId('shop'),
                      position: _shopPos!,
                      infoWindow: const InfoWindow(title: 'ตำแหน่งร้านค้า'),
                    ),
                  },
            polygons: {
              Polygon(
                polygonId: const PolygonId("mju_fence"),
                points: _mjuFencePoints,
                fillColor: Colors.green.withOpacity(0.25),
                strokeColor: Colors.green.withOpacity(0.9),
                strokeWidth: 2,
              ),
            },
            myLocationEnabled: true,
          ),

          // ส่วนแสดงข้อมูลและปุ่มยืนยัน
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "แตะบนแผนที่เพื่อระบุตำแหน่งร้าน",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_shopPos != null) ...[
                    Text(
                      "พิกัด: ${_shopPos!.latitude.toStringAsFixed(6)}, ${_shopPos!.longitude.toStringAsFixed(6)}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () {
                          // ✅ ส่งพิกัดกลับไปยังหน้า RegisterRestaurant
                          Navigator.pop(context, _shopPos);
                        },
                        child: const Text(
                          "ยืนยันตำแหน่งนี้",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ] else
                    const Text(
                      "กรุณาปักหมุดในเขตพื้นที่สีเขียว",
                      style: TextStyle(color: Colors.redAccent),
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
