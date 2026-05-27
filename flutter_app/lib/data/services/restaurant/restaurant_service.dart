import 'package:dio/dio.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';

class RestaurantService {
  Future<RestaurantModel> doLoginRestaurant(
    String username,
    String password,
  ) async {
    try {
      final response = await DioClient.dio.post(
        "/v1/restaurant/loginRestaurant",
        data: {"username": username, "password": password},
      );
      return RestaurantModel.fromJson(response.data);
    } on DioException catch (e) {
      final errorMessage = e.response?.data ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }

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

  Future<List<RestaurantModel>> searchRestaurant(String keyword) async {
    try {
      final response = await DioClient.dio.get(
        "/v1/restaurant/searchRestaurant",
        queryParameters: {"name": keyword},
      );

      if (response.statusCode == 200) {
        List data = response.data;
        return data.map((item) => RestaurantModel.fromJson(item)).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      print("Search Error: ${e.message}");
      return [];
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  Future<RestaurantModel> getRestaurantByUsername(String username) async {
    try {
      final response = await DioClient.dio.get(
        "/v1/restaurant/getRestaurantByUsername/$username",
      );
      return RestaurantModel.fromJson(response.data);
    } on DioException catch (e) {
      final errorMessage = e.response?.data ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
      throw errorMessage;
    }
  }

  Future<void> updateProfileRestaurant(RestaurantModel restaurant) async {
    try {
      await DioClient.dio.post(
        "/v1/restaurant/updateProfileRestaurant",
        data: restaurant.toJson(),
      );
    } on DioException catch (e) {
      final errorMessage = e.response?.data ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateStatusOpen(RestaurantModel restaurant) async {
    try {
      await DioClient.dio.post(
        "/v1/restaurant/updateStatusOpen",
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
