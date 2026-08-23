import 'package:dio/dio.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/member_model.dart';
import 'package:flutter_app/data/models/review_model.dart';

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

  Future<void> doRegsiterMember(MemberModel member) async {
    try {
      await DioClient.dio.post(
        "/v1/member/registerMember",
        data: member.toJson(),
      );
    } on DioException catch (e) {
      final errorMessage = e.response?.data ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }

  Future<MemberModel> getMemberByUsername(String username) async {
    try {
      final response = await DioClient.dio.get(
        "/v1/member/getMember",
        queryParameters: {'username': username},
      );
      return MemberModel.fromJson(response.data);
    } on DioException catch (e) {
      final errorMessage = e.response?.data ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfileMember(MemberModel member) async {
    try {
      await DioClient.dio.post(
        "/v1/member/updateProfileMember",
        data: member.toJson(),
      );
    } on DioException catch (e) {
      final errorMessage = e.response?.data ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addReview(ReviewSubmitModel review) async {
    try {
      await DioClient.dio.post("/v1/member/addReview", data: review.toJson());
    } on DioException catch (e) {
      final errorMessage = e.response?.data ?? "เกิดข้อผิดพลาดในการเชื่อมต่อ";
      throw errorMessage;
    } catch (e) {
      rethrow;
    }
  }

  Future<ReviewSubmitModel> getReviewByOrderId(int orderId) async {
    try {
      final response = await DioClient.dio.get('/v1/member/getReview/$orderId');
      return ReviewSubmitModel.fromJson(response.data);
    } catch (e) {
      throw Exception('ไม่สามารถโหลดข้อมูลรีวิวได้: $e');
    }
  }
}
