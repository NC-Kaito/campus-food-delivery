import 'package:flutter/material.dart';
import 'package:flutter_app/features/member/login_member.dart';
import 'package:flutter_app/data/services/restaurant/type_restaurant_service.dart';
import 'package:flutter_app/data/models/type_restaurant_model.dart';
import 'package:flutter_app/features/user/search_restaurant_user.dart';

class HomeUser extends StatefulWidget {
  const HomeUser({super.key});

  @override
  State<HomeUser> createState() => _HomeUserState();
}

class _HomeUserState extends State<HomeUser> {
  late final TextEditingController searchController;

  final TypeRestaurantService typeRestaurantService = TypeRestaurantService();

  int? _selectedTypeId;
  String? selectedType;

  // 2. รายการประเภทอาหาร
  final List<String> restaurantTypes = [
    'ทั้งหมด',
    'อาหารตามสั่ง',
    'ก๋วยเตี๋ยว',
    'เครื่องดื่ม',
    'ของหวาน',
  ];

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

  // ปรับสไตล์เมนูให้ดูพอดีกับไอคอน
  final menuTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Colors.green[700],
  );

  List<TypeRestaurantModel> typeList = [];

  Future<void> fetchTypes() async {
    try {
      final types = await typeRestaurantService.getAllTypeRestaurant();
      setState(() {
        typeList = types;
      });
    } catch (e) {
      print("เกิดข้อผิดพลาด ไม่สามารถโหลดข้อมูลประเภทร้านค้าได้");
    }
  }

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

            // ใช้ Row เพื่อวางปุ่มไว้ข้างๆ ช่องค้นหา
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
                const SizedBox(width: 10), // เว้นระยะห่างระหว่างช่องกับปุ่ม
                // เพิ่มปุ่มค้นหา
                // ในหน้า HomeUser ส่วนของ IconButton ค้นหา
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: IconButton(
                    onPressed: () {
                      // 1. ตรวจสอบก่อนว่ามีการกรอกข้อความไหม
                      if (searchController.text.trim().isNotEmpty) {
                        // 2. ใช้ Navigator.push เพื่อเปิดหน้าใหม่
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SearchRestaurantUser(
                              keyword: searchController
                                  .text, // ส่งค่าจาก Controller ไปยังหน้า Search
                            ),
                          ),
                        );
                      } else {
                        // แจ้งเตือนกรณีไม่ได้กรอกข้อความ (ถ้าต้องการ)
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
            SizedBox(height: 15), // ระยะห่างระหว่าง Search กับ Dropdown
            // --- ส่วน Dropdown ที่เพิ่มใหม่ ---
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

              // ✅ ใช้ข้อมูลจาก typeList ที่โหลดมา
              items: typeList.map((TypeRestaurantModel type) {
                return DropdownMenuItem<String>(
                  value: type.name, // หรือใช้ ID ก็ได้ถ้าต้องการ
                  child: Text(type.name ?? "ไม่ระบุ"),
                );
              }).toList(),

              onChanged: (String? newValue) {
                setState(() {
                  selectedType = newValue;

                  // ✅ หา ID ของประเภทที่เลือก เพื่อเตรียมส่งไป API ตอนค้นหา
                  try {
                    _selectedTypeId = typeList
                        .firstWhere((e) => e.name == newValue)
                        .id;
                  } catch (e) {
                    _selectedTypeId = null;
                  }
                });
                print("เลือกประเภท: $selectedType (ID: $_selectedTypeId)");
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
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.home, color: Colors.green),
                    Text("หน้าหลัก", style: menuTextStyle),
                  ],
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginMember(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(50),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person, color: Colors.green),
                      Text("เข้าสู่ระบบ", style: menuTextStyle),
                    ],
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
