import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/order_model.dart';

class OrderService {
  Future<void> memberConfirmOrder(OrderModel order) async {
    try {
      await DioClient.dio.post(
        "/v1/order/confirmMemberOrder",
        data: order.toJson(),
      );
    } on DioException catch (e) {
      final errorMessage = e.response?.data ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<OrderModel>> getConfirmOrdersByMember(String username) async {
    try {
      final response = await DioClient.dio.get(
        '/v1/order/listOrderMember/$username',
        options: Options(
          responseType: ResponseType
              .plain, // 🎯 รับแบบ plain text ป้องกัน Dio parse พังกลางสาย
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        // แปลงจาก String -> List Map อย่างปลอดภัย
        final List dynamicList = jsonDecode(response.data.toString());
        return dynamicList.map((json) => OrderModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("🚨 เกิดข้อผิดพลาดในการรับข้อมูลคำสั่งซื้อ: $e");
      return [];
    }
  }

  // ///////////////////////// Rider --
  Future<List<dynamic>> getWaitingOrders() async {
    try {
      final response = await DioClient.dio.get("/v1/order/waitingOrders");

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw "เกิดข้อผิดพลาดในการดึงข้อมูลออเดอร์: ${response.statusCode}";
      }
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data?["message"] ??
          "ไม่สามารถดึงข้อมูลคำสั่งซื้อได้ หรือเซิร์ฟเวอร์ไม่ได้เปิดอยู่";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }

  // เพิ่มพารามิเตอร์ username เข้ามาในฟังก์ชัน
  Future<List<dynamic>> getActiveOrders(String username) async {
    try {
      // 🎯 เปลี่ยน Path ให้ตรงกับ Spring Boot Controller และแนบ username เข้าไป
      final response = await DioClient.dio.get(
        "/v1/order/rider/$username/active",
      );

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw "เกิดข้อผิดพลาดในการดึงข้อมูลออเดอร์: ${response.statusCode}";
      }
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data?["message"] ??
          "ไม่สามารถดึงข้อมูลคำสั่งซื้อได้ หรือเซิร์ฟเวอร์ไม่ได้เปิดอยู่";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> confirmOrderByRider(String studentId, int orderId) async {
    try {
      await DioClient.dio.post(
        "/v1/order/confirmOrderByRider",
        data: {"studentId": studentId, "orderId": orderId},
      );
    } on DioException catch (e) {
      final errorMessage = e.response?.data ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateOrderStatus(int orderId, String newStatus) async {
    try {
      await DioClient.dio.post(
        "/v1/order/updateStatus", // 🎯 ปรับ Path ให้ตรงกับ Backend ของคุณ
        data: {"orderId": orderId, "status": newStatus},
      );
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data?["message"] ?? "ไม่สามารถอัปเดตสถานะได้";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getSuccessOrdersByRider(String username) async {
    try {
      final response = await DioClient.dio.get(
        "/v1/order/rider/$username/success",
      );

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw "เกิดข้อผิดพลาดในการดึงข้อมูลออเดอร์: ${response.statusCode}";
      }
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data?["message"] ??
          "ไม่สามารถดึงข้อมูลคำสั่งซื้อได้ หรือเซิร์ฟเวอร์ไม่ได้เปิดอยู่";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }

  //------ Restaurant ----
  Future<List<dynamic>> getWaitingOrdersByRestaurant(String username) async {
    try {
      // 🎯 เปลี่ยน Path ให้ตรงกับ Spring Boot Controller และแนบ username เข้าไป
      final response = await DioClient.dio.get(
        "/v1/order/restaurant/$username/waitingOrdersByRestaurant",
      );

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw "เกิดข้อผิดพลาดในการดึงข้อมูลออเดอร์: ${response.statusCode}";
      }
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data?["message"] ??
          "ไม่สามารถดึงข้อมูลคำสั่งซื้อได้ หรือเซิร์ฟเวอร์ไม่ได้เปิดอยู่";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> confirmOrderByRestaurant(int orderId) async {
    try {
      await DioClient.dio.post(
        "/v1/order/confirmOrderByRestaurant",
        data: {"orderId": orderId},
      );
    } on DioException catch (e) {
      final errorMessage = e.response?.data ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getActiveOrdersByRestaurant(String username) async {
    try {
      final response = await DioClient.dio.get(
        "/v1/order/restaurant/$username/active",
      );

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw "เกิดข้อผิดพลาดในการดึงข้อมูลออเดอร์: ${response.statusCode}";
      }
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data?["message"] ??
          "ไม่สามารถดึงข้อมูลคำสั่งซื้อได้ หรือเซิร์ฟเวอร์ไม่ได้เปิดอยู่";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }
}
