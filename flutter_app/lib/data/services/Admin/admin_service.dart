import 'package:dio/dio.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/admin_model.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';

class AdminService {
  Future<void> doLoginAdmin(AdminModel admin) async {
    try {
      await DioClient.dio.post("/v1/admin/loginAdmin", data: admin.toJson());
    } on DioException catch (e) {
      final errorMessage = e.response?.data ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<RestaurantModel>> getListRestaurant() async {
    try {
      var response = await DioClient.dio.get("/v1/admin/list_register_rest");
      return (response.data as List)
          .map((item) => RestaurantModel.fromJson(item))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<RestaurantModel> getRestaurantById(String id) async {
    try {
      var response = await DioClient.dio.get("/v1/getRestaurantById/$id");
      return RestaurantModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> approveRestaurant(String username) async {
    try {
      await DioClient.dio.post("/v1/admin/approveRestaurant/$username");
    } on DioException catch (e) {
      final errorMessage = e.response?.data ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectRestaurant(String username, String reason) async {
    try {
      await DioClient.dio.post(
        "/v1/admin/rejectRestaurant/$username?reason=$reason",
      );
    } on DioException catch (e) {
      final errorMessage = e.response?.data ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }
}
