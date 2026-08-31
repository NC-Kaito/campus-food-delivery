// features/admin/list_restaurant.dart
import 'dart:async'; // 🎯 เพิ่ม import สำหรับ Timer
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/services/Admin/admin_service.dart';
import 'package:flutter_app/features/admin/admin_navbar.dart';
import 'package:flutter_app/features/admin/view_register_rest.dart';

// ============ THEME TOKENS ============
class _Palette {
  static const primary = Color(0xFF2FBA6E);
  static const primaryDark = Color(0xFF1E9E5B);
  static const primarySoft = Color(0xFFE8F9EF);
  static const bg = Color(0xFFF5F7FA);
  static const cardBg = Colors.white;
  static const border = Color(0xFFE7EAF0);
  static const headerBg = Color(0xFFF9FAFB);
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
}

class ListRestaurant extends StatefulWidget {
  const ListRestaurant({super.key});

  @override
  State<ListRestaurant> createState() => _ListRestaurantState();
}

class _ListRestaurantState extends State<ListRestaurant> {
  final AdminService adminService = AdminService();

  List<RestaurantModel> restaurant = [];
  bool isLoading = false;
  Timer? _refreshTimer; // 🎯 สร้างตัวแปรเก็บ Timer

  // 🎯 เพิ่มตัวแปร showLoading เพื่อเช็กว่าจะโชว์วงกลมโหลดไหม
  void fetchAll({bool showLoading = true}) async {
    try {
      if (showLoading && mounted) setState(() => isLoading = true);
      var restaurantResponse = await adminService.getListRestaurant();
      if (mounted) setState(() => restaurant = restaurantResponse);
    } on DioException catch (e) {
      debugPrint(e.toString());
    } finally {
      if (showLoading && mounted) setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAll(); // โหลดครั้งแรกโชว์วงกลมปกติ

    // 🎯 ตั้งเวลาดึงข้อมูลใหม่แบบเบื้องหลังทุก 10 วินาที
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      fetchAll(showLoading: false);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // 🎯 ยกเลิกการนับเวลาเมื่อปิดหน้านี้ทิ้ง
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.bg,
      appBar: const AdminNavbar(),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_Palette.primary),
                strokeWidth: 2.5,
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1350),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ----- Page Header -----
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _Palette.primarySoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: _Palette.primaryDark,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            'รายการสมัครของร้านค้า (New Registration Restaurant)',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: _Palette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // ----- Main Table Card -----
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: _Palette.cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _Palette.border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              _buildHeaderRow(),
                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: _Palette.border,
                              ),
                              Expanded(
                                child: restaurant.isEmpty
                                    ? const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons
                                                  .store_mall_directory_outlined,
                                              size: 48,
                                              color: Colors.grey,
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              'ไม่มีข้อมูลร้านค้า',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: _Palette.textSecondary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: restaurant.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(
                                              height: 1,
                                              thickness: 1,
                                              color: _Palette.border,
                                            ),
                                        itemBuilder: (context, index) {
                                          final rest = restaurant[index];

                                          final dt = DateTime.tryParse(
                                            rest.registerDate ?? '',
                                          );
                                          final registerDate = dt != null
                                              ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${(dt.year > 2500 ? dt.year : dt.year + 543).toString().substring(2)}'
                                              : '-';
                                          final registerTime = dt != null
                                              ? '${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')} น.'
                                              : '-';

                                          return _buildDataRow(
                                            index: index + 1,
                                            restaurantCode:
                                                rest.username ?? '-',
                                            restaurantName:
                                                rest.restaurantName ?? '-',
                                            registerDate: registerDate,
                                            registerTime: registerTime,
                                            onTap: () async {
                                              // 🎯 ใช้ await เพื่อให้รอการกลับมาจากหน้าดูรายละเอียด แล้วค่อยรีเฟรช
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      View_RegisterRestaurant(
                                                        restaurant: rest,
                                                        index: index + 1,
                                                      ),
                                                ),
                                              );
                                              fetchAll(showLoading: false);
                                            },
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      color: _Palette.headerBg,
      child: Row(
        children: const [
          _HeaderCell(text: 'ลำดับ', flex: 1),
          _HeaderCell(text: 'รหัสร้านค้า', flex: 2),
          _HeaderCell(text: 'ชื่อร้านค้า', flex: 4),
          _HeaderCell(text: 'วันที่สมัคร', flex: 2),
          _HeaderCell(text: 'เวลาสมัคร', flex: 2),
          _HeaderCell(text: 'จัดการ', flex: 2),
        ],
      ),
    );
  }

  Widget _buildDataRow({
    required int index,
    required String restaurantCode,
    required String restaurantName,
    required String registerDate,
    required String registerTime,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              '$index',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _Palette.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              restaurantCode,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _Palette.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              restaurantName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _Palette.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              registerDate,
              style: const TextStyle(
                fontSize: 13.5,
                color: _Palette.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              registerTime,
              style: const TextStyle(
                fontSize: 13.5,
                color: _Palette.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text(
                    'ดูรายละเอียด',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Palette.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;

  const _HeaderCell({required this.text, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: Color.fromARGB(255, 69, 159, 255),
        ),
      ),
    );
  }
}
