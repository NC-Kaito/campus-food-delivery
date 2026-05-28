import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/member_model.dart';
import 'package:flutter_app/data/models/order_detail_addon_model.dart';
import 'package:flutter_app/data/models/order_detail_model.dart';
import 'package:flutter_app/data/models/order_model.dart';
import 'package:flutter_app/data/services/member/member_service.dart';
import 'package:flutter_app/data/services/order_service.dart';
import 'package:flutter_app/features/member/cart_manager_member.dart';
import 'package:flutter_app/features/member/edit_order_member.dart';
import 'package:flutter_app/features/member/location_order_member.dart';
import 'package:flutter_app/global_data.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ViewOrderMember extends StatefulWidget {
  final String storeName;
  final String storeUsername;
  final List<CartItem> storeItems;

  const ViewOrderMember({
    super.key,
    required this.storeUsername,
    required this.storeName,
    required this.storeItems,
  });

  @override
  State<ViewOrderMember> createState() => _ViewOrderMemberState();
}

class _ViewOrderMemberState extends State<ViewOrderMember> {
  final TextEditingController _addressNoteController = TextEditingController();

  LatLng? _selectedUserLocation;
  GoogleMapController? _miniMapController;

  String _loggedInMemberName = "กำลังโหลด...";
  String _loggedInMemberPhone = "กำลังโหลด...";

  static const LatLng _mjuCenter = LatLng(18.8920, 99.0145);
  final MemberService memberService = MemberService();

  @override
  void initState() {
    super.initState();
    _loadCurrentMemberProfile();
  }

  Future<void> _loadCurrentMemberProfile() async {
    try {
      String username = GlobalData.usernameMember;

      MemberModel mModel = await memberService.getMemberByUsername(username);

      setState(() {
        _loggedInMemberName =
            "${mModel.firstname ?? ''} ${mModel.lastname ?? ''}".trim();

        if (_loggedInMemberName.isEmpty) {
          _loggedInMemberName = mModel.username ?? "ไม่ระบุชื่อ";
        }

        _loggedInMemberPhone = mModel.phone ?? "ไม่ระบุเบอร์โทร";
      });
    } catch (e) {
      debugPrint("Error loading member profile: $e");
      setState(() {
        _loggedInMemberName = "ไม่สามารถดึงข้อมูลได้";
        _loggedInMemberPhone = "ไม่ระบุเบอร์โทร";
      });
    }
  }

