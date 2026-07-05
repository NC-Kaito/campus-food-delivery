// features/restaurant/agrees_restaurant.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/features/restaurant/register_restaurant.dart';

class AgreesRestaurant extends StatefulWidget {
  const AgreesRestaurant({super.key});

  @override
  State<AgreesRestaurant> createState() => _AgreesRestaurantState();
}

class _AgreesRestaurantState extends State<AgreesRestaurant> {
  // 🎯 ปรับเหลือตัวแปรจับสถานะการยินยอมเพียงค่าเดียว
  bool _isAccepted = false;

  // หัวข้อและรายละเอียดข้อตกลง
  final List<Map<String, String>> _content = [
    {
      "title": "1. คุณสมบัติของผู้เข้าร่วมโครงการ",
      "desc":
          "ข้าพเจ้ายืนยันว่าเป็นร้านค้าที่ได้รับอนุญาตให้ประกอบกิจการภายในพื้นที่ของมหาวิทยาลัยแม่โจ้อย่างถูกต้อง หากตรวจพบภายหลังว่าเป็นข้อมูลเท็จข้อตกลงนี้จะถือเป็นโมฆะทันที",
    },
    {
      "title": "2. ข้อตกลงด้านราคาและการจำหน่าย",
      "desc":
          "ร้านค้าตกลงและยินยอมจำหน่ายรายการอาหารหรือเครื่องดื่มในราคาที่ระบุไว้ในระบบอย่างเคร่งครัด โดยไม่มีการเรียกเก็บค่าธรรมเนียมหรือปรับเพิ่มราคาหน้าบ้าน นอกเหนือจากราคาที่ปรากฏในคำสั่งซื้อ",
    },
    {
      "title": "3. การเตรียมและการส่งมอบ",
      "desc":
          "ร้านค้าตกลงเริ่มจัดเตรียมอาหารทันทีเมื่อได้รับคำสั่งซื้อเพื่อลดระยะเวลาการรอคอยของผู้จัดส่ง และยินยอมตรวจสอบความถูกต้องและครบถ้วนของรายการอาหาร รวมถึงบรรจุภัณฑ์ที่มิดชิดก่อนส่งมอบผู้จัดส่ง",
    },
    {
      "title": "4. มาตรฐานการให้บริการ",
      "desc":
          "ยินยอมที่จะรักษาคุณภาพและความสะอาดของอาหารตามมาตรฐานเดียวกับการขายหน้าร้าน และพร้อมจัดเตรียมอาหารตามระยะเวลาที่ระบบกำหนดเพื่อไม่ให้เกิดความล่าช้า",
    },
    {
      "title": "5. การสิ้นสุดข้อตกลง",
      "desc":
          "รับทราบว่าหากมีการฝ่าฝืนเงื่อนไขหรือระเบียบการค้าขายภายในมหาวิทยาลัย ทางผู้ดูแลระบบมีสิทธิ์ระงับการเชื่อมต่อกับระบบจัดส่งได้ทันทีโดยไม่ต้องแจ้งให้ทราบล่วงหน้า",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'ข้อตกลงและเงื่อนไขการยินยอม',
          style: TextStyle(
            color: Color.fromARGB(255, 255, 102, 0),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // ส่วนแสดงรายละเอียดเงื่อนไขทั้งหมด
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListView.builder(
                itemCount: _content.length,
                itemBuilder: (context, index) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _content[index]['title']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _content[index]['desc']!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20), // เว้นระยะห่างระหว่างข้อ
                    ],
                  );
                },
              ),
            ),
          ),

          // 🎯 ส่วนล่าง: Checkbox ยินยอมเงื่อนไขทั้งหมดอันเดียว และปุ่มนำทาง
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isAccepted = !_isAccepted;
                    });
                  },
                  child: Row(
                    children: [
                      Checkbox(
                        value: _isAccepted,
                        onChanged: (bool? value) {
                          setState(() {
                            _isAccepted = value ?? false;
                          });
                        },
                        activeColor: const Color.fromARGB(255, 47, 255, 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          "ยอมรับข้อตกลงและเงื่อนไขทั้งหมด",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.grey[200],
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "ย้อนกลับ",
                          style: TextStyle(color: Colors.black, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color.fromARGB(
                            255,
                            13,
                            255,
                            0,
                          ),
                          elevation: _isAccepted ? 3 : 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        // 🎯 หากยังไม่ติ๊กยินยอม ปุ่มถัดไปจะถูก Disabled (เป็น null) ทันที
                        onPressed: !_isAccepted
                            ? null
                            : () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (BuildContext buildContext) {
                                      return const RegisterRestaurant();
                                    },
                                  ),
                                );
                              },
                        child: const Text(
                          "ถัดไป",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
    );
  }
}
