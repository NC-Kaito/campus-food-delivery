import 'package:dio/dio.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/menu_model.dart';

class MenuService {
  Future<List<MenuModel>> getMenusByRestaurant(
    String restaurantUsername,
  ) async {
    try {
      final response = await DioClient.dio.get(
        "/v1/menu/restaurant/$restaurantUsername",
      );

      if (response.statusCode == 200) {
        List jsonResponse = response.data;
        return jsonResponse.map((data) => MenuModel.fromJson(data)).toList();
      } else {
        throw "เกิดข้อผิดพลาด ไม่สามารถโหลดรายการอาหารได้";
      }
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data?['message'] ??
          "เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์";
      throw errorMessage;
    } catch (e) {
      print("MenuService Error: $e");
      rethrow;
    }
  }
}
