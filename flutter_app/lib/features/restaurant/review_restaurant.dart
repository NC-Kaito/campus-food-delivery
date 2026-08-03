// features/restaurant/review_restaurant.dart
import 'package:flutter/material.dart';

// 🎯 Placeholder — ยังไม่มีหน้านี้ในโค้ดที่ให้มา
// ถ้ามีหน้ารีวิวจริงอยู่แล้ว ลบไฟล์นี้แล้วแก้ import ใน
// restaurant_drawer.dart ให้ชี้ไปหน้าจริงแทน
class ReviewRestaurant extends StatelessWidget {
  const ReviewRestaurant({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("รีวิว"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black, // ปรับสีตัวอักษรให้ตัดกับพื้นหลัง
        elevation: 1, // เพิ่มมิติให้หน้าจอนิดหน่อยครับ
      ),
      body: const Center(
        child: Text(
          "หน้ารีวิว (รอเชื่อมข้อมูลจริง)",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ),
    );
  }
}
