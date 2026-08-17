import 'package:dio/dio.dart';

class DioClient {
  static final Dio dio = Dio(
    BaseOptions(
      // baseUrl: "http://10.239.194.211:8081",
      baseUrl: "http://10.200.211.84:8081", //เครื่องนารี เน็ต ปป
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {"Content-Type": "application/json"},
    ),
  )..interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
}
