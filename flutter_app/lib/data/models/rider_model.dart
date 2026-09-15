class RiderModel {
  String? studentid;
  String? password;
  String? firstName;
  String? lastName;
  String? birthday;
  String? email;
  String? phone;
  String? profileImage;
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
  String? facultyName;

  RiderModel({
    this.studentid,
    this.password,
    this.firstName,
    this.lastName,
    this.birthday,
    this.email,
    this.phone,
    this.profileImage,
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
    this.facultyName,
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
      // 🎯 แมปชื่อคีย์ให้ตรงกับ Entity (profileRiderImage)
      'profileRiderImage': profileImage,
      'studentCard_Image': studentCardImage,
      'drivingLicenseImg': drivingLicenseImg,
      'vehiclePlate': vehiclePlate,
      'vehicle_Image': vehicleImage,
      'isActive': isActive,
      'verificationStatus': verificationStatus,
      'registerDate': registerDate,
      'notApproveDetail': notApproveDetail,
      'majorId': majorId,
    };
  }

  factory RiderModel.fromJson(Map<String, dynamic> json) {
    return RiderModel(
      studentid: json['studentid']?.toString(),
      password: json['password'],
      firstName: json['firstName'] ?? json['firstname'],
      lastName: json['lastName'] ?? json['lastname'],
      birthday: json['birthday'],
      email: json['email'],
      phone: json['phone'],

      // 🎯 ดักจับ profileRiderImage จาก Entity / DTO
      profileImage:
          json['profileRiderImage'] ??
          json['profile_rider_image'] ??
          json['profileImage'] ??
          json['profileimage'] ??
          "",

      studentCardImage:
          json['studentCard_Image'] ??
          json['studentCardImage'] ??
          json['studentcard_image'] ??
          json['studentcardimage'] ??
          "",

      drivingLicenseImg:
          json['drivingLicenseImg'] ??
          json['drivinglicenseimg'] ??
          json['driving_license_img'],
      vehicleImage:
          json['vehicle_Image'] ?? json['vehicleImage'] ?? json['vehicleimage'],
      vehiclePlate:
          json['vehiclePlate'] ?? json['vehicleplate'] ?? json['vehicle_plate'],
      isActive: json['isActive'] ?? json['isactive'],
      verificationStatus:
          json['verificationStatus'] ?? json['verificationstatus'],
      registerDate: json['registerDate'] ?? json['registerdate'],
      notApproveDetail: json['notApproveDetail'] ?? json['notapprovedetail'],

      majorId: json['majorId'] ?? json['major']?['majorid'],
      majorName: json['majorName'] ?? json['major']?['majorname'],
      facultyName:
          json['facultyName'] ?? json['major']?['faculty']?['facultyname'],
    );
  }
}
