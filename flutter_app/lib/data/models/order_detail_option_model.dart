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
    final rawDetail =
        json['menuoptiondetail'] ?? json['menuOptionDetail'] ?? json['option'];

    final int resolvedOptionId =
        json['optionId'] ??
        json['optionid'] ??
        (rawDetail != null
            ? (rawDetail['optionId'] ?? rawDetail['optionid'] ?? 0)
            : 0);

    final String resolvedOptionName =
        json['optionNameAtOrder'] ??
        json['option_name_at_order'] ??
        (rawDetail != null
            ? (rawDetail['optionName'] ?? rawDetail['optionname'] ?? 'ตัวเลือก')
            : 'ตัวเลือก');

    final double resolvedPrice = json['priceAtOrder'] != null
        ? (json['priceAtOrder'] as num).toDouble()
        : (json['price_at_order'] != null
              ? (json['price_at_order'] as num).toDouble()
              : (rawDetail != null
                    ? (rawDetail['optionPrice'] ??
                              rawDetail['optionprice'] ??
                              0)
                          .toDouble()
                    : 0.0));

    final int resolvedQty = json['optionQty'] != null
        ? (json['optionQty'] as num).toInt()
        : (json['option_qty'] != null
              ? (json['option_qty'] as num).toInt()
              : 1);

    return OrderDetailOptionModel(
      optionId: resolvedOptionId,
      optionNameAtOrder: resolvedOptionName,
      priceAtOrder: resolvedPrice,
      optionQty: resolvedQty,
      menuOptionDetail: rawDetail != null
          ? OptionModel.fromJson(Map.from(rawDetail))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'optionId': optionId,
      'optionNameAtOrder': optionNameAtOrder,
      'priceAtOrder': priceAtOrder,
      'optionQty': optionQty ?? 1,
    };
  }
}
