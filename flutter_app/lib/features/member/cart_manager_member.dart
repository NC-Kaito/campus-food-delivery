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
