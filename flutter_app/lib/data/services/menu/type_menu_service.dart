import 'package:dio/dio.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/type_menu_model.dart';

class TypeMenuService {
  Future<List<TypeMenuModel>> getAllTypeMenu() async {
    try {
      final response = await DioClient.dio.get("/v1/typemenu");
      if (response.statusCode == 200) {
        List jsonResponse = response.data;
        return jsonResponse
            .map<TypeMenuModel>((data) => TypeMenuModel.fromJson(data))
            .toList();
      } else {
        throw "โหลดข้อมูลประเภทอาหารไม่สำเร็จ";
      }
    } on DioException catch (e) {
      throw e.response?.data?['message'] ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
    }
  }
}
