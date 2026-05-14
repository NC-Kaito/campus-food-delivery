class MajorModel {
  int? majorId;
  String? majorName;
  int? facultyId; // เก็บแค่ ID ไว้สำหรับส่งไป API หรือใช้ Filter
  String? facultyName; // เก็บชื่อคณะไว้สำหรับแสดงผลในหน้า UI (ถ้ามี)

  // 1. Constructor
  MajorModel({this.majorId, this.majorName, this.facultyId, this.facultyName});

  factory MajorModel.fromJson(Map<String, dynamic> json) {
    return MajorModel(
      majorId: json['majorid'],
      majorName: json['majorname'],
      facultyId: json['facultyid'],
      facultyName: json['facultyname'],
    );
  }

  // 3. To JSON (สำหรับส่งข้อมูลไปบันทึก)
  Map<String, dynamic> toJson() {
    return {'majorId': majorId, 'majorName': majorName, 'facultyId': facultyId};
  }
}
