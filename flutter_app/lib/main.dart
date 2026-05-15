import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/rider_model.dart';
import 'package:flutter_app/features/admin/login_admin.dart';
import 'package:flutter_app/features/member/login_member.dart';
import 'package:flutter_app/features/member/test_map.dart';
import 'package:flutter_app/features/restaurant/agrees_restaurant.dart';
import 'package:flutter_app/features/restaurant/login_restaurant.dart';
import 'package:flutter_app/features/restaurant/register_owner_info.dart';
import 'package:flutter_app/features/restaurant/register_restaurant.dart';
import 'package:flutter_app/features/rider/login_rider.dart';
import 'package:flutter_app/features/user/home_user.dart';

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
      home: LoginAdmin(),
    );
  }
}
