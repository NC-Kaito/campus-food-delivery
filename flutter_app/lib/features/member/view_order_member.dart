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

  final bool isFromAddOrder;

  const ViewOrderMember({
    super.key,
    required this.storeUsername,
    required this.storeName,
    required this.storeItems,
    this.isFromAddOrder = false,
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
      color: Colors.orange.shade50,
      child: const Icon(Icons.fastfood_rounded, color: Colors.orange, size: 30),
    );
  }

  Widget _buildOrderItemCard(CartItem item, int index) {
    final bool isCurryDish = item.selectedCurries.isNotEmpty;

    String displayMenuName = isCurryDish
        ? "ข้าวราดแกง (${item.selectedCurries.length} อย่าง)"
        : (item.menu.menuName ?? "ไม่มีชื่อเมนู");

    if (item.isExtraPrice) {
      displayMenuName += " (พิเศษ)";
    }

    String? rawMenuImage = item.menu.menuImage;
    String finalMenuUrl = _getFinalImageUrl(rawMenuImage);

    // 🎯 [แก้ไขแล้ว] ไม่แยกคิดราคาระหว่างข้าวแกงกับเมนูทั่วไป ให้นำ Add-on มาบวกรวมเสมอ
    int totalAddonPricePerUnit = 0;
    for (var addon in item.selectedAddons) {
      totalAddonPricePerUnit += addon.addonPrice?.toInt() ?? 0;
    }
    int finalPricePerUnit = item.unitPrice + totalAddonPricePerUnit;

    Map<String, int> addonCounts = {};
    for (var addon in item.selectedAddons) {
      String name = addon.addonMenu?.addonName ?? '';
      if (name.isNotEmpty) {
        addonCounts[name] = (addonCounts[name] ?? 0) + 1;
      }
    }

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            displayMenuName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "แก้ไข",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "ราคา $finalPricePerUnit บาท",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    if (item.selectedCurries.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6.0,
                        runSpacing: 6.0,
                        children: item.selectedCurries.map((curry) {
                          String rawCurryImage = curry.menuImage ?? '';
                          String finalCurryUrl = _getFinalImageUrl(
                            rawCurryImage,
                          );

                          return Container(
                            padding: const EdgeInsets.only(
                              left: 2,
                              right: 8,
                              top: 2,
                              bottom: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.green.shade200),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    color: Colors.grey.shade200,
                                    child: finalCurryUrl.isNotEmpty
                                        ? Image.network(
                                            Uri.encodeFull(finalCurryUrl),
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                                  Icons.fastfood_rounded,
                                                  size: 12,
                                                  color: Colors.grey,
                                                ),
                                          )
                                        : const Icon(
                                            Icons.fastfood_rounded,
                                            size: 12,
                                            color: Colors.grey,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  curry.menuName ?? "ไม่มีชื่อ",
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.green.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    if (addonCounts.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6.0,
                        runSpacing: 6.0,
                        children: addonCounts.entries.map((entry) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add_circle_rounded,
                                  size: 14,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  entry.value > 1
                                      ? "${entry.key} x${entry.value}"
                                      : entry.key,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.orange.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "จำนวน ${item.quantity}",
                        style: const TextStyle(
                          fontSize: 14,
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
    int subtotalPrice = 0;

    // 🎯 [แก้ไขแล้ว] รวมราคา Add-on ไม่ว่าจะเป็นเมนูไหนก็ตาม
    for (var item in widget.storeItems) {
      int addonsSum = 0;
      for (var addon in item.selectedAddons) {
        addonsSum += addon.addonPrice?.toInt() ?? 0;
      }
      int actualMenuPrice = item.unitPrice + addonsSum;
      subtotalPrice += (actualMenuPrice * item.quantity);
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
                    // 🎯 [แก้ไขแล้ว] รวมราคา Add-on ไม่ว่าจะเป็นเมนูไหนก็ตามตอนกดยืนยันออเดอร์
                    List<OrderDetailModel> orderItems = widget.storeItems.map((
                      cartItem,
                    ) {
                      int currentAddonsSum = 0;
                      for (var addon in cartItem.selectedAddons) {
                        currentAddonsSum += addon.addonPrice?.toInt() ?? 0;
                      }
                      double actualSubTotal =
                          (cartItem.unitPrice + currentAddonsSum) *
                          cartItem.quantity.toDouble();

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
                        orderDetailCurries: cartItem.selectedCurries.map((
                          curry,
                        ) {
                          return {
                            "menuId": curry.menuId ?? 0,
                            "priceAtOrder": 0.0,
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
            if (widget.isFromAddOrder) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
                    side: BorderSide(color: Colors.green.shade700, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "สั่งอาหารต่อ",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
