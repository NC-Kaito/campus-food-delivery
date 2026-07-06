// data/services/menu/cart_manager.dart
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/data/models/menu_addon_detail_model.dart';

// โมเดลสำหรับเก็บไอเทมที่อยู่ในตะกร้า
class CartItem {
  final MenuModel menu;
  final List<MenuAddonDetailModel>
  selectedAddons; // สำหรับท็อปปิ้งปกติ (เช่น ไข่ดาว, ไข่เจียว)
  final List<MenuModel>
  selectedCurries; // 🌟 เพิ่มฟิลด์นี้สำหรับเก็บกับข้าวราดแกง (ที่ชี้ไปตาราง Menu)
  int quantity;
  final String note;
  final int addonPrice;
  final int
  totalPrice; // แนะนำให้ค่านี้เป็น "ราคาต่อหน่วย/ต่อจาน" จะได้คูณ quantity ได้ง่ายครับ

  // 🎯 สิ่งที่เพิ่มเข้ามาเพื่อแก้ Error:
  final int
  unitPrice; // สมมติว่าเป็น int นะครับ (ถ้าคุณใช้ double ให้เปลี่ยนเป็น double)
  final bool isExtraPrice;

  CartItem({
    required this.menu,
    required this.selectedAddons,
    this.selectedCurries =
        const [], // 🎯 กำหนดให้เป็น Default Value เพื่อไม่ให้โค้ดเก่าพัง
    required this.quantity,
    required this.note,
    required this.addonPrice,
    required this.totalPrice,
    // 🎯 อย่าลืมกำหนด require ใน Constructor ด้วย
    required this.unitPrice,
    required this.isExtraPrice,
  });
}

// คลาส Singleton สำหรับจัดการตะกร้ากลาง
class CartManager {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  void addToCart(CartItem item) {
    _items.add(item);
  }

  void clearCart() {
    _items.clear();
  }

  // 🎯 1. ฟังก์ชันลบไอเทมนี้ออกจากตะกร้าทันที (เช่น กดปุ่มถังขยะ)
  void removeFromCart(CartItem item) {
    _items.remove(item);
  }

  // 🎯 2. ฟังก์ชันลดจำนวน (ถ้าเหลือ 1 แล้วกดลดอีก ให้ลบออกจากตะกร้าอัตโนมัติ)
  void decreaseQuantity(CartItem item) {
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      removeFromCart(item);
    }
  }

  // 🎯 3. ฟังก์ชันเพิ่มจำนวน
  void increaseQuantity(CartItem item) {
    item.quantity++;
  }

  Map<String, List<CartItem>> getGroupedByStore() {
    Map<String, List<CartItem>> grouped = {};
    for (var item in _items) {
      String storeUsername = item.menu.restaurant?.username ?? "unknown_store";

      if (!grouped.containsKey(storeUsername)) {
        grouped[storeUsername] = [];
      }
      grouped[storeUsername]!.add(item);
    }
    return grouped;
  }
}
