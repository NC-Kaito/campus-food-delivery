// features/restaurant/openday_rest.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/restaurant_opening_hour_model.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/features/restaurant/restaurant_navbar.dart';
import 'package:flutter_app/global_data.dart';
import 'package:flutter_app/core/network/dio_client.dart';

class OpendayRest extends StatefulWidget {
  const OpendayRest({super.key});

  @override
  State<OpendayRest> createState() => _OpendayRestState();
}

class _OpendayRestState extends State<OpendayRest> {
  static const Color _primary = Color(0xFF16A34A);
  static const Color _primaryDark = Color(0xFF0F7A38);
  static const Color _accent = Color(0xFFEA7C1E);
  static const Color _bg = Color(0xFFF5F6F8);
  static const Color _textDark = Color(0xFF1E1E24);
  static const Color _textMuted = Color(0xFF8A8D93);
  static const Color _danger = Color(0xFFE53935);

  final RestaurantService restaurantService = RestaurantService();
  RestaurantModel? restaurantModel;

  late List<RestaurantOpeningHourModel> _openingHours;
  String? _openingHoursError;
  final GlobalKey _openingHoursKey = GlobalKey();

  List<RestaurantDayOfWeek> _tempSelectedDays = [];
  TimeOfDay _slotOpenTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _slotCloseTime = const TimeOfDay(hour: 18, minute: 0);

  String? _editingGroupKey;
  List<RestaurantDayOfWeek> _originalEditingDays = [];

