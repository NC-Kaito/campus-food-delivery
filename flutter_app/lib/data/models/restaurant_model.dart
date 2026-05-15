class RestaurantModel {
  String? username; // เป็น PK ใช้เป็นรหัสร้านค้าได้เลย
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
  String? registerDate; // LocalDateTime จาก Java
  String? verificationStatus;
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
      'notapprovedetail': notApproveDetail,
      'typerestaurantId': typerestaurantId,
    };
  }

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      username: json['username'],
      password: json['password'],
      restaurantName: json['restaurantname'],
      restaurantImage: json['restaurantimage'],
      openTime: json['opentime'],
      closeTime: json['closetime'],
      openDay: json['openday'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      leaseAgreementImg: json['lease_agreement_img'],
      ownerFirstName: json['ownerfirstname'],
      ownerLastName: json['ownerlastname'],
      email: json['email'],
      phone: json['phone'],
      statusOpen: json['statusopen'],
      registerDate: json['registerdate'],
      verificationStatus: json['verificationstatus'],
      notApproveDetail: json['notapprovedetail'],
      typerestaurantId: json['typerestaurant']['typerestaurantId'] as int,
      typerestaurantName:
          json['typerestaurant']['typerestaurantName'] as String,
    );
  }
}
