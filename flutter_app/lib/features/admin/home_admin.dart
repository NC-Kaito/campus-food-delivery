import 'package:flutter/material.dart';
import 'package:flutter_app/data/services/Admin/admin_service.dart';
import 'package:flutter_app/features/admin/admin_navbar.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  bool isLoading = true;

  int _totalRestaurants = 0;
  int _totalRiders = 0;
  int _newRestaurants = 0;
  int _newRiders = 0;

  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      setState(() => isLoading = true);
      final counts = await _adminService.getDashboardCount();
      if (!mounted) return;
      setState(() {
        _totalRestaurants = counts['totalRestaurant'] ?? 0;
        _newRestaurants = counts['newRestaurant'] ?? 0;
        _totalRiders = counts['totalRider'] ?? 0;
        _newRiders = counts['newRider'] ?? 0;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50 นุ่มนวลสบายตา
      appBar: const AdminNavbar(),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7A00)),
                strokeWidth: 3,
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              color: const Color(0xFFFF7A00),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 36,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Hero / Header Banner ──
                          _buildHeroHeader(),
                          const SizedBox(height: 36),

                          // ── Active Stats Section ──
                          _buildSectionHeader(
                            title: 'ภาพรวมระบบและร้านค้าที่เปิดให้บริการ',
                            subtitle:
                                'สถิติจำนวนร้านค้าและผู้จัดส่งที่ผ่านการตรวจสอบเรียบร้อยแล้ว',
                            badgeText: 'Active Data',
                            badgeColor: const Color(0xFF10B981),
                          ),
                          const SizedBox(height: 18),
                          _buildStatsGrid(
                            cards: [
                              _MetricCard(
                                title: 'ร้านค้าที่เปิดให้บริการ',
                                count: _totalRestaurants,
                                icon: Icons.storefront_rounded,
                                themeColor: const Color(0xFF059669),
                                lightBgColor: const Color(0xFFECFDF5),
                                trendLabel: 'พร้อมให้บริการ',
                              ),
                              _MetricCard(
                                title: 'ผู้จัดส่งที่พร้อมทำงาน',
                                count: _totalRiders,
                                icon: Icons.two_wheeler_rounded,
                                themeColor: const Color(0xFF2563EB),
                                lightBgColor: const Color(0xFFEFF6FF),
                                trendLabel: 'ผ่านการอนุมัติ',
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── System Feature / Guideline Section ──
                          _buildSystemOverviewSection(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // ── Hero / Header ──────────────────────────────────────────────────────────
  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 128, 255, 0),
            Color.fromARGB(255, 175, 231, 145),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 66, 112, 220).withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7A00).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ADMIN PORTAL',
                        style: TextStyle(
                          color: Color(0xFFFF9800),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Live System',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Dashboard ภาพรวมระบบ',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'ยินดีต้อนรับสู่ศูนย์กลางการจัดการและตรวจสอบข้อมูลร้านค้าและผู้จัดส่ง',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          ElevatedButton.icon(
            onPressed: _fetchDashboardData,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              'รีเฟรชข้อมูล',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.08),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withOpacity(0.15)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Title Component ────────────────────────────────────────────────
  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
      ],
    );
  }

  // ── Responsive Grid ────────────────────────────────────────────────────────
  Widget _buildStatsGrid({required List<Widget> cards}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 680) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: card,
                  ),
                )
                .toList(),
          );
        }
        return Row(
          children: cards
              .map(
                (card) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: card,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  // ── System Feature / Description Card ──────────────────────────────────────
  Widget _buildSystemOverviewSection() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 22,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'คู่มือการปฏิบัติงานและมาตรฐานระบบ (System Capabilities)',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'แนวทางการตรวจสอบและขั้นตอนการดำเนินงานของฝ่ายบริหารจัดการระบบ',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _buildFeatureTile(
                step: '01',
                title: 'การอนุมัติร้านค้า (Merchant Verification)',
                desc:
                    'ตรวจสอบใบอนุญาต สุขอนามัย และข้อมูลเมนูอาหารก่อนเปิดรับออเดอร์',
                icon: Icons.store_mall_directory_rounded,
                color: const Color(0xFF059669),
              ),
              _buildFeatureTile(
                step: '02',
                title: 'การตรวจสอบไรเดอร์ (Rider Onboarding)',
                desc:
                    'ตรวจประวัติ เอกสารยานพาหนะ และใบอนุญาตขับขี่เพื่อความปลอดภัยของผู้ใช้บริการ',
                icon: Icons.badge_rounded,
                color: const Color(0xFF2563EB),
              ),
              _buildFeatureTile(
                step: '03',
                title: 'มอนิเตอร์สถานะเรียลไทม์ (Live Monitoring)',
                desc:
                    'ระบบดึงข้อมูลอัปเดตแบบทันท่วงที ให้คุณตัดสินใจได้ทันทีเมื่อมีรายการรอคิว',
                icon: Icons.insights_rounded,
                color: const Color(0xFFFF7A00),
              ),
              _buildFeatureTile(
                step: '04',
                title: 'บันทึกเหตุผลการปฏิเสธ (Feedback Log)',
                desc:
                    'ส่งหมายเหตุและข้อแก้ไขให้พาร์ทเนอร์ปรับปรุงเอกสารได้อย่างตรงจุดและโปร่งใส',
                icon: Icons.edit_note_rounded,
                color: const Color(0xFFE11D48),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile({
    required String step,
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 500,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF2F6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      step,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Reusable Modern Metric Card
// ══════════════════════════════════════════════════════════════════════════════
class _MetricCard extends StatefulWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color themeColor;
  final Color lightBgColor;
  final String trendLabel;
  final bool isHighlight;

  const _MetricCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.themeColor,
    required this.lightBgColor,
    required this.trendLabel,
    this.isHighlight = false,
  });

  @override
  State<_MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<_MetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered
                ? widget.themeColor.withOpacity(0.35)
                : const Color(0xFFE2E8F0),
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.themeColor.withOpacity(0.08)
                  : const Color(0xFF0F172A).withOpacity(0.02),
              blurRadius: _isHovered ? 20 : 8,
              offset: Offset(0, _isHovered ? 10 : 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: widget.lightBgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, size: 26, color: widget.themeColor),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isHighlight
                        ? widget.themeColor.withOpacity(0.12)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.trendLabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: widget.isHighlight
                          ? widget.themeColor
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '${widget.count}',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
                height: 1.0,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
