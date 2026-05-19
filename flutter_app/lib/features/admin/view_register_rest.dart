import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/services/Admin/admin_service.dart';
import 'package:flutter_app/features/admin/admin_navbar.dart';
import 'package:flutter_app/features/admin/list_restaurant.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/features/admin/map_view_restaurant.dart'
    if (dart.library.html) 'package:flutter_app/utils/map_view_web.dart';

class View_RegisterRestaurant extends StatefulWidget {
  final RestaurantModel restaurant;
  final int index;

  const View_RegisterRestaurant({
    super.key,
    required this.restaurant,
    required this.index,
  });

  @override
  State<View_RegisterRestaurant> createState() =>
      _View_RegisterRestaurantState();
}

class _View_RegisterRestaurantState extends State<View_RegisterRestaurant> {
  final AdminService adminService = AdminService();
  late RestaurantModel restaurant;

  @override
  void initState() {
    super.initState();
    restaurant = widget.restaurant;

    if (restaurant.latitude != null && restaurant.longitude != null) {
      registerMapView(
        'map-${restaurant.username}',
        restaurant.latitude!,
        restaurant.longitude!,
      );
    }
  }

  String getOpenDayText(int? openDay) {
    if (openDay == null) return '-';
    const days = [
      'อาทิตย์',
      'จันทร์',
      'อังคาร',
      'พุธ',
      'พฤหัส',
      'ศุกร์',
      'เสาร์',
    ];
    List<String> open = [];
    for (int i = 0; i < 7; i++) {
      if ((openDay >> i) & 1 == 1) {
        open.add(days[i]);
      }
    }
    return open.isEmpty ? '-' : open.join(' - ');
  }

