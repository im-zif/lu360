import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lu_360/screens/profile_screen.dart';
import 'package:lu_360/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'schedule_page.dart';
import 'map_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final authService = AuthService();

  Future<Map<String, dynamic>?> _getNextClass() async {
    final now = DateTime.now();
    final String currentDay = DateFormat('EEEE').format(now);
    final String currentTime = DateFormat('HH:mm:ss').format(now);

    try {
      final response = await supabase
          .from('schedule')
          .select()
          .eq('day', currentDay)
          .gt('start_time', currentTime)
          .order('start_time', ascending: true)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint("Error fetching class: $e");
      return null;
    }
  }

  String _formatTime(String time) {
    final DateTime dt = DateFormat("HH:mm:ss").parse(time);
    return DateFormat("h:mm a").format(dt);
  }

  String _getCountdown(String startTime) {
    final now = DateTime.now();
    final DateTime start = DateFormat("HH:mm:ss").parse(startTime);
    final DateTime target = DateTime(now.year, now.month, now.day, start.hour, start.minute);
    final difference = target.difference(now).inMinutes;
    return "Starts in $difference mins";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Clean Light Background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark, // Dark icons for light theme
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: const Icon(Icons.person, color: Colors.blueAccent),
          ),
        ),
        title: FutureBuilder<String>(
          future: authService.getUserName(),
          builder: (context, snapshot) {
            return Text(
              'Good Morning, ${snapshot.data ?? "..."}!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black87),
            onPressed: () {
              // Navigate to the ProfileScreen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= NEXT CLASS SECTION =================
            FutureBuilder<Map<String, dynamic>?>(
              future: _getNextClass(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildPlaceholderCard(true);
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return _buildNoClassCard();
                }

                final data = snapshot.data!;
                return _buildNextClassCard(
                  context,
                  subject: data['course_code'] ?? 'Unknown Course',
                  time: "${_formatTime(data['start_time'])} - ${_formatTime(data['end_time'])}",
                  location: data['room_no'] ?? 'TBA',
                  countdown: _getCountdown(data['start_time']),
                  building: "Building 7", // Example building
                );
              },
            ),

            const SizedBox(height: 30),

            // ================= SHORTCUTS =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _shortcutButton(
                  context,
                  icon: Icons.calendar_month,
                  label: "Full Schedule",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchedulePage())),
                ),
                _shortcutButton(
                  context,
                  icon: Icons.map_outlined,
                  label: "Campus Map",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen())),
                ),
                _shortcutButton(
                  context,
                  icon: Icons.search,
                  label: "Search",
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 35),

            // ================= ANNOUNCEMENTS =================
            const Text(
              "Announcements",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 15),
            _announcementTile(
              icon: Icons.campaign_outlined,
              title: "Library Extended Hours",
              subtitle: "The library will be open 24/7 for finals week.",
              time: "2 days ago",
            ),
            _announcementTile(
              icon: Icons.celebration_outlined,
              title: "Spring Fest This Friday",
              subtitle: "Join us for live music, food, and games!",
              time: "4 days ago",
            ),
            _announcementTile(
              icon: Icons.warning_amber_rounded,
              title: "Parking Lot C Closure",
              subtitle: "Lot C will be closed for maintenance on May 25th.",
              time: "1 week ago",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextClassCard(BuildContext context,
      {required String subject, required String time, required String location, required String countdown, required String building}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF144E57), Color(0xFF439A94)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(countdown, style: const TextStyle(color: Color(0xFF00BFA5), fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(subject, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(time, style: const TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text("$building, $location", style: const TextStyle(color: Colors.black45, fontSize: 15)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.location_on, size: 18),
                      label: const Text("View on Map"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shortcutButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: (MediaQuery.of(context).size.width - 70) / 3,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF1E88E5), size: 32),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _announcementTile({required IconData icon, required String title, required String subtitle, required String time}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF1F3F5), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.black54),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(time, style: const TextStyle(color: Colors.black38, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black26),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCard(bool isLoading) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : const Text("No Classes Today", style: TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildNoClassCard() => _buildPlaceholderCard(false);
}