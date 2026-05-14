import 'package:dio/dio.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/faculty_model.dart';

class FacultyService {
  Future<List<FacultyModel>> getAllFaculty() async {
    try {
      final response = await DioClient.dio.get("/v1/faculty/getFacultys");

      if (response.statusCode == 200) {
        List jsonResponse = response.data;
        return jsonResponse.map((data) => FacultyModel.fromJson(data)).toList();
      } else {
        throw "โหลดข้อมูลคณะไม่สำเร็จ";
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
