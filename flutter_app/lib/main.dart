import 'package:flutter/material.dart';
import 'package:flutter_app/data/services/in_app_notification_service.dart';
import 'package:flutter_app/main_login.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus food Delivery',

      navigatorKey: InAppNotificationService.navigatorKey,

      //ปิดแถบDebug เวลารัน
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        textTheme: GoogleFonts.kanitTextTheme(Theme.of(context).textTheme),
      ),
      home: MainLogin(),
      // home: LoginAdmin(),
    );
  }
}
