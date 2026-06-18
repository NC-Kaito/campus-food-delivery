import 'package:dio/dio.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/data/models/order_model.dart';

class OrderService {
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
}
