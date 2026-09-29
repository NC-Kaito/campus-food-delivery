class OptionDetailRequestModel {
  int? optionId;
  String optionName;
  double optionPrice;

  OptionDetailRequestModel({
    this.optionId,
    required this.optionName,
    required this.optionPrice,
  });

  Map toJson() {
    return {
      if (optionId != null) ...{
        "optionid": optionId,
        "addondetailId": optionId,
      },
      // ส่งทั้ง key ใหม่และ key เก่าเผื่อ backend บาง endpoint
      "optionname": optionName,
      "addonname": optionName,
      "optionprice": optionPrice,
      "addonprice": optionPrice,
    };
  }

  // Getter/Setter สำรองกรณี UI เก่ายังเรียกชื่อเดิม
  int? get addonDetailId => optionId;
  set addonDetailId(int? value) => optionId = value;

  String get addonname => optionName;
  set addonname(String value) => optionName = value;

  double get addonprice => optionPrice;
  set addonprice(double value) => optionPrice = value;
}

class OptionGroupRequestModel {
  int? optionGroupId;
  int? menuId; // 🎯 ผูกกับเมนูตามโครงสร้างใหม่ (Menu 1 -> N Optiongroup)
  String optionGroupName;
  bool isRequired; // 🎯 เพิ่มฟิลด์บังคับเลือก (is_required)
  bool isMultipleChoice;
  List options;

  OptionGroupRequestModel({
    this.optionGroupId,
    this.menuId,
    required this.optionGroupName,
    this.isRequired = false,
    required this.isMultipleChoice,
    required this.options,
  });

  Map toJson() {
    return {
      if (optionGroupId != null) ...{
        "optiongroupid": optionGroupId,
        "addongroupid": optionGroupId,
      },
      if (menuId != null) "menuId": menuId,
      "optiongroupname": optionGroupName,
      "addongroupname": optionGroupName,
      "is_required": isRequired,
      "is_multiple_choice": isMultipleChoice,
      // ส่งทั้ง "options" และ "details" เพื่อรองรับทั้ง DTO ใหม่และ DTO เดิม
      "options": options.map((e) => e.toJson()).toList(),
      "details": options.map((e) => e.toJson()).toList(),
    };
  }

  // Getter/Setter สำรองกรณี UI เก่ายังเรียกชื่อเดิม
  int? get addonGroupId => optionGroupId;
  set addonGroupId(int? value) => optionGroupId = value;

  String get addongroupname => optionGroupName;
  set addongroupname(String value) => optionGroupName = value;

  bool get is_multiple_choice => isMultipleChoice;
  set is_multiple_choice(bool value) => isMultipleChoice = value;

  List get details => options;
  set details(List value) => options = value;
}

// 🎯 กำหนด typedef เพื่อให้โค้ดหน้า UI เดิมที่เรียกชื่อ Addon... ยังทำงานได้ ไม่เกิด compile error
typedef AddonDetailRequestModel = OptionDetailRequestModel;
typedef AddonGroupRequestModel = OptionGroupRequestModel;
