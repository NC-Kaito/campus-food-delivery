// edit_location_member.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as toolkit;
import 'package:flutter_app/data/models/member_model.dart';
import 'package:flutter_app/data/services/member/member_service.dart';
import 'package:flutter_app/global_data.dart';

class EditLocationMember extends StatefulWidget {
  const EditLocationMember({super.key});

  @override
  State<EditLocationMember> createState() => _EditLocationMemberState();
}

class _EditLocationMemberState extends State<EditLocationMember> {
  GoogleMapController? _mapController;
  LatLng? _deliveryPos;

  // 🎯 เก็บค่าเริ่มต้นที่ดึงมาจาก Database เพื่อใช้ย้อนคืนค่า
  LatLng? _initialDeliveryPos;
  String _initialAddressDetail = "";

  final TextEditingController _addressDetailController =
      TextEditingController();
  final MemberService _memberService = MemberService();
  bool _isLoading = true;
  bool _isSaving = false;

  // ✅ 1. ขอบเขตรั้วแม่โจ้
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

  static const LatLng _defaultCenter = LatLng(18.896818, 99.013033);

  // 🎯 2. ข้อมูลสถานที่สำคัญ/อาคาร ใน ม.แม่โจ้
  final List<Map<String, dynamic>> _campusBuildings = [
    {"name": "อาคารเรียนรวม 70 ปี", "pos": const LatLng(18.894925, 99.010925)},
    {"name": "อาคารเรียนรวม 80 ปี", "pos": const LatLng(18.895130, 99.011695)},
    {
      "name": "อาคาร 60 ปี คณะวิทยาศาสตร์",
      "pos": const LatLng(18.895828, 99.012991),
    },
    {
      "name": "ตึกคณะพัฒนาการท่องเที่ยว",
      "pos": const LatLng(18.895481, 99.010917),
    },
    {"name": "ตึกคณะศิลปศาสตร์", "pos": const LatLng(18.895881, 99.011956)},
    {
      "name": "อาคารเสาวรัจ นิตยวรรธนะ ",
      "pos": const LatLng(18.896203, 99.012749),
    },
    {"name": "ตึกคณะบริหารธุรกิจ", "pos": const LatLng(18.895249, 99.013292)},
    {
      "name": "คณะวิศวกรรมและอุตสาหกรรมเกษตร",
      "pos": const LatLng(18.8980, 99.0125),
    },
    {"name": "สำนักหอสมุด", "pos": const LatLng(18.895297, 99.012338)},
    {"name": "กาดโดม (โรงอาหาร)", "pos": const LatLng(18.8950, 99.0155)},
    {"name": "หอพักหญิง 1", "pos": const LatLng(18.8990, 99.0180)},
    {"name": "หอพักชาย 1", "pos": const LatLng(18.8985, 99.0190)},
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _addressDetailController.dispose();
    super.dispose();
  }

