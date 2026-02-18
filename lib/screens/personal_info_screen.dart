import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final supabase = SupabaseService();

  final nameController = TextEditingController();
  final majorController = TextEditingController();
  final phoneController = TextEditingController();

  String studentId = "";
  String email = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  // ================= LOAD DATA =================
  Future<void> loadProfile() async {
    final profile = await supabase.getProfile();

    if (profile != null) {
      nameController.text = profile['full_name'] ?? '';
      majorController.text = profile['major'] ?? '';
      phoneController.text = profile['phone'] ?? '';

      studentId = profile['student_id'] ?? '';
      email = profile['university_email'] ?? '';
    }

    setState(() => isLoading = false);
  }

  // ================= SAVE DATA =================
  Future<void> saveProfile() async {
    await supabase.updateProfile({
      'full_name': nameController.text.trim(),
      'major': majorController.text.trim(),
      'phone': phoneController.text.trim(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile Updated Successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),


      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2979FF), Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              "Personal Information",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              TextButton(
                onPressed: saveProfile,
                child: const Text(
                  "Save",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
            iconTheme: const IconThemeData(color: Colors.white),
          ),
        ),
      ),


      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ================= PROFILE IMAGE =================
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 60,
                      backgroundImage:
                      NetworkImage("https://i.pravatar.cc/300"),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2979FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  )
                ],
              ),
            ),


            const SizedBox(height: 30),

            // ================= ACADEMIC DETAILS =================
            const Text(
              "ACADEMIC DETAILS",
              style: TextStyle(
                  fontWeight: FontWeight.bold, letterSpacing: 1),
            ),

            const SizedBox(height: 10),

            _buildCard(
              child: Column(
                children: [
                  _editableField("Full Name", nameController),

                  _lockedField("Student ID", studentId),

                  _editableField("Major", majorController),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ================= CONTACT DETAILS =================
            const Text(
              "CONTACT DETAILS",
              style: TextStyle(
                  fontWeight: FontWeight.bold, letterSpacing: 1),
            ),

            const SizedBox(height: 10),

            _buildCard(
              child: Column(
                children: [
                  _lockedField("University Email", email),
                  _editableField("Phone Number", phoneController),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ================= DELETE ACCOUNT =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  "Delete Account",
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= CARD STYLE =================
  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: child,
      ),
    );
  }


  // ================= EDITABLE FIELD =================
  Widget _editableField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2979FF),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: const InputDecoration(
            isDense: true,
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFF2979FF),
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }


  // ================= LOCKED FIELD =================
  Widget _lockedField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2979FF),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.lock, size: 14, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value.isEmpty ? "Not Available" : value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const Divider(height: 30),
      ],
    );
  }
  }