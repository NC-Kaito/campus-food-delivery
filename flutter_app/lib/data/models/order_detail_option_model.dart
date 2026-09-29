import 'package:flutter_app/data/models/option_model.dart';

class OrderDetailOptionModel {
  final int optionId;
  final String optionNameAtOrder; // Snapshot ชื่อตัวเลือก ณ ตอนสั่งซื้อ
  final double priceAtOrder; // Snapshot ราคาตัวเลือก ณ ตอนสั่งซื้อ
  int? optionQty;
  final OptionModel? menuOptionDetail;

  OrderDetailOptionModel({
    required this.optionId,
    required this.optionNameAtOrder,
    required this.priceAtOrder,
    this.menuOptionDetail,
    this.optionQty = 1,
  });

  factory OrderDetailOptionModel.fromJson(Map json) {
    // 🎯 ดึง Object ตัวเลือกลูก (Entity ใน Spring Boot เปลี่ยนเป็น menuoptiondetail)
    final rawDetail = json['menuoptiondetail'] ?? json['menuaddondetail'];

    // 🎯 ดึงชื่อตัวเลือกจาก Snapshot ก่อน ถ้าไม่มีจึง fallback ไปดึงจาก Entity Option
    String name =
        json['addonNameAtOrder'] ??
        json['optionNameAtOrder'] ??
        json['addon_name_at_order'] ??
        (rawDetail != null
            ? (rawDetail['optionname'] ??
                  rawDetail['optionName'] ??
                  rawDetail['addonname'] ??
                  'ตัวเลือกเสริม')
            : 'ตัวเลือกเสริม');

    return OrderDetailOptionModel(
      // รองรับทั้ง optionId จากฝั่ง Entity Option และ addondetailid เดิม
      optionId: rawDetail != null
          ? (rawDetail['optionid'] ??
                rawDetail['optionId'] ??
                rawDetail['addondetailid'] ??
                0)
          : (json['optionid'] ??
                json['optionId'] ??
                json['addondetailid'] ??
                0),

      optionNameAtOrder: name,

      priceAtOrder: json['priceAtOrder'] != null
          ? (json['priceAtOrder'] as num).toDouble()
          : (json['price_at_order'] != null
                ? (json['price_at_order'] as num).toDouble()
                : (rawDetail != null
                      ? (rawDetail['optionprice'] ??
                                rawDetail['addonprice'] ??
                                0)
                            .toDouble()
                      : 0.0)),

      optionQty: json['addon_qty'] != null
          ? (json['addon_qty'] as num).toInt()
          : (json['addonQty'] != null
                ? (json['addonQty'] as num).toInt()
                : (json['option_qty'] != null
                      ? (json['option_qty'] as num).toInt()
                      : 1)),

      menuOptionDetail: rawDetail != null
          ? OptionModel.fromJson(rawDetail as Map)
          : null,
    );
  }

  Map toJson() {
    return {
      'optionId': optionId,
      'addondetailid': optionId, // แนบ key เดิมไว้รองรับ DTO เก่า
      'addonNameAtOrder':
          optionNameAtOrder, // ส่ง Snapshot ชื่อตัวเลือกให้ตรงกับ Entity
      'optionNameAtOrder': optionNameAtOrder,
      'priceAtOrder': priceAtOrder,
      'addon_qty': optionQty ?? 1,
      'option_qty': optionQty ?? 1,
    };
  }
}
