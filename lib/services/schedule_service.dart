import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/schedule.dart';

class ScheduleService {
  final _supabase = Supabase.instance.client;

  Future<List<Schedule>> getScheduleByDay({
    required String dayName,
    required String batch,
    required String section
  }) async {
    try {
      final response = await _supabase
          .from('schedule')
          .select('*, rooms(floor)')
          .eq('day', dayName)    // Must match "Sunday", "Monday", etc.
          .eq('batch', batch)    // Filters for "61"
          .eq('section', section) // Filters for "E"
          .order('start_time', ascending: true);

      // ADD THIS PRINT:
      print("SUPABASE RAW RESPONSE: $response");

      return (response as List).map((item) => Schedule.fromMap(item)).toList();
    } catch (e) {
      throw Exception("Failed to fetch schedule: $e");
    }
  }
}