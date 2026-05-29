// features/member/search_restaurant_member.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/type_restaurant_model.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/data/services/restaurant/type_restaurant_service.dart';
import 'package:flutter_app/features/member/navbar_member.dart';
import 'package:flutter_app/features/member/view_restaurant_member.dart';

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
      debugPrint("Error loading types: $e");
    }
  }

  Future<void> _loadResults(String keyword) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    var data = await _service.searchRestaurant(keyword);
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
    return days.join(' - ');
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.length < 5) return "00:00";
    return timeStr.substring(0, 5);
  }

  @override
  Widget build(BuildContext context) {
    final double paddingTop = MediaQuery.of(context).padding.top;
    final double headerHeight = paddingTop + kToolbarHeight + 135;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: const NavbarMember(title: ""),

      body: Column(
        children: [
          const SizedBox(height: 80),

          // =========================================================
          // ── 🎪 ส่วนหัวระบบ: จัดเลเยอร์แบนเนอร์หลังคาเขียวให้อยู่ทับบนกล่องเสิร์ช ──
          // =========================================================
          SizedBox(
            height: headerHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 🚀 เลเยอร์ล่างสุด: กล่องพิมพ์เสิร์ชบาร์เหลืองนวลพาสเทล (สวมขอบทองความหนา 1.5 อัตโนมัติ)
                Positioned(
                  bottom: 0,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(
                        255,
                        255,
                        251,
                        209,
                      ), // สีเหลืองพาสเทลนวลตา
                      borderRadius: BorderRadius.circular(30),

                      // 🎯 จุดปรับแต่งแก้ไข: ใส่คุณสมบัติสีกรอบที่ถูกต้องในแผงโปรเจกต์ BoxDecoration ตรงนี้
                      border: Border.all(
                        color: const Color(0xFFFFB300), // สีกรอบเหลืองทอง/อมส้ม
                        width: 1.5,
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),

                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onSubmitted: _handleSearch,
                            style: const TextStyle(fontSize: 15),
                            decoration: InputDecoration(
                              hintText: "ค้นหาร้านค้าที่ต้องการ...",
                              hintStyle: const TextStyle(
                                color: Colors
                                    .black, // คุมโทนอักษรด้านในให้ออกส้มทองนวลตา
                                fontSize: 14,
                              ),

                              // 🎯 ปล่อยค่าเป็น InputBorder.none เพื่อให้ระบบซ่อนขอบแข็งเหลี่ยมอันเดิม
                              border: InputBorder.none,

                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.search,
                            color: Color(0xFFFFB300),
                            size: 26,
                          ),
                          onPressed: () =>
                              _handleSearch(_searchController.text),
                        ),
                      ],
                    ),
                  ),
                ),

                // 🚀 เลเยอร์บนสุด: รูปภาพหลังคาผ้าใบสีเขียว (ทับบดบังกล่องเสิร์ชด้านล่างตามโครงสร้างพิกเซล)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 50,
                  child: Image.asset(
                    'assets/images/restaurant_banner.png',
                    fit: BoxFit.fill,
                  ),
                ),

                // เลเยอร์ข้อความระบบโครงสร้างเปล่าหลบมุม Appbar
                Positioned(
                  top: paddingTop + kToolbarHeight + 15,
                  left: 24,
                  right: 24,
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center),
                ),
              ],
            ),
          ),

          // เว้นระยะห่างด้านล่างจากตัวกล่องเสิร์ชบาร์
          const SizedBox(height: 10),

          // ── ส่วนคัดกรองประเภทอาหาร Dropdown สีเหลืองทองแมตช์ธีมเดียวกัน ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(
                  0xFFFFFDE7,
                ), // พื้นหลัง Dropdown เหลืองพาสเทล
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(
                    0xFFFFB300,
                  ), // สีกรอบขอบทองเหลืองอมส้มหนา 1.5
                  width: 1.5,
                ),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedTypeName,
                dropdownColor: Colors.white,
                style: const TextStyle(
                  color: Color(0xFFFF8C00), // ตัวอักษรสีส้มร้านอาหารสว่าง
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFFFFB300),
                ),
                decoration: const InputDecoration(
                  hintText: "เลือกประเภทร้านค้า",
                  hintStyle: TextStyle(color: Color(0xFFFFB300), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text("ทั้งหมด ทุกประเภทอาหาร"),
                  ),
                  ..._typeList.map(
                    (type) => DropdownMenuItem(
                      value: type.name,
                      child: Text(
                        type.name ?? "",
                        style: const TextStyle(color: Colors.black87),
                      ),
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
            ),
          ),

          // ── หัวข้อแสดงผลลัพธ์ร้านอาหาร ──
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                children: [
                  const Text(
                    "ร้านอาหาร",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "(${_results.length})",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),

          // ── รายการ List การ์ดร้านค้า ──
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2ECC40)),
                  )
                : _results.isEmpty
                ? const Center(
                    child: Text(
                      "ไม่พบข้อมูลร้านค้าที่ตรงเงื่อนไข",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20, top: 4),
                    itemCount: _results.length,
                    itemBuilder: (context, index) =>
                        _buildRestaurantCard(context, _results[index]),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Widget การ์ดร้านอาหาร ──
  Widget _buildRestaurantCard(BuildContext context, RestaurantModel item) {
    final String imageUrl = item.restaurantImage != null
        ? Uri.encodeFull(item.restaurantImage!)
        : '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ViewRestaurantMember(restaurant: item),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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
                        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                      )
                    : _buildImagePlaceholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.restaurantName ?? "ร้านอาหาร",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 15,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "โรงอาหารเทิดกสิกร",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 15,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 13),
                            children: [
                              TextSpan(
                                text:
                                    "${_getOpenDayText(item.openDay)} ${_formatTime(item.openTime)} - ${_formatTime(item.closeTime)} น. ",
                                style: const TextStyle(color: Colors.black54),
                              ),
                              const TextSpan(
                                text: "(เปิดอยู่)",
                                style: TextStyle(
                                  color: Color(0xFF2ECC40),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.orange[50],
      child: const Center(
        child: Icon(Icons.restaurant, color: Colors.orange, size: 48),
      ),
    );
  }
}
