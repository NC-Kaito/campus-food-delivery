import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/rider_model.dart';
import 'package:flutter_app/data/services/Admin/admin_service.dart';
import 'package:flutter_app/features/admin/admin_navbar.dart';
import 'package:flutter_app/features/admin/list_rider.dart';

class View_RegisterRider extends StatefulWidget {
  final RiderModel rider;
  final int index;

  const View_RegisterRider({
    super.key,
    required this.rider,
    required this.index,
  });

  @override
  State<View_RegisterRider> createState() => _View_RegisterRiderState();
}

class _View_RegisterRiderState extends State<View_RegisterRider> {
  final AdminService adminService = AdminService();
  late RiderModel rider;

  @override
  void initState() {
    super.initState();
    rider = widget.rider;
  }

  // ================= API & DIALOGS =================
  void _showApproveDialog(RiderModel r) {
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
                        await _approveRider(r);
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

  void _showRejectDialog(RiderModel r) {
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
                        await _rejectRider(r, reasonController.text.trim());
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

  Future<void> _approveRider(RiderModel r) async {
    try {
      await adminService.approveRider(r.studentid!);
      setState(() => rider.verificationStatus = "Confirm");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อนุมัติผู้จัดส่งสำเร็จ'),
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

  Future<void> _rejectRider(RiderModel r, String reason) async {
    try {
      await adminService.rejectRider(r.studentid!, reason);
      setState(() {
        rider.verificationStatus = "Reject";
        rider.notApproveDetail = reason;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ปฏิเสธผู้จัดส่งสำเร็จ'),
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
    final r = rider;

    Color statusColor = r.verificationStatus == "Confirm"
        ? const Color(0xFF67E22B)
        : (r.verificationStatus == "Reject" || r.notApproveDetail != null
              ? const Color(0xFFFF9800)
              : const Color(0xFFFF9800));

    String statusText = r.verificationStatus == "Confirm"
        ? 'อนุมัติแล้ว'
        : (r.verificationStatus == "Reject" || r.notApproveDetail != null
              ? 'ปฏิเสธแล้ว'
              : 'รอดำเนินการ');

    if (r.verificationStatus != "Confirm" && r.notApproveDetail == null) {
      statusColor = const Color(0xFFFF9800);
      statusText = 'รอดำเนินการ';
    }

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
                  Icon(Icons.delivery_dining, size: 26, color: Colors.black87),
                  SizedBox(width: 8),
                  Text(
                    'รายละเอียดการสมัครของผู้จัดส่ง',
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
                              'รายละเอียดผู้จัดส่ง ลำดับที่ : ${widget.index}',
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
                            // LEFT SIDE: ข้อมูลส่วนตัว (แก้ปัญหาซ้อนทับและจัดระเบียบใหม่)
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionTitle('ข้อมูลส่วนตัว'),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _labelValue(
                                          'รหัสนักศึกษา (Student)',
                                          r.studentid ?? '-',
                                        ),
                                      ),
                                      Expanded(
                                        child: _labelValue(
                                          'เบอร์โทรศัพท์ (Phone)',
                                          r.phone ?? '-',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _labelValue(
                                          'ชื่อ - นามสกุล',
                                          '${r.firstName ?? ''} ${r.lastName ?? ''}',
                                        ),
                                      ),
                                      Expanded(
                                        child: _labelValue(
                                          'อีเมล (Email)',
                                          r.email ?? '-',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // จัดกลุ่ม คณะ, สาขา, วันเกิด ไว้ฝั่งซ้าย และรูปบัตรนักศึกษาไว้ฝั่งขวาใน Row เดียวกัน
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // ฝั่งซ้าย: ข้อมูลคณะ สาขา และวันเกิด
                                      // ฝั่งซ้าย: ข้อมูลสถาบันและการศึกษา
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _labelValue(
                                              'คณะ (Faculty)',
                                              r.facultyName ??
                                                  '-', // 👈 เปลี่ยนมาดึงค่า Dynamic จากโมเดลแล้ว!
                                            ),
                                            const SizedBox(height: 24),
                                            _labelValue(
                                              'สาขาวิชา (Major)',
                                              r.majorName ??
                                                  '-', // ดึงค่า Dynamic จากโมเดล
                                            ),
                                            const SizedBox(height: 24),
                                            _labelValue(
                                              'วันเกิด (Birthday)',
                                              r.birthday ?? '-',
                                            ),
                                          ],
                                        ),
                                      ),
                                      // ฝั่งขวา: แสดงหัวข้อ และรูปภาพบัตรนักศึกษา
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'บัตรนักศึกษา (Student Card)',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            _imageBox(
                                              r.studentCardImage,
                                              "studentCard",
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

                            // RIGHT SIDE: ข้อมูลยานพาหนะ (แสดงรูปแบบขนาน ซ้าย-ขวา ทรงแนวตั้ง)
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionTitle('ข้อมูลยานพาหนะ'),
                                  const SizedBox(height: 14),
                                  _labelValue(
                                    'ทะเบียนรถ (Vehicle Plate)',
                                    r.vehiclePlate ?? '-',
                                  ),
                                  const SizedBox(height: 20),

                                  // วางชื่อหัวข้อและภาพเรียงคู่กัน ซ้าย-ขวา
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // ฝั่งรูปยานพาหนะ
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'รูปยานพาหนะ (Vehicle image)',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            _imageBox(
                                              r.vehicleImage,
                                              "vehicle",
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // ฝั่งรูปใบขับขี่
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'รูปใบขับขี่ ( driving license image)',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            _imageBox(
                                              r.drivingLicenseImg,
                                              "license",
                                            ),
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
                        builder: (context) => const ListRider(),
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
        if (value.isNotEmpty)
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  Widget _imageBox(String? imagePath, String type) {
    final String fileName = imagePath?.split('/').last ?? "";

    String folderPath = "imageRider";
    if (type == "studentCard") folderPath = "studentCard";
    if (type == "license") folderPath = "drivingLicense";

    final String fullImageUrl =
        "http://10.244.27.84:8081/uploads/rider/$folderPath/$fileName";

    // ดึงขนาดกล่องแยกประเภท: บัตรนักศึกษาใช้แนวนอน (180x135) ยานพาหนะและใบขับขี่ใช้แนวตั้ง (180x220)
    final double boxWidth = 240;
    final double boxHeight = (type == "studentCard") ? 145 : 260;

    return Container(
      width: boxWidth,
      height: boxHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: imagePath != null && fileName.isNotEmpty
          ? GestureDetector(
              onTap: () => _showMaximizedImage(context, fullImageUrl),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Tooltip(
                  message: 'คลิกเพื่อขยายรูป',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      fullImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            )
          : const Icon(Icons.image_outlined, size: 45, color: Colors.grey),
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
