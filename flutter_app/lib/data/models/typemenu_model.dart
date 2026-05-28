class TypeMenuModel {
  // ===================== ส่วนเก็บข้อมูล =====================

  int? typemenuId;
  String? typemenuName;

  // ==========================================================

  TypeMenuModel({this.typemenuId, this.typemenuName});

  // ==========================================================
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    map["typemenu_id"] = typemenuId;
    map["typemenu_name"] = typemenuName;

    return map;
  }

  // ==========================================================
  factory TypeMenuModel.fromJson(Map<String, dynamic> json) {
    return TypeMenuModel(
      typemenuId: json["typemenu_id"],
      typemenuName: json["typemenu_name"],
    );
  }
}
