import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/rider_model.dart';
import 'package:flutter_app/data/services/Admin/admin_service.dart';
import 'package:flutter_app/features/admin/admin_navbar.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  bool isLoading = true;

  // ── เพิ่มตัวแปรเก็บค่าที่นับได้ ─────────────────────────────────────────
  int _totalRestaurants = 0; // verificationStatus == "true"
  int _totalRiders = 0; // verificationStatus == "true"
  int _newRestaurants = 0; // verificationStatus == "wait"
  int _newRiders = 0; // verificationStatus == "wait"

  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // home_admin.dart
  Future<void> _fetchDashboardData() async {
    try {
      setState(() => isLoading = true);
      final counts = await _adminService.getDashboardCount();
      setState(() {
        _totalRestaurants = counts['totalRestaurant']!;
        _newRestaurants = counts['newRestaurant']!;
        _totalRiders = counts['totalRider']!;
        _newRiders = counts['newRider']!;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AdminNavbar(),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              color: Colors.orange,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(),
                      const SizedBox(height: 10),

                      _buildSectionTitle(
                        title: 'Overview of Platform Activity',
                        icon: Icons.bar_chart_rounded,
                        iconColor: Colors.orange,
                        iconSize: 24,
                      ),
                      const SizedBox(height: 16),
                      _buildOverviewRow(), // ← ใช้ค่าจาก state

                      const SizedBox(height: 32),

                      _buildSectionTitle(
                        title: 'รายการใหม่ที่รอการตรวจสอบ',
                        icon: Icons.fiber_new_rounded,
                        iconColor: const Color(0xFFD32F2F),
                        iconSize: 32,
                      ),
                      const SizedBox(height: 16),
                      _buildNewRow(), // ← ใช้ค่าจาก state

                      const SizedBox(height: 32),

                      _buildSectionTitle(
                        title:
                            'เกี่ยวกับระบบบริหารจัดการหลังบ้าน (System Overview)',
                        icon: Icons.info_outline_rounded,
                        iconColor: Colors.blue,
                        iconSize: 24,
                      ),
                      const SizedBox(height: 16),
                      _buildSystemDescriptionBox(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ── Title ──────────────────────────────────────────────────────────────────
  Widget _buildTitle() {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.person, size: 28, color: Colors.grey[800]),
            Positioned(
              right: -4,
              bottom: -2,
              child: Icon(Icons.settings, size: 14, color: Colors.grey[800]),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[850],
          ),
        ),
      ],
    );
  }

  // ── Section Title ──────────────────────────────────────────────────────────
  Widget _buildSectionTitle({
    required String title,
    required IconData icon,
    required Color iconColor,
    double iconSize = 22,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: iconSize, color: iconColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Divider(color: Color(0xFFD9D9D9), thickness: 1),
      ],
    );
  }

  // ── Overview Row ── ใช้ค่า _totalRestaurants / _totalRiders ───────────────
  Widget _buildOverviewRow() {
    return Row(
      children: [
        Expanded(
          child: _OverviewCard(
            icon: Icons.store_rounded,
            iconColor: const Color(0xFF4CAF50),
            iconBg: const Color(0xFFE8F5E9),
            label: 'จำนวนร้านค้าทั้งหมด',
            count: _totalRestaurants, // ← ค่าจริงจาก API
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _OverviewCard(
            icon: Icons.delivery_dining_rounded,
            iconColor: const Color(0xFFFF9800),
            iconBg: const Color(0xFFFFF3E0),
            label: 'จำนวนผู้จัดส่งทั้งหมด',
            count: _totalRiders, // ← ค่าจริงจาก API
          ),
        ),
      ],
    );
  }

  // ── New Registration Row ── ใช้ค่า _newRestaurants / _newRiders ───────────
  Widget _buildNewRow() {
    return Row(
      children: [
        Expanded(
          child: _NewRegCard(
            icon: Icons.tablet_android_rounded,
            iconColor: const Color(0xFFFF9800),
            iconBg: const Color(0xFFFFFDE7),
            label: 'การสมัครร้านค้าใหม่',
            count: _newRestaurants, // ← ค่าจริงจาก API
            countColor: const Color(0xFFFF9800),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _NewRegCard(
            icon: Icons.assignment_ind_rounded,
            iconColor: const Color(0xFF2196F3),
            iconBg: const Color(0xFFFFFDE7),
            label: 'การสมัครผู้จัดส่งใหม่',
            count: _newRiders, // ← ค่าจริงจาก API
            countColor: const Color(0xFF2196F3),
          ),
        ),
      ],
    );
  }

  // ── System Description Box ─────────────────────────────────────────────────
  Widget _buildSystemDescriptionBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDescriptionLine(
            '1. ระบบตรวจสอบและอนุมัติร้านค้า (Merchant Verification): ',
            'ช่องทางคัดกรอง ตรวจสอบเอกสาร และอนุมัติสิทธิ์การเปิดร้านค้าออนไลน์ของพาร์ทเนอร์ภายในมหาวิทยาลัย',
          ),
          _buildDescriptionLine(
            '2. ระบบบริหารจัดการผู้จัดส่งอาหาร (Rider Onboarding Hub): ',
            'ตรวจสอบข้อมูลส่วนตัว บัตรนักศึกษา และเอกสารยานพาหนะของไรเดอร์เพื่อความปลอดภัยในการให้บริการ',
          ),
          _buildDescriptionLine(
            '3. การแสดงผลสถิติแบบเรียลไทม์ (Real-time Overview): ',
            'สรุปยอดรวมจำนวนร้านค้าทั้งหมด ไรเดอร์ที่สแตนด์บาย และคำขอสมัครใหม่ที่รอการดำเนินการ',
          ),
          _buildDescriptionLine(
            '4. ระบบคัดกรองและแจ้งเตือนอัจฉริยะ (Pending Alerts): ',
            'แยกแยะรายการคำสมัครใหม่ที่เพิ่งเข้าสู่ระบบ ช่วยให้แอดมินไม่พลาดทุกการอัปเดตข้อมูล',
          ),
          _buildDescriptionLine(
            '5. ระบบจัดการเหตุผลการปฏิเสธ (Disapproval & Feedback Logging): ',
            'บันทึกหมายเหตุและระบุเหตุผลอย่างชัดเจนในกรณีที่เอกสารไม่ผ่านเกณฑ์มาตรฐานของระบบ',
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionLine(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Colors.black87,
          ),
          children: [
            TextSpan(
              text: title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            TextSpan(
              text: desc,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Overview Card / New Registration Card (ไม่เปลี่ยนแปลง)
// ══════════════════════════════════════════════════════════════════════════════
class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final int count;

  const _OverviewCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            Container(
              width: 150,
              height: 95,
              color: iconBg,
              child: Icon(icon, size: 40, color: iconColor),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewRegCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final int count;
  final Color countColor;

  const _NewRegCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.count,
    required this.countColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            Container(
              width: 150,
              height: 95,
              color: iconBg,
              child: Icon(icon, size: 38, color: iconColor),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: countColor,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
