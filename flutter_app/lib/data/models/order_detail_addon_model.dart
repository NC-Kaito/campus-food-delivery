// data/models/order_detail_addon_model.dart
import 'package:flutter_app/data/models/menu_addon_detail_model.dart';

class OrderDetailAddonModel {
  final int addonDetailId;
  final double? priceAtOrder;
  final MenuAddonDetailModel?
  menuAddonDetail; // ← เพิ่มใหม่: เก็บรายละเอียดเต็ม (มีชื่อ addon ซ้อนอยู่ข้างใน) ไว้ใช้แสดงผล

  OrderDetailAddonModel({
    required this.addonDetailId,
    this.priceAtOrder,
    this.menuAddonDetail,
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

      // ← เพิ่มบรรทัดนี้: parse object ทั้งก้อนเก็บไว้ (มีชื่อ addon อยู่ข้างใน)
      menuAddonDetail: rawDetail != null
          ? MenuAddonDetailModel.fromJson(rawDetail)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'addondetailid': addonDetailId,
      'priceAtOrder': priceAtOrder ?? 0.0,
    };
  }
}
