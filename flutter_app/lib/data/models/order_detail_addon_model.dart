// data/models/order_detail_addon_model.dart
import 'package:flutter_app/data/models/menu_addon_detail_model.dart';

class OrderDetailAddonModel {
  final int addonDetailId;
  final String addonNameAtOrder; // 🎯 เก็บชื่อ Add-on ณ ตอนสั่งซื้อ
  final double priceAtOrder;
  int? addonQty;

  final MenuAddonDetailModel? menuAddonDetail;

  OrderDetailAddonModel({
    required this.addonDetailId,
    required this.addonNameAtOrder,
    required this.priceAtOrder,
    this.menuAddonDetail,
    this.addonQty,
  });

  factory OrderDetailAddonModel.fromJson(Map json) {
    final rawDetail = json['menuaddondetail'];

    // 🎯 ดึงชื่อ Add-on จาก Snapshot ก่อน ถ้าไม่มีค่อย fallback ไปดึงจาก entity
    String name =
        json['addonNameAtOrder'] ??
        json['addon_name_at_order'] ??
        (rawDetail != null && rawDetail['addonmenu'] != null
            ? (rawDetail['addonmenu']['addonname'] ??
                  rawDetail['addonmenu']['addonName'] ??
                  '')
            : '');

    return OrderDetailAddonModel(
      addonDetailId: rawDetail != null
          ? (rawDetail['addondetailid'] ?? rawDetail['addonDetailId'] ?? 0)
          : (json['addondetailid'] ?? json['addonDetailId'] ?? 0),

      addonNameAtOrder: name,

      priceAtOrder: json['priceAtOrder'] != null
          ? (json['priceAtOrder'] as num).toDouble()
          : (json['price_at_order'] != null
                ? (json['price_at_order'] as num).toDouble()
                : (rawDetail != null
                      ? (rawDetail['addonprice'] ?? 0).toDouble()
                      : 0.0)),

      addonQty: json['addon_qty'] != null
          ? (json['addon_qty'] as num).toInt()
          : (json['addonQty'] != null ? (json['addonQty'] as num).toInt() : 1),

      menuAddonDetail: rawDetail != null
          ? MenuAddonDetailModel.fromJson(rawDetail)
          : null,
    );
  }

  Map toJson() {
    return {
      'addondetailid': addonDetailId,
      'addonNameAtOrder': addonNameAtOrder, // 🎯 ส่ง Snapshot ไปบันทึก
      'priceAtOrder': priceAtOrder,
      'addon_qty': addonQty,
    };
  }
}
