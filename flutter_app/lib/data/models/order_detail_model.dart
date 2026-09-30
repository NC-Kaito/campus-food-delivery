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
  final List<OrderDetailOptionModel> options;

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

    final rawOptions =
        json['orderDetailOptions'] ??
        json['orderdetailoptions'] ??
        json['options'];

    List<OrderDetailOptionModel> parsedOptions = [];

    if (rawOptions is List) {
      parsedOptions = rawOptions
          .map((option) => OrderDetailOptionModel.fromJson(Map.from(option)))
          .toList();
    }

    final rawMenu = json['menu'];

    final String resolvedMenuName =
        json['menuNameAtOrder'] ??
        json['menu_name_at_order'] ??
        (rawMenu != null
            ? (rawMenu['menuName'] ?? rawMenu['menuname'] ?? '')
            : '');

    final double resolvedPrice = json['priceAtOrder'] != null
        ? (json['priceAtOrder'] as num).toDouble()
        : (json['price_at_order'] != null
              ? (json['price_at_order'] as num).toDouble()
              : (rawMenu != null ? (rawMenu['price'] ?? 0).toDouble() : 0.0));

    return OrderDetailModel(
      orderDetailId: json['orderdetailid'] ?? json['orderDetailId'],

      menuId:
          json['menuId'] ??
          json['menu_id'] ??
          (rawMenu != null ? (rawMenu['menuid'] ?? rawMenu['menuId'] ?? 0) : 0),

      menuNameAtOrder: resolvedMenuName,
      priceAtOrder: resolvedPrice,

      qty: json['qty'] ?? 0,

      subTotal: (json['subTotal'] ?? json['subtotal'] ?? 0).toDouble(),

      note: json['note'] ?? '',

      menu: rawMenu != null ? MenuModel.fromJson(Map.from(rawMenu)) : null,

      options: parsedOptions,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'qty': qty,
      'subTotal': subTotal,
      'note': note,
      'menuId': menuId,
      'menuNameAtOrder': menuNameAtOrder,
      'priceAtOrder': priceAtOrder,

      // ส่งเฉพาะ Option
      'options': options.map((option) => option.toJson()).toList(),
    };

    if (orderDetailId != null) {
      data['orderdetailid'] = orderDetailId;
    }

    return data;
  }
}
