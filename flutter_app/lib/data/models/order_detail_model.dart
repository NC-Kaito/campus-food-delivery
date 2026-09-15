// data/models/order_detail_model.dart
import 'package:flutter_app/data/models/order_detail_addon_model.dart';
import 'package:flutter_app/data/models/menu_model.dart';

class OrderDetailModel {
  final int? orderDetailId;
  final int menuId;
  final String menuNameAtOrder; // 🎯 ชื่อเมนู Snapshot
  final double priceAtOrder; // 🎯 ราคาเมนู Snapshot
  final int qty;
  final double subTotal;
  final String note;
  final MenuModel? menu;
  final List addons;
  final List? orderDetailCurries;

  OrderDetailModel({
    this.orderDetailId,
    required this.menuId,
    required this.menuNameAtOrder,
    required this.priceAtOrder,
    required this.qty,
    required this.subTotal,
    required this.note,
    this.menu,
    required this.addons,
    this.orderDetailCurries,
  });

  factory OrderDetailModel.fromJson(Map json) {
    var rawAddons =
        json['orderdetailaddons'] ??
        json['orderDetailAddons'] ??
        json['order_detail_addons'] ??
        json['addons'];

    List parsedAddons = [];
    if (rawAddons != null && rawAddons is List) {
      parsedAddons = rawAddons
          .map((addon) => OrderDetailAddonModel.fromJson(addon))
          .toList();
    }

    var rawCurries =
        json['orderdetailcurries'] ??
        json['orderDetailCurries'] ??
        json['order_detail_curries'] ??
        json['curries'];

    final rawMenu = json['menu'];

    // 🎯 ดึงชื่อและราคาจาก Snapshot ก่อน ถ้าไม่มีค่อย fallback หาจาก menu object
    String resolvedMenuName =
        json['menuNameAtOrder'] ??
        json['menu_name_at_order'] ??
        (rawMenu != null
            ? (rawMenu['menuname'] ?? rawMenu['menuName'] ?? '')
            : 'เมนู (ถูกลบหรือแก้ไข)');

    double resolvedPrice = json['priceAtOrder'] != null
        ? (json['priceAtOrder'] as num).toDouble()
        : (json['price_at_order'] != null
              ? (json['price_at_order'] as num).toDouble()
              : (rawMenu != null ? (rawMenu['price'] ?? 0).toDouble() : 0.0));

    return OrderDetailModel(
      orderDetailId: json['orderdetailid'] ?? json['orderDetailId'],
      menuId: rawMenu != null
          ? (rawMenu['menuid'] ?? rawMenu['menuId'] ?? 0)
          : (json['menuId'] ?? json['menu_id'] ?? 0),
      menuNameAtOrder: resolvedMenuName,
      priceAtOrder: resolvedPrice,
      qty: json['qty'] ?? 0,
      subTotal: (json['subtotal'] ?? json['subTotal'] ?? 0).toDouble(),
      note: json['note'] ?? "",
      menu: rawMenu != null ? MenuModel.fromJson(rawMenu) : null,
      addons: parsedAddons,
      orderDetailCurries: rawCurries is List ? rawCurries : null,
    );
  }

  Map toJson() {
    final Map data = {
      'qty': qty,
      'subTotal': subTotal,
      'note': note,
      'menuId': menuId,
      'menuNameAtOrder':
          menuNameAtOrder, // 🎯 ส่งชื่อ Snapshot ไปตอนสร้าง Order
      'priceAtOrder': priceAtOrder, // 🎯 ส่งราคา Snapshot ไปตอนสร้าง Order
      'addons': addons.map((addon) => addon.toJson()).toList(),
      "orderDetailCurries": orderDetailCurries,
    };

    if (orderDetailId != null) data['orderdetailid'] = orderDetailId;
    return data;
  }
}
