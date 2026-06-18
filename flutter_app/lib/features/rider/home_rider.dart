// features/rider/home_rider.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/features/rider/profile_rider.dart';
import 'package:flutter_app/features/rider/list_waiting_pickup_order.dart'; // 🎯 1. เพิ่ม Import หน้าเลือกลิสต์งานไรเดอร์เข้ามาครับ

class HomeRider extends StatefulWidget {
  const HomeRider({super.key});

  @override
  State<HomeRider> createState() => _HomeRiderState();
}

class _ThemeColor {
  static const orange = Colors.orange;
}

class _HomeRiderState extends State<HomeRider> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        title: const Text(
          "หน้าหลักไรเดอร์",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              // TODO: เปิดหน้าดูการแจ้งเตือน
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====== 🎯 1. แดชบอร์ดสรุปยอดประจำวัน ======
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDashboardCard(
                      "รายได้วันนี้",
                      "฿ 0.00",
                      Icons.account_balance_wallet,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDashboardCard(
                      "รอบจัดส่ง",
                      "0 รอบ",
                      Icons.two_wheeler,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ====== 🎯 2. Navbar ด้านล่าง ======
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        currentIndex: 0, // ไฮไลต์อยู่ที่หน้าแรก
        onTap: (index) {
          // 🎯 ดักจับเหตุการณ์การคลิกแท็บเพื่อนำทางไปยังหน้าต่างๆ
          if (index == 1) {
            // 🚀 คลิกแท็บ "รับงาน" ให้เปิดหน้า ListWaitingPickupOrder
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ListWaitingPickupOrder(),
              ),
            );
          } else if (index == 2) {
            // คลิกแท็บ "บัญชี" ให้เปิดหน้า ProfileRider
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileRider()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "หน้าหลัก"),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "รับงาน"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "บัญชี"),
        ],
      ),
    );
  }

  // 🧩 ฟังก์ชันวาดการ์ดแดชบอร์ด
  Widget _buildDashboardCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
