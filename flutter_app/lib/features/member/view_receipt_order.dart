// features/member/view_receipt_order.dart
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/order_model.dart';
import 'package:gal/gal.dart';

class ViewReceiptOrder extends StatefulWidget {
  final OrderModel order;
  final String memberName;
  final String memberPhone;

  const ViewReceiptOrder({
    super.key,
    required this.order,
    required this.memberName,
    required this.memberPhone,
  });

  @override
  State<ViewReceiptOrder> createState() => _ViewReceiptOrderState();
}

class _ViewReceiptOrderState extends State<ViewReceiptOrder> {
  final GlobalKey _receiptKey = GlobalKey();
  final Color _appBackgroundColor = const Color(0xFFF8FAFC);

  String _formatThaiDate(dynamic rawDate) {
    if (rawDate == null) return "-";
    DateTime d;
    if (rawDate is DateTime) {
      d = rawDate.toLocal();
    } else {
      d = DateTime.tryParse(rawDate.toString())?.toLocal() ?? DateTime.now();
    }
    final months = [
      "มกราคม",
      "กุมภาพันธ์",
      "มีนาคม",
      "เมษายน",
      "พฤษภาคม",
      "มิถุนายน",
      "กรกฎาคม",
      "สิงหาคม",
      "กันยายน",
      "ตุลาคม",
      "พฤศจิกายน",
      "ธันวาคม",
    ];
    final year = d.year + 543;
    return "${d.day} ${months[d.month - 1]} $year - ${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')} น.";
  }

