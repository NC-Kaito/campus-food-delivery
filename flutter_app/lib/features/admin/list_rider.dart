import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/rider_model.dart';
import 'package:flutter_app/data/services/Admin/admin_service.dart';
import 'package:flutter_app/features/admin/admin_navbar.dart';
import 'package:flutter_app/features/admin/view_register_rider.dart';

class ListRider extends StatefulWidget {
  const ListRider({super.key});

  @override
  State<ListRider> createState() => _ListRiderState();
}

class _ListRiderState extends State<ListRider> {
  final AdminService adminService = AdminService();

  List<RiderModel> riderList = []; // เปลี่ยนชื่อตัวแปรให้สื่อความหมาย
  bool isLoading = false;

  void fetchAll() async {
    try {
      setState(() => isLoading = true);
      var riderResponse = await adminService.getListRider();
      setState(() => riderList = riderResponse);
    } on DioException catch (e) {
      debugPrint(e.toString());
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
                      Icon(
                        Icons.delivery_dining,
                        size: 32,
                        color: Colors.black87,
                      ), // เปลี่ยนเป็นไอคอนรถส่งของให้ตรงบริบท
                      SizedBox(width: 10),
                      Text(
                        'รายการสมัครของผู้จัดส่ง (New Registration Rider)',
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
                            child: riderList.isEmpty
                                ? const Center(
                                    child: Text(
                                      'ไม่มีข้อมูลผู้สมัครจัดส่ง',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: riderList.length,
                                    separatorBuilder: (_, __) => const Divider(
                                      height: 1,
                                      color: Colors.grey,
                                    ),
                                    itemBuilder: (context, index) {
                                      final ri = riderList[index];

                                      // --- การจัดการชื่อ-นามสกุล ---
                                      final fullName =
                                          '${ri.firstName ?? '-'} ${ri.lastName ?? ''}'
                                              .trim();

                                      // --- การจัดการวันที่และเวลาสมัคร ---
                                      final dt = DateTime.tryParse(
                                        ri.registerDate ?? '',
                                      );
                                      final registerDate = dt != null
                                          ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${(dt.year > 2500 ? dt.year : dt.year + 543).toString().substring(2)}'
                                          : '-';
                                      final registerTime = dt != null
                                          ? '${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')} น.'
                                          : '-';

                                      return _buildDataRow(
                                        index: index + 1,
                                        studentid: ri.studentid ?? '-',
                                        riderFullName:
                                            fullName, // ✨ ส่งชื่อที่รวมแล้วไปแสดงผล
                                        registerDate: registerDate,
                                        registerTime: registerTime,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  View_RegisterRider(
                                                    rider: ri,
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
          _HeaderCell(text: 'รหัสผู้จัดส่ง', flex: 2),
          _HeaderCell(text: 'ชื่อ - นามสกุล', flex: 4),
          _HeaderCell(text: 'วันที่สมัคร', flex: 2),
          _HeaderCell(text: 'เวลาสมัคร', flex: 2),
          _HeaderCell(text: 'จัดการ', flex: 2),
        ],
      ),
    );
  }

  Widget _buildDataRow({
    required int index,
    required String studentid,
    required String riderFullName,
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
          Expanded(flex: 2, child: Text(studentid)),
          Expanded(
            flex: 4,
            child: Text(
              riderFullName, // ✨ แสดงผลชื่อและนามสกุล
              style: const TextStyle(color: Colors.black87),
            ),
          ),
          Expanded(flex: 2, child: Text(registerDate)),
          Expanded(flex: 2, child: Text(registerTime)),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64DD17), // สีเขียวตามต้นแบบ
                  foregroundColor: Colors.black,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 70,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'ดูรายละเอียด',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }
}
