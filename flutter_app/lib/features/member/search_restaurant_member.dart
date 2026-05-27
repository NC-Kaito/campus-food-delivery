import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/type_restaurant_model.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/data/services/restaurant/type_restaurant_service.dart';
import 'package:flutter_app/features/member/view_restaurant_member.dart';
import 'package:flutter_app/features/user/view_restaurant_user.dart'; // หรือใช้ของฝั่ง member ถ้ามี

class SearchRestaurantMember extends StatefulWidget {
  final String keyword;
  final int? initialTypeId;
  final String? initialTypeName;

  const SearchRestaurantMember({
    super.key,
    required this.keyword,
    this.initialTypeId,
    this.initialTypeName,
  });

  @override
  State<SearchRestaurantMember> createState() => _SearchRestaurantMemberState();
}

class _SearchRestaurantMemberState extends State<SearchRestaurantMember> {
  final RestaurantService _service = RestaurantService();
  final TypeRestaurantService _typeService = TypeRestaurantService();
  final TextEditingController _searchController = TextEditingController();

  List<RestaurantModel> _results = [];
  List<TypeRestaurantModel> _typeList = [];

  bool _isLoading = true;
  String _currentKeyword = "";

  String? _selectedTypeName;
  int? _selectedTypeId;

  @override
  void initState() {
    super.initState();
    _currentKeyword = widget.keyword;
    _searchController.text = widget.keyword;

    // 🎯 รับวิชาส่งต่อค่าเริ่มต้นมาจากหน้า Home
    _selectedTypeId = widget.initialTypeId;
    _selectedTypeName = widget.initialTypeName;

    _initData();
  }

  Future<void> _initData() async {
    await fetchTypes();
    await _loadResults(_currentKeyword);
  }

  Future<void> fetchTypes() async {
    try {
      final types = await _typeService.getAllTypeRestaurant();
      if (mounted) setState(() => _typeList = types);
    } catch (e) {
      print("Error loading types: $e");
    }
  }

  Future<void> _loadResults(String keyword) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    var data = await _service.searchRestaurant(keyword);

    // คัดกรองประเภทร้านค้าเพิ่มเติมกรณีมีการกดเลือก Dropdown
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

  void _handleSearch(String value) {
    setState(() => _currentKeyword = value);
    _loadResults(value);
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
          "ผลการค้นหาร้านค้า",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // กล่อง Header ค้นหาด้านบน
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            color: Colors.green,
            child: Column(
              children: [
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

          // แสดงจำนวนแถวผลลัพธ์
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.manage_search, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "พบร้านค้า ${_results.length} แห่ง สำหรับข้อมูล '$_currentKeyword'",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // รายการการ์ดแสดงร้านค้า
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  )
                : _results.isEmpty
                ? const Center(
                    child: Text(
                      "ไม่พบข้อมูลร้านค้าที่ตรงเงื่อนไข",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
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
    );
  }

  Widget _buildRestaurantCard(BuildContext context, RestaurantModel item) {
    final String imageUrl = item.restaurantImage != null
        ? Uri.encodeFull(item.restaurantImage!)
        : '';

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
        // 🎯 แก้ไขคำสั่งข้ามสายในไฟล์ SearchRestaurantMember.dart ตรงเหตุการณ์ onTap:
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewRestaurantMember(
                restaurant: item,
              ), // 👈 เรียกใช้งานคลาสตัวนี้แทนครับ
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
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
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
