import 'package:dio/dio.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/type_restaurant_model.dart';

class TypeRestaurantService {
  // ✅ ใช้ DioClient ที่เพื่อนมีอยู่แล้วให้เป็นประโยชน์
  Future<List<TypeRestaurantModel>> getAllTypeRestaurant() async {
    try {
      // เรียกไปที่ Endpoint ที่เราสร้างไว้ใน Spring Boot
      final response = await DioClient.dio.get("/v1/typerestaurant");

      if (response.statusCode == 200) {
        // ข้อมูลที่ได้จาก Dio (response.data) จะเป็น List/Map อยู่แล้ว ไม่ต้อง json.decode
        List jsonResponse = response.data;
        return jsonResponse
            .map((data) => TypeRestaurantModel.fromJson(data))
            .toList();
      } else {
        throw "โหลดข้อมูลประเภทอาหารไม่สำเร็จ";
      }
    } on DioException catch (e) {
      // จัดการ Error จาก Dio
      final errorMessage =
          e.response?.data?['message'] ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
      throw errorMessage;
    } catch (e) {
      print("Error: $e");
      rethrow;
    }
  }
}
