import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/services/Admin/admin_service.dart';
import 'package:flutter_app/features/admin/admin_navbar.dart';
import 'package:flutter_app/features/admin/view_register_rest.dart';

class ListRestaurant extends StatefulWidget {
  const ListRestaurant({super.key});

  @override
  State<ListRestaurant> createState() => _ListRestaurantState();
}

class _ListRestaurantState extends State<ListRestaurant> {
  final AdminService adminService = AdminService();

  List<RestaurantModel> restaurant = [];
  bool isLoading = false;

  void fetchAll() async {
    try {
      setState(() => isLoading = true);
      var restaurantResponse = await adminService.getListRestaurant();
      setState(() => restaurant = restaurantResponse);
    } on DioException catch (e) {
      print(e);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AdminNavbar(),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.store, size: 32, color: Colors.black87),
                      SizedBox(width: 10),
                      Text(
                        'รายการสมัครของร้านค้า (New Registration Restaurant)',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _buildHeaderRow(),
                          const Divider(height: 1, color: Colors.grey),
                          Expanded(
                            child: restaurant.isEmpty
                                ? const Center(
                                    child: Text(
                                      'ไม่มีข้อมูลร้านค้า',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: restaurant.length,
                                    separatorBuilder: (_, __) => const Divider(
                                      height: 1,
                                      color: Colors.grey,
                                    ),
                                    itemBuilder: (context, index) {
                                      final rest = restaurant[index];

                                      // แปลง registerdate (LocalDateTime) → วันที่ และ เวลา
                                      final dt = DateTime.tryParse(
                                        rest.registerDate ?? '',
                                      );
                                      final registerDate = dt != null
                                          ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${(dt.year - 543).toString().substring(2)}'
                                          : '-';
                                      final registerTime = dt != null
                                          ? '${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')} น.'
                                          : '-';

                                      return _buildDataRow(
                                        index: index + 1,
                                        restaurantCode: rest.username ?? '-',
                                        restaurantName:
                                            rest.restaurantName ?? '-',
                                        registerDate: registerDate,
                                        registerTime: registerTime,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  View_RegisterRestaurant(
                                                    restaurant: rest,
                                                    index: index + 1,
                                                  ),
                                            ),
                                          );
                                          fetchAll();
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
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      color: Colors.grey.shade100,
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('$index')),
          Expanded(flex: 2, child: Text(restaurantCode)),
          Expanded(flex: 4, child: Text(restaurantName)),
          Expanded(flex: 2, child: Text(registerDate)),
          Expanded(flex: 2, child: Text(registerTime)),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 56, 242, 62),
                foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: const Text('ดูรายละเอียด', style: TextStyle(fontSize: 13)),
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
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }
}
