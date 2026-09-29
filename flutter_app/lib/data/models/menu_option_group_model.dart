import 'option_model.dart';

class OptionGroupModel {
  int? optionGroupId;
  String? optionGroupName;
  bool isRequired;
  bool isMultipleChoice;
  List? options;

  OptionGroupModel({
    this.optionGroupId,
    this.optionGroupName,
    this.isRequired = false,
    this.isMultipleChoice = false,
    this.options,
  });

  factory OptionGroupModel.fromJson(Map json) {
    return OptionGroupModel(
      // รองรับทั้งคีย์ใหม่จาก Spring Boot และคีย์เก่าที่อาจส่งมา
      optionGroupId:
          json['optiongroupid'] ??
          json['optionGroupId'] ??
          json['addongroupid'],
      optionGroupName:
          json['optiongroupname'] ??
          json['optionGroupName'] ??
          json['addongroupname'],
      isRequired: json['is_required'] ?? json['isRequired'] ?? false,
      isMultipleChoice:
          json['is_multiple_choice'] ?? json['isMultipleChoice'] ?? false,
      options:
          (json['options'] ??
                  json['details'] ??
                  json['menuaddondetails'] as List?)
              ?.map((e) => OptionModel.fromJson(e as Map))
              .toList() ??
          [],
    );
  }

  Map toJson() {
    return {
      'optiongroupid': optionGroupId,
      'optiongroupname': optionGroupName,
      'is_required': isRequired,
      'is_multiple_choice': isMultipleChoice,
      if (options != null) 'options': options!.map((e) => e.toJson()).toList(),
    };
  }
}
