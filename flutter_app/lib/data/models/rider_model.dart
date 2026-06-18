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

  factory RiderModel.fromJson(Map<String, dynamic> json) {
    return RiderModel(
      studentid: json['studentid']?.toString(),
      password: json['password'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      birthday: json['birthday'],
      email: json['email'],
      phone: json['phone'],
      studentCardImage: json['studentCard_Image'],
      drivingLicenseImg: json['drivingLicenseImg'],
      vehicleImage: json['vehicle_Image'],
      vehiclePlate: json['vehiclePlate'],
      isActive: json['isActive'] as bool?,
      verificationStatus: json['verificationStatus'],
      registerDate: json['registerDate'],
      notApproveDetail: json['notApproveDetail'],

      // ✅ รองรับทั้ง DTO (flat) และ Entity (nested)
      majorId: json['majorId'] ?? json['major']?['majorid'],
      majorName: json['majorName'] ?? json['major']?['majorname'],
      facultyName:
          json['facultyName'] ?? json['major']?['faculty']?['facultyname'],
    );
  }
}
