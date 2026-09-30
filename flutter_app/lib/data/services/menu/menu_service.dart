import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/option_model.dart';
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
        final List jsonResponse = response.data;

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
        final List jsonResponse = response.data;

        final menus = jsonResponse
            .map((data) => MenuModel.fromJson(data))
            .toList();

        // Debug
        for (final m in menus) {
          print(
            "menuId: ${m.menuId} | "
            "typeMenuId: ${m.typeMenuId} | "
            "typeMenuName: ${m.typeMenuName}",
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

        print("typeMenus count: ${typeMenus.length}");

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
        "/v1/menu/restaurant/$restaurantUsername",
      );

      if (response.statusCode == 200) {
        final List jsonResponse = response.data;

        return jsonResponse
            .map((data) => MenuModel.fromJson(data))
            .where((menu) => menu.typeMenuId == typeMenuId)
            .toList();
      }

      throw "ไม่สามารถโหลดรายการอาหารได้";
    } on DioException catch (e) {
      throw e.response?.data?['message'] ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
    }
  }

  Future<void> updateMenuStatus(int menuId, bool status) async {
    try {
      await DioClient.dio.post(
        "/v1/menu/updateStatus",
        data: {'menuid': menuId, 'status': status},
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

  Future<List<OptionModel>> getAllOptionMenus(String restaurantUsername) async {
    try {
      final response = await DioClient.dio.get(
        "/v1/menuAddon/addons",
        queryParameters: {'username': restaurantUsername},
      );

      if (response.statusCode == 200) {
        final List jsonResponse = response.data;

        return jsonResponse.map((data) => OptionModel.fromJson(data)).toList();
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
      final FormData formData = FormData.fromMap({
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

  // ==========================================================
  // MENU
  // ==========================================================

  Future<void> saveMenu(Map<String, dynamic> requestData) async {
    try {
      final response = await DioClient.dio.post(
        "/v1/menu/addMenu",
        data: requestData,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw "บันทึกเมนูไม่สำเร็จ";
      }
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map<String, dynamic> && data.containsKey('message')) {
        throw data['message'];
      } else if (data is String) {
        throw data;
      } else {
        throw "เกิดข้อผิดพลาดในการเชื่อมต่อ หรือบันทึกเมนู";
      }
    }
  }

  Future<void> updateMenuByRestaurant(Map<String, dynamic> requestData) async {
    try {
      final response = await DioClient.dio.post(
        "/v1/menu/updateMenuByRestaurant",
        data: requestData,
      );

      if (response.statusCode != 200) {
        throw "อัปเดตเมนูไม่สำเร็จ";
      }
    } on DioException catch (e) {
      final msg = e.response?.data;

      throw msg is String ? msg : "เกิดข้อผิดพลาดในการอัปเดตเมนู";
    }
  }

  Future<void> deleteMenu(Map<String, dynamic> requestData) async {
    try {
      final response = await DioClient.dio.post(
        "/v1/menu/deleteMenu",
        data: requestData,
      );

      if (response.statusCode != 200) {
        throw "ลบเมนูไม่สำเร็จ";
      }
    } on DioException catch (e) {
      final msg = e.response?.data;

      throw msg is String ? msg : "เกิดข้อผิดพลาดในการลบเมนู";
    } catch (e) {
      throw e.toString();
    }
  }

  // ==========================================================
  // CURRY PRICE
  // ==========================================================

  /// ดึงราคามาตรฐานข้าวราดแกง
  ///
  /// GET
  /// /v1/menu/curry-price
  ///
  /// Query:
  /// restaurantId
  /// typeMenuId
  ///
  /// ตัวอย่าง response:
  /// {
  ///   "price": 40,
  ///   "price2": 50,
  ///   "price3": 60
  /// }
  Future<Map<String, double?>?> getCurryPrice({
    required String restaurantId,
    required int typeMenuId,
  }) async {
    try {
      final response = await DioClient.dio.get(
        "/v1/menu/curry-price",
        queryParameters: {
          'restaurantId': restaurantId,
          'typeMenuId': typeMenuId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Backend อาจส่ง {} กลับมาในกรณียังไม่มีการตั้งราคา
        if (data == null || data is! Map || data.isEmpty) {
          return null;
        }

        return {
          'price': _parseDouble(data['price']),
          'price2': _parseDouble(data['price2']),
          'price3': _parseDouble(data['price3']),
        };
      }

      throw "ไม่สามารถโหลดราคาข้าวราดแกงได้";
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map<String, dynamic> && data.containsKey('message')) {
        throw data['message'];
      }

      if (data is String) {
        throw data;
      }

      throw "เกิดข้อผิดพลาดในการโหลดราคาข้าวราดแกง";
    } catch (e) {
      print("getCurryPrice error: $e");
      rethrow;
    }
  }

  /// บันทึกราคามาตรฐานข้าวราดแกง
  ///
  /// PUT
  /// /v1/menu/curry-price
  ///
  /// Body:
  /// {
  ///   "price": 40,
  ///   "price2": 50,
  ///   "price3": 60
  /// }
  Future<void> saveCurryPrice({
    required String restaurantId,
    required int typeMenuId,
    required double price,
    required double price2,
    required double price3,
  }) async {
    try {
      final response = await DioClient.dio.put(
        "/v1/menu/curry-price",
        queryParameters: {
          'restaurantId': restaurantId,
          'typeMenuId': typeMenuId,
        },
        data: {'price': price, 'price2': price2, 'price3': price3},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw "บันทึกราคาข้าวราดแกงไม่สำเร็จ";
      }
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map<String, dynamic> && data.containsKey('message')) {
        throw data['message'];
      }

      if (data is String) {
        throw data;
      }

      throw "เกิดข้อผิดพลาดในการบันทึกราคาข้าวราดแกง";
    } catch (e) {
      print("saveCurryPrice error: $e");
      rethrow;
    }
  }

  // ==========================================================
  // HELPER
  // ==========================================================

  double? _parseDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}
