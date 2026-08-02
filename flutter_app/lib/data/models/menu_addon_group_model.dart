import 'package:flutter_app/data/models/menu_addon_detail_model.dart';

class MenuAddonGroupModel {
  int? addonGroupId;
  String? addonGroupName;
  bool? isRequired;
  int? maxSelect;
  bool? status;
  int? menuCount;
  List<MenuAddonDetailModel>? details;

  MenuAddonGroupModel({
    this.addonGroupId,
    this.addonGroupName,
    this.isRequired,
    this.maxSelect,
    this.status = true,
    this.menuCount = 0,
    this.details,
  });

  factory MenuAddonGroupModel.fromJson(Map<String, dynamic> json) {
    return MenuAddonGroupModel(
      addonGroupId: json['addongroupid'],
      addonGroupName: json['addongroupname'],
      isRequired: json['required'],
      maxSelect: json['maxselect'],
      status: json['status'] ?? true,
      menuCount: json['menuCount'] ?? 0,
      details: (json['menuaddondetails'] as List<dynamic>? ?? [])
          .map((e) => MenuAddonDetailModel.fromJson(e))
          .toList(),
    );
  }
}
