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
  final String? cancelDetail;

  // 🎯 เพิ่มตัวแปรสำหรับเก็บเวลาที่จัดส่งสำเร็จ
  final String? successtime;

  final RestaurantModel? restaurant;
  final RiderModel? rider;
  final MemberModel? member;

  final String? orderStatus;
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
    this.rider,
    this.orderStatus,
    this.cancelDetail,
    this.successtime, // 🎯 นำเข้า Constructor
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
      cancelDetail: json['canceldetail'] ?? json['cancelDetail'],

      // 🎯 ดักจับ JSON ก้อนเวลาจัดส่งสำเร็จ และครอบ .toString() ป้องกัน Error จาก Array ของ Spring Boot
      successtime:
          json['successtime']?.toString() ?? json['successTime']?.toString(),

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

      rider: json['rider'] != null ? RiderModel.fromJson(json['rider']) : null,
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
    final Map<String, dynamic> data = {
      'deliveryFee': deliveryFee,
      'totalPrice': totalPrice,
      'latitude': latitude,
      'longitude': longitude,
      'addressDetail': addressDetail,
      'canceldetail': cancelDetail,
      'memberUsername': memberUsername,
      'restaurantUsername': restaurantUsername,
      'items': items.map((item) => item.toJson()).toList(),
    };

    if (orderId != null) data['orderId'] = orderId;
    if (orderStatus != null) data['orderstatus'] = orderStatus;
    if (orderdate != null) data['orderdate'] = orderdate!.toIso8601String();

    // 🎯 แปลงกลับเป็น JSON
    if (successtime != null) data['successtime'] = successtime;

    return data;
  }
}
