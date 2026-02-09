import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lu_360/screens/home_screen.dart';
import 'package:lu_360/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://jocblproxhowcfqmruyl.supabase.co',
    anonKey: 'sb_publishable_fJBS1prJY9-69396N4emqg_G215K6If',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}
