// data/models/menu_model.dart
import 'package:flutter_app/data/models/restaurant_model.dart';

class MenuModel {
  int? menuId;
  String? menuName;
  String? description;
  String? menuImage;
  double? price;
  bool? status;
  String? restaurantId;
  int? typeMenuId;
  String? typeMenuName; // สำหรับนำมาแสดงผลหมวดหมู่ใน UI

  RestaurantModel? restaurant;

  MenuModel({
    this.menuId,
    this.menuName,
    this.description,
    this.menuImage,
    this.price,
    this.status,
    this.restaurantId,
    this.typeMenuId,
    this.typeMenuName,
    this.restaurant,
  });

  // 📥 แปลงจาก JSON หลังบ้าน (Spring Boot) เข้าสู่ Object บน Flutter
  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
      menuId: json['menuid'],
      menuName: json['menuname'],
      description: json['description'],
      menuImage: json['imageurl'],
      price: json['price']?.toDouble(),
      status: json['status'],

      restaurantId: json['restaurant'] != null
          ? json['restaurant']['username']
          : null,

      typeMenuId: json['typemenu'] != null
          ? json['typemenu']['typemenuId']
          : null,
      typeMenuName: json['typemenu'] != null
          ? json['typemenu']['typemenuName']
          : null,

      restaurant: json['restaurant'] != null
          ? RestaurantModel.fromJson(json['restaurant'])
          : null,
    );
  }

  // 📤 แปลงจาก Object บน Flutter กลับเป็น JSON (ส่งค่าไป Save/Update ฝั่ง Spring Boot)
  Map<String, dynamic> toJson() {
    return {
      'menuid': menuId,
      'menuname': menuName,
      'description': description,
      'imageurl': menuImage,
      'price': price,
      'status': status,
      // ส่งโครงสร้างความสัมพันธ์ความเชื่อมโยงเป็น Object ซ้อนตามสไตล์ JPA/Hibernate
      if (restaurantId != null) 'restaurant': {'username': restaurantId},
      if (typeMenuId != null) 'typemenu': {'typemenuId': typeMenuId},
    };
  }
}
