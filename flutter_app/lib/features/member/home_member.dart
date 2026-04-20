import 'package:flutter/material.dart';

class HomeMember extends StatefulWidget {
  const HomeMember({super.key});

  @override
  State<HomeMember> createState() => _HomeMemberState();
}

class _HomeMemberState extends State<HomeMember> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome!"),
        backgroundColor: Colors.greenAccent,
      ),
    );
  }
}
