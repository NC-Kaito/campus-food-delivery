import 'package:flutter/material.dart';

class SharedAppBarMember extends StatefulWidget implements PreferredSizeWidget {
  const SharedAppBarMember({super.key});

  @override
  State<SharedAppBarMember> createState() => _SharedAppBarMemberState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SharedAppBarMemberState extends State<SharedAppBarMember> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.lightGreenAccent,
      leading: IconButton(
        icon: const Icon(Icons.home, color: Colors.deepOrange),
        onPressed: () {},
      ),
    );
  }
}
