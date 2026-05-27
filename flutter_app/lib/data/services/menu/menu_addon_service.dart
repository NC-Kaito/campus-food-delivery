import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/menu_addon_detail_model.dart';

class MenuAddonService {
  final Dio _dio = Dio();

  Future<List<MenuAddonDetailModel>> getAddonsByMenuId(int menuId) async {
    try {
      final response = await DioClient.dio.get("/v1/menuAddon/$menuId/addons");

      if (response.statusCode == 200 && response.data != null) {
        List<MenuAddonDetailModel> flatDetailsList = [];
        List<dynamic> groupJsonList = response.data;

        // 🎯 1. วนลูปแกะกลุ่มแม่ (MenuAddonGroupModel) ออกมาก่อน
        for (var groupJson in groupJsonList) {
          MenuAddonGroupModel groupModel = MenuAddonGroupModel.fromJson(
            groupJson,
          );

          // 🎯 2. เจาะลึกลงไปสอยลิสต์รายการลูกย่อย (menuaddondetails) ที่ติดมาใน JSON
          if (groupJson['menuaddondetails'] != null) {
            List<dynamic> detailsJsonList = groupJson['menuaddondetails'];

            for (var detailJson in detailsJsonList) {
              // 🎯 3. แกะข้อมูลรายละเอียดลูกเข้าโมเดล
              MenuAddonDetailModel detailModel = MenuAddonDetailModel.fromJson(
                detailJson,
              );

              // 🚀 ผูกความสัมพันธ์ย้อนกลับไปให้กลุ่มแม่ด้วย เพื่อให้ UI ใช้คำสั่ง .menuAddonGroup แยกกลุ่มได้
              detailModel.menuAddonGroup = groupModel;

              flatDetailsList.add(detailModel);
            }
          }
        }

        return flatDetailsList; // ส่งลิสต์ที่จัดของเสร็จแล้วกลับไปให้หน้าจอ UI วาด
      } else {
        throw Exception("Failed to load addons");
      }
    } catch (e) {
      debugPrint("Error in MenuAddonService: $e");
      return [];
    }
  }
}
