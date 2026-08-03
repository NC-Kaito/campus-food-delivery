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
    // ฟังก์ชันเล็กๆ ช่วยแปลงค่าให้เป็น boolean เสมอ
    bool parseBool(dynamic value, {bool defaultValue = true}) {
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return defaultValue;
    }

    return MenuAddonDetailModel(
      addonDetailId: json['addondetailid'],
      addonPrice: (json['addonprice'] as num?)?.toDouble(),

      // ← แปลงค่า status ตรงนี้ครับ เพื่อให้รองรับทั้งเลข 1/0 และข้อความ
      status: json['status'] != null ? parseBool(json['status']) : true,

      allowqtystatus: json['allowqtystatus'] != null
          ? parseBool(json['allowqtystatus'], defaultValue: false)
          : false,
      menuAddonGroup: json['menuaddongroup'] != null
          ? MenuAddonGroupModel.fromJson(json['menuaddongroup'])
          : null,
      addonMenu: json['addonmenu'] != null
          ? AddonMenuModel.fromJson(json['addonmenu'])
          : null,
    );
  }
}
