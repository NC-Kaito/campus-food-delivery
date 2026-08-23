import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/review_model.dart';
import 'package:flutter_app/data/models/rider_model.dart';

class RiderService {
  Future<void> doLoginRider(RiderModel rider) async {
    try {
      await DioClient.dio.post("/v1/rider/loginRider", data: rider.toJson());
    } on DioException catch (e) {
      final errorMessage = e.response?.data ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> doRegsiterRider(RiderModel rider) async {
    try {
      await DioClient.dio.post("/v1/rider/registerRider", data: rider.toJson());
    } on DioException catch (e) {
      final errorMessage = e.response?.data ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, String>> doRegisterRiderWithImages({
    required RiderModel rider,
    required String studentCardPath,
    required String vehicleImagePath,
    required String drivingLicensePath,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        "riderData": jsonEncode(rider.toJson()),

        "studentCardImage": await MultipartFile.fromFile(
          studentCardPath,
          filename: 'card_${rider.studentid}.jpg',
        ),

        "vehicleImage": await MultipartFile.fromFile(
          vehicleImagePath,
          filename: 'vehicle_${rider.studentid}.jpg',
        ),

        "drivingLicenseImg": await MultipartFile.fromFile(
          vehicleImagePath,
          filename: 'vehicle_${rider.studentid}.jpg',
        ),
      });

      final response = await DioClient.dio.post(
        "/v1/rider/registerRiderWithImages",
        data: formData,
      );

      return Map<String, String>.from(response.data);
    } on DioException catch (e) {
      final errorMessage = e.response?.data ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }

  Future<RiderModel> getRiderByStudentId(String studentId) async {
    try {
      final response = await DioClient.dio.get(
        "/v1/rider/getRider",
        queryParameters: {'studentId': studentId},
      );
      return RiderModel.fromJson(response.data);
    } on DioException catch (e) {
      final errorMessage = e.response?.data ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfileMember(RiderModel rider) async {
    try {
      await DioClient.dio.post(
        "/v1/rider/updateProfileRider",
        data: rider.toJson(),
      );
    } on DioException catch (e) {
      final errorMessage = e.response?.data ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateIsActive(String studentId, bool isActive) async {
    try {
      await DioClient.dio.post(
        "/v1/rider/updateIsActive",
        data: {"studentId": studentId, "isActive": isActive},
      );
    } on DioException catch (e) {
      final errorMessage = e.response?.data ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }
}