  bool _isLoading = false;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOpeningHours();
  }

  Future<void> _fetchOpeningHours() async {
    try {
      final result = await restaurantService.getRestaurantByUsername(
        GlobalData.usernameRestaurant,
      );

      if (mounted) {
        setState(() {
          restaurantModel = result;
          final dbHours = result?.openingHours ?? [];

          _openingHours = RestaurantDayOfWeek.values.map((day) {
            RestaurantOpeningHourModel? existing;
            for (var h in dbHours) {
              if (h.dayOfWeek == day) {
                existing = h;
                break;
              }
            }

            if (existing != null) {
              return existing.copyWith(closed: false);
            } else {
              return RestaurantOpeningHourModel(
                dayOfWeek: day,
                opentime: const TimeOfDay(hour: 8, minute: 0),
                closetime: const TimeOfDay(hour: 18, minute: 0),
                open: true,
              );
            }
          }).toList();

          _isInitialLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  Future<void> _syncToDatabase(String successMessage) async {
    final validHours = _openingHours.where((h) => !h.open).toList();
    setState(() => _isLoading = true);

    try {
      if (restaurantModel != null) {
        final Map<String, dynamic> updatePayload = {
          "username": restaurantModel!.username,
          "password": restaurantModel!.password,
          "restaurantname": restaurantModel!.restaurantName,
          "statusopen": restaurantModel!.statusOpen,
          "restaurantimage": restaurantModel!.restaurantImage ?? "",
          "imagecardid": restaurantModel!.imagecardid ?? "",
          "latitude": restaurantModel!.latitude,
          "longitude": restaurantModel!.longitude,
          "openingHours": validHours.map((e) => e.toJson()).toList(),
          "typeid": restaurantModel!.typerestaurantId,
          "ownerfirstname": restaurantModel!.ownerFirstName,
          "ownerlastname": restaurantModel!.ownerLastName,
          "email": restaurantModel!.email,
          "phone": restaurantModel!.phone,
        };

        final response = await DioClient.dio.post(
          "/v1/restaurant/updateProfileRestaurant",
          data: updatePayload,
        );

        if (response.statusCode == 200 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: _primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("เกิดข้อผิดพลาด: $e"),
            backgroundColor: _danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startEdit(
    String groupKey,
    List<RestaurantOpeningHourModel> hoursInGroup,
  ) {
    setState(() {
      _editingGroupKey = groupKey;
      _originalEditingDays = hoursInGroup.map((h) => h.dayOfWeek).toList();
      _tempSelectedDays = List.from(_originalEditingDays);
      _slotOpenTime = hoursInGroup.first.opentime;
      _slotCloseTime = hoursInGroup.first.closetime;
    });

    final ctx = _openingHoursKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.15,
      );
    }
  }

  void _cancelEdit() {
    setState(() {
      _editingGroupKey = null;
      _originalEditingDays.clear();
      _tempSelectedDays.clear();
      _slotOpenTime = const TimeOfDay(hour: 8, minute: 0);
      _slotCloseTime = const TimeOfDay(hour: 18, minute: 0);
    });
  }

  Future<void> _addTimeSlot() async {
    if (_tempSelectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("กรุณาเลือกวันอย่างน้อย 1 วัน"),
          backgroundColor: _danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    List<String> duplicateDayNames = [];
    for (var day in _tempSelectedDays) {
      final existingHour = _openingHours.firstWhere((h) => h.dayOfWeek == day);
      if (!existingHour.open && !_originalEditingDays.contains(day)) {
        duplicateDayNames.add(day.labelTh);
      }
    }

    if (duplicateDayNames.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: _accent),
              SizedBox(width: 8),
              Text(
                "วันซ้ำกัน",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            "ไม่สามารถบันทึกได้เนื่องจาก วัน${duplicateDayNames.join(', วัน')} มีการตั้งเวลาทำการอยู่แล้ว หากต้องการเปลี่ยนเวลา กรุณาลบรายการเดิมออกก่อน",
            style: const TextStyle(color: _textDark, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "รับทราบ",
                style: TextStyle(color: _primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      if (_editingGroupKey != null) {
        for (var oldDay in _originalEditingDays) {
          final index = _openingHours.indexWhere((h) => h.dayOfWeek == oldDay);
          if (index != -1) {
            _openingHours[index] = _openingHours[index].copyWith(closed: true);
          }
        }
      }

      for (var day in _tempSelectedDays) {
        final index = _openingHours.indexWhere((h) => h.dayOfWeek == day);
        if (index != -1) {
          _openingHours[index] = _openingHours[index].copyWith(
            opentime: _slotOpenTime,
            closetime: _slotCloseTime,
            closed: false,
          );
        }
      }
      _cancelEdit();
      _openingHoursError = null;
    });

    await _syncToDatabase("บันทึกการตั้งค่าสำเร็จ");
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _danger.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: _danger,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: _textMuted),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textMuted,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "ยกเลิก",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _danger,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "ลบ",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
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

  Future<void> _confirmAndRemoveTimeSlot(
    List<RestaurantOpeningHourModel> hoursInGroup,
  ) async {
    final confirmed = await _showConfirmDialog(
      title: "ยืนยันการลบ?",
      message: "คุณต้องการลบรายการเวลาทำการนี้ใช่หรือไม่?",
    );

    if (confirmed == true) {
      await _removeGroupedTimeSlot(hoursInGroup);
    }
  }

  Future<void> _removeGroupedTimeSlot(
    List<RestaurantOpeningHourModel> hoursInGroup,
  ) async {
    final validHoursCount = _openingHours.where((h) => !h.open).length;

    if (validHoursCount <= hoursInGroup.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("กรุณาเปิดร้านอย่างน้อย 1 วัน"),
          backgroundColor: _danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      for (var item in hoursInGroup) {
        final index = _openingHours.indexWhere(
          (h) => h.dayOfWeek == item.dayOfWeek,
        );
        if (index != -1) {
          _openingHours[index] = _openingHours[index].copyWith(closed: true);
        }
      }
      final String groupKey =
          "${hoursInGroup.first.opentime.hour}:${hoursInGroup.first.opentime.minute}-${hoursInGroup.first.closetime.hour}:${hoursInGroup.first.closetime.minute}";
      if (_editingGroupKey == groupKey) {
        _cancelEdit();
      }
    });

    await _syncToDatabase("ลบช่วงเวลาสำเร็จ");
  }

  void _selectTimeScrollWheel(
    BuildContext context, {
    required bool isOpenTime,
  }) {
    final initialTime = isOpenTime ? _slotOpenTime : _slotCloseTime;
    Duration tempDuration = Duration(
      hours: initialTime.hour,
      minutes: initialTime.minute,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: SizedBox(
            height: 380,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "ยกเลิก",
                          style: TextStyle(
                            color: _textMuted,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        isOpenTime ? "เลือกเวลาเปิดทำการ" : "เลือกเวลาปิดทำการ",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            final newTime = TimeOfDay(
                              hour: tempDuration.inHours,
                              minute: tempDuration.inMinutes % 60,
                            );
                            if (isOpenTime) {
                              _slotOpenTime = newTime;
                            } else {
                              _slotCloseTime = newTime;
                            }
                          });
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "ตกลง",
                          style: TextStyle(
                            color: _primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1),
                Expanded(
                  child: Center(
                    child: Transform.scale(
                      scale: 1.3,
                      child: CupertinoTimerPicker(
                        mode: CupertinoTimerPickerMode.hm,
                        initialTimerDuration: tempDuration,
                        onTimerDurationChanged: (Duration newDuration) {
                          tempDuration = newDuration;
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getShortThDayName(RestaurantDayOfWeek day) {
    switch (day) {
      case RestaurantDayOfWeek.monday:
        return "จ.";
      case RestaurantDayOfWeek.tuesday:
        return "อ.";
      case RestaurantDayOfWeek.wednesday:
        return "พ.";
      case RestaurantDayOfWeek.thursday:
        return "พฤ.";
      case RestaurantDayOfWeek.friday:
        return "ศ.";
      case RestaurantDayOfWeek.saturday:
        return "ส.";
      case RestaurantDayOfWeek.sunday:
        return "อา.";
    }
  }

  List<MapEntry<String, List<RestaurantOpeningHourModel>>>
  _getGroupedOpeningHours() {
    final Map<String, List<RestaurantOpeningHourModel>> groups = {};
    for (var hour in _openingHours) {
      if (hour.open) continue;

      final String timeKey =
          "${hour.opentime.hour}:${hour.opentime.minute}-${hour.closetime.hour}:${hour.closetime.minute}";
      if (!groups.containsKey(timeKey)) {
        groups[timeKey] = [];
      }
      groups[timeKey]!.add(hour);
    }
    return groups.entries.toList();
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

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return const Scaffold(
        backgroundColor: _bg,
        appBar: RestaurantNavbar(title: 'ตั้งค่าวันเปิด-ปิดร้าน'),
        body: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    final groupedOpeningHours = _getGroupedOpeningHours();

    return Scaffold(
      backgroundColor: _bg,
      appBar: const RestaurantNavbar(title: ''),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
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
                      child: const Icon(
                        Icons.access_time_filled_outlined,
                        color: _accent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "กำหนดเวลาทำการของร้าน",
                      style: TextStyle(
                        color: _textDark,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                key: _openingHoursKey,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "เลือกวันที่เปิดร้านค้า (Open Date)",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _textDark,
                          ),
                        ),
                        if (_editingGroupKey != null)
                          const Text(
                            "กำลังแก้ไข",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: RestaurantDayOfWeek.values.map((day) {
                        final isSelected = _tempSelectedDays.contains(day);
                        final existingHour = _openingHours.firstWhere(
                          (h) => h.dayOfWeek == day,
                        );

                        final isAlreadySet =
                            !existingHour.open &&
                            !_originalEditingDays.contains(day);

                        return GestureDetector(
                          onTap: (isAlreadySet || _isLoading)
                              ? null
                              : () {
                                  setState(() {
                                    if (isSelected) {
                                      _tempSelectedDays.remove(day);
                                    } else {
                                      _tempSelectedDays.add(day);
                                    }
                                  });
                                },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isAlreadySet
                                  ? Colors.grey.shade400
                                  : (isSelected ? _accent : Colors.white),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isAlreadySet
                                    ? Colors.grey.shade400
                                    : (isSelected
                                          ? _accent
                                          : Colors.grey.shade300),
                                width: 1.5,
                              ),
                              boxShadow: isSelected && !isAlreadySet
                                  ? [
                                      BoxShadow(
                                        color: _accent.withOpacity(0.3),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Text(
                              _getShortThDayName(day),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isAlreadySet || isSelected
                                    ? Colors.white
                                    : _textDark,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      "ระบุช่วงเวลาทำการ (Open time - Close time)",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "  เวลาเปิด",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const SizedBox(width: 24),
                        const Expanded(
                          child: Text(
                            "  เวลาปิด",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: _primary,
                            ),
                            label: Text(
                              '${_slotOpenTime.hour.toString().padLeft(2, '0')}:${_slotOpenTime.minute.toString().padLeft(2, '0')} น.',
                            ),
                            onPressed: _isLoading
                                ? null
                                : () => _selectTimeScrollWheel(
                                    context,
                                    isOpenTime: true,
                                  ),
                            // 🎯 ปรับค่า BorderRadius ให้มีความเหลี่ยมขึ้น (เช่น 10 แทนที่จะเป็น pill โค้งมนวงรี)
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text("ถึง"),
                        ),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: _danger,
                            ),
                            label: Text(
                              '${_slotCloseTime.hour.toString().padLeft(2, '0')}:${_slotCloseTime.minute.toString().padLeft(2, '0')} น.',
                            ),
                            onPressed: _isLoading
                                ? null
                                : () => _selectTimeScrollWheel(
                                    context,
                                    isOpenTime: false,
                                  ),
                            // 🎯 ปรับค่า BorderRadius ให้มีความเหลี่ยมขึ้นเช่นกันครับ
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _addTimeSlot,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: const Text(
                          "บันทึก",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              Padding(
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
                      child: const Icon(
                        Icons.list_alt_rounded,
                        color: _accent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "รายการเวลาเปิดทำการของร้าน",
                      style: TextStyle(
                        color: _textDark,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
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
                    groupedOpeningHours.isNotEmpty
                        ? ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: groupedOpeningHours.length,
                            itemBuilder: (context, index) {
                              final entry = groupedOpeningHours[index];
                              final List<RestaurantOpeningHourModel>
                              hoursInGroup = entry.value;
                              final firstItem = hoursInGroup.first;

                              final String currentGroupKey = entry.key;
                              final bool isEditingThisGroup =
                                  _editingGroupKey == currentGroupKey;

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isEditingThisGroup
                                      ? _primary.withOpacity(0.04)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isEditingThisGroup
                                        ? _primary.withOpacity(0.8)
                                        : Colors.grey.shade200,
                                    width: isEditingThisGroup ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Wrap(
                                            spacing: 4,
                                            children: hoursInGroup.map((h) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: _primary.withOpacity(
                                                    0.12,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  _getShortThDayName(
                                                    h.dayOfWeek,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: _primaryDark,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              '${firstItem.opentime.hour.toString().padLeft(2, '0')}:${firstItem.opentime.minute.toString().padLeft(2, '0')} น. - ${firstItem.closetime.hour.toString().padLeft(2, '0')}:${firstItem.closetime.minute.toString().padLeft(2, '0')} น.',
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w500,
                                                color: _textDark,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isEditingThisGroup)
                                          TextButton(
                                            onPressed: _isLoading
                                                ? null
                                                : _cancelEdit,
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              minimumSize: const Size(0, 30),
                                            ),
                                            child: const Text(
                                              "ยกเลิก",
                                              style: TextStyle(
                                                color: _textMuted,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        else
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              color: _accent,
                                              size: 20,
                                            ),
                                            onPressed: _isLoading
                                                ? null
                                                : () => _startEdit(
                                                    currentGroupKey,
                                                    hoursInGroup,
                                                  ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: _danger,
                                            size: 20,
                                          ),
                                          onPressed: _isLoading
                                              ? null
                                              : () => _confirmAndRemoveTimeSlot(
                                                  hoursInGroup,
                                                ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            alignment: Alignment.center,
                            child: Text(
                              "- ยังไม่ได้ตั้งเวลาทำการ -",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade400,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                    _fieldError(_openingHoursError),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
