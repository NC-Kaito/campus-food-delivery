// features/restaurant/review_restaurant.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/services/order_service.dart';
import 'package:flutter_app/global_data.dart';

class ReviewRestaurant extends StatefulWidget {
  const ReviewRestaurant({super.key});

  @override
  State<ReviewRestaurant> createState() => _ReviewRestaurantState();
}

class _ReviewRestaurantState extends State<ReviewRestaurant> {
  final OrderService _orderService = OrderService();

  List<dynamic> _allReviews = [];
  bool _isLoading = true;

  int _star5 = 0, _star4 = 0, _star3 = 0, _star2 = 0, _star1 = 0;
  double _averageRating = 0.0;
  int _totalReviewCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchRestaurantReviews();
  }

  Future<void> _fetchRestaurantReviews() async {
    try {
      String username = GlobalData.usernameRestaurant;
      final orders = await _orderService.getReviewSuccessOrdersByRestaurant(
        username,
      );

      int s1 = 0, s2 = 0, s3 = 0, s4 = 0, s5 = 0;
      double totalStars = 0;

      for (var order in orders) {
        final double rating =
            double.tryParse((order['reviewRating'] ?? 5.0).toString()) ?? 5.0;
        totalStars += rating;

        if (rating >= 5)
          s5++;
        else if (rating >= 4)
          s4++;
        else if (rating >= 3)
          s3++;
        else if (rating >= 2)
          s2++;
        else
          s1++;
      }

      if (mounted) {
        setState(() {
          _allReviews = orders;
          _totalReviewCount = orders.length;
          _star5 = s5;
          _star4 = s4;
          _star3 = s3;
          _star2 = s2;
          _star1 = s1;
          _averageRating = _totalReviewCount > 0
              ? (totalStars / _totalReviewCount)
              : 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("🚨 เกิดข้อผิดพลาดในการโหลดหน้ารวมรีวิวร้านค้า: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final goodReviews = _allReviews.where((o) {
      final r = double.tryParse((o['reviewRating'] ?? 5.0).toString()) ?? 5.0;
      return r >= 4.0;
    }).toList();

    final updateReviews = _allReviews.where((o) {
      final r = double.tryParse((o['reviewRating'] ?? 5.0).toString()) ?? 5.0;
      return r <= 3.0;
    }).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            "รีวิวร้านค้า",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF16A34A)),
              )
            : NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(child: _buildSummaryBox()),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          indicatorColor: Colors.black,
                          indicatorWeight: 3,
                          labelColor: Colors.black,
                          unselectedLabelColor: Colors.black87,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          tabs: const [
                            Tab(text: "ทั้งหมด"),
                            Tab(text: "ดี"),
                            Tab(text: "ปรับปรุง"),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  children: [
                    _buildReviewList(_allReviews),
                    _buildReviewList(goodReviews),
                    _buildReviewList(updateReviews),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryBox() {
    double p5 = _totalReviewCount > 0 ? (_star5 / _totalReviewCount) : 0.0;
    double p4 = _totalReviewCount > 0 ? (_star4 / _totalReviewCount) : 0.0;
    double p3 = _totalReviewCount > 0 ? (_star3 / _totalReviewCount) : 0.0;
    double p2 = _totalReviewCount > 0 ? (_star2 / _totalReviewCount) : 0.0;
    double p1 = _totalReviewCount > 0 ? (_star1 / _totalReviewCount) : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: Colors.orange, size: 50),
              const SizedBox(width: 8),
              Text(
                _averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressBar(5, p5, _star5),
          const SizedBox(height: 8),
          _buildProgressBar(4, p4, _star4),
          const SizedBox(height: 8),
          _buildProgressBar(3, p3, _star3),
          const SizedBox(height: 8),
          _buildProgressBar(2, p2, _star2),
          const SizedBox(height: 8),
          _buildProgressBar(1, p1, _star1),
          const SizedBox(height: 20),
          const Text(
            "คะแนนรีวิวร้านค้า",
            style: TextStyle(fontSize: 15, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            "${_averageRating.toStringAsFixed(1)} / 5.0 ($_totalReviewCount+ รีวิว)",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int star, double percent, int count) {
    return Row(
      children: [
        Text(
          '$star',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.star_rounded, color: Colors.orange, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey.shade300,
              color: Colors.orange,
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 24,
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewList(List<dynamic> ordersList) {
    if (ordersList.isEmpty) {
      return const Center(
        child: Text(
          "ยังไม่มีข้อมูลรีวิวในส่วนนี้",
          style: TextStyle(
            fontSize: 15,
            color: Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: ordersList.length,
      itemBuilder: (context, index) {
        final order = ordersList[index];

        String customerName = "ลูกค้าปริศนา";
        if (order['member'] != null) {
          final String fName = order['member']['firstname'] ?? "";
          final String lName = order['member']['lastname'] ?? "";
          if (fName.isNotEmpty || lName.isNotEmpty) {
            customerName = "$fName $lName".trim();
          }
        }

        final int orderId = order['orderId'] ?? 0;
        final double rating =
            double.tryParse((order['reviewRating'] ?? 5.0).toString()) ?? 5.0;
        final String comment =
            order['reviewComment'] ?? "ไม่มีข้อความติชมเพิ่มเติม";

        String dateText = "ไม่ระบุวันที่";
        if (order['orderdate'] != null) {
          try {
            final DateTime dateTime = DateTime.parse(
              order['orderdate'].toString(),
            );
            dateText =
                "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}";
          } catch (_) {}
        }

        final bool isClean = order['cleanliness'] == true;
        final bool isTasty = order['tasteRating'] == true;

        return Column(
          children: [
            _buildReviewItem(
              name: customerName,
              orderId: "K${orderId.toString().padLeft(6, '0')}",
              date: dateText,
              rating: rating.toInt(),
              comment: comment,
              isClean: isClean,
              isTasty: isTasty,
            ),
            if (index < ordersList.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                color: Colors.black12,
                indent: 20,
                endIndent: 20,
              ),
          ],
        );
      },
    );
  }

  // 🎯 ฟังก์ชันสำหรับวาดแท็กสีส้มสวยๆ (แบบเดียวกับหน้ารายละเอียด)
  Widget _buildTagIfTrue(String label, bool isSelected) {
    if (!isSelected) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildReviewItem({
    required String name,
    required String orderId,
    required String date,
    required int rating,
    required String comment,
    required bool isClean,
    required bool isTasty,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey.shade300,
            child: const Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          orderId,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          date,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: Colors.orange,
                      size: 20,
                    );
                  }),
                ),

                // 🎯 เรียกใช้แท็กสีส้มแทนข้อความธรรมดาครับ
                if (isClean || isTasty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      _buildTagIfTrue("ถูกสุขลักษณะ ✨", isClean),
                      _buildTagIfTrue("รสชาติดี 😋", isTasty),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                Text(
                  comment,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: const Color(0xFFF9F7CD), child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