  Future<void> _saveReceiptToGallery() async {
    try {
      RenderRepaintBoundary boundary =
          _receiptKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        await Gal.putImageBytes(byteData.buffer.asUint8List());

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "บันทึกใบเสร็จลงในอัลบั้มรูปภาพเรียบร้อยแล้วครับ 📸",
              style: TextStyle(fontFamily: 'Kanit', fontSize: 14),
            ),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "ไม่สามารถบันทึกได้ โปรดให้สิทธิ์แอปเข้าถึงรูปภาพนะครับ ($e)",
            style: const TextStyle(fontFamily: 'Kanit', fontSize: 14),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      );
    }
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double deliveryFee = widget.order.deliveryFee;
    double totalPrice = widget.order.totalPrice;
    double subtotalPrice = totalPrice - deliveryFee;

    int totalItemsCount = widget.order.items.fold(
      0,
      (sum, item) => sum + item.qty,
    );

    return Scaffold(
      backgroundColor: _appBackgroundColor,
      appBar: AppBar(
        backgroundColor: _appBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text(
          "ใบเสร็จคำสั่งซื้อ",
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            RepaintBoundary(
              key: _receiptKey,
              child: Container(
                color: _appBackgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Header Section ---
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFECE5),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFFF7A45,
                                        ).withOpacity(0.2),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 200,
                                  height: 200,
                                  decoration: const BoxDecoration(
                                    color: ui.Color.fromARGB(
                                      255,
                                      255,
                                      255,
                                      255,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Image.asset(
                                        'assets/images/campusFoodDelivery_logo.png',
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.receipt_long_rounded,
                                                color: ui.Color.fromARGB(
                                                  255,
                                                  168,
                                                  61,
                                                  61,
                                                ),
                                                size: 22,
                                              );
                                            },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "ใบเสร็จคำสั่งซื้อ",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                "ออเดอร์ K${widget.order.orderId?.toString().padLeft(6, '0')}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "วันที่ ${_formatThaiDate(widget.order.orderdate)}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 14),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: Column(
                                children: [
                                  _buildInfoRow(
                                    icon: Icons.storefront_rounded,
                                    iconColor: const Color(0xFFFF7A45),
                                    iconBgColor: const Color(0xFFFFECE5),
                                    title: "ร้านค้า",
                                    value: "Campus Food",
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: Divider(
                                      color: Color(0xFFE2E8F0),
                                      height: 1,
                                      thickness: 1,
                                    ),
                                  ),
                                  _buildInfoRow(
                                    icon: Icons.person_rounded,
                                    iconColor: const Color(0xFF3B82F6),
                                    iconBgColor: const Color(0xFFEFF6FF),
                                    title: "ผู้สั่งซื้อ",
                                    value: widget.memberName,
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: Divider(
                                      color: Color(0xFFE2E8F0),
                                      height: 1,
                                      thickness: 1,
                                    ),
                                  ),
                                  _buildInfoRow(
                                    icon: Icons.electric_moped_rounded,
                                    iconColor: const Color(0xFF10B981),
                                    iconBgColor: const Color(0xFFECFDF5),
                                    title: "ผู้จัดส่ง",
                                    value:
                                        "${widget.order.rider?.firstName ?? '-'} ${widget.order.rider?.lastName ?? ''}"
                                            .trim(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      _TicketDivider(backgroundColor: _appBackgroundColor),

                      // --- Order Items Section ---
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "รายการอาหาร",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "$totalItemsCount รายการ",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.order.items.map((item) {
                            List<dynamic> rawCurries = [];
                            if (item.orderDetailCurries != null &&
                                item.orderDetailCurries!.isNotEmpty) {
                              rawCurries = item.orderDetailCurries!;
                            } else {
                              try {
                                final jsonItem = (item as dynamic).toJson();
                                rawCurries =
                                    jsonItem['orderDetailCurries'] ??
                                    jsonItem['orderdetailcurries'] ??
                                    [];
                              } catch (_) {}
                            }

                            String displayMenuName =
                                item.menu?.menuName ?? "รายการอาหาร";
                            if (rawCurries.isNotEmpty) {
                              displayMenuName =
                                  "ข้าวราดแกง (${rawCurries.length} อย่าง)";
                            }

                            List<Map<String, dynamic>> curriesList = [];
                            for (var e in rawCurries) {
                              String name = '';
                              if (e is Map) {
                                final menuMap = (e['menu'] is Map)
                                    ? e['menu'] as Map
                                    : e;
                                name =
                                    (menuMap['menuname'] ??
                                            menuMap['menuName'] ??
                                            menuMap['name'] ??
                                            '')
                                        .toString();
                              } else {
                                try {
                                  name =
                                      ((e as dynamic).menu?.menuName ??
                                              (e as dynamic).name ??
                                              '')
                                          .toString();
                                } catch (_) {}
                              }
                              if (name.isNotEmpty) {
                                curriesList.add({'name': name, 'qty': 1});
                              }
                            }

                            List<dynamic> rawAddons = [];
                            if (item.addons.isNotEmpty) {
                              rawAddons = item.addons;
                            } else {
                              try {
                                rawAddons =
                                    (item as dynamic).toJson()['addons'] ?? [];
                              } catch (_) {}
                            }

                            Map<String, Map<String, dynamic>> groupedAddons =
                                {};
                            for (var addon in rawAddons) {
                              String name = '';
                              int qty = 1;
                              bool canIncreaseQty = false;

                              if (addon is Map) {
                                name =
                                    addon['menuAddonDetail']?['addonMenu']?['addonName'] ??
                                    addon['addonMenu']?['addonName'] ??
                                    addon['name'] ??
                                    '';
                                qty =
                                    (addon['addonQty'] ??
                                            addon['addon_qty'] ??
                                            1)
                                        .toInt();

                                final dynamic menu =
                                    addon['menuAddonDetail']?['addonMenu'] ??
                                    addon['addonMenu'] ??
                                    addon['menuAddon'];

                                if (menu != null) {
                                  if (menu['canIncreaseQuantity'] != null) {
                                    canIncreaseQty =
                                        menu['canIncreaseQuantity'] == true;
                                  } else if (menu['allowQuantity'] != null) {
                                    canIncreaseQty =
                                        menu['allowQuantity'] == true;
                                  } else if (menu['isMultiple'] != null) {
                                    canIncreaseQty = menu['isMultiple'] == true;
                                  } else if (menu['isQuantity'] != null) {
                                    canIncreaseQty = menu['isQuantity'] == true;
                                  } else if (menu['maxQuantity'] != null) {
                                    canIncreaseQty =
                                        (menu['maxQuantity'] as num) > 1;
                                  } else if (menu['maxQty'] != null) {
                                    canIncreaseQty =
                                        (menu['maxQty'] as num) > 1;
                                  } else if (menu['addonType'] != null) {
                                    final typeStr = menu['addonType']
                                        .toString()
                                        .toLowerCase();
                                    canIncreaseQty =
                                        !typeStr.contains('radio') &&
                                        !typeStr.contains('single');
                                  }
                                }
                              } else {
                                try {
                                  name =
                                      (addon as dynamic)
                                          .menuAddonDetail
                                          ?.addonMenu
                                          ?.addonName ??
                                      '';
                                  qty = ((addon as dynamic).addonQty ?? 1)
                                      .toInt();

                                  final dynamic menu =
                                      (addon as dynamic)
                                          .menuAddonDetail
                                          ?.addonMenu ??
                                      (addon as dynamic).addonMenu;

                                  if (menu != null) {
                                    if (menu.canIncreaseQuantity != null) {
                                      canIncreaseQty =
                                          menu.canIncreaseQuantity == true;
                                    } else if (menu.allowQuantity != null) {
                                      canIncreaseQty =
                                          menu.allowQuantity == true;
                                    } else if (menu.isMultiple != null) {
                                      canIncreaseQty = menu.isMultiple == true;
                                    } else if (menu.maxQuantity != null) {
                                      canIncreaseQty =
                                          (menu.maxQuantity as num) > 1;
                                    }
                                  }
                                } catch (_) {}
                              }

                              if (name.isNotEmpty) {
                                if (groupedAddons.containsKey(name)) {
                                  groupedAddons[name]!['qty'] =
                                      (groupedAddons[name]!['qty'] as int) +
                                      qty;
                                  groupedAddons[name]!['canIncreaseQty'] = true;
                                } else {
                                  groupedAddons[name] = {
                                    'qty': qty,
                                    'canIncreaseQty': canIncreaseQty,
                                  };
                                }
                              }
                            }

                            List<Map<String, dynamic>> addonLines = [];
                            for (var curry in curriesList) {
                              addonLines.add({
                                'name': curry['name'],
                                'qty': curry['qty'],
                                'showQty': false,
                              });
                            }
                            for (var entry in groupedAddons.entries) {
                              final int q = entry.value['qty'] as int;
                              final bool canInc =
                                  entry.value['canIncreaseQty'] == true;
                              // 🎯 ให้แสดงจำนวนเหมือนหน้าออเดอร์ (ถ้าเพิ่มจำนวนได้ หรือมีจำนวนมากกว่า 1)
                              final bool show = canInc || q > 1;
                              addonLines.add({
                                'name': entry.key,
                                'qty': q,
                                'showQty': show,
                              });
                            }

                            int totalItemPrice = 0;
                            try {
                              final jsonItem = (item as dynamic).toJson();
                              var rawSubtotal =
                                  jsonItem['subtotal'] ?? jsonItem['subTotal'];
                              if (rawSubtotal != null) {
                                totalItemPrice = (rawSubtotal as num).toInt();
                              }
                            } catch (_) {}

                            if (totalItemPrice == 0) {
                              totalItemPrice =
                                  (item.menu?.price?.toInt() ?? 0) * item.qty;
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12.0),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                                vertical: 6.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          displayMenuName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (addonLines.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    const Text(
                                      "รายการเพิ่มเติม",
                                      style: TextStyle(
                                        color: Color(0xFF3B82F6),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          left: BorderSide(
                                            color: Color(0xFF10B981),
                                            width: 3,
                                          ),
                                        ),
                                      ),
                                      padding: const EdgeInsets.only(
                                        left: 10,
                                        top: 2,
                                        bottom: 2,
                                      ),
                                      child: Column(
                                        children: addonLines
                                            .map(
                                              (line) => Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 4.0,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        line['name'],
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          color: Color(
                                                            0xFF475569,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                    if (line['showQty'] == true)
                                                      Text(
                                                        "${line['qty']} จำนวน",
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Color(
                                                            0xFF0F172A,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${item.qty} จำนวน",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: Color(0xFFFF7A45),
                                        ),
                                      ),
                                      Text(
                                        "$totalItemPrice บาท",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          color: Color(0xFFFF7A45),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  const Divider(
                                    color: Color(0xFFE2E8F0),
                                    height: 1,
                                    thickness: 1,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const _TicketDivider(backgroundColor: Colors.transparent),

                      // --- Summary Section ---
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "ยอดรวมอาหาร",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "${subtotalPrice.toInt()} บาท",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
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
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "${deliveryFee.toInt()} บาท",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Divider(
                                color: Color(0xFFE2E8F0),
                                height: 1,
                                thickness: 1,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  "ยอดชำระสุทธิ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  "${totalPrice.toInt()} บาท",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                    color: Color(0xFFFF7A45),
                                    height: 1,
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
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveReceiptToGallery,
                icon: const Icon(
                  Icons.file_download_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  "บันทึกใบเสร็จเป็นรูปภาพ",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A45),
                  elevation: 6,
                  shadowColor: const Color(0xFFFF7A45).withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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

class _TicketDivider extends StatelessWidget {
  final Color backgroundColor;

  const _TicketDivider({required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 28,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final boxWidth = constraints.constrainWidth();
                const dashWidth = 6.0;
                const dashHeight = 1.5;
                final dashCount = (boxWidth / (2 * dashWidth)).floor();
                return Flex(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  direction: Axis.horizontal,
                  children: List.generate(dashCount, (_) {
                    return const SizedBox(
                      width: dashWidth,
                      height: dashHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Color(0xFFCBD5E1)),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ),
        Container(
          width: 14,
          height: 28,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              bottomLeft: Radius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}
