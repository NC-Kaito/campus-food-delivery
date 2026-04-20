import 'package:dio/dio.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/member_model.dart';

class MemberService {
  Future<void> doLoginMember(MemberModel member) async {
    try {
      await DioClient.dio.post("/v1/member/loginMember", data: member.toJson());
    } on DioException catch (e) {
      final errorMessage = e.response?.data ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }
}
