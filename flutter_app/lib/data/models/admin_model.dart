class AdminModel {
  String? username;
  String? password;
  String? firstname;
  String? lastname;

  AdminModel({this.username, this.password, this.firstname, this.lastname});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (username != null) map["username"] = username;
    map["username"] = username;
    map["password"] = password;
    map["firstname"] = firstname;
    map["lastname"] = lastname;
    return map;
  }

  factory AdminModel.fromJson(Map<String, dynamic> Json) {
    return AdminModel(
      username: Json["username"],
      password: Json["password"],
      firstname: Json["firstname"],
      lastname: Json["lastname"],
    );
  }
}
