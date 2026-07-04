// features/member/view_order_member.dart
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
import 'package:flutter_app/core/network/dio_client.dart';

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

  final Color primaryGreen = const Color(0xFF64F02D);

  @override
  void initState() {
    super.initState();
    _loadCurrentMemberProfile();
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;

    final String baseUrl = DioClient.dio.options.baseUrl;
    if (rawPath.startsWith('/')) {
      return "$baseUrl$rawPath";
    } else {
      return "$baseUrl/$rawPath";
    }
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
      color: Colors.green.shade50,
      child: Icon(Icons.fastfood_rounded, color: primaryGreen, size: 30),
    );
  }

  Widget _buildOrderItemCard(CartItem item, int index) {
    // 🌟 1. เช็กว่าเป็นเมนูประเภทข้าวราดแกงหรือไม่
    final bool isCurryDish = item.selectedCurries.isNotEmpty;

    // 🌟 2. กำหนดชื่อเมนูที่จะแสดงผลบนหัว Card ให้เหมาะสม
    final String displayMenuName = isCurryDish
        ? "ข้าวราดแกง (${item.selectedCurries.length} อย่าง)"
        : (item.menu.menuName ?? "ไม่มีชื่อเมนู");

    String? rawMenuImage = item.menu.menuImage;
    String finalMenuUrl = _getFinalImageUrl(rawMenuImage);

    // คำนวณราคาต่อหน่วย
    int finalPricePerUnit = 0;
    if (isCurryDish) {
      finalPricePerUnit = item.totalPrice;
    } else {
      int totalAddonPricePerUnit = 0;
      for (var addon in item.selectedAddons) {
        totalAddonPricePerUnit += addon.addonPrice?.toInt() ?? 0;
      }
      int baseMenuPrice = item.menu.price?.toInt() ?? 0;
      finalPricePerUnit = baseMenuPrice + totalAddonPricePerUnit;
    }

    String addonText = item.selectedAddons
        .map((e) => e.addonMenu?.addonName ?? '')
        .where((name) => name.isNotEmpty)
        .join(", ");

    String curriesText = item.selectedCurries
        .map((e) => e.menuName ?? '')
        .where((name) => name.isNotEmpty)
        .join(", ");

    return InkWell(
      onTap: () async {
        final dynamic result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditOrderMember(cartItem: item),
          ),
        );

        if (result != null) {
          setState(() {
            if (result == "REMOVE") {
              CartManager().removeFromCart(item);
              widget.storeItems.removeAt(index);

              if (widget.storeItems.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.pop(context);
                  }
                });
              }
            } else if (result is CartItem) {
              widget.storeItems[index] = result;
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
          border: Border(left: BorderSide(color: primaryGreen, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                // 🌟 3. ถ้าเป็นข้าวราดแกง ให้สลับมาใช้ไอคอนกลางแทนรูปแกงถ้วยเดี่ยวทันที
                child: isCurryDish || finalMenuUrl.isEmpty
                    ? _buildPlaceholderIcon()
                    : Image.network(
                        Uri.encodeFull(finalMenuUrl),
                        width: 65,
                        height: 65,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholderIcon(),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 🌟 4. เปลี่ยนมาเรนเดอร์ตัวแปร displayMenuName ที่เราดักค่าไว้
                        Text(
                          displayMenuName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "แก้ไข",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
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
                    if (curriesText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        "กับข้าวที่ราด: $curriesText",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    if (addonText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        "ตัวเลือกเสริม: $addonText",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade800,
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
    // 🌟 4. ปรับปรุงสูตรคิดราคารวมสินค้าทั้งหมดในร้านค้านั้นๆ ให้รองรับราดแกง
    int subtotalPrice = 0;
    for (var item in widget.storeItems) {
      if (item.selectedCurries.isNotEmpty) {
        // ถ้าราดแกง เอาค่าหัวราคาจานคูณจำนวนไปได้ทันที
        subtotalPrice += (item.totalPrice * item.quantity);
      } else {
        // เมนูตามสั่งปกติ คิดแบบราคาเบส + ท็อปปิ้งออริจินัล
        int addonsSum = 0;
        for (var addon in item.selectedAddons) {
          addonsSum += addon.addonPrice?.toInt() ?? 0;
        }
        int actualMenuPrice = (item.menu.price?.toInt() ?? 0) + addonsSum;
        subtotalPrice += (actualMenuPrice * item.quantity);
      }
    }

    int deliveryFee = 15;
    int totalPrice = subtotalPrice + deliveryFee;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryGreen),
        title: const Text(
          "สั่งซื้ออาหาร",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.shopping_cart_outlined,
              color: primaryGreen,
              size: 26,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.account_circle_outlined,
              color: primaryGreen,
              size: 26,
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
                fontSize: 18,
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
                        size: 28,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ชื่อผู้รับสินค้า",
                            style: TextStyle(
                              fontSize: 13,
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
                        size: 28,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "เบอร์โทรศัพท์",
                            style: TextStyle(
                              fontSize: 13,
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
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 16),

            // ====== ส่วนที่ 2: ที่อยู่จัดส่ง & แผนที่ดิจิทัล ======
            Row(
              children: [
                const Text(
                  "ที่อยู่จัดส่ง",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                Icon(Icons.location_on, color: primaryGreen, size: 22),
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
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                fillColor: Colors.grey[100],
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
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 16),

            // ====== ส่วนที่ 3: รายการอาหารดึงจากตะกร้าจริง ======
            Text(
              "รายการอาหาร : ${widget.storeName}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.storeItems.length,
              itemBuilder: (context, index) {
                final item = widget.storeItems[index];
                return _buildOrderItemCard(item, index);
              },
            ),
            const SizedBox(height: 16),

            // ====== ส่วนที่ 4: สรุปราคารวมทั้งหมด ======
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "ราคารวมสินค้า",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  "$subtotalPrice บาท",
                  style: const TextStyle(
                    fontSize: 15,
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  "$deliveryFee บาท",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  "ราคารวมทั้งหมด",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  "$totalPrice",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  "บาท",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ====== ส่วนปุ่มกดยืนยันคำสั่งซื้อ ======
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
                        behavior: SnackBarBehavior.fixed,
                      ),
                    );
                    return;
                  }

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => Center(
                      child: CircularProgressIndicator(color: primaryGreen),
                    ),
                  );

                  try {
                    // 🌟 5. แปลงข้อมูลตะกร้าสินค้า ให้พร้อมยิงไปหาตารางใหม่หลังบ้าน
                    List<OrderDetailModel> orderItems = widget.storeItems.map((
                      cartItem,
                    ) {
                      double actualSubTotal = 0;

                      if (cartItem.selectedCurries.isNotEmpty) {
                        // เคสราดแกง: ราคารวมคูณจำนวนไปได้โดยตรง
                        actualSubTotal =
                            (cartItem.totalPrice * cartItem.quantity)
                                .toDouble();
                      } else {
                        // เคสอาหารปกติ
                        int currentAddonsSum = 0;
                        for (var addon in cartItem.selectedAddons) {
                          currentAddonsSum += addon.addonPrice?.toInt() ?? 0;
                        }
                        actualSubTotal =
                            ((cartItem.menu.price?.toInt() ?? 0) +
                                currentAddonsSum) *
                            cartItem.quantity.toDouble();
                      }

                      // สลายข้อมูลวัตถุให้พร้อมส่งออกไปยัง JSON
                      return OrderDetailModel(
                        menuId: cartItem.menu.menuId ?? 0,
                        qty: cartItem.quantity,
                        subTotal: actualSubTotal,
                        note: cartItem.note,
                        addons: cartItem.selectedAddons.map((addonDetail) {
                          return OrderDetailAddonModel(
                            addonDetailId: addonDetail.addonDetailId ?? 0,
                            priceAtOrder: (addonDetail.addonPrice ?? 0)
                                .toDouble(),
                          );
                        }).toList(),
                        // 🎯 ยัดข้อมูลส่วนประกอบราดแกงเพิ่มเข้าไปที่โมเดลส่งออก (แมปเข้ากับฟิลด์หลังบ้านตรงๆ)
                        // หมายเหตุ: อย่าลืมแวะเพิ่มฟิลด์ orderDetailCurries ในคลาส OrderDetailModel ด้วยนะคราบบบ
                        orderDetailCurries: cartItem.selectedCurries.map((
                          curry,
                        ) {
                          return {
                            "menu": {"menuid": curry.menuId ?? 0},
                            "priceAtOrder":
                                5.0, // ล็อกยอดตักเพิ่มชิ้นละ 5 บาท Fixed ตามราคาหน้าร้าน
                          };
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
                        behavior: SnackBarBehavior.fixed,
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
                        behavior: SnackBarBehavior.fixed,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
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
