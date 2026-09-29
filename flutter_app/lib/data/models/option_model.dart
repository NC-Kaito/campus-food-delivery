class OptionModel {
  int? optionId;
  String? optionName;
  double? optionPrice;

  OptionModel({this.optionId, this.optionName, this.optionPrice});

  factory OptionModel.fromJson(Map json) {
    return OptionModel(
      optionId: json['optionid'] ?? json['optionId'] ?? json['addondetailId'],
      optionName:
          json['optionname'] ??
          json['optionName'] ??
          json['addonname'] ??
          'ตัวเลือกเสริม',
      optionPrice:
          (json['optionprice'] ??
                  json['optionPrice'] ??
                  json['addonprice'] ??
                  0)
              .toDouble(),
    );
  }

  Map toJson() {
    return {
      'optionid': optionId,
      'optionname': optionName,
      'optionprice': optionPrice,
    };
  }
}
