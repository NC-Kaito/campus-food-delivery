class MemberModel {
  // ส่วนเก็บข้อมูล
  // ใช้เก็บค่าต่างๆ เช่น ชื่อผู้ใช้, รหัสผ่าน, อีเมล
  String? username;
  String? password;
  String? firstname;
  String? lastname;
  String? email;
  String? phone;
  //-----------------------------------------------------------------------
  // Constructor (ตัวสร้าง Object)
  // ใช้สำหรับสร้าง Instance หรือ "ตัวตน" ของข้อมูลสมาชิกขึ้นมาใหม่
  MemberModel({
    this.username,
    this.password,
    this.firstname,
    this.lastname,
    this.email,
    this.phone,
  });
  //-----------------------------------------------------------------------
  // toJson() (แปลง Object เป็น Map/JSON)
  //ใช้ตอน ส่งข้อมูลออกจาก App (เช่น ส่งไปเก็บใน Database หรือส่งผ่าน API)
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (username != null) map["username"] = username;
    map["username"] = username;
    map["password"] = password;
    map["firstname"] = firstname;
    map["lastname"] = lastname;
    map["email"] = email;
    map["phone"] = phone;
    return map;
  }

  //-----------------------------------------------------------------------
  // fromJson() (แปลง JSON เป็น Object)
  // ใช้ตอน รับข้อมูลเข้ามาใน App (เช่น ดึงข้อมูลมาจาก Server)
  factory MemberModel.fromJson(Map<String, dynamic> Json) {
    return MemberModel(
      username: Json["username"],
      password: Json["password"],
      firstname: Json["firstname"],
      lastname: Json["lastname"],
      email: Json["email"],
      phone: Json["phone"],
    );
  }
}
