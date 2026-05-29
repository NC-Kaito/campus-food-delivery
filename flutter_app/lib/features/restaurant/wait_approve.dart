import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/global_data.dart';
import 'package:flutter_app/features/restaurant/login_restaurant.dart';
import 'package:flutter_app/features/restaurant/update_register.dart';

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

  // ฟังก์ชันออกจากระบบ: ทำงานเหมือนกันทุกสถานะ
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
    // เช็กสถานะเพื่อเปลี่ยนหน้าตา UI
    final bool isRejected = widget.verificationStatus == 'false';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 24.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── หัวข้อ สมัครร้านค้า ──
                  const Text(
                    'สมัครร้านค้า',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF8C00),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── ผลการตรวจสอบข้อมูล ──
                  const Text(
                    'ผลการตรวจสอบข้อมูล',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── ข้อความสถานะ ──
                  Text(
                    isRejected ? 'ไม่ผ่าน' : 'กรุณารอเจ้าหน้าที่ตรวจสอบข้อมูล',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isRejected ? Colors.red : const Color(0xFFD4AF37),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── กล่องแสดงเนื้อหาตรงกลาง ──
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: isRejected
                          ? Colors.white
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: isRejected
                        ? Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                widget.notApproveDetail ?? 'ไม่ระบุหมายเหตุ',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/waitApprove.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),

                  // ── เวลาทำการ ──
                  const Text(
                    'เวลาทำการ จันทร์-ศุกร์ 08:00-16:00',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 48),

                  // ── ปุ่ม ดูข้อมูล (เปิดให้กดไปหน้า UpdateRegister ได้เสมอ) ──
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UpdateRegisterFields(
                              // ✅ ส่งแค่นี้พอครับ เส้นสีแดงจะหายทันที
                              verificationStatus: widget.verificationStatus,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF76FF03),
                        foregroundColor: const Color(0xFF1B5E20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'ดูข้อมูล',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── ปุ่ม ออกจากระบบ (เปิดให้กดทำงานได้เสมอ) ──
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _handleLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE0E0E0),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'ออกจากระบบ',
                        style: TextStyle(
                          fontSize: 18,
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
}
