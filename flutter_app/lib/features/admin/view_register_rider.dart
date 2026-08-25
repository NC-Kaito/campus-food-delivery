//  features/admin/view_register_rider.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/rider_model.dart';
import 'package:flutter_app/data/services/Admin/admin_service.dart';
import 'package:flutter_app/features/admin/admin_navbar.dart';
import 'package:flutter_app/features/admin/list_rider.dart';
import 'package:flutter_app/core/network/dio_client.dart';

// ============ THEME TOKENS (โทนสีสอดคล้องกับหน้า View_RegisterRestaurant) ============
class _Palette {
  static const primary = Color(0xFF2FBA6E); // เขียวหลัก
  static const primaryDark = Color(0xFF1E9E5B);
  static const primarySoft = Color(0xFFE8F9EF);
  static const bg = Color(0xFFF5F7FA);
  static const cardBg = Colors.white;
  static const border = Color(0xFFE7EAF0);
  static const fieldBg = Color(0xFFF7F8FA);
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const success = Color(0xFF22C55E);
  static const danger = Color(0xFFEF4444);
  static const dangerSoft = Color(0xFFFEECEC);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFFF4E5);
  static const info = Color(0xFF3B82F6);
}

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

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
      return rawPath;
    }

    final String baseUrl = DioClient.dio.options.baseUrl;
    if (rawPath.startsWith('/')) {
      return "$baseUrl$rawPath";
    } else {
      return "$baseUrl/$rawPath";
    }
  }

  // ================= API & DIALOGS =================
  void _showApproveDialog(RiderModel r) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: _confirmDialogShell(
          icon: Icons.check_circle_rounded,
          iconColor: _Palette.success,
          iconBg: _Palette.primarySoft,
          title: 'ยืนยันการอนุมัติ',
          subtitle: 'คุณแน่ใจหรือไม่ว่าต้องการอนุมัติผู้จัดส่งคนนี้',
          child: null,
          confirmLabel: 'อนุมัติ',
          confirmColor: _Palette.success,
          onConfirm: () async {
            Navigator.pop(context);
            await _approveRider(r);
          },
        ),
      ),
    );
  }

  void _showRejectDialog(RiderModel r) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: _confirmDialogShell(
          icon: Icons.cancel_rounded,
          iconColor: _Palette.danger,
          iconBg: _Palette.dangerSoft,
          title: 'ยืนยันการปฏิเสธ',
          subtitle: 'คุณแน่ใจหรือไม่ว่าต้องการปฏิเสธผู้จัดส่งคนนี้',
          child: Padding(
            padding: const EdgeInsets.only(top: 18),
            child: TextField(
              controller: reasonController,
              maxLines: 4,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'ระบุเหตุผลในการปฏิเสธ...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: const Color(0xFFF7F8FA),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _Palette.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _Palette.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: _Palette.danger,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
          confirmLabel: 'ยืนยันปฏิเสธ',
          confirmColor: _Palette.danger,
          onConfirm: () async {
            Navigator.pop(context);
            await _rejectRider(r, reasonController.text.trim());
          },
        ),
      ),
    );
  }

  Widget _confirmDialogShell({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required Widget? child,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    return Container(
      width: 400,
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 34),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _Palette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              color: _Palette.textSecondary,
            ),
          ),
          if (child != null) child,
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: _Palette.border,
                        width: 1.4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'ยกเลิก',
                      style: TextStyle(
                        color: _Palette.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      confirmLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approveRider(RiderModel r) async {
    try {
      await adminService.approveRider(r.studentid!);
      setState(() => rider.verificationStatus = "Confirm");
      _showSnack(
        'อนุมัติผู้จัดส่งสำเร็จ',
        _Palette.success,
        Icons.check_circle,
      );
    } catch (e) {
      _showSnack('เกิดข้อผิดพลาด', _Palette.danger, Icons.error);
    }
  }

  Future<void> _rejectRider(RiderModel r, String reason) async {
    try {
      await adminService.rejectRider(r.studentid!, reason);
      setState(() {
        rider.verificationStatus = "Reject";
        rider.notApproveDetail = reason;
      });
      _showSnack('ปฏิเสธผู้จัดส่งสำเร็จ', _Palette.danger, Icons.info);
    } catch (e) {
      _showSnack('เกิดข้อผิดพลาด', _Palette.danger, Icons.error);
    }
  }

  void _showSnack(String text, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final r = rider;

    Color statusColor;
    Color statusBg;
    String statusText;
    IconData statusIcon;

    if (r.verificationStatus == 'Confirm') {
      statusColor = _Palette.success;
      statusBg = _Palette.primarySoft;
      statusText = 'อนุมัติแล้ว';
      statusIcon = Icons.check_circle_rounded;
    } else if (r.verificationStatus == 'Reject' ||
        (r.notApproveDetail != null &&
            r.notApproveDetail != 'NULL' &&
            r.notApproveDetail!.isNotEmpty)) {
      statusColor = _Palette.danger;
      statusBg = _Palette.dangerSoft;
      statusText = 'ปฏิเสธแล้ว';
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = _Palette.warning;
      statusBg = _Palette.warningSoft;
      statusText = 'รอดำเนินการ';
      statusIcon = Icons.hourglass_top_rounded;
    }

    final bool isApproved = r.verificationStatus == 'Confirm';
    final bool isRejected =
        r.verificationStatus == 'Reject' ||
        (r.notApproveDetail != null &&
            r.notApproveDetail != 'NULL' &&
            r.notApproveDetail!.isNotEmpty);
    final bool isDecided = isApproved || isRejected;

    return Scaffold(
      backgroundColor: _Palette.bg,
      appBar: const AdminNavbar(),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1350),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ----- Page Header -----
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ListRider(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _Palette.border),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: _Palette.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _Palette.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delivery_dining_rounded,
                          color: _Palette.primaryDark,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'รายละเอียดการสมัครของผู้จัดส่ง',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: _Palette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ----- Main Card -----
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _Palette.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _Palette.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Header Bar
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 18,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(color: _Palette.border),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'รายละเอียดผู้จัดส่ง • ลำดับที่ ${widget.index}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15.5,
                                    color: _Palette.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.35),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      statusIcon,
                                      size: 16,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      statusText,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Content Area
                        Padding(
                          padding: const EdgeInsets.fromLTRB(32, 26, 32, 32),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 900;
                              final left = _buildPersonalInfoSection(r);
                              final right = _buildVehicleSection(r);

                              if (isWide) {
                                return IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: left),
                                      const SizedBox(width: 36),
                                      const VerticalDivider(
                                        width: 1,
                                        thickness: 1,
                                        color: _Palette.border,
                                      ),
                                      const SizedBox(width: 36),
                                      Expanded(child: right),
                                    ],
                                  ),
                                );
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  left,
                                  const SizedBox(height: 28),
                                  const Divider(color: _Palette.border),
                                  const SizedBox(height: 28),
                                  right,
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _actionButton(
                label: 'ย้อนกลับ',
                icon: Icons.arrow_back_rounded,
                color: Colors.white,
                textColor: _Palette.textPrimary,
                borderColor: _Palette.border,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ListRider()),
                ),
              ),
              const SizedBox(width: 30),
              _actionButton(
                label: 'ปฏิเสธการสมัคร',
                icon: Icons.close_rounded,
                color: _Palette.danger,
                onPressed: isDecided ? null : () => _showRejectDialog(r),
              ),
              const SizedBox(width: 30),
              _actionButton(
                label: 'อนุมัติการสมัคร',
                icon: Icons.check_rounded,
                color: _Palette.success,
                onPressed: isDecided ? null : () => _showApproveDialog(r),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----- LEFT: ข้อมูลส่วนตัว -----
  Widget _buildPersonalInfoSection(RiderModel r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('ข้อมูลส่วนตัว', Icons.person_outline_rounded),
        const SizedBox(height: 18),

        // 1. รหัสนักศึกษา
        _labelValue('รหัสนักศึกษา (Student ID)', r.studentid ?? '-'),
        const SizedBox(height: 22),

        // 2. บัตรนักศึกษา (ปรับขนาดให้เล็กลง)
        _imageLabel('บัตรนักศึกษา (Student Card)'),
        const SizedBox(height: 10),
        _imageBox(r.studentCardImage, width: 280, height: 160),
        const SizedBox(height: 22),

        // 3. ชื่อ - นามสกุล
        _labelValue(
          'ชื่อ - นามสกุล',
          '${r.firstName ?? ''} ${r.lastName ?? ''}',
        ),
        const SizedBox(height: 18),

        // 4. คณะ
        _labelValue('คณะ (Faculty)', r.facultyName ?? '-'),
        const SizedBox(height: 18),

        // 5. สาขาวิชา
        _labelValue('สาขาวิชา (Major)', r.majorName ?? '-'),
        const SizedBox(height: 18),

        // 6. วันเกิด
        _labelValue('วันเกิด (Birthday)', r.birthday ?? '-'),
        const SizedBox(height: 18),

        // 7. อีเมล และ เบอร์โทรศัพท์
        Row(
          children: [
            Expanded(child: _labelValue('อีเมล (Email)', r.email ?? '-')),
            const SizedBox(width: 16),
            Expanded(
              child: _labelValue('เบอร์โทรศัพท์ (Phone)', r.phone ?? '-'),
            ),
          ],
        ),

        if (r.notApproveDetail != null &&
            r.notApproveDetail != 'NULL' &&
            r.notApproveDetail!.isNotEmpty) ...[
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _Palette.dangerSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _Palette.danger.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: _Palette.danger,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: _Palette.danger,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(
                          text: 'เหตุผลที่ปฏิเสธ: ',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: r.notApproveDetail),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ----- RIGHT: ข้อมูลยานพาหนะ -----
  Widget _buildVehicleSection(RiderModel r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('ข้อมูลยานพาหนะ', Icons.two_wheeler_rounded),
        const SizedBox(height: 18),
        _labelValue('ทะเบียนรถ (Vehicle Plate)', r.vehiclePlate ?? '-'),
        const SizedBox(height: 22),
        // รูปยานพาหนะ (ปรับขนาดให้เล็กลง)
        _imageLabel('รูปยานพาหนะ (Vehicle Image)'),
        const SizedBox(height: 10),
        _imageBox(r.vehicleImage, width: 280, height: 160),
        const SizedBox(height: 22),
        // รูปใบขับขี่ (ปรับขนาดให้เล็กลง)
        _imageLabel('รูปใบขับขี่ (Driving License Image)'),
        const SizedBox(height: 10),
        _imageBox(r.drivingLicenseImg, width: 280, height: 160),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color.fromARGB(255, 69, 159, 255)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color.fromARGB(255, 69, 159, 255),
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _imageLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: _Palette.textSecondary,
    ),
  );

  Widget _labelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: _Palette.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _Palette.fieldBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _Palette.border),
          ),
          child: Text(
            value.trim().isEmpty ? '-' : value,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: _Palette.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // 🎯 ปรับให้รับทั้ง width และ height เพื่อให้สามารถคุมขนาดกว้างและยาวของแต่ละรูปได้ตามต้องการ
  Widget _imageBox(String? imageUrl, {double? width, double height = 160}) {
    final String finalUrl = _getFinalImageUrl(imageUrl);
    final String encodedUrl = finalUrl.isNotEmpty
        ? Uri.encodeFull(finalUrl)
        : "";

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        border: Border.all(color: _Palette.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: encodedUrl.isNotEmpty
          ? GestureDetector(
              onTap: () => _showMaximizedImage(context, encodedUrl),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Tooltip(
                  message: 'คลิกเพื่อขยายรูป',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          encodedUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: _Palette.primary,
                                strokeWidth: 2.5,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.image_not_supported_rounded,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.zoom_in_rounded,
                              size: 16,
                              color: Colors.white,
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
              child: Icon(Icons.image_outlined, size: 36, color: Colors.grey),
            ),
    );
  }

  void _showMaximizedImage(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
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
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 40,
                  ),
                ],
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
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    Color textColor = Colors.white,
    Color? borderColor,
  }) {
    final bool disabled = onPressed == null;
    final Color effectiveBg = disabled ? const Color(0xFFE5E7EB) : color;
    final Color effectiveText = disabled ? const Color(0xFF9CA3AF) : textColor;

    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: effectiveText),
        label: Text(
          label,
          style: TextStyle(
            color: effectiveText,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBg,
          disabledBackgroundColor: const Color(0xFFE5E7EB),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: (!disabled && borderColor != null)
                ? BorderSide(color: borderColor)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
