import 'dart:convert';

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
  int? typeId; // ✅ เพิ่มใหม่ เปลี่ยนจาก typeRestaurant

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
    this.typeId, // ✅ เพิ่มใหม่
  });

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
      'statusopen': statusOpen ?? false,
      'verificationstatus': false,
      'typeid': typeId, // ✅ เพิ่มใหม่
    };
  }

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      username: json['username'],
      password: json['password'],
      restaurantName: json['restaurantname'], // ชื่อ key ต้องตรงกับ Java
      restaurantImage: json['restaurantimage'],
      openTime: json['opentime'],
      closeTime: json['closetime'],
      openDay: json['openDay'],
      latitude: (json['latitude'] as num?)
          ?.toDouble(), // ป้องกัน error ถ้าส่งมาเป็น int
      longitude: (json['longitude'] as num?)?.toDouble(),
      leaseAgreementImg: json['lease_agreement_img'],
      ownerFirstName: json['ownerfirstname'],
      ownerLastName: json['ownerlastname'],
      email: json['email'],
      phone: json['phone'],
      statusOpen: json['statusopen'],
      typeId: json['typerestaurant'] != null
          ? json['typerestaurant']['typerestaurantId'] as int
          : null,
    );
  }
}
