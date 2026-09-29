// data/models/order_detail_model.dart
import 'package:flutter_app/data/models/order_detail_option_model.dart';
import 'package:flutter_app/data/models/menu_model.dart';

class OrderDetailModel {
  final int? orderDetailId;
  final int menuId;
  final String menuNameAtOrder; // Snapshot ชื่อเมนู
  final double priceAtOrder; // Snapshot ราคาเมนู
  final int qty;
  final double subTotal;
  final String note;
  final MenuModel? menu;
  final List options;

  OrderDetailModel({
    this.orderDetailId,
    required this.menuId,
    required this.menuNameAtOrder,
    required this.priceAtOrder,
    required this.qty,
    required this.subTotal,
    required this.note,
    this.menu,
    required this.options,
  });

  factory OrderDetailModel.fromJson(Map rawJson) {
    final json = Map.from(rawJson);

    var rawOptions =
        json['orderDetailOptions'] ??
        json['orderdetailoptions'] ??
        json['order_detail_options'] ??
        json['options'] ??
        json['orderdetailaddons'] ??
        json['orderDetailAddons'] ??
        json['order_detail_addons'] ??
        json['addons'];

    List parsedOptions = [];
    if (rawOptions != null && rawOptions is List) {
      parsedOptions = rawOptions
          .map((option) => OrderDetailOptionModel.fromJson(Map.from(option)))
          .toList();
    }

    final rawMenu = json['menu'];

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
      menu: rawMenu != null ? MenuModel.fromJson(Map.from(rawMenu)) : null,
      options: parsedOptions,
    );
  }

  // 🎯 ฟังก์ชัน toJson() ที่หายไป
  Map toJson() {
    final Map data = {
      'qty': qty,
      'subTotal': subTotal,
      'note': note,
      'menuId': menuId,
      'menuNameAtOrder': menuNameAtOrder,
      'priceAtOrder': priceAtOrder,
      // ส่งทั้ง options และ addons เพื่อรองรับ Controller ทั้งแบบเก่าและใหม่
      'options': options.map((option) => option.toJson()).toList(),
      'addons': options.map((option) => option.toJson()).toList(),
    };

    if (orderDetailId != null) {
      data['orderdetailid'] = orderDetailId;
    }
    return data;
  }

  // Getter สำรองกรณี UI เก่าเรียก .addons
  List get addons => options;
}
