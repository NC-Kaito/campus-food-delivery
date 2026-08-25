// features/member/view_confirm_order_member.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/member_model.dart';
import 'package:flutter_app/data/models/order_detail_model.dart';
import 'package:flutter_app/data/models/order_model.dart';
import 'package:flutter_app/data/services/member/member_service.dart';
import 'package:flutter_app/global_data.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio_package;

import 'package:flutter_app/features/member/member_review.dart';
import 'package:flutter_app/features/member/view_review.dart';

class ViewActiveOrderMember extends StatefulWidget {
  final OrderModel order;

  const ViewActiveOrderMember({super.key, required this.order});

  @override
  State<ViewActiveOrderMember> createState() => _ViewConfirmOrderMemberState();
}

class _ViewConfirmOrderMemberState extends State<ViewActiveOrderMember> {
  GoogleMapController? _miniMapController;

  String _loggedInMemberName = "กำลังโหลด...";
  String _loggedInMemberPhone = "กำลังโหลด...";

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
    return rawPath.startsWith('/') ? "$baseUrl$rawPath" : "$baseUrl/$rawPath";
  }

  Future<void> _loadCurrentMemberProfile() async {
    try {
      String username = GlobalData.usernameMember;
      MemberModel mModel = await memberService.getMemberByUsername(username);

      if (mounted) {
        setState(() {
          _loggedInMemberName =
              "${mModel.firstname ?? ''} ${mModel.lastname ?? ''}".trim();
          if (_loggedInMemberName.isEmpty) {
            _loggedInMemberName = mModel.username ?? "ไม่ระบุชื่อ";
          }
          _loggedInMemberPhone = mModel.phone ?? "ไม่ระบุเบอร์โทร";
        });
      }
    } catch (e) {
      debugPrint("Error loading member profile: $e");
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
    _miniMapController?.dispose();
    super.dispose();
  }

  // 🎯 ยิง API กดยืนยันความถูกต้องของอาหาร
  Future<void> _confirmSuccess() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.green)),
    );

    try {
      var response = await DioClient.dio.post(
        '/v1/order/confirmSuccess?orderId=${widget.order.orderId}',
      );
      Navigator.pop(context); // ปิด Loading

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("ยืนยันรับอาหารสำเร็จ! ขอบคุณที่ใช้บริการ"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(
          context,
          true,
        ); // เด้งกลับหน้า List พร้อมส่ง true ไปเพื่อบอกให้รีเฟรชหน้า
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("เกิดข้อผิดพลาด: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🎯 เปิดหน้าต่าง (Dialog) แจ้งปัญหาอาหารผิด
  Future<void> _showReportIssueDialog() async {
    File? selectedImage;
    final TextEditingController detailController = TextEditingController();
    bool isUploading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade700,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "แจ้งปัญหา",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "รายละเอียดปัญหา:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: detailController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "เช่น ได้รับข้าวหมูทอด แทนข้าวกะเพรา...",
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: Colors.red, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "อัปโหลดรูปภาพหลักฐาน:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final XFile? image = await ImagePicker().pickImage(
                          source: ImageSource.camera,
                          imageQuality: 80,
                        );
                        if (image != null) {
                          setStateDialog(
                            () => selectedImage = File(image.path),
                          );
                        }
                      },
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_rounded,
                                    color: Colors.grey.shade400,
                                    size: 36,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "แตะเพื่อถ่ายรูป",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.pop(context),
                  child: Text(
                    "ยกเลิก",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                          if (detailController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("กรุณาระบุรายละเอียด"),
                              ),
                            );
                            return;
                          }
                          if (selectedImage == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("กรุณาอัปโหลดรูปภาพหลักฐาน"),
                              ),
                            );
                            return;
                          }

                          setStateDialog(() => isUploading = true);

                          try {
                            String fileName = selectedImage!.path
                                .split('/')
                                .last;
                            dio_package.FormData formData =
                                dio_package.FormData.fromMap({
                                  'orderId': widget.order.orderId,
                                  'issueDetail': detailController.text.trim(),
                                  'issueImage':
                                      await dio_package.MultipartFile.fromFile(
                                        selectedImage!.path,
                                        filename: fileName,
                                      ),
                                });

                            var response = await DioClient.dio.post(
                              '/v1/order/reportIssue',
                              data: formData,
                            );
                            if (response.statusCode == 200) {
                              Navigator.pop(context); // ปิด dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "ส่งเรื่องแจ้งปัญหาเรียบร้อยแล้ว",
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pop(context, true); // เด้งกลับหน้า List
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("เกิดข้อผิดพลาด: $e"),
                                backgroundColor: Colors.red,
                              ),
                            );
                            setStateDialog(() => isUploading = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "ส่งหลักฐาน",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 🎯 เปิด Popup ยืนยันก่อนเข้าสู่หน้าแจ้งปัญหา
  Future<void> _confirmReportIssue() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.help_outline_rounded,
              color: Colors.orange.shade700,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              "ยืนยันการแจ้งปัญหา",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        content: const Text(
          "คุณต้องการแจ้งปัญหา 'อาหารไม่ถูกต้อง' ใช่หรือไม่?\n\n(คุณจำเป็นต้องถ่ายรูปอาหารที่ได้รับผิดเพื่อใช้เป็นหลักฐานในการตรวจสอบ)",
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "ยกเลิก",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "ใช่, ดำเนินการต่อ",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );

    // 🎯 ถ้าลูกค้ากด "ใช่" ค่อยเปิดฟอร์มสำหรับพิมพ์และอัปโหลดรูป
    if (confirm == true) {
      _showReportIssueDialog();
    }
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 65,
      height: 65,
      color: Colors.orange.shade50,
      child: const Icon(Icons.fastfood_rounded, color: Colors.orange, size: 30),
    );
  }

  Widget _buildOrderItemCard(OrderDetailModel item) {
    // 🎯 1. ดึงรายการกับข้าว
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

    final bool isCurryDish = rawCurries.isNotEmpty;
    String displayMenuName = item.menu?.menuName ?? "รายการเมนู";
    if (isCurryDish) {
      displayMenuName = "ข้าวราดแกง (${rawCurries.length} อย่าง)";
    }

    // 🎯 2. แกะรายชื่อ รูปกับข้าว และดึงราคา
    List<Map<String, dynamic>> curriesList = [];
    for (var e in rawCurries) {
      String name = '';
      String img = '';
      int price = 0;

      if (e is Map) {
        final menuMap = (e['menu'] is Map) ? e['menu'] as Map : e;
        name =
            (menuMap['menuname'] ??
                    menuMap['menuName'] ??
                    menuMap['name'] ??
                    '')
                .toString();
        img =
            (menuMap['imageurl'] ??
                    menuMap['imageUrl'] ??
                    menuMap['menuimage'] ??
                    menuMap['menuImage'] ??
                    menuMap['image'] ??
                    '')
                .toString();
        price = (e['priceAtOrder'] ?? e['priceatorder'] ?? 0).toInt();
      } else {
        try {
          name =
              ((e as dynamic).menu?.menuName ??
                      (e as dynamic).menu?.menuname ??
                      (e as dynamic).name ??
                      '')
                  .toString();
          img =
              ((e as dynamic).menu?.menuImage ??
                      (e as dynamic).menu?.imageurl ??
                      (e as dynamic).menu?.imageUrl ??
                      (e as dynamic).image ??
                      '')
                  .toString();
          price = ((e as dynamic).priceAtOrder ?? 0).toInt();
        } catch (_) {}
      }

      if (name.isNotEmpty) {
        curriesList.add({'name': name, 'image': img, 'price': price});
      }
    }

    // 🎯 3. ดึงรายการ Add-on
    List<dynamic> rawAddons = [];
    if (item.addons.isNotEmpty) {
      rawAddons = item.addons;
    } else {
      try {
        rawAddons = (item as dynamic).toJson()['addons'] ?? [];
      } catch (_) {}
    }

    // 🎯 4. จัดกลุ่ม Add-on (รวมจำนวนและราคา)
    Map<String, Map<String, dynamic>> groupedAddons = {};
    for (var addon in rawAddons) {
      String name = '';
      int price = 0;

      if (addon is Map) {
        name =
            addon['menuAddonDetail']?['addonMenu']?['addonName'] ??
            addon['addonMenu']?['addonName'] ??
            addon['name'] ??
            '';
        price =
            (addon['priceAtOrder'] ??
                    addon['menuAddonDetail']?['addonPrice'] ??
                    0)
                .toInt();
      } else {
        try {
          name = (addon as dynamic).menuAddonDetail?.addonMenu?.addonName ?? '';
          price =
              ((addon as dynamic).priceAtOrder ??
                      (addon as dynamic).menuAddonDetail?.addonPrice ??
                      0)
                  .toInt();
        } catch (_) {}
      }

      if (name.isNotEmpty) {
        if (groupedAddons.containsKey(name)) {
          groupedAddons[name]!['qty'] =
              (groupedAddons[name]!['qty'] as int) + 1;
        } else {
          groupedAddons[name] = {'qty': 1, 'unitPrice': price};
        }
      }
    }

    // 🎯 5. คำนวณราคาด้วย "วิธีย้อนกลับ" เพื่อให้ตัวเลขเป๊ะทุกกรณี
    int totalItemPrice = 0;
    int baseUnitNoAddonPrice = 0;

    int addonsSum = 0;
    for (var addon in groupedAddons.values) {
      addonsSum += (addon['unitPrice'] as int) * (addon['qty'] as int);
    }

    try {
      final jsonItem = (item as dynamic).toJson();
      var rawSubtotal = jsonItem['subtotal'] ?? jsonItem['subTotal'];

      if (rawSubtotal != null) {
        totalItemPrice = (rawSubtotal as num).toInt();
      }
    } catch (_) {}

    if (totalItemPrice > 0) {
      int unitTotal = totalItemPrice ~/ (item.qty > 0 ? item.qty : 1);
      baseUnitNoAddonPrice = unitTotal - addonsSum;
      if (baseUnitNoAddonPrice < 0) baseUnitNoAddonPrice = 0;
    } else {
      int baseMenuPrice = item.menu?.price?.toInt() ?? 0;
      if (baseMenuPrice == 0) {
        try {
          final jsonItem = (item as dynamic).toJson();
          baseMenuPrice = (jsonItem['menu']?['price'] ?? 0).toInt();
        } catch (_) {}
      }

      int curriesSum = 0;
      for (var curry in curriesList) {
        curriesSum += curry['price'] as int;
      }

      baseUnitNoAddonPrice = baseMenuPrice + curriesSum;
      totalItemPrice = (baseUnitNoAddonPrice + addonsSum) * item.qty;
    }

    String rawMenuUrl = item.menu?.menuImage ?? '';
    if (rawMenuUrl.isEmpty && curriesList.isNotEmpty) {
      rawMenuUrl = curriesList.first['image'] as String;
    }
    final String finalMenuUrl = _getFinalImageUrl(rawMenuUrl);

    return Container(
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
              child: finalMenuUrl.isNotEmpty
                  ? Image.network(
                      Uri.encodeFull(finalMenuUrl),
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
                  Text(
                    displayMenuName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "ราคา $baseUnitNoAddonPrice บาท",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  if (curriesList.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6.0,
                      runSpacing: 6.0,
                      children: curriesList.map((curry) {
                        String rawCurryImage = curry['image'] as String;
                        String finalCurryUrl = _getFinalImageUrl(rawCurryImage);
                        String curryName = curry['name'] as String;

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
                                curryName,
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

                  if (groupedAddons.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6.0,
                      runSpacing: 6.0,
                      children: groupedAddons.entries.map((entry) {
                        String name = entry.key;
                        int qty = entry.value['qty'] as int;
                        int unitPrice = entry.value['unitPrice'] as int;

                        String displayText = name;
                        if (qty > 1) {
                          int totalAddonPrice = unitPrice * qty;
                          displayText += " x$qty";
                          if (totalAddonPrice > 0)
                            displayText += " (+฿$totalAddonPrice)";
                        } else {
                          if (unitPrice > 0) displayText += " (+฿$unitPrice)";
                        }

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
                                displayText,
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

                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "จำนวน ${item.qty}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "รวม $totalItemPrice บาท",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineDot(
    String label,
    bool isCompleted,
    bool isLineCompleted, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  color: isFirst
                      ? Colors.transparent
                      : (isCompleted
                            ? const Color(0xFF64F02D)
                            : Colors.grey.shade300),
                ),
              ),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF64F02D)
                      : Colors.grey.shade300,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted
                        ? const Color(0xFF2E7D32)
                        : Colors.grey.shade400,
                    width: 1,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 4,
                  color: isLast
                      ? Colors.transparent
                      : (isLineCompleted
                            ? const Color(0xFF64F02D)
                            : Colors.grey.shade300),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: isCompleted ? Colors.black87 : Colors.grey.shade500,
              fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double deliveryFee = widget.order.deliveryFee;
    double totalPrice = widget.order.totalPrice;
    double subtotalPrice = totalPrice - deliveryFee;

    LatLng deliveryLocation = LatLng(
      widget.order.latitude,
      widget.order.longitude,
    );

    // 🎯 อัปเดตเงื่อนไข Timeline ให้ครอบคลุมสถานะ
    String status = (widget.order.orderStatus ?? "").toLowerCase();
    int currentStep = 1;

    if (status.contains("waitingrestaurant") ||
        status.contains("cooking") ||
        status.contains("preparing")) {
      currentStep = 2;
    } else if (status.contains("rideraccepted") ||
        status.contains("riderarrived") ||
        status.contains("goingtorestaurant")) {
      currentStep = 3;
    } else if (status.contains("delivery") ||
        status.contains("delivering") ||
        status.contains("ontheway") ||
        status.contains("pickedup")) {
      currentStep = 4;
    } else if (status.contains("delivered") ||
        status.contains("success") ||
        status.contains("completed") ||
        status.contains("reviewsuccess")) {
      currentStep = 5; // ถึงที่หมายแล้ว
    }

    // 🎯 ดึงสถานะที่แท้จริงแบบเดียวกับการ์ดด้านนอก
    final bool isCompleted =
        status == 'success' ||
        status == 'completed' ||
        status == 'reviewsuccess';
    final bool isReviewed = status == 'reviewsuccess';

    // ⏱️ เช็กเวลา 1 ชั่วโมง สำหรับการแจ้งปัญหา (นำระบบแกะเวลาจากหน้า List มาใช้)
    bool isWithinOneHour = true;
    try {
      dynamic rawSuccessTime;
      // พยายามหาชื่อตัวแปรที่ตรงกับใน OrderModel (ป้องกัน NoSuchMethodError)
      try {
        rawSuccessTime = (widget.order as dynamic).successtime;
      } catch (_) {
        try {
          rawSuccessTime = (widget.order as dynamic).successTime;
        } catch (_) {}
      }

      final dynamic rawOrderDate = widget.order.orderdate;

      if (rawSuccessTime != null && rawOrderDate != null) {
        DateTime orderDate;
        if (rawOrderDate is DateTime) {
          orderDate = rawOrderDate.toLocal();
        } else {
          orderDate = DateTime.parse(rawOrderDate.toString()).toLocal();
        }

        int hour = 0;
        int minute = 0;

        if (rawSuccessTime is List) {
          hour = int.tryParse(rawSuccessTime[0].toString()) ?? 0;
          if (rawSuccessTime.length > 1) {
            minute = int.tryParse(rawSuccessTime[1].toString()) ?? 0;
          }
        } else {
          String timeStr = rawSuccessTime
              .toString()
              .replaceAll(RegExp(r'[\[\]]'), '')
              .trim();
          List<String> timeParts = timeStr.contains(':')
              ? timeStr.split(':')
              : timeStr.split(',');
          if (timeParts.isNotEmpty) {
            hour = int.tryParse(timeParts[0].trim()) ?? 0;
          }
          if (timeParts.length > 1) {
            minute = int.tryParse(timeParts[1].trim()) ?? 0;
          }
        }

        DateTime successDateTime = DateTime(
          orderDate.year,
          orderDate.month,
          orderDate.day,
          hour,
          minute,
        );

        // 🎯 ตัดวินาทีทิ้ง ป้องกันบั๊กเวลาสั่ง 10:00:55 เทียบกับเวลาส่ง 10:00:00
        DateTime strippedOrderDate = DateTime(
          orderDate.year,
          orderDate.month,
          orderDate.day,
          orderDate.hour,
          orderDate.minute,
        );

        if (successDateTime.isBefore(strippedOrderDate)) {
          successDateTime = successDateTime.add(const Duration(days: 1));
        }

        if (DateTime.now().difference(successDateTime).inMinutes >= 60) {
          isWithinOneHour = false;
        }
      } else if (isCompleted) {
        isWithinOneHour = false;
      }
    } catch (e) {
      debugPrint("Error parsing success time in view: $e");
      isWithinOneHour = false;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryGreen),
        title: const Text(
          "รายละเอียดคำสั่งซื้อ",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    const TextSpan(
                      text: "เลขที่ออเดอร์ : ",
                      style: TextStyle(color: Colors.black87),
                    ),
                    TextSpan(
                      text:
                          "K${widget.order.orderId?.toString().padLeft(6, '0') ?? '000000'}",
                      style: TextStyle(color: primaryGreen),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "จัดส่งโดย",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.order.rider != null)
              Row(
                children: [
                  const Icon(
                    Icons.delivery_dining,
                    size: 40,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ชื่อ : ${widget.order.rider!.firstName ?? ''} ${widget.order.rider!.lastName ?? ''}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "เบอร์โทรศัพท์ : ${widget.order.rider!.phone ?? '-'}",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  Icon(Icons.hourglass_empty, size: 30, color: primaryGreen),
                  const SizedBox(width: 12),
                  Text(
                    "สถานะ: กำลังรอผู้จัดส่งรับงาน...",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 16),

            const Text(
              "สถานะคำสั่งซื้อ",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),

            if (status.contains("cancel"))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cancel_rounded,
                          color: Colors.red.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "คำสั่งซื้อนี้ถูกยกเลิกแล้ว",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "สาเหตุ: ${widget.order.cancelDetail ?? 'ไม่มีผู้จัดส่งรับงานภายในเวลาที่กำหนด'}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              )
            else if (status.contains("issue_reported"))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.support_agent_rounded,
                      color: Colors.orange.shade700,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "มีการแจ้งปัญหาออเดอร์นี้\nระบบกำลังดำเนินการตรวจสอบ",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFBFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimelineDot(
                      "ค้นหาผู้จัดส่ง",
                      currentStep >= 1,
                      currentStep >= 2,
                      isFirst: true,
                    ),
                    _buildTimelineDot(
                      "ร้านรับออเดอร์",
                      currentStep >= 2,
                      currentStep >= 3,
                    ),
                    _buildTimelineDot(
                      "ผู้จัดส่งไปรับ",
                      currentStep >= 3,
                      currentStep >= 4,
                    ),
                    _buildTimelineDot(
                      "กำลังจัดส่ง",
                      currentStep >= 4,
                      currentStep >= 5,
                    ),
                    _buildTimelineDot(
                      "จัดส่งสำเร็จ",
                      currentStep >= 5,
                      currentStep >= 6,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            const Text(
              "ข้อมูลผู้สั่งซื้อ",
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
                            "ชื่อผู้รับ",
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
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: deliveryLocation,
                    zoom: 16.0,
                  ),
                  onMapCreated: (controller) => _miniMapController = controller,
                  zoomControlsEnabled: false,
                  zoomGesturesEnabled: false,
                  scrollGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  markers: {
                    Marker(
                      markerId: const MarkerId('history_delivery_pos'),
                      position: deliveryLocation,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                    ),
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.order.addressDetail.isNotEmpty) ...[
              Text(
                "จุดสังเกต / รายละเอียดที่อยู่:",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.order.addressDetail,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 16),

            const Text(
              "รายการอาหาร",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.order.items.length,
              itemBuilder: (context, index) {
                return _buildOrderItemCard(widget.order.items[index]);
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
                  "${subtotalPrice.toStringAsFixed(0)} บาท",
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
                  "${deliveryFee.toStringAsFixed(0)} บาท",
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "ยอดรวมทั้งสิ้น",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "${totalPrice.toStringAsFixed(0)} บาท",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),

      // 🎯 แท็บเครื่องมือด้านล่าง อัปเดตใหม่ให้โชว์ปุ่มรีวิวและแจ้งปัญหาแบบแยกเงื่อนไข
      bottomNavigationBar: isCompleted
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ⭐ 1. แสดงปุ่ม รีวิวคำสั่งซื้อ หรือ ดูรีวิว (เช็กแค่สถานะรีวิว)
                    if (!isReviewed)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MemberReview(order: widget.order),
                              ),
                            ).then((result) {
                              if (result == true) Navigator.pop(context, true);
                            });
                          },
                          icon: const Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "รีวิวคำสั่งซื้อ",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ViewReview(order: widget.order),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.rate_review_rounded,
                            color: Colors.blue,
                          ),
                          label: const Text(
                            "ดูการรีวิวของคุณ",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Colors.blue,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.blue.shade50,
                          ),
                        ),
                      ),

                    // 🚨 2. ปุ่มแจ้งปัญหา (เช็กแค่ว่าอยู่ในเวลา 1 ชั่วโมงหรือไม่ โดยไม่สนว่ารีวิวไปหรือยัง)
                    if (isWithinOneHour) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _confirmReportIssue,
                          icon: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red,
                          ),
                          label: const Text(
                            "แจ้งปัญหาอาหารผิด",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Colors.red,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : null, // ถ้าออเดอร์ยังไม่เสร็จ ก็ไม่ต้องโชว์แท็บด้านล่าง
    );
  }
}
