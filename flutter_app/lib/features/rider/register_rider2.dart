// features/admin/register_rider2.dart
import 'dart:io';
import 'package:flutter/material.dart';
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
  String? _selectedProvince; // 🎯 ตัวแปรเก็บจังหวัดที่ไรเดอร์เลือก

  File? _studentCardImage;
  File? _drivingLicenseImage;
  File? _vehicleImage;

  bool _isLoadingFaculty = true;
  bool _isLoadingMajor = false;
  bool _isRegistering = false;

  String? _studentCardError;
  String? _drivingLicenseError;
  String? _vehicleImageError;
  String? _plateError;
  String? _provinceError; // 🎯 เก็บแจ้งเตือนกรณีลืมเลือกจังหวัด

  // 🎯 รายชื่อ 77 จังหวัดประเทศไทยสำหรับ Dropdown ตัวเลือกไรเดอร์
  final List<String> _provinces = [
    "กรุงเทพมหานคร",
    "กระบี่",
    "กาญจนบุรี",
    "กาฬสินธุ์",
    "กำแพงเพชร",
    "ขอนแก่น",
    "จันทบุรี",
    "ฉะเชิงเทรา",
    "ชลบุรี",
    "ชัยนาท",
    "ชัยภูมิ",
    "ชุมพร",
    "เชียงราย",
    "เชียงใหม่",
    "ตรัง",
    "ตราด",
    "ตาก",
    "นครนายก",
    "นครปฐม",
    "นครพนม",
    "นครราชสีมา",
    "นครศรีธรรมราช",
    "นครสวรรค์",
    "นนทบุรี",
    "นราธิวาส",
    "น่าน",
    "บึงกาฬ",
    "บุรีรัมย์",
    "ปทุมธานี",
    "ประจวบคีรีขันธ์",
    "ปราจีนบุรี",
    "ปัตตานี",
    "พระนครศรีอยุธยา",
    "พะเยา",
    "พังงา",
    "พัทลุง",
    "พิจิตร",
    "พิษณุโลก",
    "เพชรบุรี",
    "เพชรบูรณ์",
    "แพร่",
    "ภูเก็ต",
    "มหาสารคาม",
    "มุกดาหาร",
    "แม่ฮ่องสอน",
    "ยโสธร",
    "ยะลา",
    "ร้อยเอ็ด",
    "ระนอง",
    "ระยอง",
    "ราชบุรี",
    "ลพบุรี",
    "ลำปาง",
    "ลำพูน",
    "เลย",
    "ศรีสะเกษ",
    "สกลนคร",
    "สงขลา",
    "สตูล",
    "สมุทรปราการ",
    "สมุทรสงคราม",
    "สมุทรสาคร",
    "สระแก้ว",
    "สระบุรี",
    "สิงห์บุรี",
    "สุโขทัย",
    "สุพรรณบุรี",
    "สุราษฎร์ธานี",
    "สุรินทร์",
    "หนองคาย",
    "หนองบัวลำภู",
    "อ่างทอง",
    "อำนาจเจริญ",
    "อุดรธานี",
    "อุตรดิตถ์",
    "อุทัยธานี",
    "อุบลราชธานี",
  ];

  @override
  void initState() {
    super.initState();
    _loadFaculties();

    _selectedFacultyId = widget.savedFacultyId;
    _selectedMajorId = widget.savedMajorId;
    _studentCardImage = widget.savedStudentCard;
    _drivingLicenseImage = widget.savedDrivingLicense;
    _vehicleImage = widget.savedVehicleImage;

    // ตรวจสอบและแกะค่าแยก เลขทะเบียน และ จังหวัด ออกจากข้อมูลเก่า (ถ้ามีบันทึกมา)
    if (widget.savedPlate != null && widget.savedPlate!.isNotEmpty) {
      final oldPlate = widget.savedPlate!;
      String detectedProvince = "";

      for (var province in _provinces) {
        if (oldPlate.endsWith(" $province") || oldPlate.endsWith("$province")) {
          detectedProvince = province;
          break;
        }
      }

      if (detectedProvince.isNotEmpty) {
        _selectedProvince = detectedProvince;
        _licensePlateController.text = oldPlate
            .replaceAll(detectedProvince, "")
            .trim();
      } else {
        _licensePlateController.text = oldPlate;
      }
    }

    if (widget.savedFacultyId != null) {
      _loadMajors(widget.savedFacultyId!, restoreMajorId: true);
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
      if (!restoreMajorId) _selectedMajorId = null;
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
    final plateNumber = _licensePlateController.text.trim();

    setState(() {
      _studentCardError = _validateImage(_studentCardImage, "รูปบัตรนักศึกษา");
      _drivingLicenseError = _validateImage(
        _drivingLicenseImage,
        "รูปใบขับขี่",
      );
      _vehicleImageError = _validateImage(_vehicleImage, "รูปรัด");

      // ตรวจสอบความถูกต้องของจังหวัด
      _provinceError = _selectedProvince == null
          ? "กรุณาเลือกจังหวัดทะเบียนรถ"
          : null;

      if (plateNumber.isEmpty) {
        _plateError = "กรุณากรอกเลขทะเบียนรถ";
      } else if (!RegExp(
        r'^[a-zA-Z\u0E00-\u0E7F0-9 ]+$',
      ).hasMatch(plateNumber)) {
        _plateError = "ต้องเป็นภาษาไทย อังกฤษ หรือตัวเลขเท่านั้น";
      } else if (plateNumber.length < 2 || plateNumber.length > 15) {
        _plateError = "ความยาวทะเบียนรถไม่ถูกต้อง";
      } else {
        _plateError = null;
      }
    });

    if (_studentCardError != null ||
        _drivingLicenseError != null ||
        _vehicleImageError != null ||
        _plateError != null ||
        _provinceError != null) {
      return;
    }

    if (_selectedMajorId == null) {
      _showError("กรุณาเลือกสาขาวิชา");
      return;
    }

    setState(() => _isRegistering = true);

    try {
      // 🎯 ประกบรวมร่างข้อความ: "[เลขทะเบียน] [จังหวัด]" ส่งเข้าฟิลด์รถตามมาตรฐานโครงสร้างเดิม
      final finalVehiclePlate = "$plateNumber $_selectedProvince";

      RiderModel rider = RiderModel(
        studentid: widget.studentId,
        password: widget.password,
        firstName: widget.firstName,
        lastName: widget.lastName,
        birthday: widget.birthday,
        email: widget.email,
        phone: widget.phone,
        majorId: _selectedMajorId,
        vehiclePlate: finalVehiclePlate,
        isActive: false,
        verificationStatus: "wait",
      );

      final imagePaths = await riderService.doRegisterRiderWithImages(
        rider: rider,
        studentCardPath: _studentCardImage!.path,
        drivingLicensePath: _drivingLicenseImage!.path,
        vehicleImagePath: _vehicleImage!.path,
      );

      rider.studentCardImage = imagePaths['studentCardUrl'];
      rider.drivingLicenseImg = imagePaths['drivingLicenseUrl'];
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

  String? _validateImage(File? file, String fieldName) {
    if (file == null) return "กรุณาแนบ$fieldName";

    final ext = file.path.split('.').last.toLowerCase();
    if (ext != 'jpg' && ext != 'jpeg' && ext != 'png') {
      return "$fieldName ต้องเป็น .jpg หรือ .png เท่านั้น";
    }

    final sizeInBytes = file.lengthSync();
    if (sizeInBytes > 2 * 1024 * 1024)
      return "$fieldName ต้องมีขนาดไม่เกิน 2MB";

    return null;
  }

  Future<void> _pickImage(int type) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (type == 0) {
          _studentCardImage = File(image.path);
          _studentCardError = null;
        }
        if (type == 1) {
          _drivingLicenseImage = File(image.path);
          _drivingLicenseError = null;
        }
        if (type == 2) {
          _vehicleImage = File(image.path);
          _vehicleImageError = null;
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

                    _buildLabel("แนบรูปใบขับขี่ (Driving License)"),
                    _buildImagePicker(
                      _drivingLicenseImage,
                      () => _pickImage(1),
                      errorText: _drivingLicenseError,
                    ),

                    _buildLabel("คณะ (Faculty)"),
                    _buildFacultyDropdown(),
                    _buildLabel("สาขาวิชา (Major)"),
                    _buildMajorDropdown(),

                    const Divider(height: 40),

                    _buildSectionTitle("ข้อมูลยานพาหนะ"),

                    // 🎯 ประกอบโครงสร้างกล่องข้อความ ทะเบียน และดรอปดาวน์จังหวัดให้อยู่ในชุดเดียวกัน
                    _buildLabel("เลขทะเบียนรถ (License Plate)"),
                    _buildTextField(
                      _licensePlateController,
                      "กรอกเฉพาะหมวดอักษรและตัวเลข เช่น 1กข 1234",
                      errorText: _plateError,
                    ),

                    _buildLabel("จังหวัดทะเบียนรถ (Province)"),
                    _buildProvinceDropdown(),

                    _buildLabel("แนบรูปรถที่ใช้ (Vehicle Image)"),
                    _buildImagePicker(
                      _vehicleImage,
                      () => _pickImage(2),
                      errorText: _vehicleImageError,
                    ),

                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSecondaryButton("ย้อนกลับ", () {
                            final currentPlateStr = _licensePlateController.text
                                .trim();
                            final fullPlateWithProv = _selectedProvince != null
                                ? "$currentPlateStr $_selectedProvince"
                                : currentPlateStr;

                            Navigator.pop(context, {
                              'facultyId': _selectedFacultyId,
                              'majorId': _selectedMajorId,
                              'plate': fullPlateWithProv,
                              'studentCard': _studentCardImage,
                              'drivingLicense': _drivingLicenseImage,
                              'vehicleImage': _vehicleImage,
                            });
                          }),
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
          onChanged: (_) => setState(() => _plateError = null),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : Colors.grey.shade400,
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

  // 🎯 วิดเจ็ต Dropdown เลือกจังหวัด 77 จังหวัดสลักขอบขนานสวยงาม
  Widget _buildProvinceDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _provinceError != null
                    ? Colors.red
                    : Colors.grey.shade400,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _provinceError != null ? Colors.red : Colors.green,
                width: 1.5,
              ),
            ),
          ),
          value: _selectedProvince,
          hint: const Text("----เลือกจังหวัดป้ายทะเบียน----"),
          items: _provinces
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
          onChanged: (val) {
            setState(() {
              _selectedProvince = val;
              _provinceError =
                  null; // เคลียร์พาร์ทสีแดงแจ้งเตือนเมื่อกดยืนยันเลือก
            });
          },
        ),
        if (_provinceError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _provinceError!,
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green, width: 1.5),
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green, width: 1.5),
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
        side: BorderSide(),
      ),
      child: Text(text, style: const TextStyle(color: Colors.black)),
    );
  }
}
