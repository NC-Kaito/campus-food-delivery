// data/models/order_detail_model.dart
import 'package:flutter_app/data/models/order_detail_addon_model.dart';
import 'package:flutter_app/data/models/menu_model.dart'; // 🎯 อิมพอร์ตโมเดลเมนูอาหารเข้ามาด้วยนะครับ

class OrderDetailModel {
  final int? orderDetailId;
  final int menuId;
  final int qty;
  final double subTotal;
  final String note;
  final MenuModel? menu; // 🎯 เพิ่มฟิลด์รับวัตถุข้อมูลเมนู (รวมชื่อและรูปภาพ)
  final List<OrderDetailAddonModel> addons;

  OrderDetailModel({
    this.orderDetailId,
    required this.menuId,
    required this.qty,
    required this.subTotal,
    required this.note,
    this.menu, // 🎯
    required this.addons,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      orderDetailId: json['orderdetailid'] ?? json['orderDetailId'],

      menuId: json['menu'] != null
          ? (json['menu']['menuid'] ?? json['menu']['menuId'] ?? 0)
          : (json['menuId'] ?? json['menu_id'] ?? 0),

      qty: json['qty'] ?? 0,
      subTotal: (json['subtotal'] ?? json['subTotal'] ?? 0).toDouble(),
      note: json['note'] ?? "",

      // 🎯 สอยก้อนข้อมูลเมนูอาหารมาแปลงสวมเข้าโมเดลเพื่อนำไปวาดภาพหน้า UI
      menu: json['menu'] != null ? MenuModel.fromJson(json['menu']) : null,

      addons: json['orderDetailAddons'] != null
          ? (json['orderDetailAddons'] as List)
                .map((addon) => OrderDetailAddonModel.fromJson(addon))
                .toList()
          : (json['addons'] != null
                ? (json['addons'] as List)
                      .map((addon) => OrderDetailAddonModel.fromJson(addon))
                      .toList()
                : []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderdetailid': orderDetailId,
      'qty': qty,
      'subtotal': subTotal,
      'note': note,
      'menu': {'menuid': menuId},
      'orderDetailAddons': addons.map((addon) => addon.toJson()).toList(),
    };
  }
}
