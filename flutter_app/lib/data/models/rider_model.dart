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
  bool? verificationStatus;
  String? registerDate;
  String? notApproveDetail;
  int? majorId;
  String? majorName;

  // --- Constructor ---
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
  });

  // --- From JSON (รับข้อมูลจาก API) ---
  factory RiderModel.fromJson(Map<String, dynamic> json) {
    return RiderModel(
      studentid: json['studentid'],
      // password ปกติจะไม่ถูกส่งกลับมา (เป็น null) แต่ดักไว้เผื่อใช้
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
      isActive: json['isActive'],
      verificationStatus: json['verificationStatus'],
      registerDate: json['registerDate'],
      notApproveDetail: json['notApproveDetail'],
      majorId: json['majorId'],
      majorName: json['majorName'],
    );
  }

  // --- To JSON (ส่งข้อมูลไป Register/Login) ---
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
      'drivingLicenseImg': drivingLicenseImg ?? '',
      'vehiclePlate': vehiclePlate,
      'vehicle_Image': vehicleImage,
      'majorId': majorId,
      // ฟิลด์พวกนี้ปกติจะให้ Server เป็นคนจัดการ แต่ใส่เผื่อไว้กรณี Update
      'isActive': isActive ?? false,
      'verificationStatus': verificationStatus ?? false,
    };
  }
}
