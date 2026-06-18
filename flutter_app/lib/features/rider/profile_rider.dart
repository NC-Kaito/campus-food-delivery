import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/rider_model.dart';
import 'package:flutter_app/data/services/rider/rider_service.dart';
import 'package:flutter_app/global_data.dart';

class ProfileRider extends StatefulWidget {
  const ProfileRider({super.key});

  @override
  State<ProfileRider> createState() => _ProfileRiderState();
}

class _ProfileRiderState extends State<ProfileRider> {
  final RiderService _riderService = RiderService();

  RiderModel? _rider;
  bool _isLoading = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRiderProfile();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadRiderProfile() async {
    try {
      final rider = await _riderService.getRiderByStudentId(
        GlobalData.usernameRider,
      );
      setState(() {
        _rider = rider;
        _emailController.text = rider.email ?? "";
        _phoneController.text = rider.phone ?? "";
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("โหลดข้อมูลไม่สำเร็จ: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_rider == null) return;
    try {
      final updated = RiderModel(
        studentid: _rider!.studentid,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        firstName: _rider!.firstName,
        lastName: _rider!.lastName,
        birthday: _rider!.birthday,
        facultyName: _rider!.facultyName,
        majorName: _rider!.majorName,
        vehiclePlate: _rider!.vehiclePlate,
      );
      await _riderService.updateProfileMember(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("บันทึกสำเร็จ"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("บันทึกไม่สำเร็จ: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildField(
    String label,
    String value, {
    bool isEditable = false,
    TextEditingController? controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            initialValue: isEditable ? null : value,
            enabled: isEditable,
            decoration: InputDecoration(
              filled: true,
              fillColor: isEditable ? Colors.white : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.home_outlined, color: Colors.orange, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delivery_dining, color: Colors.orange),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.orange),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.orange),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Header: Profile Image
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.orange, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "แก้โปรไฟล์",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Section 1: Contact
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "ข้อมูลติดต่อ",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    "อีเมล (Email)",
                    _rider?.email ?? "",
                    isEditable: true,
                    controller: _emailController,
                  ),
                  _buildField(
                    "เบอร์โทรศัพท์ (Phone)",
                    _rider?.phone ?? "",
                    isEditable: true,
                    controller: _phoneController,
                  ),

                  const SizedBox(height: 16),

                  // Section 2: Personal Info
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "ข้อมูลส่วนตัว",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildField("รหัสนักศึกษา", _rider?.studentid ?? "-"),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          "ชื่อจริง",
                          _rider?.firstName ?? "-",
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildField("นามสกุล", _rider?.lastName ?? "-"),
                      ),
                    ],
                  ),
                  _buildField("วันเดือนปีเกิด", _rider?.birthday ?? "-"),
                  _buildField("คณะ", _rider?.facultyName ?? "-"),
                  _buildField("สาขาวิชา", _rider?.majorName ?? "-"),

                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            "ออกจากระบบ",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF64FF20),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            "บันทึกการแก้ไข",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
