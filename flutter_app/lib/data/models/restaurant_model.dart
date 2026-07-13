import 'restaurant_opening_hour_model.dart'; // import ตัวที่สร้างไว้ก่อนหน้า

class RestaurantModel {
  String? username;
  String? password;
  String? restaurantName;
  String? restaurantImage;
  List<RestaurantOpeningHourModel>? openingHours;
  double? latitude;
  double? longitude;
  String? imagecardid;
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
    this.openingHours,
    this.latitude,
    this.longitude,
    this.imagecardid,
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
      'openingHours': openingHours?.map((e) => e.toJson()).toList(),
      'latitude': latitude,
      'longitude': longitude,
      'imagecardid': imagecardid,
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
      restaurantImage: json['restaurantimage'] ?? json['restaurantImage'],
      openingHours: (json['openingHours'] as List?)
          ?.map(
            (e) =>
                RestaurantOpeningHourModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      imagecardid: json['imagecardid'],
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
