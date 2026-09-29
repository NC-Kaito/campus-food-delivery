import 'package:dio/dio.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/option_group_request_model.dart';
import 'package:flutter_app/data/models/option_model.dart';
import 'package:flutter_app/data/models/menu_option_group_model.dart';

class MenuOptionService {
  Future<List<OptionGroupModel>> getOptionsByMenuId(int menuId) async {
    try {
      final response = await DioClient.dio.get('/v1/menuAddon/$menuId/addons');

      if (response.statusCode != 200 || response.data == null) {
        return [];
      }

      final dynamic rawData = response.data;

      if (rawData is! List) {
        return [];
      }

      return rawData
          .whereType<Map>()
          .map((json) => OptionGroupModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      print('Error getOptionsByMenuId: ${e.message}');
      return [];
    } catch (e) {
      print('Error getOptionsByMenuId: $e');
      return [];
    }
  }

  /// ชื่อเดิมเพื่อไม่ให้หน้า UI เก่าที่เรียก service นี้พัง
  /// แต่ return model ใหม่เป็น OptionGroupModel
  Future<List<OptionGroupModel>> getAddonsByMenuId(int menuId) {
    return getOptionsByMenuId(menuId);
  }

  // ============================================================
  // CREATE OPTION GROUP
  // ============================================================

  Future<bool> createOptionGroup(OptionGroupRequestModel request) async {
    try {
      final response = await DioClient.dio.post(
        '/v1/menuAddon/createGroup',
        data: request.toJson(),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map && data['message'] != null) {
        throw Exception(data['message']);
      }

      throw Exception('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// ชื่อเดิมเพื่อรองรับโค้ด UI เดิม
  /// ใช้ OptionGroupRequestModel โดยตรง ไม่ใช้ Addon model
  Future<bool> createAddonGroupTemplate(OptionGroupRequestModel request) {
    return createOptionGroup(request);
  }

  // ============================================================
  // UPDATE OPTION GROUP
  // ============================================================

  Future<bool> updateOptionGroup(OptionGroupRequestModel request) async {
    try {
      final response = await DioClient.dio.post(
        '/v1/menuAddon/updateGroup',
        data: request.toJson(),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map && data['message'] != null) {
        throw Exception(data['message']);
      }

      throw Exception('เกิดข้อผิดพลาดในการอัปเดตกลุ่มตัวเลือก');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// ชื่อเดิมเพื่อรองรับโค้ด UI เดิม
  Future<bool> updateAddonGroupTemplate(OptionGroupRequestModel request) {
    return updateOptionGroup(request);
  }

  // ============================================================
  // GET OPTION GROUPS BY RESTAURANT
  // ============================================================

  Future<List<OptionGroupModel>> getOptionGroupsByRestaurant(
    String username,
  ) async {
    try {
      final response = await DioClient.dio.get(
        '/v1/menuAddon/groups',
        queryParameters: {'username': username},
      );

      if (response.data is! List) {
        return [];
      }

      return (response.data as List)
          .whereType<Map>()
          .map((json) => OptionGroupModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map && data['message'] != null) {
        throw Exception(data['message']);
      }

      throw Exception('ไม่สามารถโหลดกลุ่มตัวเลือกได้');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// ชื่อเดิมเพื่อรองรับโค้ด UI เดิม
  Future<List<OptionGroupModel>> getAddonGroupsByRestaurant(String username) {
    return getOptionGroupsByRestaurant(username);
  }

  // ============================================================
  // OPTION GROUP STATUS
  // ============================================================

  Future<bool> toggleOptionGroupStatus(int optionGroupId, bool status) async {
    try {
      final response = await DioClient.dio.patch(
        '/v1/menuAddon/groups/$optionGroupId/status',
        data: {'status': status},
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map && data['message'] != null) {
        throw Exception(data['message']);
      }

      throw Exception('ไม่สามารถอัปเดตสถานะกลุ่มตัวเลือกได้');
    }
  }

  /// ชื่อเดิมเพื่อรองรับโค้ด UI เดิม
  Future<bool> toggleAddonGroupStatus(int groupId, bool status) {
    return toggleOptionGroupStatus(groupId, status);
  }

  // ============================================================
  // SEARCH OPTION
  // ============================================================

  Future<List<OptionModel>> searchOptionName(String keyword) async {
    if (keyword.trim().isEmpty) {
      return [];
    }

    try {
      final response = await DioClient.dio.get(
        '/v1/menuAddon/searchAddonName',
        queryParameters: {'keyword': keyword.trim()},
      );

      if (response.data is! List) {
        return [];
      }

      return (response.data as List)
          .whereType<Map>()
          .map((json) => OptionModel.fromJson(json))
          .toList();
    } catch (e) {
      // Search failure should not break the UI.
      return [];
    }
  }

  /// ชื่อเดิม แต่ใช้ OptionModel เป็น model ใหม่
  Future<List<OptionModel>> searchAddonName(String keyword) {
    return searchOptionName(keyword);
  }

  // ============================================================
  // DELETE OPTION GROUP
  // ============================================================

  Future<bool> deleteOptionGroup(int optionGroupId) async {
    try {
      final response = await DioClient.dio.post(
        '/v1/menuAddon/groups/$optionGroupId',
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map && data['message'] != null) {
        throw Exception(data['message']);
      }

      throw Exception('ไม่สามารถลบกลุ่มตัวเลือกได้');
    }
  }

  /// ชื่อเดิมเพื่อรองรับโค้ด UI เดิม
  Future<bool> deleteAddonGroup(int groupId) {
    return deleteOptionGroup(groupId);
  }

  // ============================================================
  // MENU <-> OPTION GROUP MAPPING
  // ============================================================

  Future<void> updateMenuOptionMapping(
    int menuId,
    List<int> optionGroupIds,
  ) async {
    try {
      final response = await DioClient.dio.post(
        '/v1/menuAddon/updateMenuMapping',
        data: {'menuId': menuId, 'optionGroupIds': optionGroupIds},
      );

      if (response.statusCode != 200) {
        throw Exception('บันทึกการผูกกลุ่มตัวเลือกไม่สำเร็จ');
      }
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map && data['message'] != null) {
        throw Exception(data['message']);
      }

      throw Exception('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// ชื่อเดิมเพื่อรองรับ UI เดิม
  Future<void> updateMenuAddonMapping(int menuId, List<int> optionGroupIds) {
    return updateMenuOptionMapping(menuId, optionGroupIds);
  }

  // ============================================================
  // OPTION STATUS
  // ============================================================

  Future<bool> toggleOptionStatus(int optionId, bool status) async {
    try {
      final response = await DioClient.dio.patch(
        '/v1/menuAddon/details/$optionId/status',
        data: {'status': status},
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map && data['message'] != null) {
        throw Exception(data['message']);
      }

      throw Exception('ไม่สามารถอัปเดตสถานะตัวเลือกได้');
    }
  }

  /// ชื่อเดิมเพื่อรองรับ UI เดิม
  Future<bool> toggleAddonDetailStatus(int addonDetailId, bool status) {
    return toggleOptionStatus(addonDetailId, status);
  }

  // ============================================================
  // COUNT MENU USING OPTION GROUP
  // ============================================================

  Future<int> getMenuCountUsingOptionGroup(int optionGroupId) async {
    try {
      final response = await DioClient.dio.get(
        '/v1/menuAddon/groups/$optionGroupId/menuCount',
      );

      final data = response.data;

      if (data is Map && data['count'] is num) {
        return (data['count'] as num).toInt();
      }

      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// ชื่อเดิมเพื่อรองรับ UI เดิม
  Future<int> getMenuCountUsingGroup(int groupId) {
    return getMenuCountUsingOptionGroup(groupId);
  }
}
