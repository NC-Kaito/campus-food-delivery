import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/features/restaurant/list_menu_restaurant.dart';
import 'package:flutter_app/features/restaurant/restaurant_navbar.dart';
import 'package:flutter_app/global_data.dart';

class HomeRestaurant extends StatefulWidget {
  const HomeRestaurant({super.key});

  @override
  State<HomeRestaurant> createState() => _HomeRestaurantState();
}

class _HomeRestaurantState extends State<HomeRestaurant> {
  final RestaurantService restaurantService = RestaurantService();
  RestaurantModel? restaurantModel;

  String? restaurantimage;
  String? restaurantname = "กำลังโหลด...";
  int? openday;
  String? phone = "-";
  String? opentime = "--:--";
  String? closetime = "--:--";
  String? typerestaurantName = "-";
  bool statusopen = true;

  Future<void> loadRestaurantData() async {
    final rest = await restaurantService.getRestaurantByUsername(
      GlobalData.usernameRestaurant,
    );
    setState(() {
      if (rest != null) {
        restaurantModel = rest;
        if (rest.restaurantImage != null) {
          restaurantimage = rest.restaurantImage!.replaceAll(
            '10.244.27.211',
            '10.244.27.84',
          );
        }
        restaurantname = rest.restaurantName;
        openday = rest.openDay;
        phone = rest.phone;
        opentime = rest.openTime;
        closetime = rest.closeTime;
        typerestaurantName = rest.typerestaurantName ?? "อาหารตามสั่ง";
        statusopen = rest.statusOpen ?? true;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    loadRestaurantData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: const RestaurantNavbar(title: ""),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- ส่วนหัวรูปภาพ ---
            Stack(
              children: [
                Container(
                  height: 290,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(0),
                      bottomRight: Radius.circular(0),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(0),
                      bottomRight: Radius.circular(0),
                    ),
                    child: restaurantimage != null
                        ? Image.network(
                            Uri.encodeFull(restaurantimage!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                                  'assets/images/default_restaurant.png',
                                  fit: BoxFit.cover,
                                ),
                          )
                        : Container(
                            color: const Color(0xFFD92D2D),
                            child: const Icon(
                              Icons.image_outlined,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),

            // --- ส่วนเนื้อหาด้านล่าง ---
            Transform.translate(
              offset: const Offset(0, -25),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),

                    // ชื่อร้านค้า
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            restaurantname ?? "ร้านคุณแบม",
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // หัวข้อเมนูแนะนำ
                    const Text(
                      "เมนูแนะนำ",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // การ์ดเมนูแนะนำ
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              'https://images.unsplash.com/photo-1617093727343-374698b1b08d?q=80&w=200',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.fastfood,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "คะน้าหมูกรอบ",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                "ราคา 40 บาท",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    // ตัวจุดนำทาง
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // ปุ่มแท็บ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 40,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5DF232),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () {
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (_) => const SalesPage(),
                              //   ),
                              // );
                            },
                            child: const Text(
                              "ยอดขาย",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          height: 40,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5DF232),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ListMenuRestaurant(),
                                ),
                              );
                            },
                            child: const Text(
                              "เมนู",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          height: 40,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5DF232),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () {
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (_) => const ReviewPage(),
                              //   ),
                              // );
                            },
                            child: const Text(
                              "ดูรีวิว",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // ตารางข้อมูลรายละเอียดร้าน
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _buildInfoRow(
                                Icons.storefront,
                                "ชื่อร้านค้า",
                                restaurantname ?? "-",
                              ),
                              const SizedBox(height: 20),
                              _buildInfoRow(
                                Icons.shopping_cart_outlined,
                                "วันทำการ",
                                _parseOpenDays(openday),
                              ),
                              const SizedBox(height: 20),
                              _buildInfoRow(
                                Icons.phone_in_talk_outlined,
                                "เบอร์โทรศัพท์",
                                phone ?? "-",
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 190,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            children: [
                              _buildInfoRow(
                                Icons.restaurant_menu,
                                "ประเภทร้านค้า",
                                typerestaurantName ?? "-",
                              ),
                              const SizedBox(height: 20),
                              _buildInfoRow(
                                Icons.access_time,
                                "เวลาเปิด - ปิด",
                                "$opentime - $closetime น.",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 28, color: Colors.black),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _parseOpenDays(int? dayMask) {
    if (dayMask == null) return "จันทร์ - เสาร์";
    if (dayMask == 127) return "เปิดทุกวัน";
    if (dayMask == 126) return "จันทร์ - เสาร์";
    if (dayMask == 62) return "จันทร์ - ศุกร์";
    return "จันทร์ - เสาร์";
  }
}