  @override
  void dispose() {
    _addressNoteController.dispose();
    _miniMapController?.dispose();
    super.dispose();
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 65,
      height: 65,
      color: Colors.orange[50],
      child: const Icon(Icons.fastfood, color: Colors.orange, size: 30),
    );
  }

  Widget _buildOrderItemCard(CartItem item, String baseIp, int index) {
    String? rawMenuImage = item.menu.menuImage;
    String safeImageUrl = "";
    if (rawMenuImage != null && rawMenuImage.isNotEmpty) {
      safeImageUrl = rawMenuImage
          .replaceAll("10.226.43.211", baseIp)
          .replaceAll("10.0.2.2", baseIp);
    }

    int totalAddonPricePerUnit = 0;
    for (var addon in item.selectedAddons) {
      totalAddonPricePerUnit += addon.addonPrice?.toInt() ?? 0;
    }

    int baseMenuPrice = item.menu.price?.toInt() ?? 0;
    int finalPricePerUnit = baseMenuPrice + totalAddonPricePerUnit;

    String addonText = item.selectedAddons
        .map((e) => e.addonMenu?.addonName ?? '')
        .where((name) => name.isNotEmpty)
        .join(", ");

    return InkWell(
      onTap: () async {
        // 🚀 1. เปิดหน้าแก้ไขรายการอาหารตามปกติ
        final dynamic result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditOrderMember(cartItem: item),
          ),
        );

        // 🚀 2. ตรวจสอบสถานะขากลับเมื่อหน้า Edit ปิดสนิทลงแล้ว
        // 🚀 2. ดักเช็กข้อมูลขากลับเมื่อหน้า Edit ปิดสนิทลงแล้ว
        if (result != null) {
          setState(() {
            if (result == "REMOVE") {
              // 🎯 จุดแก้ไขวิกฤต: สั่งลบไอเทมตัวนี้ออกจากตะกร้ากลาง (CartManager) จริงๆ ด้วยครับ!
              CartManager().removeFromCart(item);

              // จากนั้นค่อยลบออกจาก List จำลองที่วาดบนหน้านี้
              widget.storeItems.removeAt(index);

              // ดักเช็กถ้าของเกลี้ยงตะกร้าแล้ว ให้เคลียร์คิวถอยฉากกลับหน้าแรกทันที
              if (widget.storeItems.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.pop(context);
                  }
                });
              }
            } else if (result is CartItem) {
              // กรณีแก้ไขเพิ่มลดจำนวนหรือแอนออนปกติ -> เขียนทับตัวแปรแถวเดิม
              widget.storeItems[index] = result;

              // 💡 ทริคเสริม: เพื่อความเนี๊ยบของระบบ ถ้าเขากดบันทึกแก้ไขจำนวนหรือแอดออนมาใหม่
              // เราก็ต้องอัปเดตไอเทมชิ้นนั้นกลับเข้าตะกร้าหลักในเครื่องด้วยเช่นกันครับ
              final int mainCartIndex = CartManager().items.indexOf(item);
              if (mainCartIndex != -1) {
                CartManager().items[mainCartIndex] = result;
              }
            }
          });
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
          border: const Border(left: BorderSide(color: Colors.green, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: safeImageUrl.isNotEmpty
                    ? Image.network(
                        Uri.encodeFull(safeImageUrl),
                        width: 65,
                        height: 65,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholderIcon(),
                      )
                    : _buildPlaceholderIcon(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.menu.menuName ?? "ไม่มีชื่อเมนู",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "แก้ไข",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "ราคา $finalPricePerUnit บาท",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (addonText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        "ตัวเลือกเสริม: $addonText",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "จำนวน ${item.quantity}",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const String baseIp = "10.244.27.211";

    // 🎯 แก้ไข: คำนวณราคารวมสินค้าโดยคิดรวมราคาเมนู + ราคา Add-on ทั้งหมด คูณด้วยจำนวนชิ้นจริง
    int subtotalPrice = 0;
    for (var item in widget.storeItems) {
      int addonsSum = 0;
      for (var addon in item.selectedAddons) {
        addonsSum += addon.addonPrice?.toInt() ?? 0;
      }
      int actualMenuPrice = (item.menu.price?.toInt() ?? 0) + addonsSum;
      subtotalPrice += (actualMenuPrice * item.quantity);
    }

    int deliveryFee = 15;
    int totalPrice = subtotalPrice + deliveryFee;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.orange),
        title: const Text(
          "สั่งซื้ออาหาร",
          style: TextStyle(
            color: Colors.orange,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.shopping_cart_outlined,
              color: Colors.orange,
              size: 28,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Colors.orange,
              size: 28,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====== ส่วนที่ 1: ข้อมูลลูกค้า ======
            const Text(
              "ข้อมูลลูกค้า",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 32,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ชื่อผู้รับสินค้า",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _loggedInMemberName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.phone_in_talk_outlined,
                        size: 32,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "เบอร์โทรศัพท์",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _loggedInMemberPhone,
                            style: const TextStyle(
                              fontSize: 15,
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
            const SizedBox(height: 16),
            const Divider(height: 1, color: Colors.grey),
            const SizedBox(height: 16),

            // ====== ส่วนที่ 2: ที่อยู่จัดส่ง & แผนที่จริงดิจิทัล ======
            Row(
              children: [
                const Text(
                  "ที่อยู่จัดส่ง",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                Icon(Icons.location_on, color: Colors.red, size: 24),
              ],
            ),
            const SizedBox(height: 12),

            InkWell(
              onTap: () async {
                final LatLng? selectedLocation = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LocationOrderMember(),
                  ),
                );

                if (selectedLocation != null) {
                  setState(() {
                    _selectedUserLocation = selectedLocation;
                  });
                  _miniMapController?.animateCamera(
                    CameraUpdate.newLatLng(selectedLocation),
                  );
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _selectedUserLocation ?? _mjuCenter,
                          zoom: 15.5,
                        ),
                        onMapCreated: (controller) =>
                            _miniMapController = controller,
                        zoomControlsEnabled: false,
                        zoomGesturesEnabled: false,
                        scrollGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                        tiltGesturesEnabled: false,
                        markers: _selectedUserLocation == null
                            ? {}
                            : {
                                Marker(
                                  markerId: const MarkerId(
                                    'delivery_fixed_pos',
                                  ),
                                  position: _selectedUserLocation!,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueRed,
                                  ),
                                ),
                              },
                      ),
                      Positioned.fill(
                        child: Container(color: Colors.transparent),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            Text(
              "ข้อมูลที่อยู่เพิ่มเติม ถ้ามี (เลขห้อง / จุดสังเกต)",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressNoteController,
              decoration: InputDecoration(
                hintText: "เช่น ใต้ตึก60ปี",
                fillColor: Colors.grey[200],
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Colors.grey),
            const SizedBox(height: 16),

            // ====== ส่วนที่ 3: รายการอาหารดึงจากตะกร้าจริง ======
            Text(
              "รายการอาหาร : ${widget.storeName}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.storeItems.length,
              itemBuilder: (context, index) {
                final item = widget.storeItems[index];
                // 🎯 จุดปรับปรุง: ส่งพารามิเตอร์ index พ่วงท้ายเข้าไปเพื่อให้ลูปจำตำแหน่งการแก้ไขได้
                return _buildOrderItemCard(item, baseIp, index);
              },
            ),
            const SizedBox(height: 16),

            // ====== ส่วนที่ 4: สรุปราคารวมทั้งหมด ======
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "ราคารวมสินค้า",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "$subtotalPrice บาท",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "ค่าจัดส่ง",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "$deliveryFee บาท",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: Colors.grey),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "ราคารวมทั้งหมด",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  "$totalPrice บาท",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ====== ส่วนปุ่มกดยืนยันคำสั่งซื้อ เชื่อมต่อระบบยิง API ครบวงจร ======
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (_selectedUserLocation == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "⚠️ กรุณาแตะแผ่นแผนที่เพื่อระบุตำแหน่งจัดส่งสินค้าก่อนครับ",
                        ),
                        backgroundColor: Colors.amber,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    ),
                  );

                  try {
                    List<OrderDetailModel> orderItems = widget.storeItems.map((
                      cartItem,
                    ) {
                      // คำนวณหาราคารวมสุทธิรายจาน (ราคาเมนูเดี่ยว + ราคาท็อปปิ้งทั้งหมด) เพื่อส่งเก็บลงฟิลด์ subTotal
                      int currentAddonsSum = 0;
                      for (var addon in cartItem.selectedAddons) {
                        currentAddonsSum += addon.addonPrice?.toInt() ?? 0;
                      }
                      double actualSubTotal =
                          ((cartItem.menu.price?.toInt() ?? 0) +
                              currentAddonsSum) *
                          cartItem.quantity.toDouble();

                      return OrderDetailModel(
                        menuId: cartItem.menu.menuId ?? 0,
                        qty: cartItem.quantity,
                        subTotal:
                            actualSubTotal, // ยัดยอดราคาเน็ตที่คำนวณท็อปปิ้งเรียบร้อยแล้ว
                        note: cartItem.note,
                        addons: cartItem.selectedAddons.map((addonDetail) {
                          return OrderDetailAddonModel(
                            addonDetailId: addonDetail.addonDetailId ?? 0,
                          );
                        }).toList(),
                      );
                    }).toList();

                    OrderModel finalOrder = OrderModel(
                      deliveryFee: deliveryFee.toDouble(),
                      totalPrice: totalPrice.toDouble(),
                      latitude: _selectedUserLocation!.latitude,
                      longitude: _selectedUserLocation!.longitude,
                      addressDetail: _addressNoteController.text,
                      memberUsername: GlobalData.usernameMember,
                      restaurantUsername: widget.storeUsername,
                      items: orderItems,
                    );

                    debugPrint(
                      "ร้านค้าที่แอปกำลังจะส่งไปคือ: ${widget.storeName}",
                    );
                    debugPrint("ก้อนข้อมูลที่จะส่ง: ${finalOrder.toJson()}");

                    await OrderService().memberConfirmOrder(finalOrder);

                    if (!mounted) return;
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "🎉 สั่งซื้ออาหารสำเร็จ! ระบบกำลังตามหาไรเดอร์ให้คุณครับ",
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );

                    CartManager().clearCart();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  } catch (error) {
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("❌ สั่งซื้อไม่สำเร็จ: $error"),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        // 🎯 เพิ่มมาร์จิ้นดักไว้ เพื่อยกตัวกล่องให้ลอยหนีการเบียดบังของ BottomNavigationBar
                        margin: const EdgeInsets.only(
                          bottom: 100,
                          left: 20,
                          right: 20,
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5CFF33),
                  foregroundColor: Colors.black,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  "ยืนยันคำสั่งซื้อ",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
