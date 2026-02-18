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

  // =========================
  // GET USER PROFILE
  // =========================
  Future<Map<String, dynamic>?> getProfile() async {
    final user = _client.auth.currentUser;

    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle(); // safer than single()

    return response;
  }

  // =========================
  // UPDATE USER PROFILE
  // =========================
  Future<void> updateProfile(Map<String, dynamic> profile) async {
    final user = _client.auth.currentUser;

    if (user == null) return;

    await _client.from('profiles').upsert({
      'id': user.id,
      ...profile,
    });
  }
  // notification setting
  Future<List<Map<String, dynamic>>> getNotificationSettings() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('notification_settings')
        .select()
        .eq('user_id', user.id);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateNotification(String id, bool value) async {
    await _client
        .from('notification_settings')
        .update({'enabled': value})
        .eq('id', id);
  }

}
