// data/models/menu_model.dart
import 'package:flutter_app/data/models/restaurant_model.dart';

class MenuModel {
  int? menuId;
  String? menuName;
  String? description;
  String? menuImage;
  double? price; // ราคาปกติ หรือ ราคาข้าวราด 1 อย่าง
  double? price2; // 🎯 ราคาข้าวราด 2 อย่าง (เป็น null ได้ สำหรับเมนูทั่วไป)
  double? price3; // 🎯 ราคาข้าวราด 3 อย่าง (เป็น null ได้ สำหรับเมนูทั่วไป)
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
    this.price2,
    this.price3,
    this.status,
    this.restaurantId,
    this.typeMenuId,
    this.typeMenuName,
    this.restaurant,
  });

  // 📥 แปลงจาก JSON หลังบ้าน (Spring Boot) เข้าสู่ Object บน Flutter
  factory MenuModel.fromJson(Map json) {
    return MenuModel(
      menuId: json['menuid'] ?? json['menuId'],
      menuName: json['menuname'] ?? json['menuName'],
      description: json['description'],
      menuImage: json['imageurl'] ?? json['imageUrl'],
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,

      // 🎯 ดึงราคา 2 อย่าง และ 3 อย่าง พร้อมแปลงเป็น double
      price2: json['price2'] != null
          ? (json['price2'] as num).toDouble()
          : null,
      price3: json['price3'] != null
          ? (json['price3'] as num).toDouble()
          : null,

      status: json['status'],

      restaurantId: json['restaurant'] != null
          ? json['restaurant']['username']
          : (json['restaurantId'] ?? json['restaurant_id']),

      typeMenuId: json['typemenu'] != null
          ? json['typemenu']['typemenuId']
          : (json['typeMenuId'] ?? json['type_menu_id']),
      typeMenuName: json['typemenu'] != null
          ? json['typemenu']['typemenuName']
          : json['typeMenuName'],

      restaurant: json['restaurant'] != null
          ? RestaurantModel.fromJson(json['restaurant'])
          : null,
    );
  }

  // 📤 แปลงจาก Object บน Flutter กลับเป็น JSON (ส่งค่าไป Save/Update ฝั่ง Spring Boot)
  Map toJson() {
    return {
      'menuid': menuId,
      'menuname': menuName,
      'description': description,
      'imageurl': menuImage,
      'price': price,
      'price2': price2, // 🎯 แนบราคา 2 อย่าง
      'price3': price3, // 🎯 แนบราคา 3 อย่าง
      'status': status,
      if (restaurantId != null) 'restaurant': {'username': restaurantId},
      if (restaurantId != null) 'restaurantId': restaurantId,
      if (typeMenuId != null) 'typemenu': {'typemenuId': typeMenuId},
      if (typeMenuId != null) 'typeMenuId': typeMenuId,
      if (typeMenuName != null) 'typeMenuName': typeMenuName,
    };
  }
}
