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
}
