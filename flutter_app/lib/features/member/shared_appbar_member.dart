import 'package:flutter/material.dart';
import 'package:flutter_app/features/user/home_user.dart';

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
      backgroundColor: Colors.green,
      leading: IconButton(
        icon: const Icon(Icons.home, color: Colors.deepOrange),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomeUser()),
          );
        },
      ),
    );
  }
}
