import 'package:flutter_app/data/models/addon_menu_model.dart';

class MenuAddonDetailModel {
  int? addonDetailId;
  double? addonPrice;
  MenuAddonGroupModel?
  menuAddonGroup; //  แก้ไขชนิดข้อมูลให้เป็นโครงสร้าง Group ที่ถูกต้อง
  AddonMenuModel? addonMenu;

  MenuAddonDetailModel({
    this.addonDetailId,
    this.addonPrice,
    this.menuAddonGroup,
    this.addonMenu,
  });

  factory MenuAddonDetailModel.fromJson(Map<String, dynamic> json) {
    return MenuAddonDetailModel(
      addonDetailId: json['addondetailid'],
      addonPrice: (json['addonprice'] as num?)?.toDouble(),
      //  แก้ไขให้แกะกล่อง Object ออกมาเป็นโมเดลกลุ่มย่อยอย่างถูกต้อง
      menuAddonGroup: json['menuaddongroup'] != null
          ? MenuAddonGroupModel.fromJson(json['menuaddongroup'])
          : null,
      addonMenu: json['addonmenu'] != null
          ? AddonMenuModel.fromJson(json['addonmenu'])
          : null,
    );
  }
}

class MenuAddonGroupModel {
  int? addonGroupId;
  String? addonGroupName;
  bool? isRequired;
  int? maxSelect;

  MenuAddonGroupModel({
    this.addonGroupId,
    this.addonGroupName,
    this.isRequired,
    this.maxSelect,
  });

  factory MenuAddonGroupModel.fromJson(Map<String, dynamic> json) {
    return MenuAddonGroupModel(
      addonGroupId: json['addongroupid'],
      addonGroupName: json['addongroupname'],
      isRequired:
          json['isRequired'], // ถ้าหลังบ้านชื่อคลาสหรือ column เป็นแบบนี้ ปล่อยไว้ตรงตัวได้เลยครับ
      maxSelect: json['maxselect'],
    );
  }
}

class AddonMenuModel {
  int? addonId;
  String? addonName;

  AddonMenuModel({this.addonId, this.addonName});

  factory AddonMenuModel.fromJson(Map<String, dynamic> json) {
    return AddonMenuModel(
      addonId: json['addonid'],
      addonName: json['addonname'],
    );
  }
}
