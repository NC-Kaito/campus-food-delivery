import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/order_model.dart';
import 'package:flutter_app/data/models/review_model.dart';

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

  // 🎯 ฟังก์ชันสำหรับแจ้งปัญหาคำสั่งซื้อพร้อมอัปโหลดรูปภาพ
  Future<bool> reportIssue(
    int orderId,
    String issueDetail,
    File issueImage,
  ) async {
    try {
      // ดึงชื่อไฟล์จาก Path
      String fileName = issueImage.path.split('/').last;

      // จัดเตรียมข้อมูลเป็น FormData (เหมือนฝั่ง Postman)
      FormData formData = FormData.fromMap({
        'orderId': orderId,
        'issueDetail': issueDetail,
        'issueImage': await MultipartFile.fromFile(
          issueImage.path,
          filename: fileName,
        ),
      });

      // ยิง Request ไปยัง Spring Boot
      Response response = await DioClient.dio.post(
        '/v1/order/reportIssue',
        data: formData,
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      throw Exception("เกิดข้อผิดพลาดในการแจ้งปัญหา: $e");
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

  // 🎯 เปลี่ยนชนิดข้อมูลและแก้พาร์ทให้ตรงกับ Spring Boot เรียบร้อยแล้วครับ
  Future<List<dynamic>> getReviewSuccessOrders(String studentId) async {
    try {
      // 🎯 แก้พาร์ทตรงนี้ให้เป็น /v1/order/... แล้วครับ
      final response = await DioClient.dio.get(
        '/v1/order/rider/$studentId/review',
      );

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw Exception(
          "ไม่สามารถดึงข้อมูลรีวิวได้ รหัสข้อผิดพลาด: ${response.statusCode}",
        );
      }
    } catch (e) {
      print("🚨 เกิดข้อผิดพลาดในการดึงออเดอร์ที่รีวิวแล้ว: $e");
      rethrow;
    }
  }

  // 🎯 ฟังก์ชันใหม่สำหรับ "ร้านค้า" ดึงรีวิวโดยเฉพาะ
  Future<List<dynamic>> getReviewSuccessOrdersByRestaurant(
    String username,
  ) async {
    try {
      // 🎯 วิ่งไปที่เส้นทางของร้านค้าที่เราเพิ่งสร้างเมื่อกี้
      final response = await DioClient.dio.get(
        '/v1/order/restaurant/$username/review',
      );

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw Exception(
          "ไม่สามารถดึงข้อมูลรีวิวของร้านค้าได้: ${response.statusCode}",
        );
      }
    } catch (e) {
      print("🚨 เกิดข้อผิดพลาดในการดึงรีวิวของร้านค้า: $e");
      rethrow;
    }
  }

  // 🎯 ฟังก์ชันขอล็อกออเดอร์ (กันไรเดอร์คนอื่นแย่ง)
  Future<void> lockOrder(int orderId, String riderId) async {
    try {
      await DioClient.dio.post(
        '/v1/order/lockOrder',
        queryParameters: {'orderId': orderId, 'riderId': riderId},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw "LOCKED"; // ส่ง Flag ออกไปบอก UI ว่าโดนล็อกอยู่
      }
      throw "เกิดข้อผิดพลาด ไม่สามารถเข้าถึงออเดอร์ได้";
    } catch (e) {
      throw "เกิดข้อผิดพลาด ไม่สามารถเข้าถึงออเดอร์ได้";
    }
  }

  // 🎯 ฟังก์ชันปลดล็อกออเดอร์
  Future<void> unlockOrder(int orderId, String riderId) async {
    try {
      await DioClient.dio.post(
        '/v1/order/unlockOrder',
        queryParameters: {'orderId': orderId, 'riderId': riderId},
      );
    } catch (e) {
      // 🚀 ไม่ต้อง throw error เพราะฝั่ง Backend มีระบบ Auto-unlock 1 นาทีคอยซัพพอร์ตอยู่แล้ว
      print("Unlock Failed (Ignored): $e");
    }
  }

  // 🎯 ฟังก์ชันดึงรายงานรายได้ย้อนหลังตามช่วงเวลา
  Future<List<Map<String, dynamic>>> getRiderIncomeByDateRange(
    String studentId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // ปรับเวลาให้ครอบคลุมทั้งวัน (ตั้งแต่ 00:00:00 ของวันเริ่ม จนถึง 23:59:59 ของวันสิ้นสุด)
      final start = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        0,
        0,
        0,
      );
      final end = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );

      final response = await DioClient.dio.get(
        '/v1/order/rider/$studentId/income',
        queryParameters: {
          'startDate': start.toIso8601String(),
          'endDate': end.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      print("🚨 เกิดข้อผิดพลาดในการดึงข้อมูลรายได้: $e");
      return [];
    }
  }
}
