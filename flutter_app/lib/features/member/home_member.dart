import 'package:flutter/material.dart';
import 'package:flutter_app/features/member/list_order_member.dart';
import 'package:flutter_app/features/member/profile_member.dart';
import 'package:flutter_app/data/services/restaurant/type_restaurant_service.dart';
import 'package:flutter_app/data/models/type_restaurant_model.dart';
import 'package:flutter_app/features/member/search_restaurant_member.dart';
import 'package:flutter_app/features/user/search_restaurant_user.dart';

class HomeMember extends StatefulWidget {
  const HomeMember({super.key});

  @override
  State<HomeMember> createState() => _HomeMemberState();
}

class _HomeMemberState extends State<HomeMember> {
  late final TextEditingController searchController;

  final TypeRestaurantService typeRestaurantService = TypeRestaurantService();
  List<TypeRestaurantModel> typeList = [];
  int? _selectedTypeId;
  String? selectedType;

  @override
  void initState() {
    searchController = TextEditingController();
    fetchTypes();
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchTypes() async {
    try {
      final types = await typeRestaurantService.getAllTypeRestaurant();
      setState(() => typeList = types);
    } catch (e) {
      print("เกิดข้อผิดพลาด ไม่สามารถโหลดข้อมูลประเภทร้านค้าได้");
    }
  }

  // ปรับสไตล์เมนูให้ดูพอดีกับไอคอน
  final menuTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Colors.green[700],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CAMPUS EAT"),
        backgroundColor: Colors.green,
        centerTitle: true, // ปรับชื่อแอปให้อยู่ตรงกลาง
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: double.infinity),
            Text(
              "Campus Food Delivery",
              style: TextStyle(
                color: Colors.green[800],
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),

            // ✅ Search + ปุ่ม
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: Colors.green),
                      labelText: "ค้นหาร้านค้า",
                      hintText: "กรุณากรอกชื่อร้านค้า",
                      labelStyle: const TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.green),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Colors.deepOrange,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: IconButton(
                    // 🎯 ค้นหาปุ่ม IconButton ค้นหาใน HomeMember แล้วเปลี่ยนโค้ด onPressed เป็นชุดนี้ครับ:
                    onPressed: () {
                      if (searchController.text.trim().isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SearchRestaurantMember(
                              keyword: searchController.text,
                              initialTypeId:
                                  _selectedTypeId, // 👈 ส่ง ID ประเภทร้านค้าที่เลือกจาก Dropdown ข้ามไปด้วย
                              initialTypeName:
                                  selectedType, // 👈 ส่ง ชื่อประเภทร้านค้าไปตั้งค่าเริ่มต้น
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "กรุณากรอกชื่อร้านค้าที่ต้องการค้นหา",
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.search, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // ✅ Dropdown ประเภทร้านค้า
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.category, color: Colors.green),
                labelText: "ประเภทธุรกิจ/ร้านค้า",
                labelStyle: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.green),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.green, width: 2),
                ),
              ),
              hint: const Text("เลือกประเภทอาหาร"),
              items: typeList.map((TypeRestaurantModel type) {
                return DropdownMenuItem<String>(
                  value: type.name,
                  child: Text(type.name ?? "ไม่ระบุ"),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedType = newValue;
                  try {
                    _selectedTypeId = typeList
                        .firstWhere((e) => e.name == newValue)
                        .id;
                  } catch (e) {
                    _selectedTypeId = null;
                  }
                });
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // ปุ่มที่ 1: หน้าหลัก
                InkWell(
                  onTap: () {
                    // ตอนนี้อยู่ที่หน้าหลักอยู่แล้ว หรือสามารถสั่ง Refresh ข้อมูลได้ครับ
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 4.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.home, color: Colors.green),
                        Text("หน้าหลัก", style: menuTextStyle),
                      ],
                    ),
                  ),
                ),

                // ปุ่มที่ 2: ตะกร้าอาหาร (แก้ไขครอบสมบูรณ์ กดติดแน่นอน)
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ListOrderMember(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 4.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_basket, color: Colors.green),
                        Text("ตะกร้าอาหาร", style: menuTextStyle),
                      ],
                    ),
                  ),
                ),

                // ปุ่มที่ 3: คำสั่งซื้อ
                InkWell(
                  onTap: () {
                    // บันทึกคำสั่งยิงไปหน้าประวัติคำสั่งซื้อขยับต่อได้เลยครับ
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 4.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.list_alt, color: Colors.green),
                        Text("คำสั่งซื้อ", style: menuTextStyle),
                      ],
                    ),
                  ),
                ),

                // ปุ่มที่ 4: โปรไฟล์
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileMember(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 4.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person, color: Colors.green),
                        Text("โปรไฟล์", style: menuTextStyle),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
