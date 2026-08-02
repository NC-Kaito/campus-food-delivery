import 'package:flutter_app/data/models/addon_menu_model.dart';
import 'package:flutter_app/data/models/menu_addon_group_model.dart';

class MenuAddonDetailModel {
  int? addonDetailId;
  double? addonPrice;
  bool? status;
  bool allowqtystatus;
  MenuAddonGroupModel? menuAddonGroup;
  AddonMenuModel? addonMenu;

  MenuAddonDetailModel({
    this.addonDetailId,
    this.addonPrice,
    this.status,
    this.allowqtystatus = false,
    this.menuAddonGroup,
    this.addonMenu,
  });

  factory MenuAddonDetailModel.fromJson(Map<String, dynamic> json) {
    return MenuAddonDetailModel(
      addonDetailId: json['addondetailid'],
      addonPrice: (json['addonprice'] as num?)?.toDouble(),
      status: json['status'], // ← เพิ่ม
      allowqtystatus: json['allowqtystatus'],
      menuAddonGroup: json['menuaddongroup'] != null
          ? MenuAddonGroupModel.fromJson(json['menuaddongroup'])
          : null,
      addonMenu: json['addonmenu'] != null
          ? AddonMenuModel.fromJson(json['addonmenu'])
          : null,
    );
  }
}
