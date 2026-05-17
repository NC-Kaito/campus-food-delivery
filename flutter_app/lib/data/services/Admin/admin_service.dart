import 'package:dio/dio.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/admin_model.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/models/rider_model.dart';

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

  // admin_service.dart
  Future<Map<String, int>> getDashboardCount() async {
    var response = await DioClient.dio.get("/v1/admin/count");
    final data = response.data;
    return {
      'totalRestaurant': data['totalRestaurant'] as int,
      'newRestaurant': data['newRestaurant'] as int,
      'totalRider': data['totalRider'] as int,
      'newRider': data['newRider'] as int,
    };
  }

  //-----------Restaurant-----------------------------------------------------------------------

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

  //-------------Rider-----------------------------------------------------------------------------
  Future<List<RiderModel>> getListRider() async {
    try {
      var response = await DioClient.dio.get("/v1/admin/list_register_rider");
      return (response.data as List)
          .map((item) => RiderModel.fromJson(item))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<RiderModel> getRiderById(String id) async {
    try {
      var response = await DioClient.dio.get("/v1/getRiderById/$id");
      return RiderModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> approveRider(String studentid) async {
    try {
      await DioClient.dio.post("/v1/admin/approveRider/$studentid");
    } on DioException catch (e) {
      final errorMessage = e.response?.data ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectRider(String studentid, String reason) async {
    try {
      await DioClient.dio.post(
        "/v1/admin/rejectRider/$studentid?reason=$reason",
      );
    } on DioException catch (e) {
      final errorMessage = e.response?.data ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }
}
