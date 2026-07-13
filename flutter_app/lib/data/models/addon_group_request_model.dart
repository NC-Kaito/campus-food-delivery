class AddonDetailRequestModel {
  int? addonDetailId;
  String addonname;
  double addonprice;
  bool status;
  bool allowqtystatus; // ← 1. เพิ่มตัวแปรนี้

  AddonDetailRequestModel({
    this.addonDetailId,
    required this.addonname,
    required this.addonprice,
    this.status = true,
    this.allowqtystatus = false, // ← 2. กำหนดค่าเริ่มต้น
  });

  Map<String, dynamic> toJson() {
    return {
      if (addonDetailId != null) "addondetailId": addonDetailId,
      "addonname": addonname,
      "addonprice": addonprice,
      "status": status,
      "allowqtystatus": allowqtystatus, // ← 3. ส่งค่าแปลงเป็น JSON
    };
  }
}

class AddonGroupRequestModel {
  int? addonGroupId;
  String restaurantUsername;
  String addongroupname;
  bool isRequired;
  int maxselect;
  bool status;
  List<AddonDetailRequestModel> details;

  AddonGroupRequestModel({
    this.addonGroupId,
    required this.restaurantUsername,
    required this.addongroupname,
    required this.isRequired,
    required this.maxselect,
    this.status = true,
    required this.details,
  });

  Map<String, dynamic> toJson() {
    return {
      if (addonGroupId != null) "addongroupid": addonGroupId,
      "restaurantUsername": restaurantUsername,
      "addongroupname": addongroupname,
      "required": isRequired,
      "maxselect": maxselect,
      "status": status,
      "details": details.map((e) => e.toJson()).toList(),
    };
  }
}
