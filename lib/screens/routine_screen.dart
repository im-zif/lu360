import 'package:flutter/material.dart';

class RoutineScreen extends StatelessWidget {
  const RoutineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

    );
  }
}
class NextClass {
  final String courseCode;
  final String title;
  final String day;
  final String startTime;
  final String endTime;
  final String location;
  final String teacher;
  final String image;
  final Color color;

  NextClass({
    required this.courseCode,
    required this.title,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.teacher,
    required this.image,
    required this.color,
  });

  factory NextClass.fromMap(Map<String, dynamic> map) {
    Color color;
    switch (map['color']) {
      case 'green':
        color = Colors.green;
        break;
      case 'purple':
        color = Colors.purple;
        break;
      case 'orange':
        color = Colors.orange;
        break;
      default:
        color = Colors.blue;
    }

    return NextClass(
      courseCode: map['course_code'] ?? '',
      title: map['title'] ?? '',
      day: map['day'] ?? '',
      startTime: map['start_time'] ?? '',
      endTime: map['end_time'] ?? '',
      location: map['location'] ?? '',
      teacher: map['teacher'] ?? '',
      image: map['image'] ?? '',
      color: color,
    );
  }
}
