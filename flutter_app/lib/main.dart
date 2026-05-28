import 'package:flutter/material.dart';
import 'package:flutter_app/features/admin/login_admin.dart';

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
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.green)),
      home: SelectRolePage(),

      // home: LoginAdmin(),
    );
  }
}
