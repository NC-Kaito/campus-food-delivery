import 'package:flutter_app/data/models/order_detail_model.dart';

class OrderModel {
  final double deliveryFee;
  final double totalPrice;
  final double latitude;
  final double longitude;
  final String addressDetail;
  final String memberUsername;
  final String restaurantUsername;
  final List<OrderDetailModel> items; // ซ้อนลิสต์ของรายการอาหารทั้งหมด

  OrderModel({
    required this.deliveryFee,
    required this.totalPrice,
    required this.latitude,
    required this.longitude,
    required this.addressDetail,
    required this.memberUsername,
    required this.restaurantUsername,
    required this.items,
  });

  // แปลงร่างครอบจักรวาลกลายเป็นก้อน Single JSON Object ส่งเป้าหมายหา Spring Boot
  Map<String, dynamic> toJson() {
    return {
      'deliveryFee': deliveryFee,
      'totalPrice': totalPrice,
      'latitude': latitude,
      'longitude': longitude,
      'addressDetail': addressDetail,
      'memberUsername': memberUsername,
      'restaurantUsername': restaurantUsername,
      'items': items
          .map((item) => item.toJson())
          .toList(), // 🚀 แตกแขนงลูปอาหารออกไป
    };
  }
}
