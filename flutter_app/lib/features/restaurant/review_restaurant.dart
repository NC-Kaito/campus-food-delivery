// features/restaurant/review_restaurant.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/features/restaurant/restaurant_scaffold.dart';

// 🎯 Placeholder — ยังไม่มีหน้านี้ในโค้ดที่ให้มา
// ถ้ามีหน้ารีวิวจริงอยู่แล้ว ลบไฟล์นี้แล้วแก้ import ใน
// restaurant_drawer.dart ให้ชี้ไปหน้าจริงแทน
class ReviewRestaurant extends StatelessWidget {
  const ReviewRestaurant({super.key});

  @override
  Widget build(BuildContext context) {
    return const RestaurantScaffold(
      title: "รีวิว",
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          "หน้ารีวิว (รอเชื่อมข้อมูลจริง)",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ),
    );
  }
}
