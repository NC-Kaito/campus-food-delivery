import 'package:dio/dio.dart';

class DioClient {
  static final Dio dio = Dio(
    BaseOptions(
      // baseUrl: "http://10.228.208.211:8081",
      baseUrl: "http://10.35.139.84:8081", //เครื่องนารี เน็ต ปป
      // baseUrl: "https://unrushed-secret-reload.ngrok-free.dev",
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
    ),
  )..interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
}
