import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/addon_menu_model.dart';
import 'package:flutter_app/data/models/menu_model.dart';
import 'package:flutter_app/data/models/type_menu_model.dart';

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

  Future<List<TypeMenuModel>> getTypeMenuByRestaurant(
    String restaurantUsername,
  ) async {
    try {
      final response = await DioClient.dio.get(
        "/v1/menu/restaurant/$restaurantUsername",
      );

      if (response.statusCode == 200) {
        List jsonResponse = response.data;

        final menus = jsonResponse
            .map((data) => MenuModel.fromJson(data))
            .toList();

        // ✅ Debug ดูว่า parse ได้ค่าไหม
        for (final m in menus) {
          print(
            "menuId: ${m.menuId} | typeMenuId: ${m.typeMenuId} | typeMenuName: ${m.typeMenuName}",
          );
        }

        final seen = <int>{};
        final typeMenus = <TypeMenuModel>[];

        for (final menu in menus) {
          if (menu.typeMenuId != null && seen.add(menu.typeMenuId!)) {
            typeMenus.add(
              TypeMenuModel(
                typemenuId: menu.typeMenuId,
                typemenuName: menu.typeMenuName,
              ),
            );
          }
        }

        print("typeMenus count: ${typeMenus.length}"); // ✅ ต้องได้ > 0

        return typeMenus;
      } else {
        throw "เกิดข้อผิดพลาด";
      }
    } on DioException catch (e) {
      throw e.response?.data?['message'] ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
    }
  }

  Future<List<MenuModel>> getMenusByTypeMenu(
    String restaurantUsername,
    int typeMenuId,
  ) async {
    try {
      final response = await DioClient.dio.get(
        "/v1/menu/restaurant/$restaurantUsername", // ✅ ใช้ endpoint เดิม
      );

      if (response.statusCode == 200) {
        List jsonResponse = response.data;
        return jsonResponse
            .map((data) => MenuModel.fromJson(data))
            .where(
              (menu) => menu.typeMenuId == typeMenuId,
            ) // ✅ filter ใน Flutter
            .toList();
      }
      throw "ไม่สามารถโหลดรายการอาหารได้";
    } on DioException catch (e) {
      throw e.response?.data?['message'] ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
    }
  }

  Future<void> updateMenuStatus(int menuId, bool status) async {
    try {
      // ยิง POST ไปที่เอนพอยต์ใหม่
      await DioClient.dio.post(
        "/v1/menu/updateStatus",
        data: {
          'menuid': menuId, // ส่งข้อมูลให้ตรงกับฟิลด์ใน menuDto ของ Java
          'status': status,
        },
      );
    } on DioException catch (e) {
      final errorMessage = e.response?.data is String
          ? e.response?.data
          : "ไม่สามารถอัปเดตสถานะได้";
      throw errorMessage;
    } catch (e) {
      throw "เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์: $e";
    }
  }

  Future<List<AddonMenuModel>> getAllAddonMenus(
    String restaurantUsername,
  ) async {
    try {
      // 🌟 ส่ง username แนบไปเป็น Query Parameter กรองค่าหลังบ้าน
      final response = await DioClient.dio.get(
        "/v1/menuAddon/addons",
        queryParameters: {'username': restaurantUsername},
      );

      if (response.statusCode == 200) {
        List jsonResponse = response.data;
        return jsonResponse
            .map((data) => AddonMenuModel.fromJson(data))
            .toList();
      } else {
        throw "ไม่สามารถโหลดข้อมูลตัวเลือกเสริมได้";
      }
    } on DioException catch (e) {
      throw e.response?.data?['message'] ??
          "เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์";
    }
  }

  Future<String?> uploadMenuImage(File? imageFile) async {
    if (imageFile == null) return null;
    try {
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await DioClient.dio.post(
        '/v1/menu/uploadMenuImage',
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['url'];
      }
      return null;
    } catch (e) {
      print("uploadMenuImage error: $e");
      return null;
    }
  }

  // ✅ บันทึกเมนูพร้อม Add-on
  Future<void> saveMenuWithAddons(Map<String, dynamic> requestData) async {
    try {
      final response = await DioClient.dio.post(
        "/v1/menuAddon/addMenuWithAddons",
        data: requestData,
      );
      if (response.statusCode != 200) {
        throw "บันทึกเมนูไม่สำเร็จ";
      }
    } on DioException catch (e) {
      final msg = e.response?.data;
      throw (msg is String ? msg : "เกิดข้อผิดพลาดในการบันทึกเมนู");
    }
  }

  Future<void> updateMenuByRestaurant(Map<String, dynamic> requestData) async {
    try {
      final response = await DioClient.dio.put(
        "/v1/menuAddon/updateMenuByRestaurant",
        data: requestData,
      );
      if (response.statusCode != 200) {
        throw "อัปเดตเมนูไม่สำเร็จ";
      }
    } on DioException catch (e) {
      final msg = e.response?.data;
      throw (msg is String ? msg : "เกิดข้อผิดพลาดในการอัปเดตเมนู");
    }
  }
}
