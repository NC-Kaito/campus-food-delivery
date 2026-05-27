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
}
