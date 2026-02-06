import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/schedule.dart';

class ScheduleService {
  final _client = Supabase.instance.client;

  Future<List<Schedule>> getScheduleByDay(String day) async {
    final response = await _client
        .from('classes')
        .select()
        .eq('day', day)
        .order('start_time');

    return response.map<Schedule>((e) => Schedule.fromMap(e)).toList();
  }
}
//goes to schedule page