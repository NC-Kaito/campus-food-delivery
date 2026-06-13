// features/user/home_user.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/features/member/login_member.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/data/services/restaurant/type_restaurant_service.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/type_restaurant_model.dart';
import 'package:flutter_app/features/user/view_restaurant_user.dart';
import 'package:flutter_app/core/network/dio_client.dart'; // 🎯 มั่นใจว่าอิมพอร์ตดึงตัวแปรกลาง DioClient เข้ามาสวมไอพีรูปภาพ

class HomeUser extends StatefulWidget {
  const HomeUser({super.key});

  @override
  State<HomeUser> createState() => _HomeUserState();
}

class _HomeUserState extends State<HomeUser> {
  final TextEditingController searchController = TextEditingController();
  final RestaurantService _restaurantService = RestaurantService();
  final TypeRestaurantService _typeRestaurantService = TypeRestaurantService();

  List<RestaurantModel> _results = [];
  List<TypeRestaurantModel> typeList = [];

  bool _isLoading = true;
  String? selectedType;
  int? _selectedTypeId;

  final menuTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Colors.green[700],
  );

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    await fetchTypes();
    await _loadResults("");
  }

  Future<void> fetchTypes() async {
    try {
      final types = await _typeRestaurantService.getAllTypeRestaurant();
      setState(() {
        typeList = types;
      });
    } catch (e) {
      print("เกิดข้อผิดพลาด ไม่สามารถโหลดข้อมูลประเภทร้านค้าได้: $e");
    }
  }

  Future<void> _loadResults(String keyword) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    var data = await _restaurantService.searchRestaurant(keyword);

    if (_selectedTypeId != null) {
      data = data.where((r) => r.typerestaurantId == _selectedTypeId).toList();
    }

    if (mounted) {
      setState(() {
        _results = data;
        _isLoading = false;
      });
    }
  }

  String _getOpenDayText(int? bitwiseValue) {
    if (bitwiseValue == null || bitwiseValue == 0) return "ไม่ระบุวันเปิด";
    if (bitwiseValue == 127) return "เปิดทุกวัน";

    final dayMap = {
      1: "อา.",
      2: "จ.",
      4: "อ.",
      8: "พ.",
      16: "พฤ.",
      32: "ศ.",
      64: "ส.",
    };

    List<String> days = [];
    dayMap.forEach((key, value) {
      if ((bitwiseValue & key) != 0) days.add(value);
    });

    return "เปิดวัน: ${days.join(', ')}";
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http'))
      return rawPath; // รองรับลิงก์เต็มรูปแบบกรณีข้อมูลเก่าค้างตู้ DB

    final String baseUrl = DioClient.dio.options.baseUrl;
    if (rawPath.startsWith('/')) {
      return "$baseUrl$rawPath";
    } else {
      return "$baseUrl/$rawPath";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("CAMPUS EAT"),
        backgroundColor: Colors.green,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── ส่วนกล่องค้นหาข้อมูลด้านบน (Header สีเขียว) ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Campus Food Delivery",
                  style: TextStyle(
                    color: Colors.green[800],
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: searchController,
                        onFieldSubmitted: (value) => _loadResults(value),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.green,
                          ),
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
                        onPressed: () => _loadResults(searchController.text),
                        icon: const Icon(Icons.search, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

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
                      borderSide: const BorderSide(
                        color: Colors.green,
                        width: 2,
                      ),
                    ),
                  ),
                  hint: const Text("เลือกประเภทอาหาร"),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text("ทั้งหมด"),
                    ),
                    ...typeList.map((TypeRestaurantModel type) {
                      return DropdownMenuItem<String>(
                        value: type.name,
                        child: Text(type.name ?? "ไม่ระบุ"),
                      );
                    }),
                  ],
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
                    _loadResults(searchController.text);
                  },
                ),
              ],
            ),
          ),

          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.manage_search, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      searchController.text.trim().isEmpty &&
                              selectedType == null
                          ? "ร้านค้าทั้งหมดในระบบ มีจำนวน ${_results.length} แห่ง"
                          : "พบร้านค้า ${_results.length} แห่ง จากการกรองข้อมูลล่าสุด",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  )
                : _results.isEmpty
                ? const Center(child: Text("ไม่พบข้อมูลร้านค้า"))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      return _buildRestaurantCard(context, _results[index]);
                    },
                  ),
          ),
        ],
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

  Widget _buildRestaurantCard(BuildContext context, RestaurantModel item) {
    // 🎯 แปลงพาร์ทรูปสั้นให้กลายเป็น URL ลิงก์รูปภาพตัวเต็มที่ผูกติดไอพีศูนย์กลาง
    final String finalImageUrl = _getFinalImageUrl(item.restaurantImage);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewRestaurantUser(restaurant: item),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: finalImageUrl.isNotEmpty
                    ? Image.network(
                        finalImageUrl, // 🌟 ยิงโหลดตรงผ่านลิงก์รูปภาพประกอบเสร็จสมบูรณ์
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.green,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.restaurant,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.restaurant,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.restaurantName ?? "ร้านอาหาร",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _getOpenDayText(item.openDay),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_filled,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${item.openTime?.substring(0, 5)} - ${item.closeTime?.substring(0, 5)} น.",
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "• เปิดอยู่",
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
