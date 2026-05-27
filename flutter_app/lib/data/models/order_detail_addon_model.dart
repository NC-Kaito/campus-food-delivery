class OrderDetailAddonModel {
  final int addonDetailId;

  OrderDetailAddonModel({required this.addonDetailId});

  // แปลงเป็น Map ให้ตรงกับ private int addondetailid ใน Java
  Map<String, dynamic> toJson() {
    return {'addondetailid': addonDetailId};
  }
}
