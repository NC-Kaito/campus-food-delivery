// ​// features/rider/home_rider.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/features/rider/profile_rider.dart';
import 'package:flutter_app/features/rider/list_waiting_pickup_order.dart';

// 🚀 นำเข้าไฟล์ที่จำเป็นสำหรับการดึงรูปโปรไฟล์
import 'package:flutter_app/data/services/rider/rider_service.dart';
import 'package:flutter_app/global_data.dart';
import 'package:flutter_app/core/network/dio_client.dart';

class HomeRider extends StatefulWidget {
  const HomeRider({super.key});

  @override
  State<HomeRider> createState() => _HomeRiderState();
}

class _HomeRiderState extends State<HomeRider>
    with SingleTickerProviderStateMixin {
  // สถานะเปิด-ปิดรับงาน
  bool _isOnline = true;

  // 0 = รายวัน, 1 = รายเดือน
  int _selectedIncomeTab = 0;

  // 🚀 ตัวแปรสำหรับเก็บ URL รูปโปรไฟล์
  String? _profileImageUrl;
  final RiderService _riderService = RiderService();

  // กำหนดชุดสีที่ดูสบายตาและพรีเมียมขึ้น
  final Color _primaryOrange = const Color(0xFFF97316);
  final Color _accentBlue = const Color(0xFF3B82F6);
  final Color _bgCoolGray = const Color(0xFFF8FAFC);
  final Color _textDark = const Color(0xFF1E293B);
  final Color _textMuted = const Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    // 🚀 เรียกใช้ฟังก์ชันดึงข้อมูลโปรไฟล์ตอนเปิดหน้า
    _loadRiderProfile();
  }

  // 🚀 ฟังก์ชันดึงข้อมูล Rider
  Future<void> _loadRiderProfile() async {
    try {
      final rider = await _riderService.getRiderByStudentId(
        GlobalData.usernameRider,
      );
      if (mounted) {
        setState(() {
          // หาก backend ของน้องนารีใช้ฟิลด์อื่นเก็บรูปโปรไฟล์ สามารถเปลี่ยนตรงนี้ได้เลยนะครับ
          _profileImageUrl = rider.studentCardImage;
        });
      }
    } catch (e) {
      debugPrint("โหลดข้อมูลโปรไฟล์หน้า Home ไม่สำเร็จ: $e");
    }
  }

  // 🚀 ฟังก์ชันแปลง URL รูปภาพให้สมบูรณ์
  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;
    final String baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/') ? "$baseUrl$rawPath" : "$baseUrl/$rawPath";
  }

  @override
  Widget build(BuildContext context) {
    // เตรียม URL รูปภาพที่สมบูรณ์ไว้ใช้งาน
    final String finalAvatarUrl = _getFinalImageUrl(_profileImageUrl);

    return Scaffold(
      backgroundColor: _bgCoolGray,
      appBar: AppBar(
        backgroundColor: _primaryOrange,
        elevation: 0,
        title: const Text(
          "หน้าหลักไรเดอร์",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
              size: 26,
            ),
            onPressed: () {
              // TODO: เปิดหน้าดูการแจ้งเตือน
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====== 🎯 ส่วนที่ 1: สถานะการทำงาน ======
            _buildStatusHeader(finalAvatarUrl),
            const SizedBox(height: 24),

            // ====== 🎯 ส่วนที่ 2: แดชบอร์ดรายได้ ======
            _buildIncomeDashboard(context),
            const SizedBox(height: 24),

            // ====== 🎯 ส่วนที่ 3: สถิติการทำงาน (สามารถกดไปดูรีวิวได้) ======
            _buildPerformanceSection(context),
            const SizedBox(height: 24),

            // ====== 🎯 ส่วนที่ 4: รายการจัดส่งล่าสุด ======
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "รายการจัดส่งล่าสุด",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  Text(
                    "ดูทั้งหมด",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _accentBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildRecentDeliveriesList(),
            const SizedBox(height: 20),
          ],
        ),
      ),

      // ====== 🎯 Navbar ด้านล่าง ======
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.blueGrey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          selectedItemColor: _primaryOrange,
          unselectedItemColor: Colors.blueGrey.shade300,
          backgroundColor: Colors.white,
          currentIndex: 0,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (index) {
            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ListWaitingPickupOrder(),
                ),
              );
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileRider()),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: "หน้าหลัก",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_rounded),
              label: "รับงาน",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: "บัญชี",
            ),
          ],
        ),
      ),
    );
  }

  // 🧩 ฟังก์ชันวาดส่วนหัวสลับสถานะรับงาน พร้อมรูปโปรไฟล์ (อัปเดตให้รับ URL รูป)
  Widget _buildStatusHeader(String finalAvatarUrl) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _accentBlue.withOpacity(0.06),
            spreadRadius: 2,
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isOnline
                            ? Colors.green.shade400
                            : Colors.grey.shade300,
                        width: 2.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.orange.shade50,
                      // 🚀 นำ URL รูปมาใส่ตรงนี้ครับ
                      backgroundImage: finalAvatarUrl.isNotEmpty
                          ? NetworkImage(finalAvatarUrl)
                          : null,
                      // 🚀 หากไม่มีรูป จะแสดงไอคอนคนแทน
                      child: finalAvatarUrl.isEmpty
                          ? Icon(
                              Icons.person_rounded,
                              size: 40,
                              color: Colors.orange.shade300,
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _isOnline ? Colors.green : Colors.grey.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isOnline ? "กำลังเปิดรับงาน" : "พักการรับงาน",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _isOnline ? Colors.green.shade700 : _textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isOnline
                        ? "ระบบพร้อมส่งงานให้คุณแล้ว"
                        : "เปิดสวิตช์เมื่อพร้อมรับงาน",
                    style: TextStyle(fontSize: 12.5, color: _textMuted),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: _isOnline,
            activeColor: _primaryOrange,
            activeTrackColor: Colors.orange.shade200,
            onChanged: (value) {
              setState(() {
                _isOnline = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeDashboard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _accentBlue.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    title: "รายวัน",
                    isSelected: _selectedIncomeTab == 0,
                    onTap: () => setState(() => _selectedIncomeTab = 0),
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    title: "รายเดือน",
                    isSelected: _selectedIncomeTab == 1,
                    onTap: () => setState(() => _selectedIncomeTab = 1),
                  ),
                ),
              ],
            ),
          ),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _selectedIncomeTab == 0
                ? _buildIncomeSideBySideContent(
                    title: "ยอดที่ได้วันนี้",
                    amount: "฿ 450.00",
                    rounds: "12",
                  )
                : _buildIncomeSideBySideContent(
                    title: "ยอดที่ได้เดือนนี้",
                    amount: "฿ 12,450.00",
                    rounds: "245",
                  ),
          ),

          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RiderIncomeHistoryPage(),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(color: Colors.blue.shade50, width: 1.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "ดูประวัติรายได้ย้อนหลัง",
                    style: TextStyle(
                      color: _accentBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: _accentBlue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? _accentBlue : _textMuted,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeSideBySideContent({
    required String title,
    required String amount,
    required String rounds,
  }) {
    return Padding(
      key: ValueKey(title),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 16,
                      color: Colors.green.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          Container(height: 50, width: 1.5, color: Colors.blue.shade50),
          const SizedBox(width: 24),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.two_wheeler_rounded,
                      size: 16,
                      color: _primaryOrange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "รอบจัดส่งสำเร็จ",
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      rounds,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "รอบ",
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RiderReviewPage()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFFFFF7ED), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.orange.shade100, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFF59E0B),
                      size: 42,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "คะแนนรีวิวของคุณ",
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text(
                            "4.9",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 38,
                              color: Color(0xFF1E293B),
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "/ 5.0",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.orange.shade300,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentDeliveriesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blueGrey.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.restaurant_rounded,
                  color: _accentBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ร้านข้าวมันไก่ป้าณี",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: _textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "จัดส่งเมื่อ 14:30 น.",
                          style: TextStyle(color: _textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "+ ฿ 45.00",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "สำเร็จ",
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// =========================================================================
// 🚀 หน้าสำหรับดูประวัติรายได้ย้อนหลัง
// =========================================================================
class RiderIncomeHistoryPage extends StatefulWidget {
  const RiderIncomeHistoryPage({super.key});

  @override
  State<RiderIncomeHistoryPage> createState() => _RiderIncomeHistoryPageState();
}

class _RiderIncomeHistoryPageState extends State<RiderIncomeHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color _themeBlue = const Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: _themeBlue,
        elevation: 0,
        title: const Text(
          "ประวัติรายได้ย้อนหลัง",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.blue.shade100,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          tabs: const [
            Tab(text: "รายวัน (ย้อนหลัง)"),
            Tab(text: "รายเดือน"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildDailyHistoryList(), _buildMonthlyHistoryList()],
      ),
    );
  }

  Widget _buildDailyHistoryList() {
    final List<Map<String, String>> dailyData = [
      {"date": "26 ส.ค. 2569", "rounds": "12", "amount": "฿ 450.00"},
      {"date": "25 ส.ค. 2569", "rounds": "15", "amount": "฿ 580.00"},
      {"date": "24 ส.ค. 2569", "rounds": "10", "amount": "฿ 380.00"},
      {"date": "23 ส.ค. 2569", "rounds": "14", "amount": "฿ 520.00"},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: dailyData.length,
      itemBuilder: (context, index) {
        final item = dailyData[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _themeBlue.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.blue.shade50),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: _themeBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["date"]!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "จัดส่งสำเร็จ ${item["rounds"]} รอบ",
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                item["amount"]!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthlyHistoryList() {
    final List<Map<String, String>> monthlyData = [
      {"month": "สิงหาคม 2569", "rounds": "245", "amount": "฿ 12,450.00"},
      {"month": "กรกฎาคม 2569", "rounds": "310", "amount": "฿ 15,800.00"},
      {"month": "มิถุนายน 2569", "rounds": "290", "amount": "฿ 14,200.00"},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: monthlyData.length,
      itemBuilder: (context, index) {
        final item = monthlyData[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _themeBlue.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.blue.shade50),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFF10B981),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["month"]!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "รวมจัดส่ง ${item["rounds"]} รอบ",
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                item["amount"]!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =========================================================================
// 🚀 หน้าสำหรับดูรีวิวของไรเดอร์
// =========================================================================
class RiderReviewPage extends StatelessWidget {
  const RiderReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF97316),
        title: const Text(
          "รีวิวจากลูกค้า",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (i) => const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 20,
                        ),
                      ),
                    ),
                    Text(
                      "เมื่อวานนี้",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  "บริการดีมากครับ พูดจาสุภาพ ส่งอาหารรวดเร็วและกล่องอาหารยังอยู่ในสภาพสมบูรณ์ ประทับใจมากครับ!",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.grey.shade200,
                      child: const Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "คุณลูกค้า (ไม่ระบุชื่อ)",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
