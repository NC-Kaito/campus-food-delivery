class FacultyModel {
  int? facultyId;
  String? facultyName;

  FacultyModel({this.facultyId, this.facultyName});

  factory FacultyModel.fromJson(Map<String, dynamic> json) {
    return FacultyModel(
      facultyId: json['facultyid'],
      facultyName: json['facultyname'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'facultyId': facultyId, 'facultyName': facultyName};
  }
}
