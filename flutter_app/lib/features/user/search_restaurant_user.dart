import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/type_restaurant_model.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/data/services/restaurant/type_restaurant_service.dart';
import 'package:flutter_app/features/user/view_restaurant_user.dart';
// import 'package:flutter_app/features/restaurant/view_restaurant.dart'; // อย่าลืมแก้ Path

class SearchRestaurantUser extends StatefulWidget {
  final String keyword;
  const SearchRestaurantUser({super.key, required this.keyword});

  @override
  State<SearchRestaurantUser> createState() => _SearchRestaurantUserState();
}

class _SearchRestaurantUserState extends State<SearchRestaurantUser> {
  final RestaurantService _service = RestaurantService();
  final TypeRestaurantService _typeService = TypeRestaurantService();
  final TextEditingController _searchController = TextEditingController();

  List<RestaurantModel> _results = [];
  List<TypeRestaurantModel> _typeList = [];

  bool _isLoading = true;
  bool _isShowingFallback = false;
  String _currentKeyword = "";

  String? _selectedTypeName;
  int? _selectedTypeId;

  @override
  void initState() {
    super.initState();
    _currentKeyword = widget.keyword;
    _searchController.text = widget.keyword;
    _initData();
  }

  // โหลดข้อมูลหมวดหมู่และผลลัพธ์การค้นหาพร้อมกัน
  Future<void> _initData() async {
    await fetchTypes();
    await _loadResults(_currentKeyword);
  }

  Future<void> fetchTypes() async {
    try {
      final types = await _typeService.getAllTypeRestaurant();
      if (mounted) {
        setState(() {
          _typeList = types;
        });
      }
    } catch (e) {
      print("Error loading types: $e");
    }
  }

  Future<void> _loadResults(String keyword) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // ✅ เรียก Service ค้นหา (สามารถปรับ Service ให้รับ TypeId เพิ่มได้ถ้า Backend รองรับ)
    var data = await _service.searchRestaurant(keyword);
    bool showingFallback = false;

    // กรองข้อมูลในฝั่ง Client เพิ่มเติมตามประเภทที่เลือก (ถ้ามีการเลือก)
    if (_selectedTypeId != null) {
      data = data.where((r) => r.typerestaurantId == _selectedTypeId).toList();
    }

    if (mounted) {
      setState(() {
        _results = data;
        _isShowingFallback = showingFallback;
        _isLoading = false;
      });
    }
  }

  void _handleSearch(String value) {
    setState(() {
      _currentKeyword = value;
    });
    _loadResults(value);
  }

  String _getOpenDayText(int? bitwiseValue) {
    if (bitwiseValue == null || bitwiseValue == 0) return "ไม่ระบุวันเปิด";
    if (bitwiseValue == 127) return "เปิดทุกวัน"; // 1+2+4+8+16+32+64 = 127

    List<String> days = [];

    // สร้าง Map สำหรับเทียบค่า
    final dayMap = {
      1: "อา.",
      2: "จ.",
      4: "อ.",
      8: "พ.",
      16: "พฤ.",
      32: "ศ.",
      64: "ส.",
    };

    // วนลูปเช็กทีละ Bit
    dayMap.forEach((key, value) {
      if ((bitwiseValue & key) != 0) {
        days.add(value);
      }
    });

    return "เปิดวัน: ${days.join(', ')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "ค้นหาร้านอาหาร",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // ส่วน Header: ค้นหา + Dropdown
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            color: Colors.green,
            child: Column(
              children: [
                // แถวปุ่มค้นหา
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: _handleSearch,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: "ค้นหาร้านอาหาร...",
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.green,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.green),
                        onPressed: () => _handleSearch(_searchController.text),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Dropdown เลือกประเภท
                DropdownButtonFormField<String>(
                  value: _selectedTypeName,
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.category,
                      color: Colors.green,
                      size: 20,
                    ),
                    hintText: "เลือกประเภทร้านค้า",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("ทั้งหมด")),
                    ..._typeList.map(
                      (type) => DropdownMenuItem(
                        value: type.name,
                        child: Text(type.name ?? ""),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedTypeName = val;
                      _selectedTypeId = val == null
                          ? null
                          : _typeList.firstWhere((e) => e.name == val).id;
                    });
                    _loadResults(_searchController.text);
                  },
                ),
              ],
            ),
          ),

          // รายงานสถานะ
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.manage_search, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isShowingFallback
                          ? "ไม่พบร้านสำหรับ '$_currentKeyword' (แสดงร้านแนะนำ)"
                          : "พบร้านค้า ${_results.length} แห่ง สำหรับ '$_currentKeyword'",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_isShowingFallback && !_isLoading) _buildFallbackBanner(),

          // รายชื่อร้านค้า
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
                      // --------------------
                      final item = _results[index];
                      // ============

                      const String imageBaseUrl =
                          "http://10.226.43.211:8081/uploads/restaurant/imageRestaurant/";
                      return _buildRestaurantCard(context, item, imageBaseUrl);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: const Text(
        "🔍 ลองดูร้านค้าแนะนำด้านล่างนี้นะครับ",
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  // 2. ปรับปรุง Widget _buildRestaurantCard
  Widget _buildRestaurantCard(
    BuildContext context,
    RestaurantModel item,
    String baseUrl,
  ) {
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
            // ส่วนรูปภาพ
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  "$baseUrl${item.restaurantImage}",
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.grey,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
            // ส่วนรายละเอียดข้อมูล
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

                  // --- เพิ่มส่วนวันเปิด-ปิด ---
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        // ใช้ Expanded กันตัวหนังสือยาวเกินแล้วล้นจอ (Pixel Overflow)
                        child: Text(
                          _getOpenDayText(item.openDay),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                          overflow: TextOverflow
                              .ellipsis, // ถ้าชื่อวันยาวมากจะขึ้น ...
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // --- ส่วนเวลาเปิด-ปิด ---
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
                        // ใช้ substring(0, 5) เพื่อตัดวินาทีออก ให้เหลือแค่ 10:00
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // เพิ่มสถานะ เปิด/ปิด เล็กๆ
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
