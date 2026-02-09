import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lu_360/services/auth_service.dart';

import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  final authService = AuthService();

  void logOut() async{
    await authService.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E88E5), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),

            // ================= 1. PROFILE HEADER =================
            Center(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 65,
                      backgroundImage: NetworkImage('https://i.pravatar.cc/300'), // Replace with local asset if needed
                    ),
                  ),
                  Positioned(
                    bottom: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E88E5),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FutureBuilder<String>(
              future: authService.getUserName(),
              builder: (context, snapshot) {
                return Text(
                  '${snapshot.data ?? "..."}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                );
              },
            ),
            const SizedBox(height: 4),
            const Text(
              "Computer Science & Engineering",
              style: TextStyle(fontSize: 15, color: Colors.blueGrey, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 40),

            // ================= 2. ACCOUNT SETTINGS LIST =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ACCOUNT SETTINGS",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSettingsTile(Icons.person, "Personal Information", () {}),
                        _buildDivider(),
                        _buildSettingsTile(Icons.notifications, "Notifications", () {}),
                        _buildDivider(),
                        _buildSettingsTile(Icons.security, "Security & Privacy", () {}),
                        _buildDivider(),
                        _buildSettingsTile(Icons.help, "Help & Support", () {}),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ================= 3. LOG OUT BUTTON =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: logOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFF1F1), // Light red background
                  foregroundColor: Colors.red, // Red text/icon color
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 65),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, size: 22),
                    SizedBox(width: 12),
                    Text("Log Out", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Helper Widget for Settings Items
  Widget _buildSettingsTile(IconData icon, String title, VoidCallback? onTap, {Widget? trailing}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.blueGrey, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 16),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, color: Colors.black26, size: 16),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.05), indent: 20, endIndent: 20);
  }
}