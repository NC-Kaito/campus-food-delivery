import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/services/Admin/admin_service.dart';
import 'package:flutter_app/features/admin/admin_navbar.dart';
import 'package:flutter_app/features/admin/list_restaurant.dart';

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

  // ================= API & DIALOGS (คงเดิมตาม Logic ของคุณ) =================
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
                        // ทำให้เส้นตรงกลางสูงเท่ากับเนื้อหาที่ยาวที่สุด
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LEFT SIDE
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
                                  const SizedBox(height: 28),
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
                                  const SizedBox(height: 16),
                                  // =========================
                                  // CONTACT INFO
                                  // =========================
                                  _sectionTitle('ข้อมูลการติดต่อ'),
                                  const SizedBox(height: 14),

                                  // ใช้ Row ใหญ่ครอบทั้งหมดเพื่อให้ alignment ของชื่อ-นามสกุล และที่ตั้ง เริ่มที่บรรทัดเดียวกัน
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // ฝั่งซ้ายของข้อมูลติดต่อ (ชื่อ, อีเมล, เบอร์)
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _labelValue(
                                              'ชื่อ-นามสกุล เจ้าของ',
                                              '${r.ownerFirstName ?? ''} ${r.ownerLastName ?? ''}',
                                            ),
                                            const SizedBox(height: 26),
                                            _labelValue(
                                              'อีเมล (Email)',
                                              r.email ?? '-',
                                            ),
                                            const SizedBox(height: 26),
                                            _labelValue(
                                              'เบอร์โทรศัพท์ (Phone)',
                                              r.phone ?? '-',
                                            ),
                                          ],
                                        ),
                                      ),

                                      // ฝั่งขวาของข้อมูลติดต่อ (แผนที่)
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
                                              height:
                                                  145, // ปรับความสูงตามความเหมาะสม
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFD9D9D9,
                                                  ),
                                                ),
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.map,
                                                  size: 42,
                                                  color: Colors.grey,
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

                            // RIGHT SIDE (IMAGES CENTERED)
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment
                                    .start, // จัดให้อยู่ตรงกลางหน้าจอฝั่งขวา
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
                                  const SizedBox(height: 30),
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
                      ), // เปลี่ยนชื่อ Class ตามหน้าจริงของคุณ
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

  Widget _imageBox(String? imagePath) {
    // 1. ดึงเฉพาะชื่อไฟล์ออกมา (เพราะใน DB ของคุณเก็บ "images/restaurant/rest01.png")
    // เราต้องการแค่ "rest01.png"
    final String fileName = imagePath?.split('/').last ?? "";

    return Container(
      width: 180,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: imagePath != null && fileName.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                // 2. ใส่ URL เต็มๆ แล้วตามด้วยตัวแปร fileName
                "http://10.244.27.84:8081/uploads/restaurant/imageRestaurant/$fileName",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // ถ้าโหลดไม่ได้ ให้แสดงไอคอนเสีย
                  return const Center(
                    child: Icon(Icons.image_not_supported, color: Colors.grey),
                  );
                },
              ),
            )
          : const Icon(Icons.image_outlined, size: 50, color: Colors.grey),
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
