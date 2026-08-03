// features/restaurant/sales_restaurant.dart
import 'package:flutter/material.dart';

// 🎯 Placeholder — ยังไม่มีหน้านี้ในโค้ดที่ให้มา
// ถ้ามีหน้ายอดขายจริงอยู่แล้ว ลบไฟล์นี้แล้วแก้ import ใน
// restaurant_drawer.dart ให้ชี้ไปหน้าจริงแทน
class SalesRestaurant extends StatelessWidget {
  const SalesRestaurant({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("ยอดขาย"),
        backgroundColor: Colors.white,
        foregroundColor: Colors
            .black, // ทำให้ตัวหนังสือและปุ่มย้อนกลับเป็นสีดำ เพื่อให้เห็นชัดบนพื้นขาว
        elevation: 1, // ใส่เงาบางๆ ให้แยกกับเนื้อหาด้านล่างนิดหน่อยครับ
      ),
      body: const Center(
        child: Text(
          "หน้ายอดขาย (รอเชื่อมข้อมูลจริง)",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ),
    );
  }
}
