import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lu_360/screens/home_screen.dart';
import 'package:lu_360/screens/login_screen.dart';
import 'package:lu_360/services/auth_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize shared preferences and check the flag
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  await Supabase.initialize(
    url: 'https://jocblproxhowcfqmruyl.supabase.co',
    anonKey: 'sb_publishable_fJBS1prJY9-69396N4emqg_G215K6If',
  );

  // 2. Pass the flag to app
  runApp(MyApp(hasSeenOnboarding: hasSeenOnboarding));
}

class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding;

  // 3. Require the flag in the constructor
  const MyApp({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // 4. Decide which screen to show first
      home: hasSeenOnboarding ? const AuthGate() : const OnboardingScreen(),
    );
  }
}