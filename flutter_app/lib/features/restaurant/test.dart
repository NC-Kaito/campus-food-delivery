import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/member_model.dart';
import 'package:flutter_app/data/services/member/member_service.dart';
import 'package:flutter_app/global_data.dart';

// Image Upload
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class Test extends StatefulWidget {
  const Test({super.key});

  @override
  State<Test> createState() => _TestState();
}

class _TestState extends State<Test> {
  MemberService memberService = MemberService();
  MemberModel memberData = MemberModel();

  String? firstname = "";
  String? lastname = "";
  String? imageUrl;

  Future<void> loadMemberData() async {
    String username = GlobalData.usernameMember;
    final member = await memberService.getMemberByUsername(username);

    setState(() {
      memberData = member;
      firstname = memberData.firstname;
      lastname = memberData.lastname;
      imageUrl = memberData.profileimg;

      emailController.text = memberData.email!;
    });
  }

  ////////////////////////////
  late final TextEditingController usernameController;
  late final TextEditingController emailController;

  //////////////////////////// Upload Image
  File? imageFile;
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    loadMemberData();
    usernameController = TextEditingController();
    emailController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    // TODO: implement dispose
    super.dispose();
  }

  // Upload Imgae
  Future<void> pickupImageInGallery() async {
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );

    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
    // Service Upload to Backend
    // memberService.updateProfileMember(imageFile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.green, title: Text("Natthapong")),
      body: Column(
        children: [
          Text("$firstname"),
          Text("$lastname"),
          CircleAvatar(
            radius: 100,
            backgroundImage: NetworkImage(Uri.encodeFull(imageUrl!)),
          ),
          ClipRRect(
            child: Image.network(
              Uri.encodeFull(imageUrl!),
              width: 200,
              height: 200,
            ),
          ),
          Form(
            child: Column(
              children: [
                TextFormField(controller: usernameController),
                SizedBox(height: 20),
                TextFormField(controller: emailController),
                SizedBox(height: 20),
                // Upload Image
                GestureDetector(
                  onTap: pickupImageInGallery,
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.file(imageFile!, fit: BoxFit.cover),
                          )
                        : const Icon(
                            Icons.add_a_photo,
                            color: Colors.red,
                            size: 28,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
