// features/rider/list_waiting_pickup_order.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/services/rider/rider_service.dart';
import 'package:flutter_app/data/services/order_service.dart';
import 'package:flutter_app/data/models/order_model.dart';
import 'package:flutter_app/features/rider/navbar_rider.dart';
import 'package:flutter_app/global_data.dart';

import 'package:flutter_app/features/rider/account_menagement_rider.dart';

import 'package:flutter_app/features/rider/view_waiting_pickup_order.dart'
    as waiting;
import 'package:flutter_app/features/rider/view_delivery_detail.dart'
    as delivery;
import 'package:flutter_app/features/rider/view_review_rider.dart' as review;

class ListWaitingPickupOrder extends StatefulWidget {
  const ListWaitingPickupOrder({super.key});

  @override
  State<ListWaitingPickupOrder> createState() => _ListWaitingPickupOrderState();
}

class _ListWaitingPickupOrderState extends State<ListWaitingPickupOrder>
    with SingleTickerProviderStateMixin {
  final RiderService _riderService = RiderService();
  final OrderService _orderService = OrderService();

  bool _isReady = false;
  bool _isUpdating = false;
  bool _isLoadingOrders = false;
  bool _isLoadingStatus = true;
  int _selectedTabIndex = 0;

  int _activeOrderCount = 0;

  late final TabController _tabController;
  List _realOrders = [];
  Timer? _autoRefreshTimer;

  final Color _primaryOrange = const Color(0xFF00B300);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchRiderStatus();
    _fetchActiveOrderBadgeCount();
  }

  Future _fetchActiveOrderBadgeCount() async {
    try {
      String studentId = GlobalData.usernameRider;

      final waitingOrders = await _orderService.getWaitingOrders();
      final activeOrders = await _orderService.getActiveOrders(studentId);

      if (mounted) {
        setState(() {
          _activeOrderCount = waitingOrders.length + activeOrders.length;
        });
      }
    } catch (e) {
      debugPrint("เกิดข้อผิดพลาดในการนับออเดอร์แจ้งเตือน: " + e.toString());
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isReady && !_isLoadingOrders && !_isUpdating) {
        _fetchOrdersBackground();
        _fetchActiveOrderBadgeCount();
      }
    });
  }

  Future _fetchOrdersBackground() async {
    if (!_isReady) return;
    try {
      List orders = [];
      String studentId = GlobalData.usernameRider;

      if (_selectedTabIndex == 0) {
        orders = await _orderService.getWaitingOrders();
      } else if (_selectedTabIndex == 1) {
        orders = await _orderService.getActiveOrders(studentId);
      } else if (_selectedTabIndex == 2) {
        // 🎯 ดึงออเดอร์สำเร็จทั้งหมดมาก่อน
        List rawOrders = await _orderService.getSuccessOrdersByRider(studentId);
        // 🎯 กรองข้อมูลแบบรัดกุม 100% (Whitelist)
        orders = rawOrders.where((o) {
          String status = '';
          try {
            // แปลงเป็น Model ก่อนเพื่อให้ชัวร์ว่าดึง Field มาถูกเป๊ะๆ
            final model = OrderModel.fromJson(o);
            status = (model.orderStatus ?? '').trim().toLowerCase();
          } catch (e) {
            // สำรองเผื่อข้อมูลมาเป็น Map ตรงๆ
            if (o is Map) {
              status = (o['orderStatus'] ?? o['orderstatus'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase();
            }
          }
          // 🎯 คัดเฉพาะสถานะที่เกี่ยวกับการ "จัดส่งสำเร็จ" แต่ "ยังไม่รีวิว" เท่านั้นครับ
          return status == 'success' ||
              status == 'completed' ||
              status == 'delivered';
        }).toList();
      } else if (_selectedTabIndex == 3) {
        orders = await _orderService.getReviewSuccessOrders(studentId);
      } else if (_selectedTabIndex == 4) {
        try {
          orders = await _orderService.getCancelOrdersByRider(studentId);
        } catch (e) {
          debugPrint("โหลดรายการที่ยกเลิกของไรเดอร์ไม่สำเร็จ: " + e.toString());
          orders = [];
        }
      }

      if (mounted) {
        setState(() {
          _realOrders = orders;
        });
      }
    } catch (e) {
      debugPrint("Auto-refresh orders failure: " + e.toString());
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future _fetchRiderStatus() async {
    try {
      String studentId = GlobalData.usernameRider;
      final riderData = await _riderService.getRiderByStudentId(studentId);

      if (mounted) {
        setState(() {
          _isReady = riderData.isActive ?? false;
          _isLoadingStatus = false;
        });

        if (_isReady) {
          _fetchOrders();
          _startAutoRefresh();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStatus = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🚨 โหลดสถานะไรเดอร์ล้มเหลว: " + e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future _fetchOrders() async {
    if (!_isReady) return;

    setState(() {
      _isLoadingOrders = true;
    });

    try {
      List orders = [];
      String studentId = GlobalData.usernameRider;

      if (_selectedTabIndex == 0) {
        orders = await _orderService.getWaitingOrders();
      } else if (_selectedTabIndex == 1) {
        orders = await _orderService.getActiveOrders(studentId);
      } else if (_selectedTabIndex == 2) {
        // 🎯 ดึงออเดอร์สำเร็จทั้งหมดมาก่อน
        List rawOrders = await _orderService.getSuccessOrdersByRider(studentId);
        // 🎯 กรองข้อมูลแบบรัดกุม 100% (Whitelist) เหมือนกันกับด้านบนครับ
        orders = rawOrders.where((o) {
          String status = '';
          try {
            final model = OrderModel.fromJson(o);
            status = (model.orderStatus ?? '').trim().toLowerCase();
          } catch (e) {
            if (o is Map) {
              status = (o['orderStatus'] ?? o['orderstatus'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase();
            }
          }
          // 🎯 แสดงเฉพาะรายการที่รอรีวิว หรือเพิ่งส่งสำเร็จหมาดๆ
          return status == 'success' ||
              status == 'completed' ||
              status == 'delivered';
        }).toList();
      } else if (_selectedTabIndex == 3) {
        orders = await _orderService.getReviewSuccessOrders(studentId);
      } else if (_selectedTabIndex == 4) {
        try {
          orders = await _orderService.getCancelOrdersByRider(studentId);
        } catch (e) {
          debugPrint("โหลดรายการที่ยกเลิกของไรเดอร์ไม่สำเร็จ: " + e.toString());
          orders = [];
        }
      }

      if (mounted) {
        setState(() {
          _realOrders = orders;
          _isLoadingOrders = false;
        });
      }

      _fetchActiveOrderBadgeCount();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingOrders = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🚨 โหลดรายการออเดอร์ล้มเหลว: " + e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future _toggleActiveStatus(bool newStatus) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      String studentId = GlobalData.usernameRider;
      await _riderService.updateIsActive(studentId, newStatus);

      if (mounted) {
        setState(() {
          _isReady = newStatus;
          _isUpdating = false;

          if (!newStatus) {
            _realOrders.clear();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? "เปิดระบบพร้อมรับงานแล้ว 🏍️"
                  : "ปิดระบบพักการทำงานแล้ว 💤",
            ),
            duration: const Duration(seconds: 1),
          ),
        );

        if (newStatus) {
          _fetchOrders();
          _startAutoRefresh();
        } else {
          _autoRefreshTimer?.cancel();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🚨 เปลี่ยนสถานะไม่สำเร็จ: " + e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future _openOrderDetail(
    OrderModel orderModel,
    dynamic rawOrder, {
    bool isReviewTab = false,
  }) async {
    if (_selectedTabIndex == 0) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Colors.orange),
          ),
        );

        await _orderService.lockOrder(
          orderModel.orderId ?? 0,
          GlobalData.usernameRider,
        );

        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) Navigator.pop(context);

        if (e.toString() == "LOCKED") {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("มีผู้จัดส่งท่านอื่นกำลังพิจารณาออเดอร์นี้อยู่"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
          return;
        }
      }
    }

    Widget targetPage;
    if (_selectedTabIndex == 0) {
      targetPage = waiting.ViewWaitingPickupOrder(orderModel: orderModel);
    } else if (isReviewTab) {
      targetPage = review.ViewReviewRider(orderModel: orderModel);
    } else {
      targetPage = delivery.ViewDeliveryDetail(orderModel: orderModel);
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    );

    if (_selectedTabIndex == 0) {
      await _orderService.unlockOrder(
        orderModel.orderId ?? 0,
        GlobalData.usernameRider,
      );
    }

    if (result == true ||
        _selectedTabIndex == 1 ||
        _selectedTabIndex == 2 ||
        _selectedTabIndex == 4) {
      _fetchOrders();
    }
  }

  String _getFinalProfileImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;

    final String baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/')
        ? baseUrl + rawPath
        : baseUrl + '/' + rawPath;
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF64FF20),
        indicatorWeight: 3,
        labelColor: const Color(0xFF2E7D32),
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        labelPadding: const EdgeInsets.symmetric(horizontal: 2.0),
        onTap: (index) {
          if (_selectedTabIndex == index) return;
          setState(() => _selectedTabIndex = index);
          _fetchOrders();
        },
        tabs: const [
          Tab(text: "งานใหม่"),
          Tab(text: "รายการจัดส่ง"),
          Tab(text: "จัดส่งสำเร็จ"),
          Tab(text: "ดูรีวิว"),
          Tab(text: "ยกเลิก"),
        ],
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final orderModel = OrderModel.fromJson(order);
    final int rawOrderId = orderModel.orderId ?? 0;
    final String orderId = rawOrderId.toString().padLeft(6, '0');
    final String restaurantName =
        orderModel.restaurant?.restaurantName ?? "ไม่ระบุชื่อร้าน";

    String memberFullName = "ไม่ระบุชื่อผู้รับ";
    String finalImgUrl = "";

    if (orderModel.member != null) {
      final String firstName = orderModel.member?.firstname ?? "";
      final String lastName = orderModel.member?.lastname ?? "";
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        memberFullName = firstName + " " + lastName;
      }
      final String? rawImgPath = orderModel.member?.profileimg ?? "";
      finalImgUrl = _getFinalProfileImageUrl(rawImgPath);
    } else if (order["customerName"] != null) {
      memberFullName = order["customerName"];
    }

    int totalItems = 0;
    if (orderModel.items.isNotEmpty) {
      for (var item in orderModel.items) {
        totalItems += item.qty;
      }
    } else if (order["orderDetails"] != null && order["orderDetails"] is List) {
      totalItems = (order["orderDetails"] as List).length;
    } else if (order["items"] != null && order["items"] is List) {
      totalItems = (order["items"] as List).length;
    }

    String orderTimeText = "--:--";
    if (orderModel.orderdate != null) {
      final DateTime dateTime = orderModel.orderdate!;
      orderTimeText =
          dateTime.hour.toString().padLeft(2, '0') +
          ":" +
          dateTime.minute.toString().padLeft(2, '0') +
          " น.";
    }

    String buttonText = "ดูรายละเอียด";
    final bool isReviewTab = _selectedTabIndex == 3;
    final bool isCancelTab = _selectedTabIndex == 4;
    final bool isSuccessTab = _selectedTabIndex == 2;
    Color buttonColor = const Color(0xFF00B300);
    Color textColor = const Color.fromARGB(255, 255, 255, 255);

    final String orderStatus = (orderModel.orderStatus ?? '')
        .trim()
        .toLowerCase();

    if (_selectedTabIndex == 0) {
      buttonText = "ดูรายละเอียดเพื่อรับงาน";
    } else if (_selectedTabIndex == 1) {
      buttonText = "ดูเส้นทาง / Status จัดส่ง";
    } else if (isReviewTab) {
      buttonText = "ดูรีวิวการจัดส่ง";
    } else if (isCancelTab) {
      buttonText = "ดูเหตุผลการยกเลิก";
      buttonColor = Colors.red.shade600;
    }

    final bool isDeliveredWaitingConfirm = orderStatus == 'delivered';
    final bool isDeliverySuccess =
        orderStatus == 'success' ||
        orderStatus == 'completed' ||
        orderStatus == 'reviewsuccess';

    final String successStatusText = isDeliveredWaitingConfirm
        ? "ส่งแล้ว (รอลูกค้ายืนยัน)"
        : isDeliverySuccess
        ? "จัดส่งสำเร็จเรียบร้อย"
        : "จัดส่งสำเร็จเรียบร้อย";

    final bool showSuccessStatus = isSuccessTab && !isCancelTab;

    final String cancelDetail = orderModel.cancelDetail ?? "";

    final double cardRating =
        double.tryParse((order['reviewRating'] ?? 5.0).toString()) ?? 5.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isCancelTab ? const Color(0xFFFFEBEE) : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCancelTab ? Colors.red.shade200 : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 17, 156, 70).withOpacity(0.4),
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: isCancelTab
            ? const Color(0xFFFFEBEE)
            : const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          splashColor: Colors.green.withOpacity(0.15),
          highlightColor: Colors.green.withOpacity(0.05),
          onTap: () async {
            await Future.delayed(const Duration(milliseconds: 600));
            if (!mounted) return;

            // 🎯 อนุญาตให้กดที่การ์ดเพื่อดูรายละเอียดได้ทุกแท็บ (รวมถึงแท็บยกเลิก)
            _openOrderDetail(orderModel, order, isReviewTab: isReviewTab);
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isCancelTab
                                ? Colors.red.withOpacity(0.15)
                                : const Color(0xFF00B300).withOpacity(0.15),
                            backgroundImage: finalImgUrl.isNotEmpty
                                ? NetworkImage(finalImgUrl)
                                : null,
                            child: finalImgUrl.isEmpty
                                ? Icon(
                                    Icons.person,
                                    size: 20,
                                    color: isCancelTab
                                        ? Colors.red
                                        : const Color(0xFF00B300),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              memberFullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "เลขที่ออเดอร์",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          "K" + orderId,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isCancelTab
                                ? Colors.red
                                : const Color(0xFF00B300),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 4),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isCancelTab
                                ? Colors.red
                                : const Color(0xFF00B300),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "รับที่ (ร้านค้า)",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            restaurantName,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isReviewTab) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        cardRating.toString() + " คะแนน",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (isCancelTab) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.cancel_rounded,
                        size: 20,
                        color: Colors.red.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cancelDetail.isNotEmpty
                              ? "ยกเลิก: " + cancelDetail
                              : "ยกเลิก",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (showSuccessStatus) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Icon(
                        isDeliveredWaitingConfirm
                            ? Icons.delivery_dining_rounded
                            : Icons.check_circle_rounded,
                        size: 20,
                        color: isDeliveredWaitingConfirm
                            ? Colors.orange.shade700
                            : const Color(0xFF00B300),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        successStatusText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDeliveredWaitingConfirm
                              ? Colors.orange.shade800
                              : const Color(0xFF00B300),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "ทั้งหมด " + totalItems.toString() + " รายการ",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "เวลาสั่งซื้อ: " + orderTimeText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 🎯 แสดงปุ่มเฉพาะเมื่อ "ไม่ใช่แท็บจัดส่งสำเร็จ" และ "ไม่ใช่แท็บยกเลิก"
              if (!isSuccessTab && !isCancelTab) ...[
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1, color: Colors.black12),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _openOrderDetail(
                        orderModel,
                        order,
                        isReviewTab: isReviewTab,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        buttonText,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // 🎯 แท็บสำเร็จและแท็บยกเลิก จะไม่แสดงปุ่ม แต่เว้นระยะห่างด้านล่างไว้ให้การ์ดดูสมดุล
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const NavbarRider(title: "รับงาน"),
      body: _isLoadingStatus
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "งานของฉัน",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          shadows: [
                            Shadow(
                              color: Colors.orange.withOpacity(0.3),
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _isReady ? "พร้อมรับงาน" : "พักการทำงาน",
                            style: TextStyle(
                              color: _isReady
                                  ? const Color(0xFF00B300)
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _isUpdating
                                ? null
                                : () => _toggleActiveStatus(!_isReady),
                            child: Opacity(
                              opacity: _isUpdating ? 0.5 : 1.0,
                              child: Container(
                                width: 54,
                                height: 28,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _isReady
                                        ? const Color(0xFF00B300)
                                        : Colors.grey,
                                    width: 2,
                                  ),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  mainAxisAlignment: _isReady
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  children: [
                                    if (_isReady)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 6),
                                        child: Text(
                                          "ON",
                                          style: TextStyle(
                                            color: Color(0xFF00B300),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    Container(
                                      margin: const EdgeInsets.all(2),
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _isReady
                                            ? const Color(0xFF00B300)
                                            : Colors.grey,
                                      ),
                                    ),
                                    if (!_isReady)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 4),
                                        child: Text(
                                          "OFF",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildTabBar(),
                if (_isReady && !_isLoadingStatus)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    // 🎯 ใช้ + แทน $
                    child: Text(
                      "ทั้งหมด " + _realOrders.length.toString() + " รายการ",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: !_isReady
                      ? _buildDisabledState()
                      : _isLoadingOrders
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.orange,
                          ),
                        )
                      : _realOrders.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _fetchOrders,
                          color: Colors.orange,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            itemCount: _realOrders.length,
                            itemBuilder: (context, index) {
                              return _buildOrderCard(_realOrders[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.blueGrey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          selectedItemColor: _primaryOrange,
          unselectedItemColor: Colors.blueGrey.shade300,
          backgroundColor: Colors.white,
          currentIndex: 1,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (index) {
            if (index == 0) {
              Navigator.popUntil(context, (route) => route.isFirst);
            } else if (index == 2) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountManagementRider(),
                ),
              );
            }
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: "หน้าหลัก",
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.list_alt_rounded),
                  if (_activeOrderCount > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          _activeOrderCount > 99
                              ? '99+'
                              : _activeOrderCount.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              label: "รับงาน",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: "บัญชี",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.power_settings_new, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "เปิดสถานะพร้อมรับงาน เพื่อเริ่มดูออเดอร์ใหม่",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String emptyMessage = _selectedTabIndex == 0
        ? "ยังไม่มีออเดอร์ใหม่ในระบบขณะนี้"
        : _selectedTabIndex == 1
        ? "ยังไม่มีรายการที่กำลังจัดส่ง"
        : _selectedTabIndex == 2
        ? "ยังไม่มีรายการที่จัดส่งสำเร็จ"
        : _selectedTabIndex == 3
        ? "ยังไม่มีรายการที่ได้รับการรีวิว"
        : "ยังไม่มีรายการที่ถูกยกเลิก";

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      color: Colors.orange,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          Icon(
            Icons.layers_clear_outlined,
            size: 80,
            color: Colors.orange.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              emptyMessage,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
