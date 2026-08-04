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
  final List<dynamic>? orderDetailCurries;

  OrderDetailModel({
    this.orderDetailId,
    required this.menuId,
    required this.qty,
    required this.subTotal,
    required this.note,
    this.menu,
    required this.addons,
    this.orderDetailCurries,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    // 🎯 ดึง Addons โดยเช็คทุกชื่อคีย์ที่เป็นไปได้จาก Backend
    var rawAddons =
        json['orderdetailaddons'] ??
        json['orderDetailAddons'] ??
        json['order_detail_addons'] ??
        json['addons'];

    List<OrderDetailAddonModel> parsedAddons = [];
    if (rawAddons != null && rawAddons is List) {
      parsedAddons = rawAddons
          .map((addon) => OrderDetailAddonModel.fromJson(addon))
          .toList();
    }

    // 🎯 ดึง OrderDetailCurries โดยเช็คทุกชื่อคีย์ที่เป็นไปได้
    var rawCurries =
        json['orderdetailcurries'] ??
        json['orderDetailCurries'] ??
        json['order_detail_curries'] ??
        json['curries'];

    return OrderDetailModel(
      orderDetailId: json['orderdetailid'] ?? json['orderDetailId'],
      menuId: json['menu'] != null
          ? (json['menu']['menuid'] ?? json['menu']['menuId'] ?? 0)
          : (json['menuId'] ?? json['menu_id'] ?? 0),
      qty: json['qty'] ?? 0,
      subTotal: (json['subtotal'] ?? json['subTotal'] ?? 0).toDouble(),
      note: json['note'] ?? "",
      menu: json['menu'] != null ? MenuModel.fromJson(json['menu']) : null,
      addons: parsedAddons,
      orderDetailCurries: rawCurries is List ? rawCurries : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'qty': qty,
      'subTotal': subTotal,
      'note': note,
      'menuId': menuId,
      'addons': addons.map((addon) => addon.toJson()).toList(),
      "orderDetailCurries": orderDetailCurries,
    };

    if (orderDetailId != null) data['orderdetailid'] = orderDetailId;
    return data;
  }
}
