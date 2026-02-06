import 'package:flutter/material.dart';

class Schedule {
  final String courseCode;
  final String title;
  final String day;
  final String startTime;
  final String endTime;
  final String location;
  final Color color;

  Schedule({
    required this.courseCode,
    required this.title,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.color,
  });

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      courseCode: map['course_code'],
      title: map['title'],
      day: map['day'],
      startTime: map['start_time'],
      endTime: map['end_time'],
      location: map['location'],
      color: _colorFromString(map['color']),
    );
  }

  static Color _colorFromString(String color) {
    switch (color) {
      case 'green':
        return Colors.green;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}
// goes to scedule service