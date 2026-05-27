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
      isRequired: json['isRequired'],
      maxSelect: json['maxselect'],
    );
  }
}
