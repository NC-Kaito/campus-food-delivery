import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/addon_group_request_model.dart';
import 'package:flutter_app/data/models/addon_menu_model.dart';
import 'package:flutter_app/data/models/menu_addon_detail_model.dart';
import 'package:flutter_app/data/models/menu_addon_group_model.dart';

class MenuAddonService {
  final Dio _dio = Dio();

  Future<List<MenuAddonDetailModel>> getAddonsByMenuId(int menuId) async {
    try {
      final response = await DioClient.dio.get("/v1/menuAddon/$menuId/addons");

      if (response.statusCode == 200 && response.data != null) {
        List<MenuAddonDetailModel> flatDetailsList = [];
        List<dynamic> groupJsonList = response.data;

        for (var groupJson in groupJsonList) {
          MenuAddonGroupModel groupModel = MenuAddonGroupModel.fromJson(
            groupJson,
          );

          groupModel.isRequired = groupJson['required'] == true;

          if (groupJson['menuaddondetails'] != null) {
            List<dynamic> detailsJsonList = groupJson['menuaddondetails'];

            for (var detailJson in detailsJsonList) {
              MenuAddonDetailModel detailModel = MenuAddonDetailModel.fromJson(
                detailJson,
              );

              detailModel.menuAddonGroup = groupModel;

              flatDetailsList.add(detailModel);
            }
          }
        }

        return flatDetailsList;
      } else {
        throw Exception("Failed to load addons");
      }
    } catch (e) {
      debugPrint("Error in MenuAddonService: $e");
      return [];
    }
  }

  Future<bool> createAddonGroupTemplate(AddonGroupRequestModel request) async {
    try {
      final response = await DioClient.dio.post(
        '/v1/menuAddon/createGroup',
        data: request.toJson(),
      );

      // เช็ก HTTP Status 200 หรือ 201 (Created)
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ??
            'เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์',
      );
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<bool> updateAddonGroupTemplate(AddonGroupRequestModel requsst) async {
    try {
      final response = await DioClient.dio.post(
        '/v1/menuAddon/updateGroup',
        data: requsst.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } on DioException catch (e) {
      throw Exception('Error: $e');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // ดึง addon groups ทั้งหมดของร้าน
  Future<List<MenuAddonGroupModel>> getAddonGroupsByRestaurant(
    String username,
  ) async {
    try {
      final response = await DioClient.dio.get(
        '/v1/menuAddon/groups',
        queryParameters: {'username': username},
      );
      return (response.data as List)
          .map((e) => MenuAddonGroupModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'ไม่สามารถโหลดข้อมูล addon ได้',
      );
    }
  }

  // toggle status เปิด/ปิด group
  Future<bool> toggleAddonGroupStatus(int groupId, bool status) async {
    try {
      final response = await DioClient.dio.patch(
        '/v1/menuAddon/groups/$groupId/status',
        data: {'status': status},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'ไม่สามารถอัปเดตสถานะได้');
    }
  }

  Future<List<AddonMenuModel>> searchAddonName(String keyword) async {
    if (keyword.trim().isEmpty) return [];
    try {
      final response = await DioClient.dio.get(
        '/v1/menuAddon/searchAddonName',
        queryParameters: {'keyword': keyword.trim()},
      );
      final List data = response.data as List;
      return data.map((e) => AddonMenuModel.fromJson(e)).toList();
    } catch (e) {
      return []; // ค้นหาไม่ได้ก็แค่ไม่โชว์ suggestion เฉยๆ ไม่ต้อง throw ให้กระทบ UX
    }
  }
}
