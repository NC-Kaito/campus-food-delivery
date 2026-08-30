// features/rider/home_rider.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/features/rider/account_menagement_rider.dart';
import 'package:flutter_app/features/rider/list_waiting_pickup_order.dart';

import 'package:flutter_app/data/services/rider/rider_service.dart';
import 'package:flutter_app/data/services/order_service.dart';
import 'package:flutter_app/features/rider/navbar_rider.dart';
import 'package:flutter_app/global_data.dart';
import 'package:flutter_app/core/network/dio_client.dart';

class HomeRider extends StatefulWidget {
  const HomeRider({super.key});

  @override
  State<HomeRider> createState() => _HomeRiderState();
}

class _HomeRiderState extends State<HomeRider>
    with SingleTickerProviderStateMixin {
  bool _isOnline = true;

  // 🎯 ตัวแปรเก็บ Filter ที่เลือก (ค่าเริ่มต้นคือ "7 วันย้อนหลัง")
  String _selectedFilter = '7days';
  String _previousFilter = '7days';
  DateTimeRange? _selectedDateRange;

  List<Map<String, dynamic>> _incomeData = [];
  bool _isLoadingIncome = true;

  // 🎯 ตัวแปรเก็บจำนวนออเดอร์แจ้งเตือนที่ปุ่ม "รับงาน"
  int _activeOrderCount = 0;

  String? _profileImageUrl;
  final RiderService _riderService = RiderService();
  final OrderService _orderService = OrderService();

  final Color _primaryOrange = const Color(0xFFF97316);
  final Color _accentBlue = const Color(0xFF3B82F6);
  final Color _bgCoolGray = const Color(0xFFF8FAFC);
  final Color _textDark = const Color(0xFF1E293B);
  final Color _textMuted = const Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _loadRiderProfile();
    _loadIncomeData(); // โหลดข้อมูลทันที
    _fetchActiveOrderCount(); // 🎯 โหลดจำนวนออเดอร์แจ้งเตือน
  }

  Future<void> _loadRiderProfile() async {
    try {
      final rider = await _riderService.getRiderByStudentId(
        GlobalData.usernameRider,
      );
      if (mounted) {
        setState(() {
          _profileImageUrl = rider.studentCardImage;
        });
      }
    } catch (e) {
      debugPrint("โหลดข้อมูลโปรไฟล์หน้า Home ไม่สำเร็จ: $e");
    }
  }

  // 🎯 ฟังก์ชันโหลดจำนวนออเดอร์ใหม่และออเดอร์ที่กำลังจัดส่ง เพื่อโชว์ Badge แดง
  Future<void> _fetchActiveOrderCount() async {
    try {
      String studentId = GlobalData.usernameRider;

      // 1. ดึงงานใหม่ที่ยังไม่มีใครรับ
      final waitingOrders = await _orderService.getWaitingOrders();
      // 2. ดึงงานที่ไรเดอร์คนนี้รับแล้ว แต่ยังส่งไม่เสร็จ
      final activeOrders = await _orderService.getActiveOrders(studentId);

      if (mounted) {
        setState(() {
          _activeOrderCount = waitingOrders.length + activeOrders.length;
        });
      }
    } catch (e) {
      debugPrint("เกิดข้อผิดพลาดในการนับออเดอร์แจ้งเตือน: $e");
    }
  }

  // 🎯 สร้าง List ตัวเลือกใน Dropdown แบบเรียบง่าย ใช้งานสะดวก
  List<DropdownMenuItem<String>> _buildFilterOptions() {
    return const [
      DropdownMenuItem(value: 'today', child: Text('วันนี้')),
      DropdownMenuItem(value: '3days', child: Text('3 วันย้อนหลัง')),
      DropdownMenuItem(value: '7days', child: Text('7 วันย้อนหลัง')),
      DropdownMenuItem(value: '1month', child: Text('1 เดือนย้อนหลัง')),
      DropdownMenuItem(value: '3months', child: Text('3 เดือนย้อนหลัง')),
      DropdownMenuItem(value: '6months', child: Text('6 เดือนย้อนหลัง')),
      DropdownMenuItem(value: 'custom', child: Text('เลือกช่วงเวลาเอง...')),
    ];
  }

  // 🎯 ฟังก์ชันเรียกปฏิทินให้ไรเดอร์เลือกช่วงเวลาแบบ Custom
  Future<void> _pickDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange:
          _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryOrange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      setState(() {
        _selectedFilter = 'custom';
        _selectedDateRange = pickedRange;
      });
      _loadIncomeData();
    } else {
      // ถ้ายกเลิก ให้กลับไปใช้ Filter ก่อนหน้า
      setState(() {
        _selectedFilter = _previousFilter;
      });
    }
  }

  // 🎯 ฟังก์ชันโหลดข้อมูลรายได้ โดยแปลง Filter เป็นวันที่ Start/End
  Future<void> _loadIncomeData() async {
    setState(() => _isLoadingIncome = true);

    DateTime start;
    DateTime end;
    DateTime now = DateTime.now();
    DateTime todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
    DateTime todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (_selectedFilter == 'today') {
      start = todayStart;
      end = todayEnd;
    } else if (_selectedFilter == '3days') {
      start = todayStart.subtract(const Duration(days: 3));
      end = todayEnd;
    } else if (_selectedFilter == '7days') {
      start = todayStart.subtract(const Duration(days: 7));
      end = todayEnd;
    } else if (_selectedFilter == '1month') {
      start = DateTime(now.year, now.month - 1, now.day);
      end = todayEnd;
    } else if (_selectedFilter == '3months') {
      start = DateTime(now.year, now.month - 3, now.day);
      end = todayEnd;
    } else if (_selectedFilter == '6months') {
      start = DateTime(now.year, now.month - 6, now.day);
      end = todayEnd;
    } else if (_selectedFilter == 'custom' && _selectedDateRange != null) {
      start = _selectedDateRange!.start;
      end = DateTime(
        _selectedDateRange!.end.year,
        _selectedDateRange!.end.month,
        _selectedDateRange!.end.day,
        23,
        59,
        59,
      );
    } else {
      start = todayStart.subtract(const Duration(days: 7));
      end = todayEnd;
    }

    try {
      final data = await _orderService.getRiderIncomeByDateRange(
        GlobalData.usernameRider,
        start,
        end,
      );

      if (mounted) {
        setState(() {
          _incomeData = data;
          _isLoadingIncome = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingIncome = false);
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year + 543}";
  }

  // 🎯 แปลงเลขเดือนเป็นชื่อภาษาไทย
  String _getMonthNameThai(String monthStr) {
    const months = [
      "ม.ค.",
      "ก.พ.",
      "มี.ค.",
      "เม.ย.",
      "พ.ค.",
      "มิ.ย.",
      "ก.ค.",
      "ส.ค.",
      "ก.ย.",
      "ต.ค.",
      "พ.ย.",
      "ธ.ค.",
    ];
    int m = int.tryParse(monthStr) ?? 1;
    return months[m - 1];
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;
    final String baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/') ? "$baseUrl$rawPath" : "$baseUrl/$rawPath";
  }

  @override
  Widget build(BuildContext context) {
    final String finalAvatarUrl = _getFinalImageUrl(_profileImageUrl);

    return Scaffold(
      backgroundColor: _bgCoolGray,
      appBar: const NavbarRider(title: "หน้าหลักไรเดอร์"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(finalAvatarUrl),
            const SizedBox(height: 24),
            _buildIncomeDashboard(context),
            const SizedBox(height: 24),
            _buildPerformanceSection(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
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
              ).then((_) {
                // 🎯 รีเฟรชแจ้งเตือนเมื่อกลับมา
                _fetchActiveOrderCount();
              });
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountManagementRider(),
                ),
              );
            }
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: "หน้าหลัก",
            ),
            BottomNavigationBarItem(
              // 🎯 ซ้อน Stack ใส่ Badge แดงตรงปุ่มรับงาน
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.list_alt_rounded),
                  if (_activeOrderCount > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          _activeOrderCount > 99 ? '99+' : '$_activeOrderCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              label: "รับงาน",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: "ตั้งค่าบัญชี",
            ),
          ],
        ),
      ),
    );
  }

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
                      backgroundImage: finalAvatarUrl.isNotEmpty
                          ? NetworkImage(finalAvatarUrl)
                          : null,
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
          // 🎯 เปลี่ยนสี Switch ตรงนี้เป็นสีเขียว
          Switch(
            value: _isOnline,
            activeColor: Colors.green.shade600,
            activeTrackColor: Colors.green.shade200,
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade200,
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
    bool isGroupByMonth = false;
    if (_selectedFilter == '3months' || _selectedFilter == '6months') {
      isGroupByMonth = true;
    } else if ((_selectedFilter == 'custom' ||
            _selectedFilter == 'custom_month') &&
        _selectedDateRange != null) {
      if (_selectedDateRange!.end.difference(_selectedDateRange!.start).inDays >
          31) {
        isGroupByMonth = true;
      }
    }

    List<Map<String, dynamic>> displayTableData = [];
    if (isGroupByMonth) {
      Map<String, Map<String, dynamic>> monthlyMap = {};
      for (var item in _incomeData) {
        try {
          List<String> parts = item['date'].toString().split('/');
          if (parts.length == 3) {
            String monthName = _getMonthNameThai(parts[1]);
            int yearTH = int.parse(parts[2]);
            String monthYear = "$monthName $yearTH";

            if (!monthlyMap.containsKey(monthYear)) {
              monthlyMap[monthYear] = {
                "date": monthYear,
                "rounds": 0,
                "amount": 0.0,
              };
            }
            monthlyMap[monthYear]!["rounds"] += (item['rounds'] as num).toInt();
            monthlyMap[monthYear]!["amount"] += (item['amount'] as num)
                .toDouble();
          }
        } catch (_) {}
      }
      displayTableData = monthlyMap.values.toList();
    } else {
      displayTableData = List.from(_incomeData);
    }

    final double totalAmount = _incomeData.fold<double>(
      0.0,
      (sum, item) => sum + (item['amount'] as num).toDouble(),
    );
    final int totalRounds = _incomeData.fold<int>(
      0,
      (sum, item) => sum + (item['rounds'] as num).toInt(),
    );

    String dateRangeText = "";
    if ((_selectedFilter == 'custom' || _selectedFilter == 'custom_month') &&
        _selectedDateRange != null) {
      if (_selectedDateRange!.start.isAtSameMomentAs(_selectedDateRange!.end)) {
        dateRangeText = _formatDate(_selectedDateRange!.start);
      } else {
        dateRangeText =
            "${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}";
      }
    }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "สรุปรายรับ",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (dateRangeText.isNotEmpty &&
                          (_selectedFilter == 'custom' ||
                              _selectedFilter == 'custom_month'))
                        Text(
                          dateRangeText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFilter == 'custom_month'
                          ? 'custom'
                          : _selectedFilter,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: Colors.blue,
                      ),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                      items: _buildFilterOptions(),
                      onChanged: (val) {
                        if (val != null) {
                          if (val == 'custom') {
                            _previousFilter = _selectedFilter == 'custom_month'
                                ? 'custom'
                                : _selectedFilter;
                            _pickDateRange();
                          } else {
                            setState(() {
                              _selectedFilter = val;
                            });
                            _loadIncomeData();
                          }
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          _buildIncomeSideBySideContent(
            title: "ยอดรวมทั้งหมด",
            amount: "฿ ${totalAmount.toStringAsFixed(0)}",
            rounds: totalRounds.toString(),
          ),

          // ── ส่วนตารางข้อมูล (ยืดเต็มความกว้าง 100%) ──
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: _isLoadingIncome
                  ? const Padding(
                      padding: EdgeInsets.all(30.0),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.blue),
                      ),
                    )
                  : displayTableData.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Center(
                        child: Text(
                          "ไม่มีประวัติการส่งสำเร็จในช่วงเวลานี้",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // หัวตาราง
                        Container(
                          color: Colors.grey.shade50,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  isGroupByMonth ? 'เดือน' : 'วันที่',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const Expanded(
                                flex: 2,
                                child: Text(
                                  'รอบจัดส่ง',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const Expanded(
                                flex: 2,
                                child: Text(
                                  'รายได้ (฿)',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ข้อมูลแต่ละแถว
                        ...displayTableData.map((data) {
                          final double amount = (data['amount'] as num)
                              .toDouble();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade100),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    data['date'].toString(),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    data['rounds'].toString(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    amount.toStringAsFixed(0),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
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
                    fontSize: 26,
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
                        fontSize: 26,
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
          // TODO: ไปหน้าดูรีวิว
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF7ED), Colors.white],
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
}
