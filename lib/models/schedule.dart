import 'package:flutter/material.dart';

class Schedule {
  final String courseCode;
  final String teacherName;
  final String day;
  final String startTime;
  final String endTime;
  final String roomNo;
  final bool isOnline;

  Schedule({
    required this.courseCode,
    required this.teacherName,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.roomNo,
    required this.isOnline,
  });

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      courseCode: map['course_code'] ?? 'No Code', // Matches table
      teacherName: map['teacher_name'] ?? 'TBA',    // Matches table
      day: map['day'] ?? '',
      startTime: map['start_time'] ?? '',
      endTime: map['end_time'] ?? '',
      roomNo: map['room_no'] ?? 'TBA',             // NOT 'location'
      isOnline: map['is_online'] ?? false,
    );
  }

  // UI Helper: Generates a color based on the course code string
  Color get color {
    final int hash = courseCode.hashCode;
    final List<Color> colors = [Colors.blue, Colors.purple, Colors.orange, Colors.teal, Colors.pink];
    return colors[hash.abs() % colors.length];
  }
}