// features/restaurant/review_restaurant.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/order_model.dart';
import 'package:flutter_app/data/models/review_model.dart';
import 'package:flutter_app/data/services/member/member_service.dart';
import 'package:flutter_app/data/services/order_service.dart';
import 'package:flutter_app/features/restaurant/restaurant_navbar.dart';
import 'package:flutter_app/global_data.dart';

class _RestaurantReviewEntry {
  final OrderModel order;
  final ReviewSubmitModel? review;

  _RestaurantReviewEntry({required this.order, required this.review});

  int get rating => review?.restaurantrating ?? 0;
}

class ReviewRestaurant extends StatefulWidget {
  const ReviewRestaurant({super.key});

  @override
  State<ReviewRestaurant> createState() => _ReviewRestaurantState();
}

class _ReviewRestaurantState extends State<ReviewRestaurant> {
  final OrderService _orderService = OrderService();
  final MemberService _memberService = MemberService();

  static const Color _primary = Color(0xFF16A34A);

  bool _isLoading = true;
  String? _errorMessage;

  List<_RestaurantReviewEntry> _allReviews = [];

  /// null = แสดงทั้งหมด, ไม่งั้นกรองเฉพาะดาวนั้น (1-5)
  int? _selectedStar;

  @override
  void initState() {
    super.initState();
    _fetchAllReviews();
  }

  Future<void> _fetchAllReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String username = GlobalData.usernameRestaurant;

      // 1. ดึงออเดอร์ที่มีรีวิวของร้าน
      final rawOrders = await _orderService.getReviewSuccessOrdersByRestaurant(
        username,
      );

      final List<OrderModel> orders = rawOrders
          .map((o) => OrderModel.fromJson(o))
          .where((o) => o.orderId != null)
          .toList();

      // 2. ดึงรายละเอียดรีวิวของแต่ละออเดอร์
      final List<_RestaurantReviewEntry> entries = [];
      for (final order in orders) {
        ReviewSubmitModel? review;
        try {
          review = await _memberService.getReviewByOrderId(order.orderId!);
        } catch (e) {
          debugPrint("โหลดรีวิวของออเดอร์ ${order.orderId} ไม่สำเร็จ: $e");
        }
        entries.add(_RestaurantReviewEntry(order: order, review: review));
      }

      // เรียงรีวิวล่าสุดขึ้นก่อน
      entries.sort((a, b) {
        final da = a.order.orderdate;
        final db = b.order.orderdate;
        if (da == null || db == null) return 0;
        return db.compareTo(da);
      });

