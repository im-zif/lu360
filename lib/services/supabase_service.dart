import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../screens/home_screen.dart'; // if needed for NextClass
import '../models/schedule.dart';
// import '../models/next_class.dart';
import '../screens/routine_screen.dart';

class SupabaseService {
  final _client = Supabase.instance.client;

  Future<NextClass?> getNextClass() async {
    final now = DateTime.now();

    // Get today’s weekday name
    final dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri"];
    String today = dayNames[now.weekday - 1]; // Mon=0

    // Current time as HH:MM
    final currentTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    final response = await _client
        .from('classes')
        .select()
        .eq('day', today)
        .gte('start_time', currentTime)
        .order('start_time')
        .limit(1);

    if (response.isEmpty) return null;

    return NextClass.fromMap(response.first);
  }
}
