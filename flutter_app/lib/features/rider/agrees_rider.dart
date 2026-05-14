import 'package:flutter/material.dart';
import 'package:flutter_app/features/rider/register_rider.dart';

class AgreesRider extends StatefulWidget {
  const AgreesRider({super.key});

  @override
  State<AgreesRider> createState() => _AgreesRiderState();
}

class _AgreesRiderState extends State<AgreesRider> {
  List<bool?> _agreements = List.generate(5, (index) => null);
  bool _agreeAll = false;

  final List<Map<String, String>> _content = [
    {
      "title": "1. คุณสมบัติของผู้เข้าร่วมโครงการ",
      "desc":
          "ข้าพเจ้ายืนยันว่าเป็นนักศึกษาที่กำลังศึกษาอยู่ในมหาวิทยาลัยแม่โจ้และมีสถานภาพเป็นนักศึกษาที่ถูกต้องตามระเบียบของมหาวิทยาลัย หากตรวจสอบพบว่าเป็นข้อมูลเท็จข้าพเจ้ายินยอมให้ยกเลิกสิทธิ์การเป็นผู้จัดส่งทันที",
    },
    {
      "title": "2. ข้อตกลงด้านค่าตอบแทนและการปฏิบัติงาน",
      "desc":
          "ข้าพเจ้ายินยอมรับค่าตอบแทนในการจัดส่ง(ค่ารอบ)ตามอัตราที่ระบบกำหนดคือ 15 บาทต่อรอบโดยจะไม่มีการเรียกเก็บค่าบริการเพิ่มเติมจากผู้ซื้อนอกเหนือจากที่ปรากฏในระบบ ทั้งนี้ข้าพเจ้าหน้าที่ปฏิบัติขั้นตอนการรับส่งอาหาร โดยตกลงสำรองจ่ายค่าอาหารให้แก่ร้านค้าก่อนรับสินค้า และจะได้รับเงินคืนพร้อมค่าบริการจัดส่งจากผู้ซื้อเมื่อการจัดส่งเสร็จสิ้นสมบูรณ์เท่านั้น",
    },
    {
      "title": "3. ค่าธรรมเนียมการใช้บริการรายเดือน",
      "desc":
          "ผู้สมัครยินยอมชำระค่าธรรมเนียมการใช้บริการระบบ ในอัตรา 100 บาทต่อเดือนโดยจะต้องชำระให้เสร็จสิ้นตามรอบเวลาที่ระบบกำหนดเพื่อรักษาสถานะการเปิดรับงานในระบบ",
    },
    {
      "title": "4. มาตรฐานการให้บริการ",
      "desc":
          "ยินยอมที่จะรักษาความสมบูรณ์ของอาหารตั้งแต่รับจากร้านค้าจนถึงมือผู้รับ จัดส่งด้วยความรวดเร็วและสุภาพ และไม่เปิดเผยข้อมูลส่วนบุคคลของลูกค้าแก่บุคคลภายนอก",
    },
    {
      "title": "5. การสิ้นสุดข้อตกลง",
      "desc":
          "รับทราบว่าหากพ้นสภาพการเป็นนักศึกษาหรือมีการร้องเรียนเกี่ยวกับพฤติกรรมที่ไม่เหมาะสมทีมงานมีสิทธิ์ระงับการเข้าถึงระบบได้ทันทีโดยไม่ต้องแจ้งให้ทราบล่วงหน้า",
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
                                      return const RegisterRider(); // ไปที่หน้าสมัครสมาชิก Rider
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
