// data/services/menu/cart_manager.dart
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/data/models/menu_addon_detail_model.dart';

// โมเดลสำหรับเก็บไอเทมที่อยู่ในตะกร้า
class CartItem {
  final MenuModel menu;
  final List<MenuAddonDetailModel> selectedAddons;
  int quantity;
  final String note;
  final int addonPrice;
  final int totalPrice;

  CartItem({
    required this.menu,
    required this.selectedAddons,
    required this.quantity,
    required this.note,
    required this.addonPrice,
    required this.totalPrice,
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
      // ถ้าจำนวนเหลือ 1 แล้วกดลด ให้ลบออกจากตะกร้าเลย
      removeFromCart(item);
    }
  }

  // 🎯 3. ฟังก์ชันเพิ่มจำนวน (สำหรับกดปุ่ม + ในหน้าดูรายละเอียดออเดอร์)
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
