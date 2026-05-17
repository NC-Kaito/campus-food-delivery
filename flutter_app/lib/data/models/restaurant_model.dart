class RestaurantModel {
  String? username;
  String? password;
  String? restaurantName;
  String? restaurantImage;
  String? openTime;
  String? closeTime;
  int? openDay;
  double? latitude;
  double? longitude;
  String? leaseAgreementImg;
  String? ownerFirstName;
  String? ownerLastName;
  String? email;
  String? phone;
  bool? statusOpen;
  String? registerDate;
  String?
  verificationStatus; // 🎯 เช็คจุดนี้: ต้องเป็น String? เพื่อรองรับ "wait", "Confirm" จาก DTO
  String? notApproveDetail;
  int? typerestaurantId;
  String? typerestaurantName;

  RestaurantModel({
    this.username,
    this.password,
    this.restaurantName,
    this.restaurantImage,
    this.openTime,
    this.closeTime,
    this.openDay,
    this.latitude,
    this.longitude,
    this.leaseAgreementImg,
    this.ownerFirstName,
    this.ownerLastName,
    this.email,
    this.phone,
    this.statusOpen,
    this.registerDate,
    this.verificationStatus,
    this.notApproveDetail,
    this.typerestaurantId,
    this.typerestaurantName,
  });

  // ขาไปหา Spring Boot (RestaurantDto) ตัวพิมพ์เล็กและตัวงูตรงเป๊ะตามโครงสร้าง Java
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'restaurantname': restaurantName,
      'restaurantimage': restaurantImage,
      'opentime': openTime,
      'closetime': closeTime,
      'openday': openDay,
      'latitude': latitude,
      'longitude': longitude,
      'lease_agreement_img': leaseAgreementImg,
      'ownerfirstname': ownerFirstName,
      'ownerlastname': ownerLastName,
      'email': email,
      'phone': phone,
      'statusopen': statusOpen,
      'registerdate': registerDate,
      'verificationstatus': verificationStatus,
      'typeid': typerestaurantId,
    };
  }

  // ขารับกลับมาจาก Spring Boot แกะได้ทั้งเวอร์ชันพิมพ์เล็กและเผื่อกรณี Entity วิ่งมาสลับ
  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      username: json['username'],
      password: json['password'],
      restaurantName: json['restaurantname'] ?? json['restaurantName'],
      restaurantImage: json['restaurantimage'],
      openTime: json['opentime'] ?? json['openTime'],
      closeTime: json['closetime'] ?? json['closeTime'],
      openDay: json['openday'] ?? json['openDay'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      leaseAgreementImg: json['lease_agreement_img'],
      ownerFirstName: json['ownerfirstname'] ?? json['ownerFirstName'],
      ownerLastName: json['ownerlastname'] ?? json['ownerLastName'],
      email: json['email'],
      phone: json['phone'],
      statusOpen: json['statusopen'] ?? json['statusOpen'],
      registerDate: json['registerdate'] ?? json['registerDate'],
      verificationStatus:
          json['verificationstatus']?.toString() ??
          json['verificationStatus']?.toString(),
      notApproveDetail: json['notapprovedetail'] ?? json['notApproveDetail'],

      // ดักจับรหัสประเภท เผื่อกรณีดึงข้อมูลผ่านการเขียนแบบ DTO ตรงๆ หรือดึงแบบ Object ซ้อน
      typerestaurantId:
          json['typeid'] ??
          (json['typerestaurant'] != null
              ? json['typerestaurant']['typerestaurantId'] as int?
              : null),
      typerestaurantName: json['typerestaurant'] != null
          ? json['typerestaurant']['typerestaurantName'] as String?
          : null,
    );
  }
}