      if (mounted) {
        setState(() {
          _allReviews = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "โหลดรีวิวไม่สำเร็จ: $e";
          _isLoading = false;
        });
      }
    }
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;
    final String baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/') ? "$baseUrl$rawPath" : "$baseUrl/$rawPath";
  }

  // ---- คำนวณสรุปคะแนนจากลิสต์ที่ดึงมา ----
  double get _averageRating {
    final rated = _allReviews.where((e) => e.rating > 0).toList();
    if (rated.isEmpty) return 0.0;
    final sum = rated.fold<int>(0, (acc, e) => acc + e.rating);
    return double.parse((sum / rated.length).toStringAsFixed(1));
  }

  int _countForStar(int star) {
    return _allReviews.where((e) => e.rating == star).length;
  }

  Color _colorForStar(int star) {
    switch (star) {
      case 5:
        return const Color(0xFF16A34A); // เขียว
      case 4:
        return const Color(0xFFEA7C1E); // ส้ม
      case 3:
        return const Color(0xFFF5A623); // เหลือง/ส้มอ่อน
      case 2:
        return const Color(0xFFEF6C4D); // ส้มแดง
      default:
        return const Color(0xFFE53935); // แดง
    }
  }

  List<_RestaurantReviewEntry> get _filteredReviews {
    if (_selectedStar == null) return _allReviews;
    return _allReviews.where((e) => e.rating == _selectedStar).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const RestaurantNavbar(title: "รีวิวร้านค้า"),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _errorMessage != null
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: _fetchAllReviews,
              color: _primary,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _buildSummaryHeader(),
                  const SizedBox(height: 16),
                  _buildFilterChips(),
                  const SizedBox(height: 16),
                  if (_filteredReviews.isEmpty)
                    _buildEmptyState()
                  else
                    ..._filteredReviews.map(_buildReviewCard),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchAllReviews,
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              child: const Text(
                "ลองอีกครั้ง",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------- ส่วนหัว: สรุปคะแนนเฉลี่ย (รวมดาวและคะแนนไว้ในกล่องเดียวกัน) -------------------
  Widget _buildSummaryHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Colors.orange, size: 28),
                const SizedBox(width: 6),
                Text(
                  _averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "คะแนนรวมของร้าน",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "จากทั้งหมด ${_allReviews.length} รีวิว",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------- แถบปุ่มกรองตามดาว (แสดงเฉพาะดาวที่มีรีวิว) -------------------
  Widget _buildFilterChips() {
    final availableStars = <int>[];
    for (int star = 5; star >= 1; star--) {
      if (_countForStar(star) > 0) {
        availableStars.add(star);
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildChip(
            label: "ทั้งหมด (${_allReviews.length})",
            isSelected: _selectedStar == null,
            baseColor: Colors.black87,
            onTap: () => setState(() => _selectedStar = null),
          ),
          for (int star in availableStars) ...[
            const SizedBox(width: 8),
            _buildChip(
              label: "$star (${_countForStar(star)})",
              icon: Icons.star_rounded,
              isSelected: _selectedStar == star,
              baseColor: _colorForStar(star),
              onTap: () => setState(() => _selectedStar = star),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required Color baseColor,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    final Color bg = isSelected ? Colors.black87 : baseColor.withOpacity(0.12);
    final Color fg = isSelected ? Colors.white : baseColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: isSelected ? Colors.amber : fg),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Text(
          "ยังไม่มีข้อมูลรีวิวในส่วนนี้",
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
      ),
    );
  }

  // ------------------- การ์ดรีวิวแต่ละใบ -------------------
  Widget _buildReviewCard(_RestaurantReviewEntry entry) {
    final order = entry.order;
    final review = entry.review;

    String memberName = "ไม่ระบุชื่อลูกค้า";
    String finalImgUrl = "";
    if (order.member != null) {
      final firstName = order.member?.firstname ?? "";
      final lastName = order.member?.lastname ?? "";
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        memberName = "$firstName $lastName".trim();
      }
      finalImgUrl = _getFinalImageUrl(order.member?.profileimg);
    }

    String dateText = "";
    if (order.orderdate != null) {
      final d = order.orderdate!;
      dateText =
          "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
    }

    String itemsText = "";
    if (order.items.isNotEmpty) {
      itemsText = order.items
          .map((it) => it.menu?.menuName ?? "")
          .where((name) => name.isNotEmpty)
          .join(", ");
    }

    final int rating = entry.rating;
    final String comment =
        (review?.commentrestaurant != null &&
            review!.commentrestaurant!.isNotEmpty)
        ? review.commentrestaurant!
        : "ลูกค้าไม่ได้ให้ความคิดเห็นเพิ่มเติม";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.orange.shade50,
                backgroundImage: finalImgUrl.isNotEmpty
                    ? NetworkImage(finalImgUrl)
                    : null,
                child: finalImgUrl.isEmpty
                    ? Icon(Icons.person, color: Colors.orange.shade400)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memberName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 16,
                          color: Colors.orange,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Text(
                dateText,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),

          if (itemsText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              "รายการ : $itemsText",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],

          if (review?.cleanliness == true || review?.tasteRating == true) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (review?.cleanliness == true) _buildTag("ถูกสุขลักษณะ"),
                if (review?.tasteRating == true) _buildTag("รสชาติดี"),
              ],
            ),
          ],

          const SizedBox(height: 10),
          Text(
            comment,
            style: TextStyle(
              fontSize: 13.5,
              color:
                  (review?.commentrestaurant != null &&
                      review!.commentrestaurant!.isNotEmpty)
                  ? Colors.black87
                  : Colors.grey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
