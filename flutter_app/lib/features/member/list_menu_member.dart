import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/data/services/menu/menu_service.dart';
import 'package:flutter_app/features/member/add_order_member.dart';
import 'package:flutter_app/features/member/navbar_member.dart';

class ListMenuMember extends StatefulWidget {
  final RestaurantModel
  restaurantModel; // 🎯 รับข้อมูลร้านค้าต่อสายมาจากหน้า ViewRestaurantMember
  const ListMenuMember({super.key, required this.restaurantModel});

  @override
  State<ListMenuMember> createState() => _ListMenuMemberState();
}

class _ListMenuMemberState extends State<ListMenuMember> {
  List<MenuModel> _menus = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMenus();
  }

  Future<void> _fetchMenus() async {
    try {
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
    const String baseIp = "10.244.27.211";

    return Scaffold(
      backgroundColor: Colors.grey[50], // ปรับสีพื้นหลังให้อ่อนลงดูสบายตา
      appBar: const NavbarMember(title: ""),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _menus.isEmpty
          ? const Center(
              child: Text(
                "ยังไม่มีรายการเมนูในขณะนี้",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _menus.length,
                    itemBuilder: (context, index) {
                      final menu = _menus[index];

                      String? rawMenuImage =
                          menu.menuImage ?? (menu as dynamic).imageUrl;

                      String safeImageUrl = "";
                      if (rawMenuImage != null && rawMenuImage.isNotEmpty) {
                        safeImageUrl = rawMenuImage
                            .replaceAll("10.226.43.211", baseIp)
                            .replaceAll("10.0.2.2", baseIp);
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddOrderMember(menuModel: menu),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(15),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: safeImageUrl.isNotEmpty
                                  ? Image.network(
                                      Uri.encodeFull(safeImageUrl),
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return _buildPlaceholderIcon();
                                          },
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
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    menu.description ?? "",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "ราคา ${menu.price?.toStringAsFixed(0) ?? '0'} บาท",
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: IconButton(
                              // 🎯 ปุ่มไอคอนบวกกดสั่งงานลงตระกร้าจริงเช่นกัน
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AddOrderMember(menuModel: menu),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.add_circle,
                                color: Colors.green,
                                size: 38,
                              ),
                            ),
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

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.orange.shade50,
      child: const Icon(Icons.fastfood, size: 32, color: Colors.orange),
    );
  }
}
