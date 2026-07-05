import 'package:flutter/material.dart';
import 'package:flutter_app/features/restaurant/restaurant_drawer.dart';
import 'package:flutter_app/features/restaurant/restaurant_navbar.dart';

// 🎯 Scaffold กลางที่รวม AppBar + Drawer ไว้ให้พร้อม
// ทุกหน้าที่ใช้ RestaurantNavbar ให้เปลี่ยนมาเรียก RestaurantScaffold แทน Scaffold ปกติ
class RestaurantScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBodyBehindAppBar;
  final Color? backgroundColor;

  const RestaurantScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBodyBehindAppBar = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: RestaurantNavbar(title: title),
      drawer: const RestaurantDrawer(),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
