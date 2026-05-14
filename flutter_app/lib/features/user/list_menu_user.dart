import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/menu_model.dart'; // อย่าลืม import model
import 'package:flutter_app/data/services/menu/menu_service.dart';

class ListMenuUser extends StatefulWidget {
  final RestaurantModel restaurantModel;
  const ListMenuUser({super.key, required this.restaurantModel});

  @override
  State<ListMenuUser> createState() => _ListMenuUserState();
}

class _ListMenuUserState extends State<ListMenuUser> {
  List<MenuModel> _menus = []; // เก็บข้อมูลเมนูจริง
  bool _isLoading = true; // สถานะการโหลด

  @override
  void initState() {
    super.initState();
    _fetchMenus(); // เรียกโหลดข้อมูลเมื่อเข้าหน้าจอ
  }

  Future<void> _fetchMenus() async {
    try {
      // เช็คว่ามี username ไหม
      if (widget.restaurantModel.username == null) return;

      final data = await MenuService().getMenusByRestaurant(
        widget.restaurantModel.username!,
      );

      if (mounted) {
        setState(() {
          _menus = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error fetching menus: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // กำหนด Base URL สำหรับรูปภาพเมนู (แก้ IP ให้ตรงกับเครื่องเพื่อนนะ)
    const String menuImageBaseUrl =
        "http://10.226.43.211:8081/uploads/restaurant/menu/";

    return Scaffold(
      appBar: AppBar(
        // แสดงชื่อร้านจริงๆ จาก model
        title: Text("เมนูของ ${widget.restaurantModel.restaurantName}"),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // แสดงตัวหมุนขณะโหลด
          : _menus.isEmpty
          ? const Center(
              child: Text("ยังไม่มีรายการเมนูในขณะนี้"),
            ) // กรณีไม่มีข้อมูล
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _menus.length,
                    itemBuilder: (context, index) {
                      final menu = _menus[index]; // ดึงข้อมูลเมนูตัวที่ index
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(10),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child:
                                menu.menuImage != null &&
                                    menu.menuImage!.isNotEmpty
                                ? Image.network(
                                    "$menuImageBaseUrl${menu.menuImage}",
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _buildPlaceholderIcon(),
                                  )
                                : _buildPlaceholderIcon(),
                          ),
                          title: Text(
                            menu.menuName ?? "ไม่มีชื่อเมนู",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(menu.description ?? ""),
                              const SizedBox(height: 5),
                              Text(
                                "ราคา ${menu.price?.toStringAsFixed(0)} บาท",
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.add_circle,
                            color: Colors.green,
                            size: 35,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // Widget สำหรับแสดงไอคอนแทนรูปภาพกรณีไม่มีรูป
  Widget _buildPlaceholderIcon() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.orange.shade100,
      child: const Icon(Icons.fastfood, size: 30, color: Colors.orange),
    );
  }
}
