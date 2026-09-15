// features/rider/register_rider2.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_app/main_login.dart';
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
  static const Color _primary = Color(0xFF16A34A);
  static const Color _primaryDark = Color(0xFF0F7A38);
  static const Color _accent = Color(0xFFEA7C1E);
  static const Color _bg = Color(0xFFF5F6F8);
  static const Color _textDark = Color(0xFF1E1E24);
  static const Color _textMuted = Color(0xFF8A8D93);
  static const Color _danger = Color(0xFFE53935);

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final FacultyService _facultyService = FacultyService();
  final MajorService _majorService = MajorService();
  final RiderService riderService = RiderService();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _licensePlateController = TextEditingController();

  List<FacultyModel> _faculties = [];
  List<MajorModel> _majors = [];

  int? _selectedFacultyId;
  int? _selectedMajorId;
  String? _selectedProvince;

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
  String? _provinceError;

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

    if (widget.savedPlate != null && widget.savedPlate!.isNotEmpty) {
      final oldPlate = widget.savedPlate!;
      String detectedProvince = "";

      for (var province in _provinces) {
        if (oldPlate.endsWith(" " + province) || oldPlate.endsWith(province)) {
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

  Future<void> _pickImage(int type) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: _primary),
                ),
                title: const Text(
                  "ถ่ายรูป",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 75,
                    maxWidth: 1024,
                    maxHeight: 1024,
                  );
                  if (image != null) _setImagePath(type, File(image.path));
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library, color: _primary),
                ),
                title: const Text(
                  "เลือกจากแกลเลอรี่",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 75,
                    maxWidth: 1024,
                    maxHeight: 1024,
                  );
                  if (image != null) _setImagePath(type, File(image.path));
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _setImagePath(int type, File file) {
    setState(() {
      if (type == 0) {
        _studentCardImage = file;
        _studentCardError = null;
      } else if (type == 1) {
        _drivingLicenseImage = file;
        _drivingLicenseError = null;
      } else if (type == 2) {
        _vehicleImage = file;
        _vehicleImageError = null;
      }
    });
  }

  String? _validateImage(File? file, String fieldName) {
    if (file == null) return "กรุณาแนบ" + fieldName;
    final ext = file.path.split('.').last.toLowerCase();
    if (ext != 'jpg' && ext != 'jpeg' && ext != 'png') {
      return fieldName + " ต้องเป็น .jpg หรือ .png เท่านั้น";
    }
    final sizeInBytes = file.lengthSync();
    if (sizeInBytes > 2 * 1024 * 1024) {
      return fieldName + " ต้องมีขนาดไม่เกิน 2MB";
    }
    return null;
  }

  Future<void> _onRegister() async {
    setState(() {
      _studentCardError = _validateImage(_studentCardImage, "รูปบัตรนักศึกษา");
      _drivingLicenseError = _validateImage(
        _drivingLicenseImage,
        "รูปใบขับขี่",
      );
      _vehicleImageError = _validateImage(_vehicleImage, "รูปรถ");
    });

    final isFormValid = formKey.currentState?.validate() ?? false;

    if (!isFormValid ||
        _studentCardError != null ||
        _drivingLicenseError != null ||
        _vehicleImageError != null) {
      return;
    }

    setState(() => _isRegistering = true);

    try {
      final plateNumber = _licensePlateController.text.trim();
      final finalVehiclePlate = plateNumber + " " + _selectedProvince!;

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

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainLogin()),
          (route) => false,
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  InputDecoration _inputDecoration({String hint = "", Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _danger, width: 1.6),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 14),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: _textDark,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }

  Widget _fieldError(String? message) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 14, color: _danger),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _danger, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({required IconData icon, required String title}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, left: 2),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _textDark,
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    Widget dot({
      required bool active,
      required bool done,
      required IconData icon,
      required String label,
    }) {
      return Column(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (active || done) ? _primary : Colors.grey[300],
              shape: BoxShape.circle,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: _primary.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              done ? Icons.check_rounded : icon,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: (active || done) ? FontWeight.w700 : FontWeight.w500,
              color: (active || done) ? _textDark : _textMuted,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          dot(
            active: false,
            done: true,
            icon: Icons.person_outline_rounded,
            label: "ข้อมูลส่วนตัว",
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Container(height: 2, color: _primary.withOpacity(0.5)),
            ),
          ),
          dot(
            active: true,
            done: false,
            icon: Icons.two_wheeler_rounded,
            label: "หลักฐานและรถ",
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> getFormData() {
      final currentPlateStr = _licensePlateController.text.trim();
      final fullPlateWithProv = _selectedProvince != null
          ? currentPlateStr + " " + _selectedProvince!
          : currentPlateStr;

      return {
        'facultyId': _selectedFacultyId,
        'majorId': _selectedMajorId,
        'plate': fullPlateWithProv,
        'studentCard': _studentCardImage,
        'drivingLicense': _drivingLicenseImage,
        'vehicleImage': _vehicleImage,
      };
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        Navigator.pop(context, getFormData());
      },
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: _bg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: _textDark,
              ),
            ),
            onPressed: () => Navigator.pop(context, getFormData()),
          ),
          title: const Text(
            'สมัครผู้จัดส่ง',
            style: TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        body: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(color: Colors.white, child: _buildStepIndicator()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(
                        icon: Icons.school_outlined,
                        title: "ข้อมูลสถานศึกษา",
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("คณะ (Faculty)"),
                            _isLoadingFaculty
                                ? const LinearProgressIndicator(color: _primary)
                                : DropdownButtonFormField<int>(
                                    value: _selectedFacultyId,
                                    decoration: _inputDecoration(
                                      hint: "----เลือกคณะ----",
                                    ),
                                    validator: (val) =>
                                        val == null ? "กรุณาเลือกคณะ" : null,
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
                                      if (val != null)
                                        _loadMajors(val, restoreMajorId: false);
                                    },
                                  ),

                            _buildLabel("สาขาวิชา (Major)"),
                            _isLoadingMajor
                                ? const LinearProgressIndicator(color: _primary)
                                : DropdownButtonFormField<int>(
                                    value: _selectedMajorId,
                                    decoration: _inputDecoration(
                                      hint: "----เลือกสาขา----",
                                    ),
                                    validator: (val) =>
                                        val == null ? "กรุณาเลือกสาขา" : null,
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
                                        : (val) => setState(
                                            () => _selectedMajorId = val,
                                          ),
                                  ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      _sectionHeader(
                        icon: Icons.assignment_turned_in_outlined,
                        title: "หลักฐานประกอบการสมัคร",
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildUploadBox(
                              "บัตรนักศึกษา (Student ID Card)",
                              "รูปถ่ายบัตรนักศึกษา",
                              Icons.badge_outlined,
                              _studentCardImage,
                              () => _pickImage(0),
                              errorText: _studentCardError,
                            ),
                            const SizedBox(height: 16),
                            _buildUploadBox(
                              "ใบขับขี่ (Driving License)",
                              "รูปถ่ายใบขับขี่รถยนต์/จักรยานยนต์",
                              Icons.drive_eta_outlined,
                              _drivingLicenseImage,
                              () => _pickImage(1),
                              errorText: _drivingLicenseError,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      _sectionHeader(
                        icon: Icons.two_wheeler_outlined,
                        title: "ข้อมูลยานพาหนะ",
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("เลขทะเบียนรถ (License Plate)"),
                            TextFormField(
                              controller: _licensePlateController,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: _inputDecoration(
                                hint: "เช่น 1กข 1234",
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty)
                                  return "กรุณากรอกเลขทะเบียนรถ";
                                if (!RegExp(
                                  r'^[a-zA-Z\u0E00-\u0E7F0-9 ]+$',
                                ).hasMatch(value)) {
                                  return "ต้องเป็นภาษาไทย อังกฤษ หรือตัวเลขเท่านั้น";
                                }
                                if (value.length < 2 || value.length > 15)
                                  return "ความยาวทะเบียนรถไม่ถูกต้อง";
                                return null;
                              },
                            ),

                            _buildLabel("จังหวัดป้ายทะเบียน (Province)"),
                            DropdownButtonFormField<String>(
                              value: _selectedProvince,
                              decoration: _inputDecoration(
                                hint: "----เลือกจังหวัด----",
                              ),
                              validator: (val) => val == null
                                  ? "กรุณาเลือกจังหวัดทะเบียนรถ"
                                  : null,
                              items: _provinces
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedProvince = val),
                            ),
                            const SizedBox(height: 16),

                            _buildUploadBox(
                              "รูปถ่ายรถ (Vehicle Image)",
                              "รูปรถที่ใช้จัดส่ง",
                              Icons.motorcycle_outlined,
                              _vehicleImage,
                              () => _pickImage(2),
                              errorText: _vehicleImageError,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          "กรุณาตรวจสอบข้อมูลให้ถูกต้องก่อนกดสมัคร",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, color: _textMuted),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, getFormData()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textMuted,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        "ย้อนกลับ",
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [_primary, _primaryDark],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isRegistering ? null : _onRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isRegistering
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "สมัครผู้จัดส่ง",
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadBox(
    String label,
    String subtitle,
    IconData defaultIcon,
    File? selectedFile,
    VoidCallback onTap, {
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) _buildLabel(label),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: selectedFile != null
                  ? Colors.white
                  : const Color(0xFFF0F1F3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: errorText != null
                    ? _danger
                    : (selectedFile != null
                          ? _primary.withOpacity(0.4)
                          : Colors.grey.shade300),
                width: errorText != null ? 1.5 : 1.2,
              ),
            ),
            child: selectedFile != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(selectedFile, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 14,
                                color: _primary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "เปลี่ยนรูป",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(defaultIcon, color: _primary, size: 24),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "แตะเพื่ออัปโหลด " + subtitle,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "รองรับ .jpg, .png ขนาดไม่เกิน 2MB",
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        _fieldError(errorText),
      ],
    );
  }
}
