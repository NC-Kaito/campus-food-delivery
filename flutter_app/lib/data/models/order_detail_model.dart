import 'package:flutter_app/data/models/order_detail_addon_model.dart';

class OrderDetailModel {
  final int menuId;
  final int qty;
  final double subTotal;
  final String note;
  final List<OrderDetailAddonModel> addons; // ซ้อนลิสต์ของท็อปปิ้งไว้ข้างใน

  OrderDetailModel({
    required this.menuId,
    required this.qty,
    required this.subTotal,
    required this.note,
    required this.addons,
  });

  // แปลงข้อมูลและสั่ง .toJson() ตัวท็อปปิ้งซ้อนลึกลงไปอีกชั้น
  Map<String, dynamic> toJson() {
    return {
      'menuId': menuId,
      'qty': qty,
      'subTotal': subTotal,
      'note': note,
      'addons': addons
          .map((addon) => addon.toJson())
          .toList(), // 🚀 ส่งต่อ JSON เป็นทอดๆ
    };
  }
}
