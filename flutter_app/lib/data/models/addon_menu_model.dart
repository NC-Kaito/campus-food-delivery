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
