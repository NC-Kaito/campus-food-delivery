class MemberModel {
  String? username;
  String? password;
  String? firstname;
  String? lastname;
  String? email;
  String? phone;
  String? profileimg;
  double? latitude;
  double? longitude;
  String? defaultlocation;

  MemberModel({
    this.username,
    this.password,
    this.firstname,
    this.lastname,
    this.email,
    this.phone,
    this.profileimg,
    this.latitude,
    this.longitude,
    this.defaultlocation,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (username != null) map["username"] = username;
    map["password"] = password;
    map["firstname"] = firstname;
    map["lastname"] = lastname;
    map["email"] = email;
    map["phone"] = phone;
    map["profileimg"] = profileimg;
    map["latitude"] = latitude;
    map["longitude"] = longitude;

    // 🎯 ส่งทั้งแบบ CamelCase และ Lowercase เพื่อป้องกันปัญหาฝั่ง API
    map["defaultLocation"] = defaultlocation;
    map["defaultlocation"] = defaultlocation;
    return map;
  }

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      username: json["username"],
      password: json["password"],
      firstname: json["firstname"],
      lastname: json["lastname"],
      email: json["email"],
      phone: json["phone"],
      profileimg: json["profileimg"],
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      defaultlocation: json['defaultLocation'] ?? json['defaultlocation'],
    );
  }
}
