import 'package:flutter/material.dart';
import '../services/auth_service.dart';


class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {

  final oldPassword = TextEditingController();
  final newPassword = TextEditingController();

  void changePassword() {
    final authService = AuthService();

    Future<void> changePassword() async {

      final email = authService.getCurrentUserEmail();

      if (email == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("User not logged in")));
        return;
      }

      final error = await authService.changePassword(
        email: email,
        oldPassword: oldPassword.text.trim(),
        newPassword: newPassword.text.trim(),
      );

      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password Changed Successfully")),
        );

        oldPassword.clear();
        newPassword.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: $error")),
        );
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Security & Privacy")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: oldPassword,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Old Password"),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: newPassword,
              obscureText: true,
              decoration: const InputDecoration(labelText: "New Password"),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: changePassword,
              child: const Text("Change Password"),
            )
          ],
        ),
      ),
    );
  }
}
