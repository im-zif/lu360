import 'package:flutter/material.dart';
// import '../services/supabase_service.dart'; // Commented out for now

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {

  // final supabase = SupabaseService(); // Commented out for now
  List<Map<String, dynamic>> settings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    // Mock loading delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock data until you create table in Supabase
    final data = [
      {
        'id': 1,
        'category': 'General',
        'title': 'Push Notifications',
        'description': 'Receive push notifications',
        'icon': 'notifications',
        'enabled': true
      },
      {
        'id': 2,
        'category': 'General',
        'title': 'Email Alerts',
        'description': 'Receive email notifications',
        'icon': 'warning',
        'enabled': false
      },
      {
        'id': 3,
        'category': 'Schedule',
        'title': 'Event Reminders',
        'description': 'Remind me about events',
        'icon': 'schedule',
        'enabled': true
      },
    ];

    setState(() {
      settings = data;
      isLoading = false;
    });
  }

  IconData getIcon(String name) {
    switch (name) {
      case 'notifications':
        return Icons.notifications;
      case 'schedule':
        return Icons.access_time;
      case 'warning':
        return Icons.warning;
      case 'celebration':
        return Icons.celebration;
      default:
        return Icons.settings;
    }
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Group by category
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var item in settings) {
      grouped.putIfAbsent(item['category'], () => []);
      grouped[item['category']]!.add(item);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Notification Settings",
            style: TextStyle(color: Colors.black)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          ...grouped.entries.map((entry) {

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 20),

                Text(
                  entry.key.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 10),

                ...entry.value.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            getIcon(item['icon']),
                            color: Colors.blue,
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['description'],
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Switch(
                          value: item['enabled'],
                          onChanged: (value) async {
                            setState(() {
                              item['enabled'] = value;
                            });

                            // Commented out until table exists
                            // await supabase.updateNotification(item['id'], value);
                          },
                        )
                      ],
                    ),
                  );
                }).toList(),
              ],
            );
          }).toList(),

          const SizedBox(height: 30),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {},
            child: const Text(
              "Save Preferences",
              style: TextStyle(fontSize: 16),
            ),
          ),

          const SizedBox(height: 20),

          const Center(
            child: Text(
              "Changes may take a few minutes to sync across devices.",
              style: TextStyle(color: Colors.grey),
            ),
          )
        ],
      ),
    );
  }
}
