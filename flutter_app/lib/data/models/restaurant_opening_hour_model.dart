import 'package:flutter/material.dart';

enum RestaurantDayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  /// แปลงเป็น string ให้ตรงกับ Java enum DayOfWeek เช่น "MONDAY"
  String toApiValue() => name.toUpperCase();

  /// แปลงจาก string ที่ backend ส่งมา เช่น "MONDAY" -> RestaurantDayOfWeek.monday
  static RestaurantDayOfWeek fromApiValue(String value) {
    return RestaurantDayOfWeek.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => throw ArgumentError('Unknown day of week: $value'),
    );
  }

  /// ชื่อวันภาษาไทยไว้ใช้แสดงผลใน UI
  String get labelTh {
    switch (this) {
      case RestaurantDayOfWeek.monday:
        return 'วันจันทร์';
      case RestaurantDayOfWeek.tuesday:
        return 'วันอังคาร';
      case RestaurantDayOfWeek.wednesday:
        return 'วันพุธ';
      case RestaurantDayOfWeek.thursday:
        return 'วันพฤหัสบดี';
      case RestaurantDayOfWeek.friday:
        return 'วันศุกร์';
      case RestaurantDayOfWeek.saturday:
        return 'วันเสาร์';
      case RestaurantDayOfWeek.sunday:
        return 'วันอาทิตย์';
    }
  }
}

class RestaurantOpeningHourModel {
  final RestaurantDayOfWeek dayOfWeek;
  final TimeOfDay opentime;
  final TimeOfDay closetime;
  final bool open;

  const RestaurantOpeningHourModel({
    required this.dayOfWeek,
    required this.opentime,
    required this.closetime,
    required this.open,
  });

  factory RestaurantOpeningHourModel.fromJson(Map<String, dynamic> json) {
    return RestaurantOpeningHourModel(
      dayOfWeek: RestaurantDayOfWeek.fromApiValue(json['dayOfWeek'] as String),
      opentime: _timeOfDayFromString(json['opentime'] as String),
      closetime: _timeOfDayFromString(json['closetime'] as String),
      open: json['open'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek.toApiValue(),
      'opentime': _timeOfDayToString(opentime),
      'closetime': _timeOfDayToString(closetime),
      'open': open,
    };
  }

  RestaurantOpeningHourModel copyWith({
    RestaurantDayOfWeek? dayOfWeek,
    TimeOfDay? opentime,
    TimeOfDay? closetime,
    bool? closed,
  }) {
    return RestaurantOpeningHourModel(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      opentime: opentime ?? this.opentime,
      closetime: closetime ?? this.closetime,
      open: closed ?? this.open,
    );
  }

  /// แปลง "08:00:00" หรือ "08:00" -> TimeOfDay(8, 0)
  static TimeOfDay _timeOfDayFromString(String value) {
    final parts = value.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// แปลง TimeOfDay(8, 0) -> "08:00:00" ให้ตรง format LocalTime ฝั่ง Java
  static String _timeOfDayToString(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm:00';
  }
}
