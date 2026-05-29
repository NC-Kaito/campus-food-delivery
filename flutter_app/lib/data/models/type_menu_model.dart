class TypeMenuModel {
  // ===================== ส่วนเก็บข้อมูล =====================

  int? typemenuId;
  String? typemenuName;

  // ==========================================================

  TypeMenuModel({this.typemenuId, this.typemenuName});

  // ==========================================================
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    // ✅ ปรับแก้ Key ให้ตรงกับฝั่ง Java Spring Boot (ไม่มีตัวขีดล่าง _)
    map["typemenuId"] = typemenuId;
    map["typemenuName"] = typemenuName;

    return map;
  }

  // ==========================================================
  factory TypeMenuModel.fromJson(Map<String, dynamic> json) {
    return TypeMenuModel(
      // ✅ ปรับแก้ Key ให้ดึงตามค่าจริงจากหลังบ้าน
      typemenuId: json["typemenuId"],
      typemenuName: json["typemenuName"],
    );
  }
}
