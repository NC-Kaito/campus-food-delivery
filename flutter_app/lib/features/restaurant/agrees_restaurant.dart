import 'package:flutter/material.dart';
import 'package:flutter_app/features/restaurant/register_restaurant.dart';
import 'package:flutter_app/features/user/register_member.dart';

class AgreesRestaurant extends StatefulWidget {
  const AgreesRestaurant({super.key});

  @override
  State<AgreesRestaurant> createState() => _AgreesRestaurantState();
}

class _AgreesRestaurantState extends State<AgreesRestaurant> {
  // สร้าง List สำหรับเก็บสถานะการเลือกแต่ละข้อ (5 ข้อ)
  // null = ยังไม่เลือก, true = ยินยอม, false = ไม่ยินยอม
  List<bool?> _agreements = List.generate(5, (index) => null);
  bool _agreeAll = false;

  // หัวข้อและรายละเอียดตามรูปภาพ
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

  void _handleAgreeAll(bool? value) {
    setState(() {
      _agreeAll = value ?? false;
      for (int i = 0; i < _agreements.length; i++) {
        _agreements[i] = _agreeAll ? true : null;
      }
    });
  }

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
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
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
                      const SizedBox(height: 4),
                      Text(
                        _content[index]['desc']!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      Row(
                        children: [
                          _buildChoice(index, true, "ยินยอม"),
                          const SizedBox(width: 20),
                          _buildChoice(index, false, "ไม่ยินยอม"),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),
          ),

          // ส่วนล่าง (ยินยอมทั้งหมด และ ปุ่ม)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _agreeAll,
                      onChanged: _handleAgreeAll,
                      activeColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Text(
                      "ยินยอมทั้งหมด",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.greenAccent[400],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed:
                            _agreements.contains(null) ||
                                _agreements.contains(false)
                            ? null // ปิดปุ่มถ้ายังเลือกไม่ครบ หรือมีข้อที่ไม่ยินยอม
                            : () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (BuildContext buildContext) {
                                      return RegisterRestaurant();
                                    },
                                  ),
                                );
                              },
                        child: const Text(
                          "ถัดไป",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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

  Widget _buildChoice(int index, bool value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: _agreements[index] == value,
          onChanged: (bool? newValue) {
            setState(() {
              if (newValue == true) {
                _agreements[index] = value;
              } else {
                _agreements[index] = null;
              }
              // เช็คว่าถ้าติ๊กยินยอมทุกข้อ ให้ติ๊ก "ยินยอมทั้งหมด" อัตโนมัติ
              _agreeAll =
                  !_agreements.contains(null) && !_agreements.contains(false);
            });
          },
          activeColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Text(label),
      ],
    );
  }
}
