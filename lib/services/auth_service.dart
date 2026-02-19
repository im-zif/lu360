import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {

  final SupabaseClient _supabase = Supabase.instance.client;

  //Sign in with email and password
  Future<AuthResponse> signInWithEmailPassword(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
        email: email,
        password: password
    );
  }

  //Sign up with email and password
  Future<AuthResponse> signUpWithEmailPassword(String email, String password) async {
    return await _supabase.auth.signUp(
        email: email,
        password: password
    );
  }

  //Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  //Get user email
  String? getCurrentUserEmail(){
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }

  //Ger user name
  Future<String> getUserName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return "Guest";

    final data = await Supabase.instance.client
        .from('profiles')
        .select('full_name')
        .eq('id', user.id)
        .single();

    return data['full_name'] ?? "User";
  }
  // Change Password
  Future<String?> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      // Step 1: Re-authenticate user
      await _supabase.auth.signInWithPassword(
        email: email,
        password: oldPassword,
      );

      // Step 2: Update password
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return null; // success
    } catch (e) {
      return e.toString(); // error message
    }
  }

  // Get User Role
  Future<String> getUserRole() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return "student";

    try {
      final data = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();
      return data['role']?.toString() ?? "student";
    } catch (e) {
      return "student";
    }
  }

  // Add Announcement (Admin Only)
  Future<void> addAnnouncement(String title, String subtitle) async {
    await _supabase.from('announcements').insert({
      'title': title,
      'subtitle': subtitle,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Get Announcements Stream
  Stream<List<Map<String, dynamic>>> getAnnouncementsStream() {
    return _supabase
        .from('announcements')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }


}