  // 🎯 ดึงพิกัดและที่อยู่ที่เคยบันทึกไว้ และจำค่าเริ่มต้นไว้
  Future<void> _loadSavedLocation() async {
    try {
      MemberModel member = await _memberService.getMemberByUsername(
        GlobalData.usernameMember,
      );

      if (mounted) {
        setState(() {
          if (member.latitude != null && member.longitude != null) {
            _deliveryPos = LatLng(member.latitude!, member.longitude!);
            _initialDeliveryPos = _deliveryPos; // จำพิกัดเริ่มต้น
          }

          if (member.defaultlocation != null &&
              member.defaultlocation!.isNotEmpty) {
            _addressDetailController.text = member.defaultlocation!;
            _initialAddressDetail =
                member.defaultlocation!; // จำข้อความเริ่มต้น
          }

          _isLoading = false;
        });

        if (_deliveryPos != null && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_deliveryPos!, 17.0),
          );
        }
      }
    } catch (e) {
      debugPrint("Error loading member location: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🎯 ฟังก์ชันย้อนกลับไปใช้พิกัดและที่อยู่เริ่มต้นที่ดึงมาจาก DB
  void _resetToDefaultLocation() {
    FocusScope.of(context).unfocus();

    if (_initialDeliveryPos == null && _initialAddressDetail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ ไม่มีประวัติที่อยู่ที่เคยบันทึกไว้ก่อนหน้านี้'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _deliveryPos = _initialDeliveryPos;
      _addressDetailController.text = _initialAddressDetail;
    });

    if (_deliveryPos != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_deliveryPos!, 17.0),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 คืนค่าหมุดและรายละเอียดที่อยู่เริ่มต้นเรียบร้อยแล้ว'),
        backgroundColor: Colors.blueGrey,
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _isInsideFence(LatLng tappedPoint) {
    var polygon = _mjuFencePoints
        .map((p) => toolkit.LatLng(p.latitude, p.longitude))
        .toList();
    var point = toolkit.LatLng(tappedPoint.latitude, tappedPoint.longitude);
    return toolkit.PolygonUtil.containsLocation(point, polygon, false);
  }

  String _getNearestBuilding(LatLng tapPos) {
    String nearestName = "";
    double minDistance = double.infinity;

    for (var building in _campusBuildings) {
      double distance = toolkit.SphericalUtil.computeDistanceBetween(
        toolkit.LatLng(tapPos.latitude, tapPos.longitude),
        toolkit.LatLng(
          (building['pos'] as LatLng).latitude,
          (building['pos'] as LatLng).longitude,
        ),
      ).toDouble();

      if (distance < minDistance) {
        minDistance = distance;
        nearestName = building['name'] as String;
      }
    }

    if (minDistance <= 40.0) {
      return nearestName;
    }

    return "";
  }

  void _onMapTap(LatLng position) {
    if (_isInsideFence(position)) {
      setState(() {
        _deliveryPos = position;

        String nearestBuilding = _getNearestBuilding(position);
        if (nearestBuilding.isNotEmpty) {
          _addressDetailController.text = nearestBuilding;
        } else {
          bool isOldTextABuilding = _campusBuildings.any(
            (b) => b['name'] == _addressDetailController.text.trim(),
          );
          if (isOldTextABuilding) {
            _addressDetailController.clear();
          }
        }
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(position));
    } else {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📍 กรุณาเลือกจุดจัดส่งภายในเขตมหาวิทยาลัยเท่านั้น'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveLocation() async {
    FocusScope.of(context).unfocus();

    if (_deliveryPos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาปักหมุดจุดจัดส่งบนแผนที่'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_addressDetailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาระบุรายละเอียดที่อยู่ / จุดสังเกต'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      MemberModel updateModel = MemberModel(
        username: GlobalData.usernameMember,
        latitude: _deliveryPos!.latitude,
        longitude: _deliveryPos!.longitude,
        defaultlocation: _addressDetailController.text.trim(),
      );

      await _memberService.updateLocationMember(updateModel);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ บันทึกจุดจัดส่งเรียบร้อยแล้ว'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, {
        'latitude': _deliveryPos!.latitude,
        'longitude': _deliveryPos!.longitude,
        'addressDetail': _addressDetailController.text.trim(),
        'defaultlocation': _addressDetailController.text.trim(),
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🚨 บันทึกไม่สำเร็จ: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('จุดจัดส่งของคุณ'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF64F02D)),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _deliveryPos ?? _defaultCenter,
                zoom: _deliveryPos != null ? 17.0 : 15.0,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                if (_deliveryPos != null) {
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(_deliveryPos!, 17.0),
                  );
                }
              },
              onTap: _onMapTap,
              markers: _deliveryPos == null
                  ? {}
                  : {
                      Marker(
                        markerId: const MarkerId('delivery_spot'),
                        position: _deliveryPos!,
                        infoWindow: const InfoWindow(title: 'จุดส่งอาหาร'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ),
                      ),
                    },
              polygons: {
                Polygon(
                  polygonId: const PolygonId("mju_fence"),
                  points: _mjuFencePoints,
                  fillColor: const Color(0xFF00B300).withOpacity(0.15),
                  strokeColor: const Color(0xFF00B300).withOpacity(0.8),
                  strokeWidth: 2,
                ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
            ),
          ),
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
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFF64F02D),
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "รายละเอียดที่จัดส่ง",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_deliveryPos != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "ปักหมุดแล้ว",
                            style: TextStyle(
                              color: const Color(0xFF00B300),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _addressDetailController,
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText:
                          "กรุณาปักหมุด หรือ พิมพ์สถานที่\n(เช่น ตึก A ชั้น 2 ห้อง 201)",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Color(0xFF64F02D),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🎯 แถวปุ่มกด "คืนค่าเดิม" (ซ้าย) และปุ่ม "ยืนยันและบันทึกข้อมูล" (ขวา)
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _isSaving
                                ? null
                                : _resetToDefaultLocation,
                            icon: const Icon(Icons.restore_rounded, size: 20),
                            label: const Text(
                              "ค่าเดิม",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              side: BorderSide(
                                color: Colors.grey.shade400,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveLocation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00B300),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    "ยืนยันและบันทึกข้อมูล",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
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
