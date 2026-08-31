// data/models/order_detail_addon_model.dart
import 'package:flutter_app/data/models/menu_addon_detail_model.dart';

class OrderDetailAddonModel {
  final int addonDetailId;
  final double? priceAtOrder;
  int? addonQty;

  final MenuAddonDetailModel? menuAddonDetail;

  OrderDetailAddonModel({
    required this.addonDetailId,
    this.priceAtOrder,
    this.menuAddonDetail,
    this.addonQty,
  });

  factory OrderDetailAddonModel.fromJson(Map<String, dynamic> json) {
    final rawDetail = json['menuaddondetail'];

    return OrderDetailAddonModel(
      addonDetailId: rawDetail != null
          ? (rawDetail['addondetailid'] ?? rawDetail['addonDetailId'] ?? 0)
          : (json['addondetailid'] ?? json['addonDetailId'] ?? 0),

      priceAtOrder: json['priceAtOrder'] != null
          ? (json['priceAtOrder'] as num).toDouble()
          : (json['price_at_order'] != null
                ? (json['price_at_order'] as num).toDouble()
                : 0.0),

      // 🎯 ดึงจำนวน Add-on จาก JSON ที่รับมาจาก Spring Boot
      addonQty: json['addon_qty'] != null
          ? (json['addon_qty'] as num).toInt()
          : (json['addonQty'] != null ? (json['addonQty'] as num).toInt() : 1),

      menuAddonDetail: rawDetail != null
          ? MenuAddonDetailModel.fromJson(rawDetail)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'addondetailid': addonDetailId,
      'priceAtOrder': priceAtOrder ?? 0.0,
      'addon_qty': addonQty,
    };
  }
}
