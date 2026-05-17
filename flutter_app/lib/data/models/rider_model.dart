class RiderModel {
  String? studentid;
  String? password;
  String? firstName;
  String? lastName;
  String? birthday;
  String? email;
  String? phone;
  String? studentCardImage;
  String? drivingLicenseImg;
  String? vehiclePlate;
  String? vehicleImage;
  bool? isActive;
  String? verificationStatus;
  String? registerDate;
  String? notApproveDetail;
  int? majorId;
  String? majorName;
  String? facultyName; // 👈 1. เพิ่มตัวแปรเก็บชื่อคณะตรงนี้

  RiderModel({
    this.studentid,
    this.password,
    this.firstName,
    this.lastName,
    this.birthday,
    this.email,
    this.phone,
    this.studentCardImage,
    this.drivingLicenseImg,
    this.vehiclePlate,
    this.vehicleImage,
    this.isActive,
    this.verificationStatus,
    this.registerDate,
    this.notApproveDetail,
    this.majorId,
    this.majorName,
    this.facultyName, // 👈 2. เพิ่มใน Constructor
  });

  Map<String, dynamic> toJson() {
    return {
      'studentid': studentid,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'birthday': birthday,
      'email': email,
      'phone': phone,
      'studentCard_Image': studentCardImage,
      'drivingLicenseImg': drivingLicenseImg,
      'vehiclePlate': vehiclePlate,
      'vehicle_Image': vehicleImage,
      'isActive': isActive,
      'verificationStatus': verificationStatus,
      'registerDate': registerDate,
      'notApproveDetail': notApproveDetail,
      'majorId': majorId,
      // ถ้าส่งกลับไป Server ให้ใส่เพิ่ม (ถ้ามี)
    };
  }

  // --- From JSON ใน rider_model.dart ---
  factory RiderModel.fromJson(Map<String, dynamic> json) {
    return RiderModel(
      studentid: json['studentid']
          ?.toString(), // ป้องกันกรณี API ส่งมาเป็นตัวเลข int
      password: json['password'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      birthday: json['birthday'],
      email: json['email'],
      phone: json['phone'],
      studentCardImage: json['studentCard_Image'],
      drivingLicenseImg: json['drivingLicenseImg'],
      vehiclePlate: json['vehiclePlate'],
      vehicleImage: json['vehicle_Image'],
      isActive: json['isActive'] as bool?,
      verificationStatus: json['verificationStatus'],
      registerDate: json['registerDate'],
      notApproveDetail: json['notApproveDetail'],

      // 👈 แก้ไขจุดที่ 1: เปลี่ยนจาก 'majorId' เป็น 'majorid' และ 'majorName' เป็น 'majorname'
      majorId: json['major'] != null ? json['major']['majorid'] as int? : null,
      majorName: json['major'] != null
          ? json['major']['majorname'] as String?
          : null,

      // 👈 แก้ไขจุดที่ 2: เจาะลึกลงไปแกะ facultyname ที่ซ้อนอยู่ในก้อน major (พิมพ์เล็กทั้งหมด)
      facultyName: json['major'] != null && json['major']['faculty'] != null
          ? json['major']['faculty']['facultyname'] as String?
          : null,
    );
  }
}
