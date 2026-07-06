class AddonDetailRequestModel {
  int? addonDetailId; // ← เพิ่มบรรทัดนี้ null = แถวใหม่, มีค่า = แถวเดิม
  String addonname;
  double addonprice;
  bool status;

  AddonDetailRequestModel({
    this.addonDetailId, // ← เพิ่มบรรทัดนี้
    required this.addonname,
    required this.addonprice,
    this.status = true,
  });

  Map<String, dynamic> toJson() {
    return {
      if (addonDetailId != null)
        "addondetailId": addonDetailId, // ← เพิ่มบรรทัดนี้
      "addonname": addonname,
      "addonprice": addonprice,
      "status": status,
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
      "isRequired": isRequired,
      "maxselect": maxselect,
      "status": status,
      "details": details.map((e) => e.toJson()).toList(),
    };
  }
}
