import 'package:dio/dio.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';

class RestaurantService {
  Future<void> doRegisterRestaurant(RestaurantModel restaurant) async {
    try {
      await DioClient.dio.post(
        "/v1/restaurant/registerRestaurant",
        data: restaurant.toJson(),
      );
    } on DioException catch (e) {
      final errorMessage = e.response?.data ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }
}
