import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_app/data/models/faculty_model.dart';
import 'package:flutter_app/data/models/major_model.dart';
import 'package:flutter_app/data/models/rider_model.dart';
import 'package:flutter_app/data/services/rider/faculty_service.dart';
import 'package:flutter_app/data/services/rider/major_service.dart';
import 'package:flutter_app/data/services/rider/rider_service.dart';

class RegisterRider2 extends StatefulWidget {
  final String? studentId;
  final String? password;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? birthday;

  final int? savedFacultyId;
  final int? savedMajorId;
  final String? savedPlate;
  final File? savedStudentCard;
  final File? savedDrivingLicense;
  final File? savedVehicleImage;

  const RegisterRider2({
    super.key,
    this.studentId,
    this.password,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.birthday,
    this.savedFacultyId,
    this.savedMajorId,
    this.savedPlate,
    this.savedStudentCard,
    this.savedDrivingLicense,
    this.savedVehicleImage,
  });

  @override
  State<RegisterRider2> createState() => _RegisterRider2State();
}

class _RegisterRider2State extends State<RegisterRider2> {
  final FacultyService _facultyService = FacultyService();
  final MajorService _majorService = MajorService();
  final RiderService riderService = RiderService();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _licensePlateController = TextEditingController();

  List<FacultyModel> _faculties = [];
  List<MajorModel> _majors = [];

  int? _selectedFacultyId;
  int? _selectedMajorId;

  // ✅ เพิ่มตัวแปรเก็บไฟล์ใบขับขี่
  File? _studentCardImage;
  File? _drivingLicenseImage;
  File? _vehicleImage;

  bool _isLoadingFaculty = true;
  bool _isLoadingMajor = false;
  bool _isRegistering = false;

  // ✅ เพิ่มใน State class
  String? _studentCardError;
  String? _drivingLicenseError;
  String? _vehicleImageError;
  String? _plateError;

  @override
  void initState() {
    super.initState();
    _loadFaculties();

    // ✅ restore ค่าเดิม
    _selectedFacultyId = widget.savedFacultyId;
    _selectedMajorId = widget.savedMajorId;
    _studentCardImage = widget.savedStudentCard;
    _drivingLicenseImage = widget.savedDrivingLicense;
    _vehicleImage = widget.savedVehicleImage;

    if (widget.savedPlate != null) {
      _licensePlateController.text = widget.savedPlate!;
    }

    if (widget.savedFacultyId != null) {
      _loadMajors(widget.savedFacultyId!, restoreMajorId: true); // ✅
    }
  }

