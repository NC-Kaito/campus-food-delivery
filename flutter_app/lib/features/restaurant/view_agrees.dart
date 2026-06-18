import 'package:flutter/material.dart';
import 'package:flutter_app/features/restaurant/restaurant_navbar.dart';

class ViewAgrees extends StatefulWidget {
  const ViewAgrees({super.key});

  @override
  State<ViewAgrees> createState() => _ViewAgreesState();
}

class _ViewAgreesState extends State<ViewAgrees> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const RestaurantNavbar(title: "ข้อตกลงการให้บริการ"),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 15),
            const Text(
              "ข้อตกลงและเงื่อนไขการยินยอม",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 131, 42),
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.6,
                      ),
                      children: const [
                        TextSpan(
                          text: "1. คุณสมบัติของผู้เข้าร่วมโครงการ\n",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              "ข้าพเจ้ายืนยันว่าเป็นร้านค้าที่ได้รับอนุญาตให้ประกอบกิจการภายในพื้นที่ของมหาวิทยาลัยแม่โจ้อย่างถูกต้อง หากตรวจพบภายหลังว่าเป็นข้อมูลเท็จข้อตกลงนี้จะถือเป็นโมฆะทันที\n\n",
                        ),

                        TextSpan(
                          text: "2. ข้อตกลงด้านราคาและการจำหน่าย\n",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              "ร้านค้าตกลงและยินยอมจำหน่ายรายการอาหารหรือเครื่องดื่มในราคาที่ระบุไว้ในระบบอย่างเคร่งครัด โดยไม่มีการเรียกเก็บค่าธรรมเนียมหรือปรับเพิ่มราคาหน้าบ้าน นอกเหนือจากราคาที่ปรากฏในคำสั่งซื้อ\n\n",
                        ),

                        TextSpan(
                          text: "3. การเตรียมและการส่งมอบ\n",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              "ร้านค้าตกลงเริ่มจัดเตรียมอาหารทันทีเมื่อได้รับคำสั่งซื้อเพื่อลดระยะเวลาการรอคอยของผู้จัดส่ง และยินยอมตรวจสอบความถูกต้องและครบถ้วนของรายการอาหาร รวมถึงบรรจุภัณฑ์ที่มิดชิดก่อนส่งมอบผู้จัดส่ง\n\n",
                        ),

                        TextSpan(
                          text: "4. มาตรฐานการให้บริการ\n",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              "ยินยอมที่จะรักษาคุณภาพและความสะอาดของอาหารตามมาตรฐานเดียวกับการขายหน้าร้าน และพร้อมจัดเตรียมอาหารตามระยะเวลาที่ระบบกำหนดเพื่อไม่ให้เกิดความล่าช้า\n\n",
                        ),

                        TextSpan(
                          text: "5. การสิ้นสุดข้อตกลง\n",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              "รับทราบว่าหากมีการฝ่าฝืนเงื่อนไขหรือระเบียบการค้าขายภายในมหาวิทยาลัย ทางผู้ดูแลระบบมีสิทธิ์ระงับการเชื่อมต่อกับระบบจัดส่งได้ทันทีโดยไม่ต้องแจ้งให้ทราบล่วงหน้า",
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // ปุ่มย้อนกลับ
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 85, 255, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "ย้อนกลับ",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
