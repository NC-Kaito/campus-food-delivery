// data/models/order_model.dart
import 'package:flutter_app/data/models/member_model.dart';
import 'package:flutter_app/data/models/order_detail_model.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/rider_model.dart';

class OrderModel {
  final int? orderId;
  final double deliveryFee;
  final double totalPrice;
  final double latitude;
  final double longitude;
  final String addressDetail;
  final String memberUsername;
  final String restaurantUsername;
  final DateTime? orderdate;

  final RestaurantModel? restaurant;
  final RiderModel? rider; // 🎯 รับก้อนอ็อบเจ็กต์ Rider เข้ามา
  final MemberModel? member;

  final String?
  orderStatus; // 🎯 พี่เติมตัวนี้กลับมาให้ เพื่อใช้วาด Timeline ครับ
  final List<OrderDetailModel> items;

  OrderModel({
    this.orderId,
    required this.deliveryFee,
    required this.totalPrice,
    required this.latitude,
    required this.longitude,
    required this.addressDetail,
    this.orderdate,
    required this.memberUsername,
    required this.restaurantUsername,
    this.member,
    this.restaurant,
    this.rider, // 🎯
    this.orderStatus, // 🎯
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['orderId'] ?? json['orderid'],
      deliveryFee: (json['deliveryFee'] ?? json['delivery_fee'] ?? 0)
          .toDouble(),
      totalPrice: (json['totalPrice'] ?? json['totalprice'] ?? 0).toDouble(),
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      addressDetail: json['addressDetail'] ?? json['addressdetail'] ?? "",

      memberUsername: json['member'] != null
          ? json['member']['username'] ?? ""
          : "",
      restaurantUsername: json['restaurant'] != null
          ? json['restaurant']['username'] ?? ""
          : "",

      member: json['member'] != null
          ? MemberModel.fromJson(json['member'])
          : null,
      restaurant: json['restaurant'] != null
          ? RestaurantModel.fromJson(json['restaurant'])
          : null,

      // 🎯 ดักจับ JSON ก้อนไรเดอร์ และแปลงเข้าโมเดล
      rider: json['rider'] != null ? RiderModel.fromJson(json['rider']) : null,

      // 🎯 ดักจับสถานะออเดอร์จากฐานข้อมูล
      orderStatus: json['orderstatus'] ?? json['orderStatus'],

      items: (json['orderDetails'] != null)
          ? (json['orderDetails'] as List)
                .map((item) => OrderDetailModel.fromJson(item))
                .toList()
          : (json['items'] != null
                ? (json['items'] as List)
                      .map((item) => OrderDetailModel.fromJson(item))
                      .toList()
                : []),
      orderdate: json['orderdate'] != null
          ? DateTime.parse(json['orderdate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'deliveryFee': deliveryFee,
      'totalPrice': totalPrice,
      'latitude': latitude,
      'longitude': longitude,
      'addressDetail': addressDetail,
      'memberUsername': memberUsername,
      'restaurantUsername': restaurantUsername,
      'orderstatus': orderStatus,
      'orderdate': orderdate?.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}