  // ================= API & DIALOGS =================
  void _showApproveDialog(RestaurantModel r) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.all(22),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'คุณแน่ใจหรือไม่\nว่าต้องการอนุมัติข้อมูลนี้',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _dialogButton(
                      'ยกเลิก',
                      const Color(0xFFD0D0D0),
                      Colors.black87,
                      () => Navigator.pop(context),
                      isOutlined: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dialogButton(
                      'อนุมัติ',
                      const Color(0xFF67E22B),
                      Colors.white,
                      () async {
                        Navigator.pop(context);
                        await _approveRestaurant(r);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRejectDialog(RestaurantModel r) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(22),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'คุณแน่ใจหรือไม่\nว่าต้องการปฏิเสธข้อมูลนี้',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: reasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'หมายเหตุ....',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _dialogButton(
                      'ยกเลิก',
                      const Color(0xFFD0D0D0),
                      Colors.black87,
                      () => Navigator.pop(context),
                      isOutlined: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dialogButton(
                      'ตกลง',
                      const Color(0xFFFF3B30),
                      Colors.white,
                      () async {
                        Navigator.pop(context);
                        await _rejectRestaurant(
                          r,
                          reasonController.text.trim(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogButton(
    String label,
    Color color,
    Color textColor,
    VoidCallback onPressed, {
    bool isOutlined = false,
  }) {
    return SizedBox(
      height: 44,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(label, style: TextStyle(color: textColor)),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(label, style: TextStyle(color: textColor)),
            ),
    );
  }

  Future<void> _approveRestaurant(RestaurantModel r) async {
    try {
      await adminService.approveRestaurant(r.username!);
      setState(() => restaurant.verificationStatus = "Confirm");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อนุมัติร้านค้าสำเร็จ'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เกิดข้อผิดพลาด'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectRestaurant(RestaurantModel r, String reason) async {
    try {
      await adminService.rejectRestaurant(r.username!, reason);
      setState(() => restaurant.notApproveDetail = reason);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ปฏิเสธร้านค้าสำเร็จ'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เกิดข้อผิดพลาด'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    Color statusColor = r.verificationStatus == true
        ? const Color(0xFF67E22B)
        : (r.notApproveDetail != null
              ? const Color(0xFFFF3B30)
              : const Color(0xFFFF9800));
    String statusText = r.verificationStatus == true
        ? 'อนุมัติแล้ว'
        : (r.notApproveDetail != null ? 'ปฏิเสธแล้ว' : 'รอดำเนินการ');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AdminNavbar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.store, size: 26, color: Colors.black87),
                  SizedBox(width: 8),
                  Text(
                    'รายละเอียดการสมัครของร้านค้า',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    // Header Bar
                    Container(
                      height: 46,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2F2F2),
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFD9D9D9)),
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 34),
                          Expanded(
                            child: Text(
                              'รายละเอียดร้านค้า ลำดับที่ : ${widget.index}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            width: 172,
                            height: 46,
                            alignment: Alignment.center,
                            color: statusColor,
                            child: Text(
                              statusText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content Area
                    Padding(
                      padding: const EdgeInsets.fromLTRB(34, 24, 34, 34),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LEFT SIDE (ข้อมูลร้านค้า & ข้อมูลการติดต่อ)
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionTitle('ข้อมูลร้านค้า'),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _labelValue(
                                          'ID ร้านค้า',
                                          r.username ?? '-',
                                        ),
                                      ),
                                      Expanded(
                                        child: _labelValue(
                                          'ชื่อร้าน (Restaurant Name)',
                                          r.restaurantName ?? '-',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _labelValue(
                                          'วันที่เปิดทำการ',
                                          getOpenDayText(r.openDay),
                                        ),
                                      ),
                                      Expanded(
                                        child: _labelValue(
                                          'เวลาเปิด - ปิด',
                                          '${r.openTime ?? '-'} - ${r.closeTime ?? '-'} น.',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  _sectionTitle('ข้อมูลการติดต่อ'),
                                  const SizedBox(height: 14),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _labelValue(
                                              'ชื่อ-นามสกุล เจ้าของ',
                                              '${r.ownerFirstName ?? ''} ${r.ownerLastName ?? ''}',
                                            ),
                                            const SizedBox(height: 24),
                                            _labelValue(
                                              'อีเมล (Email)',
                                              r.email ?? '-',
                                            ),
                                            const SizedBox(height: 24),
                                            _labelValue(
                                              'เบอร์โทรศัพท์ (Phone)',
                                              r.phone ?? '-',
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'ที่ตั้งร้านค้า (latitude-longitude)',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              width: 190,
                                              height: 145,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFD9D9D9,
                                                  ),
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child:
                                                  (r.latitude != null &&
                                                      r.longitude != null)
                                                  ? ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      child: kIsWeb
                                                          ? buildMapView(
                                                              'map-${r.username}',
                                                            )
                                                          : GoogleMap(
                                                              initialCameraPosition:
                                                                  CameraPosition(
                                                                    target: LatLng(
                                                                      r.latitude!,
                                                                      r.longitude!,
                                                                    ),
                                                                    zoom: 17,
                                                                  ),
                                                              markers: {
                                                                Marker(
                                                                  markerId:
                                                                      const MarkerId(
                                                                        'shop',
                                                                      ),
                                                                  position: LatLng(
                                                                    r.latitude!,
                                                                    r.longitude!,
                                                                  ),
                                                                  infoWindow: InfoWindow(
                                                                    title:
                                                                        r.restaurantName ??
                                                                        'ร้านค้า',
                                                                  ),
                                                                ),
                                                              },
                                                              zoomControlsEnabled:
                                                                  false,
                                                              scrollGesturesEnabled:
                                                                  false,
                                                              zoomGesturesEnabled:
                                                                  false,
                                                              rotateGesturesEnabled:
                                                                  false,
                                                              tiltGesturesEnabled:
                                                                  false,
                                                              myLocationButtonEnabled:
                                                                  false,
                                                              liteModeEnabled:
                                                                  true,
                                                            ),
                                                    )
                                                  : const Center(
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons.location_off,
                                                            size: 36,
                                                            color: Colors.grey,
                                                          ),
                                                          SizedBox(height: 4),
                                                          Text(
                                                            'ไม่มีข้อมูลพิกัด',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (r.notApproveDetail != null) ...[
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFEEEE),
                                        border: Border.all(color: Colors.red),
                                      ),
                                      child: Text(
                                        'เหตุผลที่ปฏิเสธ : ${r.notApproveDetail}',
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // MIDDLE DIVIDER
                            const VerticalDivider(
                              width: 60,
                              thickness: 1,
                              color: Color(0xFFD9D9D9),
                            ),

                            // RIGHT SIDE (ข้อมูลเอกสาร: ปรับปรุงโครงสร้างให้เรียงแนวนอน ซ้าย-ขวา ทรงยาวแนวตั้ง)
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionTitle('ข้อมูลเอกสาร'),
                                  const SizedBox(height: 14),

                                  // ใช้ Row บังคับจัดระเบียบให้ภาพ รูปร้านค้า และ รูปสัญญาเช่า แสดงผลเคียงคู่กัน
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // ฝั่งรูปร้านค้า
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'รูปร้านค้า (Restaurant Image)',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            _imageBox(r.restaurantImage),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 16,
                                      ), // ระยะเว้นวรรคช่องว่างระหว่างรูป
                                      // ฝั่งรูปสัญญาเช่า
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'รูปสัญญาเช่า (lease_agreement)',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            _imageBox(r.leaseAgreementImg),
                                          ],
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
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Buttons Bottom
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _actionButton(
                    label: 'ย้อนกลับ',
                    color: const Color(0xFFD9D9D9),
                    textColor: Colors.black87,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ListRestaurant(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _actionButton(
                    label: 'ปฏิเสธการสมัคร',
                    color: const Color(0xFFFF3B30),
                    onPressed: () => _showRejectDialog(r),
                  ),
                  const SizedBox(width: 10),
                  _actionButton(
                    label: 'อนุมัติการสมัคร',
                    color: const Color(0xFF67E22B),
                    onPressed: () => _showApproveDialog(r),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF6AD12B),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(color: Color(0xFFD9D9D9), thickness: 1),
      ],
    );
  }

  Widget _labelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _imageBox(String? imageUrl) {
    String? encodedUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final uri = Uri.parse(imageUrl);
      encodedUrl = uri
          .replace(
            path: uri.path
                .split('/')
                .map((s) => Uri.encodeComponent(s))
                .join('/'),
          )
          .toString();
    }

    return Container(
      width: 240,
      height: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: encodedUrl != null
          ? GestureDetector(
              onTap: () => _showMaximizedImage(context, encodedUrl!),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Tooltip(
                  message: 'คลิกเพื่อขยายรูป',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Image.network(
                          encodedUrl,
                          width: 240,
                          height: 260,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : const Center(
              child: Icon(Icons.image_outlined, size: 50, color: Colors.grey),
            ),
    );
  }

  void _showMaximizedImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
    Color textColor = Colors.white,
  }) {
    return SizedBox(
      width: 160,
      height: 45,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          label,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
