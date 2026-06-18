// data/models/order_detail_addon_model.dart

class OrderDetailAddonModel {
  final int addonDetailId;
  final double?
  priceAtOrder; // 🎯 เพิ่มตัวแปรเก็บราคาท็อปปิ้ง ณ ตอนที่กดสั่งซื้อ (จากฐานข้อมูลหลังบ้าน)

  OrderDetailAddonModel({required this.addonDetailId, this.priceAtOrder});

  // 📥 ── ขารับเข้า (เสก JSON จากฐานข้อมูล Spring Boot ชั้นในสุดมาเป็น Object บน Flutter) ──
  factory OrderDetailAddonModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailAddonModel(
      // 🎯 ดักจับกะเทาะเอา addondetailid ออกมาจากก้อนความสัมพันธ์ Object "menuaddondetail" จริงของหลังบ้าน
      addonDetailId: json['menuaddondetail'] != null
          ? (json['menuaddondetail']['addondetailid'] ??
                json['menuaddondetail']['addonDetailId'] ??
                0)
          : (json['addondetailid'] ?? json['addonDetailId'] ?? 0),

      // สอยค่าราคาประทับตราตอนสั่งซื้อมาด้วย
      priceAtOrder: json['priceAtOrder'] != null
          ? (json['priceAtOrder'] as num).toDouble()
          : (json['price_at_order'] != null
                ? (json['price_at_order'] as num).toDouble()
                : 0.0),
    );
  }

  // 📤 ── ขาส่งออก (แปลงเป็น Map ให้ตรงกับโครงสร้าง JPA Entity ของระบบ Spring Boot) ──
  Map<String, dynamic> toJson() {
    return {
      // แมปกลับไปเป็นรูปแบบโครงสร้าง Object เพื่อให้ตัวตรวจสอบฝั่ง Java รับไปผูกเงื่อนไขง่ายๆ
      'menuaddondetail': {'addondetailid': addonDetailId},
      'priceAtOrder': priceAtOrder,
    };
  }
}
