// features/member/view_order_member.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/member_model.dart';
import 'package:flutter_app/data/models/order_detail_addon_model.dart';
import 'package:flutter_app/data/models/order_detail_model.dart';
import 'package:flutter_app/data/models/order_model.dart';
import 'package:flutter_app/data/services/in_app_notification_service.dart';
import 'package:flutter_app/data/services/member/member_service.dart';
import 'package:flutter_app/data/services/order_status_monitor.dart';
import 'package:flutter_app/data/services/order_service.dart';
import 'package:flutter_app/features/member/cart_manager_member.dart';
import 'package:flutter_app/features/member/edit_order_member.dart';
import 'package:flutter_app/features/member/edit_curry_order_member.dart';
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

  final Color primaryGreen = const Color(0xFF00B300);

  @override
  void initState() {
    super.initState();
    _loadCurrentMemberProfile();
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;

    final String baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/')
        ? baseUrl + rawPath
        : baseUrl + '/' + rawPath;
  }

  Future<void> _loadCurrentMemberProfile() async {
    try {
      String username = GlobalData.usernameMember;
      MemberModel mModel = await memberService.getMemberByUsername(username);

      if (mounted) {
        setState(() {
          _loggedInMemberName =
              ((mModel.firstname ?? '') + " " + (mModel.lastname ?? '')).trim();

          if (_loggedInMemberName.isEmpty) {
            _loggedInMemberName = mModel.username ?? "ไม่ระบุชื่อ";
          }
          _loggedInMemberPhone = mModel.phone ?? "ไม่ระบุเบอร์โทร";

          if (mModel.latitude != null && mModel.longitude != null) {
            _selectedUserLocation = LatLng(mModel.latitude!, mModel.longitude!);
          }
          if (mModel.defaultlocation != null &&
              mModel.defaultlocation!.isNotEmpty) {
            _addressNoteController.text = mModel.defaultlocation!;
          }
        });

        if (_selectedUserLocation != null && _miniMapController != null) {
          _miniMapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_selectedUserLocation!, 16.0),
          );
        }
      }
    } catch (e) {
      debugPrint("Error loading member profile: " + e.toString());
      if (mounted) {
        setState(() {
          _loggedInMemberName = "ไม่สามารถดึงข้อมูลได้";
          _loggedInMemberPhone = "ไม่ระบุเบอร์โทร";
        });
      }
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
      width: 70,
      height: 70,
      color: const Color(0xFFF3F8F4),
      child: const Icon(
        Icons.fastfood_rounded,
        color: Color.fromARGB(255, 217, 131, 11),
        size: 30,
      ),
    );
  }

  Widget _buildOrderItemCard(CartItem item, int index) {
    final bool isCurryDish = item.selectedCurries.isNotEmpty;

    String displayMenuName = isCurryDish
        ? "ข้าวราดแกง (" + item.selectedCurries.length.toString() + " อย่าง)"
        : (item.menu.menuName ?? "ไม่มีชื่อเมนู");

    if (item.isExtraPrice) {
      displayMenuName += " (พิเศษ)";
    }

    String? rawMenuImage = item.menu.menuImage;
    String finalMenuUrl = _getFinalImageUrl(rawMenuImage);

    int addonsSum = 0;
    for (var addon in item.selectedAddons) {
      addonsSum += addon.addonPrice?.toInt() ?? 0;
    }
    int curriesSum = 0;
    for (var curry in item.selectedCurries) {
      curriesSum += (curry.price ?? 0).toInt();
    }
    int singleItemTotal = item.unitPrice + addonsSum + curriesSum;
    int itemTotalPrice = singleItemTotal * item.quantity;

    Map<String, Map<String, dynamic>> groupedAddons = {};
    for (var addon in item.selectedAddons) {
      String name = addon.addonMenu?.addonName ?? '';
      int price = addon.addonPrice?.toInt() ?? 0;

      bool canIncreaseQty = false;
      try {
        final dynamic a = addon;
        final dynamic menu =
            a.addonMenu ?? a.menuAddon ?? a.addonGroup ?? a.menuAddonDetail;

        if (menu != null) {
          if (menu.canIncreaseQuantity != null) {
            canIncreaseQty = menu.canIncreaseQuantity == true;
          } else if (menu.allowQuantity != null) {
            canIncreaseQty = menu.allowQuantity == true;
          } else if (menu.isMultiple != null) {
            canIncreaseQty = menu.isMultiple == true;
          } else if (menu.isQuantity != null) {
            canIncreaseQty = menu.isQuantity == true;
          } else if (menu.maxQuantity != null) {
            canIncreaseQty = (menu.maxQuantity as num) > 1;
          } else if (menu.maxQty != null) {
            canIncreaseQty = (menu.maxQty as num) > 1;
          }
        }

        if (a.canIncreaseQuantity != null) {
          canIncreaseQty = a.canIncreaseQuantity == true;
        } else if (a.isMultiple != null) {
          canIncreaseQty = a.isMultiple == true;
        }
      } catch (_) {}

      if (name.isNotEmpty) {
        if (groupedAddons.containsKey(name)) {
          groupedAddons[name]!['qty'] =
              (groupedAddons[name]!['qty'] as int) + 1;
          groupedAddons[name]!['canIncreaseQty'] = true;
        } else {
          groupedAddons[name] = {
            'qty': 1,
            'unitPrice': price,
            'canIncreaseQty': canIncreaseQty,
          };
        }
      }
    }

    final bool hasAddons =
        groupedAddons.isNotEmpty || item.selectedCurries.isNotEmpty;

    // 🎯 กรองข้อความ "ราดแกง: [...]" ออกจากหมายเหตุ ไม่ให้แสดงซ้ำ
    String cleanNote = item.note.trim();
    cleanNote = cleanNote
        .replaceAll(RegExp(r'ราดแกง:\s*\[.*?\]\s*'), '')
        .trim();

    return InkWell(
      onTap: () async {
        Widget editPage;
        if (isCurryDish) {
          editPage = EditCurryOrderMember(
            cartItem: item,
            storeUsername: widget.storeUsername,
          );
        } else {
          editPage = EditOrderMember(cartItem: item);
        }

        final dynamic result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => editPage),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 17, 156, 70).withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, 5),
            ),
          ],
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
                        width: 70,
                        height: 70,
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          itemTotalPrice.toString() + " บาท",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00B300),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Divider(height: 1, color: Color(0xFFE0E0E0)),
                    const SizedBox(height: 8),

                    if (hasAddons) ...[
                      // 🎯 ถ้าเป็นข้าวราดแกง เปลี่ยนชื่อหัวข้อเป็น "รายการ"
                      Text(
                        isCurryDish ? "รายการ" : "รายการเพิ่มเติม",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 6),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 3.5,
                              decoration: BoxDecoration(
                                color: primaryGreen,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (var curry in item.selectedCurries)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              curry.menuName ?? "แกง",
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            "1 จำนวน",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromARGB(
                                                255,
                                                0,
                                                0,
                                                0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  for (var entry in groupedAddons.entries)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              entry.key,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          if (entry.value['canIncreaseQty'] ==
                                                  true ||
                                              (entry.value['qty'] as int) >
                                                  1) ...[
                                            const SizedBox(width: 8),
                                            RichText(
                                              text: TextSpan(
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color.fromARGB(
                                                    255,
                                                    217,
                                                    131,
                                                    11,
                                                  ),
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text:
                                                        (entry.value['qty']
                                                                as int)
                                                            .toString() +
                                                        " ",
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const TextSpan(text: "จำนวน"),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // 🎯 แสดงเฉพาะข้อความที่ไม่มีคำว่า "ราดแกง: [...]"
                    if (cleanNote.isNotEmpty) ...[
                      Text(
                        "หมายเหตุ: " + cleanNote,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "แก้ไข",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 217, 131, 11),
                          ),
                        ),
                        Text(
                          item.quantity.toString() + " จำนวน",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00B300),
                          ),
                        ),
                      ],
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
    for (var item in widget.storeItems) {
      int addonsSum = 0;
      for (var addon in item.selectedAddons) {
        addonsSum += addon.addonPrice?.toInt() ?? 0;
      }
      int curriesSum = 0;
      for (var curry in item.selectedCurries) {
        curriesSum += (curry.price ?? 0).toInt();
      }
      int actualMenuPrice = item.unitPrice + addonsSum + curriesSum;
      subtotalPrice += (actualMenuPrice * item.quantity);
    }

    int deliveryFee = 10;
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
                final dynamic result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LocationOrderMember(),
                  ),
                );

                if (result != null) {
                  if (result is Map<String, dynamic>) {
                    setState(() {
                      _selectedUserLocation = LatLng(
                        result['latitude'],
                        result['longitude'],
                      );
                      if (result['defaultlocation'] != null ||
                          result['addressDetail'] != null) {
                        _addressNoteController.text =
                            result['defaultlocation'] ??
                            result['addressDetail'] ??
                            "";
                      }
                    });
                  } else if (result is LatLng) {
                    setState(() {
                      _selectedUserLocation = result;
                    });
                  }

                  if (_selectedUserLocation != null &&
                      _miniMapController != null) {
                    _miniMapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(_selectedUserLocation!, 16.0),
                    );
                  }
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
                          zoom: _selectedUserLocation != null ? 16.0 : 15.5,
                        ),
                        onMapCreated: (controller) {
                          _miniMapController = controller;
                          if (_selectedUserLocation != null) {
                            _miniMapController!.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                _selectedUserLocation!,
                                16.0,
                              ),
                            );
                          }
                        },
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
                color: const Color.fromARGB(255, 0, 0, 0),
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
              "รายการอาหาร : " + widget.storeName,
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
                  subtotalPrice.toString() + " บาท",
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
                  deliveryFee.toString() + " บาท",
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
                  totalPrice.toString(),
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
                          "กรุณาแตะแผ่นแผนที่เพื่อระบุตำแหน่งจัดส่งสินค้าก่อน",
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
                    List<OrderDetailModel> orderItems = widget.storeItems.map((
                      cartItem,
                    ) {
                      final bool isCurryDishItem =
                          cartItem.selectedCurries.isNotEmpty;
                      String itemMenuName = isCurryDishItem
                          ? "ข้าวราดแกง (" +
                                cartItem.selectedCurries.length.toString() +
                                " อย่าง)"
                          : (cartItem.menu.menuName ?? "ไม่มีชื่อเมนู");
                      if (cartItem.isExtraPrice) {
                        itemMenuName += " (พิเศษ)";
                      }

                      int currentAddonsSum = 0;
                      Map<int, Map<String, dynamic>> groupedAddonsForApi = {};

                      for (var addon in cartItem.selectedAddons) {
                        int id = addon.addonDetailId ?? 0;
                        double price = (addon.addonPrice ?? 0).toDouble();
                        String addonName = addon.addonMenu?.addonName ?? '';
                        currentAddonsSum += price.toInt();

                        if (groupedAddonsForApi.containsKey(id)) {
                          groupedAddonsForApi[id]!['qty'] += 1;
                        } else {
                          groupedAddonsForApi[id] = {
                            'priceAtOrder': price,
                            'qty': 1,
                            'name': addonName,
                          };
                        }
                      }

                      int curriesSumItem = 0;
                      for (var curry in cartItem.selectedCurries) {
                        curriesSumItem += (curry.price ?? 0).toInt();
                      }

                      double actualSubTotal =
                          (cartItem.unitPrice +
                              currentAddonsSum +
                              curriesSumItem) *
                          cartItem.quantity.toDouble();

                      List<OrderDetailAddonModel> finalAddons =
                          groupedAddonsForApi.entries.map((e) {
                            return OrderDetailAddonModel(
                              addonDetailId: e.key,
                              addonNameAtOrder: e.value['name'] ?? '',
                              priceAtOrder: e.value['priceAtOrder'],
                              addonQty: e.value['qty'],
                            );
                          }).toList();

                      // 🎯 บันทึก note โดยตัด string ราดแกง ออก
                      String rawNote = cartItem.note.trim();
                      String finalCleanNote = rawNote
                          .replaceAll(RegExp(r'ราดแกง:\s*\[.*?\]\s*'), '')
                          .trim();

                      return OrderDetailModel(
                        menuId: cartItem.menu.menuId ?? 0,
                        menuNameAtOrder: itemMenuName,
                        priceAtOrder: cartItem.unitPrice.toDouble(),
                        qty: cartItem.quantity,
                        subTotal: actualSubTotal,
                        note: finalCleanNote,
                        addons: finalAddons,
                        orderDetailCurries: cartItem.selectedCurries.map((
                          curry,
                        ) {
                          return {
                            "menuId": curry.menuId ?? 0,
                            "priceAtOrder": (curry.price ?? 0.0).toDouble(),
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

                    await OrderService().memberConfirmOrder(finalOrder);

                    // เริ่มติดตามสถานะออเดอร์หลังสั่งซื้อสำเร็จ
                    // เพื่อให้ Notify ทำงานเมื่อสถานะเปลี่ยน เช่น ร้านรับออเดอร์ / ไรเดอร์รับงาน
                    OrderStatusMonitor().startMonitoring();

                    // แจ้งเตือนทันทีหลังสร้างออเดอร์สำเร็จ
                    InAppNotificationService.showTopBanner(
                      title: 'สั่งซื้อสำเร็จ ',
                      message: 'ระบบกำลังตามหาไรเดอร์ให้คุณ',
                      icon: Icons.check_circle_rounded,
                      color: Colors.blue,
                    );

                    if (!mounted) return;
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "สั่งซื้ออาหารสำเร็จ! ระบบกำลังตามหาไรเดอร์ให้คุณ",
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
                        content: Text(
                          "❌ สั่งซื้อไม่สำเร็จ: " + error.toString(),
                        ),
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
