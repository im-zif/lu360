import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _selectedBatch;
  String? _selectedSection;

  // 1. Updated these lists to include all your actual batches and sections
  final List<String> _batches = ["60", "61", "62", "63", "64", "65", "66", "67", "68"];
  final List<String> _sections = ["A", "B", "C", "D", "E", "F", "G", "H", "I"];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // Load saved data when the screen opens
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBatch = prefs.getString('selected_batch');
    final savedSection = prefs.getString('selected_section');

    setState(() {
      // 2. Added safety checks (.contains) to prevent the Dropdown crash!
      if (savedBatch != null && _batches.contains(savedBatch)) {
        _selectedBatch = savedBatch;
      }
      if (savedSection != null && _sections.contains(savedSection)) {
        _selectedSection = savedSection;
      }
    });
  }

  // Save data instantly when the user changes a dropdown
  Future<void> _savePreference(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Schedule Preferences",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          const Text(
            "Set your batch and section so the Home screen shows your correct upcoming class.",
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // --- BATCH DROPDOWN ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedBatch,
                hint: const Text("Select your Batch"),
                isExpanded: true,
                items: _batches.map((String batch) {
                  return DropdownMenuItem(
                    value: batch,
                    child: Text("Batch $batch"),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedBatch = newValue);
                    _savePreference('selected_batch', newValue);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // --- SECTION DROPDOWN ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSection,
                hint: const Text("Select your Section"),
                isExpanded: true,
                items: _sections.map((String section) {
                  return DropdownMenuItem(
                    value: section,
                    child: Text("Section $section"),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedSection = newValue);
                    _savePreference('selected_section', newValue);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}