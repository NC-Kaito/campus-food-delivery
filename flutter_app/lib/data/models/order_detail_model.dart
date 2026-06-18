// data/models/order_detail_model.dart
import 'package:flutter_app/data/models/order_detail_addon_model.dart';
import 'package:flutter_app/data/models/menu_model.dart';

class OrderDetailModel {
  final int? orderDetailId;
  final int menuId;
  final int qty;
  final double subTotal;
  final String note;
  final MenuModel? menu;
  final List<OrderDetailAddonModel> addons;

  OrderDetailModel({
    this.orderDetailId,
    required this.menuId,
    required this.qty,
    required this.subTotal,
    required this.note,
    this.menu,
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
    final Map<String, dynamic> data = {
      'qty': qty,
      // 🎯 แก้เป็น subTotal (ตัว T ใหญ่) เพื่อให้ตรงกับฝั่ง Java เด๊ะๆ ครับ
      'subTotal': subTotal,
      'note': note,
      'menuId': menuId,
      'addons': addons.map((addon) => addon.toJson()).toList(),
    };

    if (orderDetailId != null) data['orderdetailid'] = orderDetailId;
    return data;
  }
}
