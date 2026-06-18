import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/services/Admin/admin_service.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/features/restaurant/login_restaurant.dart';
import 'package:flutter_app/features/restaurant/restaurant_navbar.dart';

class CloseAccount extends StatefulWidget {
  final RestaurantModel restaurant; // รับค่า Model เข้ามา
  const CloseAccount({super.key, required this.restaurant});

  @override
  State<CloseAccount> createState() => _CloseAccountState();
}

class _CloseAccountState extends State<CloseAccount> {
  final AdminService adminService = AdminService();
  final RestaurantService restaurantService = RestaurantService();
  bool _isLoading = false;

  // ฟังก์ชันยิง API ปิดบัญชี
  Future<void> _doCloseAccount() async {
    setState(() => _isLoading = true);
    try {
      await restaurantService.doCloseAccount(widget.restaurant.username!);

      if (mounted) {
        setState(() => _isLoading = false);

        // แสดงผลความสำเร็จ
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ปิดบัญชีสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );

        // นำทางกลับไปหน้า Login และเคลียร์หน้าเก่าทั้งหมดทิ้ง
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginRestaurant()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เกิดข้อผิดพลาดในการปิดบัญชี'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ฟังก์ชันแสดง Dialog ยืนยันรูปแบบเดียวกับหน้าออกจากระบบ
  void _showConfirmDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel_rounded,
                  color: Color(0xFFE53935),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ปิดบัญชีร้านค้า',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'คุณต้องการปิดบัญชีร้านค้าถาวรใช่หรือไม่?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'ยกเลิก',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // ปิด Dialog
                        _doCloseAccount(); // ยิง API
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'ปิดบัญชี',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const RestaurantNavbar(title: "ปิดบัญชีร้านค้า"),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 25),
                const Icon(
                  Icons.warning_rounded,
                  color: Color.fromARGB(255, 214, 2, 2),
                  size: 50,
                ),
                const SizedBox(height: 15),
                const Text(
                  "ยืนยันการปิดบัญชี",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 255, 115, 0),
                  ),
                ),
                const SizedBox(height: 25),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[800],
                            height: 1.8,
                          ),
                          children: const [
                            TextSpan(
                              text:
                                  "หากคุณดำเนินการปิดบัญชีร้านค้า จะมีผลดังต่อไปนี้:\n\n",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            TextSpan(
                              text: "1. ไม่สามารถกู้คืนบัญชีนี้ได้อีก\n",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  "เมื่อปิดบัญชีแล้ว ข้อมูลทั้งหมดจะถูกลบออกจากระบบถาวร\n\n",
                            ),
                            TextSpan(
                              text: "2. ไม่สามารถรับคำสั่งซื้อได้\n",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  "ร้านค้าของคุณจะถูกถอดออกจากระบบและลูกค้าจะไม่สามารถสั่งซื้ออาหารได้\n\n",
                            ),
                            TextSpan(
                              text: "3. ไม่สามารถเข้าสู่ระบบได้\n",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  "ชื่อผู้ใช้งานและรหัสผ่านนี้จะถูกยกเลิกการใช้งานทันที\n\n",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey[400]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              "ยกเลิก",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => _showConfirmDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              "ปิดบัญชี",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Loading Overlay
            if (_isLoading)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
