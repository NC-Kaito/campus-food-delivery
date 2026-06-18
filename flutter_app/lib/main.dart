import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_app/data/models/rider_model.dart';
import 'package:flutter_app/features/admin/login_admin.dart';
import 'package:flutter_app/features/member/login_member.dart';
import 'package:flutter_app/features/member/test_map.dart';

import 'package:flutter_app/select_role.dart';

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
      //ปิดแถบDebug เวลารัน
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: .fromSeed(seedColor: Colors.green),
        textTheme: GoogleFonts.kanitTextTheme(Theme.of(context).textTheme),
      ),
      home: SelectRolePage(),
      // home: LoginAdmin(),
    );
  }
}
