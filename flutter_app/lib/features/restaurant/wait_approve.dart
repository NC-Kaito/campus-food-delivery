// features/restaurant/wait_approve.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/global_data.dart';
import 'package:flutter_app/features/restaurant/login_restaurant.dart';
import 'package:flutter_app/features/restaurant/update_register.dart';
import 'package:flutter_app/features/restaurant/account_management.dart';

class WaitApprove extends StatefulWidget {
  final String verificationStatus; // รับค่า 'wait' หรือ 'false'
  final String? notApproveDetail; // รับข้อความหมายเหตุ

  const WaitApprove({
    super.key,
    required this.verificationStatus,
    this.notApproveDetail,
  });

  @override
  State<WaitApprove> createState() => _WaitApproveState();
}

class _WaitApproveState extends State<WaitApprove> {
  RestaurantModel? get restaurantModel => null;

  // ฟังก์ชันออกจากระบบ
  void _handleLogout() {
    GlobalData.usernameRestaurant = ""; // ล้างค่าเซสชัน

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginRestaurant()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isRejected = widget.verificationStatus == 'false';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6), // พื้นหลังสีสว่างสบายตา
      // ─── Custom Navbar แบบลดทอน (มีแค่ Home และ Profile) ───
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 8),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                height: kToolbarHeight + 8,
                child: Row(
                  children: [
                    // ปุ่ม Home
                    Material(
                      color: const Color(0xFFFFF1DE), // orangeSoft
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        splashColor: const Color(0xFFFF8C00).withOpacity(0.18),
                        highlightColor: const Color(
                          0xFFFF8C00,
                        ).withOpacity(0.08),
                        onTap: () => Navigator.popUntil(
                          context,
                          (route) => route.isFirst,
                        ),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFF8C00).withOpacity(0.22),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.home_rounded,
                            color: Color(0xFFFF8C00), // orange
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        '',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F1F1F),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // ปุ่ม Profile (แสดงแค่ Icon)
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 38,
                        height: 38,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFF8C00),
                              const Color(0xFFFF8C00).withOpacity(0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF8C00).withOpacity(0.28),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Container(
                            color: const Color(0xFFFFF1DE),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              color: Color(0xFFFF8C00),
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ─── โลโก้หรือไอคอนด้านบน ───
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isRejected
                          ? Colors.red.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isRejected
                          ? Icons.error_outline_rounded
                          : Icons.hourglass_top_rounded,
                      size: 48,
                      color: isRejected ? Colors.redAccent : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── ข้อความสถานะหลัก ───
                  Text(
                    isRejected ? 'ไม่ผ่านการอนุมัติ' : 'อยู่ระหว่างการตรวจสอบ',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: isRejected ? Colors.redAccent : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isRejected
                        ? 'ข้อมูลของคุณยังไม่ผ่านเกณฑ์ โปรดแก้ไขแล้วส่งใหม่'
                        : 'ทีมงานกำลังเร่งตรวจสอบข้อมูลร้านค้าของคุณ\nอดใจรออีกนิดนะครับ 😊',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ─── การ์ดแสดงผลเนื้อหา (Dynamic ตามสถานะ) ───
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: isRejected
                        ? _buildRejectedContent()
                        : _buildWaitingContent(),
                  ),
                  const SizedBox(height: 24),

                  // ─── เวลาทำการ (ทำเป็น Badge เล็กๆ น่ารัก) ───
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'เวลาทำการ จ.-ศ. 08:00 - 16:00 น.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ─── ปุ่ม ดำเนินการ (ดูข้อมูล / แก้ไข) ───
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UpdateRegisterFields(
                              verificationStatus: widget.verificationStatus,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF76FF03), // เขียวแบรนด์
                        foregroundColor: Colors.black,
                        elevation: 4,
                        shadowColor: const Color(0xFF76FF03).withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isRejected
                                ? 'ดูข้อมูลการสมัคร'
                                : 'ดูข้อมูลการสมัคร',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── ปุ่ม ออกจากระบบ ───
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: TextButton(
                      onPressed: _handleLogout,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'ออกจากระบบ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🔴 เนื้อหาเมื่อสถานะเป็น "ไม่ผ่าน (Rejected)"
  Widget _buildRejectedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Colors.redAccent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'หมายเหตุจากเจ้าหน้าที่',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade100),
          ),
          child: Text(
            widget.notApproveDetail ?? 'ไม่ระบุสาเหตุ',
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // 🟡 เนื้อหาเมื่อสถานะเป็น "รอตรวจสอบ (Waiting)"
  Widget _buildWaitingContent() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/waitApprove.png',
            height: 160,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 160,
              color: Colors.orange.shade50,
              child: const Center(
                child: Icon(
                  Icons.storefront_rounded,
                  size: 60,
                  color: Colors.orange,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'สถานะ: รอดำเนินการ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade700,
          ),
        ),
      ],
    );
  }
}