  // --- API Functions ---
  Future<void> _loadFaculties() async {
    try {
      final data = await _facultyService.getAllFaculty();
      setState(() {
        _faculties = data;
        _isLoadingFaculty = false;
      });
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _loadMajors(int facultyId, {bool restoreMajorId = false}) async {
    setState(() {
      _isLoadingMajor = true;
      _majors = [];
      if (!restoreMajorId) _selectedMajorId = null; // ✅ reset เฉพาะตอนเลือกใหม่
    });
    try {
      final data = await _majorService.getMajorByFaculty(facultyId);
      setState(() {
        _majors = data;
        _isLoadingMajor = false;
      });
    } catch (e) {
      setState(() => _isLoadingMajor = false);
      _showError(e.toString());
    }
  }

  Future<void> _onRegister() async {
    final plate = _licensePlateController.text.trim();

    // ✅ validate ทุกอย่างพร้อมกัน แล้ว setState ครั้งเดียว
    setState(() {
      _studentCardError = _validateImage(_studentCardImage, "รูปบัตรนักศึกษา");
      _drivingLicenseError = _validateImage(
        _drivingLicenseImage,
        "รูปใบขับขี่",
      );
      _vehicleImageError = _validateImage(_vehicleImage, "รูปรถ");

      if (plate.isEmpty)
        _plateError = "กรุณากรอกเลขทะเบียนรถ";
      else if (!RegExp(r'^[a-zA-Z\u0E00-\u0E7F0-9 ]+$').hasMatch(plate))
        _plateError = "ต้องเป็นภาษาไทย อังกฤษ หรือตัวเลขเท่านั้น";
      else if (plate.length < 5 || plate.length > 30)
        _plateError = "ความยาว 5-30 ตัวอักษร";
      else
        _plateError = null;
    });

    // ✅ ถ้ามี error ใดๆ หยุด
    if (_studentCardError != null ||
        _drivingLicenseError != null ||
        _vehicleImageError != null ||
        _plateError != null)
      return;

    if (_selectedMajorId == null) {
      _showError("กรุณาเลือกสาขาวิชา");
      return;
    }

    setState(() => _isRegistering = true);

    try {
      RiderModel rider = RiderModel(
        studentid: widget.studentId,
        password: widget.password,
        firstName: widget.firstName,
        lastName: widget.lastName,
        birthday: widget.birthday,
        email: widget.email,
        phone: widget.phone,
        majorId: _selectedMajorId,
        vehiclePlate: _licensePlateController.text,
        isActive: false,
        verificationStatus: "wait",
      );

      // ✅ ส่ง path ของใบขับขี่ไปด้วย (ปรับ Service ให้รับ parameter นี้ด้วยนะเพื่อน)
      final imagePaths = await riderService.doRegisterRiderWithImages(
        rider: rider,
        studentCardPath: _studentCardImage!.path,
        drivingLicensePath: _drivingLicenseImage!.path, // เพิ่มตัวนี้
        vehicleImagePath: _vehicleImage!.path,
      );

      rider.studentCardImage = imagePaths['studentCardUrl'];
      rider.drivingLicenseImg =
          imagePaths['drivingLicenseUrl']; // แมพค่าใบขับขี่
      rider.vehicleImage = imagePaths['vehicleImageUrl'];

      await riderService.doRegsiterRider(rider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("สมัครสำเร็จ รอการตรวจสอบ"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  // ✅ เพิ่มใน State class
  String? _validateImage(File? file, String fieldName) {
    if (file == null) return "กรุณาแนบ$fieldName";

    // เช็คนามสกุลไฟล์
    final ext = file.path.split('.').last.toLowerCase();
    if (ext != 'jpg' && ext != 'jpeg' && ext != 'png')
      return "$fieldName ต้องเป็น .jpg หรือ .png เท่านั้น";

    // เช็คขนาดไฟล์ 100KB - 1MB
    final sizeInBytes = file.lengthSync();
    if (sizeInBytes < 100 * 1024)
      return "$fieldName ต้องมีขนาดไม่ต่ำกว่า 100KB";
    if (sizeInBytes > 1024 * 1024) return "$fieldName ต้องมีขนาดไม่เกิน 1MB";

    return null;
  }

  // --- UI Helpers ---
  Future<void> _pickImage(int type) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (type == 0) {
          _studentCardImage = File(image.path);
          _studentCardError = null; // ✅ ล้าง error
        }
        if (type == 1) {
          _drivingLicenseImage = File(image.path);
          _drivingLicenseError = null; // ✅ ล้าง error
        }
        if (type == 2) {
          _vehicleImage = File(image.path);
          _vehicleImageError = null; // ✅ ล้าง error
        }
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "สมัครผู้จัดส่ง",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isRegistering
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("ข้อมูลเชิงหลักฐาน"),

                    _buildLabel("แนบรูปบัตรนักศึกษา (Student ID Card)"),
                    _buildImagePicker(
                      _studentCardImage,
                      () => _pickImage(0),
                      errorText: _studentCardError,
                    ),

                    // ✅ เพิ่มส่วนการเลือกรูปใบขับขี่
                    _buildLabel("แนบรูปใบขับขี่ (Driving License)"),
                    _buildImagePicker(
                      _drivingLicenseImage,
                      () => _pickImage(1),
                      errorText: _drivingLicenseError, // ✅
                    ),

                    _buildLabel("คณะ (Faculty)"),
                    _buildFacultyDropdown(),
                    _buildLabel("สาขาวิชา (Major)"),
                    _buildMajorDropdown(),

                    const Divider(height: 40),

                    _buildSectionTitle("ข้อมูลยานพาหนะ"),
                    _buildLabel("เลขทะเบียนรถ (License Plate)"),
                    _buildTextField(
                      _licensePlateController,
                      "ตัวอย่าง กข 123 เชียงใหม่",
                      errorText: _plateError,
                    ),

                    _buildLabel("แนบรูปรถที่ใช้ (Vehicle Image)"),
                    _buildImagePicker(
                      _vehicleImage,
                      () => _pickImage(2),
                      errorText: _vehicleImageError, // ✅
                    ),

                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSecondaryButton(
                            "ย้อนกลับ",
                            () => Navigator.pop(context, {
                              'facultyId': _selectedFacultyId,
                              'majorId': _selectedMajorId,
                              'plate': _licensePlateController.text,
                              'studentCard': _studentCardImage,
                              'drivingLicense': _drivingLicenseImage,
                              'vehicleImage': _vehicleImage,
                            }),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildPrimaryButton(
                            "สมัครผู้จัดส่ง",
                            _onRegister,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // --- Widgets ย่อยคงเดิม ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: (_) =>
              setState(() => _plateError = null), // ✅ ล้าง error เมื่อพิมพ์
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : Colors.transparent,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : Colors.green,
                width: 1.5,
              ),
            ),
          ),
        ),
        // ✅ แสดง error ใต้ช่องกรอก
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePicker(
    File? imageFile,
    VoidCallback onTap, {
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 120,
            width: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              // ✅ border แดงเมื่อ error
              border: Border.all(
                color: errorText != null ? Colors.red : Colors.grey.shade300,
                width: errorText != null ? 1.5 : 1,
              ),
            ),
            child: imageFile == null
                ? Icon(
                    Icons.add,
                    size: 40,
                    color: errorText != null ? Colors.red : Colors.grey,
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(imageFile, fit: BoxFit.cover),
                  ),
          ),
        ),
        // ✅ แสดง error text ใต้รูป
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildFacultyDropdown() {
    return _isLoadingFaculty
        ? const LinearProgressIndicator()
        : DropdownButtonFormField<int>(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            value: _selectedFacultyId,
            hint: const Text("----เลือกคณะ----"),
            items: _faculties
                .map(
                  (f) => DropdownMenuItem(
                    value: f.facultyId,
                    child: Text(f.facultyName ?? ""),
                  ),
                )
                .toList(),
            onChanged: (val) {
              setState(() => _selectedFacultyId = val);
              if (val != null) _loadMajors(val, restoreMajorId: false);
            },
          );
  }

  Widget _buildMajorDropdown() {
    return _isLoadingMajor
        ? const LinearProgressIndicator()
        : DropdownButtonFormField<int>(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            value: _selectedMajorId,
            hint: const Text("----เลือกสาขา----"),
            items: _majors
                .map(
                  (m) => DropdownMenuItem(
                    value: m.majorId,
                    child: Text(m.majorName ?? ""),
                  ),
                )
                .toList(),
            onChanged: _selectedFacultyId == null
                ? null
                : (val) => setState(() => _selectedMajorId = val),
          );
  }

  Widget _buildPrimaryButton(String text, VoidCallback? onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF76FF03),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 15),
        elevation: 0,
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildSecondaryButton(String text, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 15),
        backgroundColor: Colors.grey[300],
        side: BorderSide.none,
      ),
      child: Text(text, style: const TextStyle(color: Colors.black)),
    );
  }
}
