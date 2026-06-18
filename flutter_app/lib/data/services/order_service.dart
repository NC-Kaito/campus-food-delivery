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
      );

      if (response.statusCode == 200) {
        List data = response.data;
        return data.map((json) => OrderModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("เกิดข้อผิดพลาด ไม่สามารถดึงข้อมูลคำสั่งซื้อจากฐานข้อมูลได้: $e");
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
}
