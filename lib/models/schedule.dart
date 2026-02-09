import 'package:flutter/material.dart';

class Schedule {
  final String courseCode;
  final String teacherName;
  final String day;
  final String startTime;
  final String endTime;
  final String roomNo;
  final bool isOnline;
  final double floor;

  Schedule({
    required this.courseCode,
    required this.teacherName,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.roomNo,
    required this.isOnline,
    required this.floor,
  });

  factory Schedule.fromMap(Map<String, dynamic> map) {
    // Check if floor exists in the main map or the joined 'rooms' object
    var floorData = map['floor'] ?? (map['rooms'] != null ? map['rooms']['floor'] : null);

    double finalFloor = 0.0;
    if (floorData != null) {
      finalFloor = double.tryParse(floorData.toString()) ?? 0.0;
    }

    return Schedule(
      courseCode: map['course_code'] ?? 'No Code',
      teacherName: map['teacher_name'] ?? 'TBA',
      day: map['day'] ?? '',
      startTime: map['start_time'] ?? '',
      endTime: map['end_time'] ?? '',
      roomNo: map['room_no'] ?? 'TBA',
      isOnline: map['is_online'] ?? false,
      floor: finalFloor, // Now correctly receives 2.0 for RAB-302
    );
  }

  Color get color {
    final int hash = courseCode.hashCode;
    final List<Color> colors = [Colors.blue, Colors.purple, Colors.orange, Colors.teal, Colors.pink];
    return colors[hash.abs() % colors.length];
  }
}