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

  // แปลงจาก Object กลับเป็น JSON (สำหรับส่งไป Save/Update)
  Map<String, dynamic> toJson() {
    return {
      'menuId': menuId,
      'menuName': menuName,
      'description': description,
      'imageUrl': menuImage,
      'price': price,
      'status': status,
      'restaurant': {'restaurantId': restaurantId},
      'typeMenu': {'typeMenuId': typeMenuId},
    };
  }
}
