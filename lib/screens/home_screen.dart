import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lu_360/screens/profile_screen.dart';
import 'package:lu_360/screens/settings_screen.dart';
import 'package:lu_360/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/minimap_preview.dart';
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
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final role = await authService.getUserRole();
    if (mounted) {
      setState(() {
        _isAdmin = (role == 'admin');
      });
    }
  }

  // ... _showAddAnnouncementDialog remains exactly the same ...
  void _showAddAnnouncementDialog() {
    final titleCtrl = TextEditingController();
    final subCtrl = TextEditingController();
    bool isPosting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("New Announcement"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Title")),
                TextField(controller: subCtrl, decoration: const InputDecoration(labelText: "Subtitle")),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: isPosting
                    ? null
                    : () async {
                  if (titleCtrl.text.isEmpty) return;
                  setDialogState(() => isPosting = true);

                  try {
                    await authService.addAnnouncement(titleCtrl.text, subCtrl.text);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Announcement Posted!"), backgroundColor: Colors.green),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setDialogState(() => isPosting = false);
                    }
                  }
                },
                child: isPosting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Post"),
              )
            ],
          );
        },
      ),
    );
  }

  // UPDATED: Now fetches based on user preferences
  Future<Map<String, dynamic>?> _getNextClass() async {
    final now = DateTime.now();
    final currentDay = DateFormat('EEEE').format(now);
    final currentTime = DateFormat('HH:mm:ss').format(now);

    try {
      // 1. Get the saved preferences
      final prefs = await SharedPreferences.getInstance();
      final preferredBatch = prefs.getString('selected_batch');
      final preferredSection = prefs.getString('selected_section');

      // 2. Start building the query
      var query = supabase
          .from('schedule')
          .select('*, rooms(building_name, floor)')
          .eq('day', currentDay)
          .gt('start_time', currentTime);

      // 3. Add filters if the user has saved them in settings
      // Note: Make sure 'batch' and 'section' match your Supabase column names
      if (preferredBatch != null && preferredBatch.isNotEmpty) {
        query = query.eq('batch', preferredBatch);
      }
      if (preferredSection != null && preferredSection.isNotEmpty) {
        query = query.eq('section', preferredSection);
      }

      // 4. Execute the query
      final response = await query.order('start_time', ascending: true).limit(1).maybeSingle();

      if (response != null) {
        final roomData = response['rooms'] as Map<String, dynamic>?;
        response['building_name'] = roomData?['building_name'] ?? 'Unknown Building';
        response['floor'] = double.tryParse(roomData?['floor']?.toString() ?? '0') ?? 0.0;
        response.remove('rooms');
      }

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
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
        onPressed: _showAddAnnouncementDialog,
        label: const Text("Post Update"),
        icon: const Icon(Icons.edit),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      )
          : null,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        // UPDATED: Profile Icon now routes to ProfileScreen
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: const Icon(Icons.person, color: Colors.blueAccent),
            ),
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
          // UPDATED: Settings Icon routes to SettingsScreen
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) {
                // When we return from Settings, refresh the Home page to fetch the new class
                setState(() {});
              });
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
                  building: data['building_name'] ?? 'Unknown Building',
                  floor: data['floor'] ?? 0.0,
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

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: authService.getAnnouncementsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text("No announcements yet.");
                }

                final announcements = snapshot.data!;
                return Column(
                  children: announcements.map((announcement) {
                    final date = DateTime.parse(announcement['created_at']);
                    final timeString = DateFormat('MMM d, h:mm a').format(date);

                    return _announcementTile(
                      icon: Icons.campaign_outlined,
                      title: announcement['title'],
                      subtitle: announcement['subtitle'] ?? "",
                      time: timeString,
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ... (The rest of your widgets: _buildNextClassCard, _shortcutButton, _announcementTile, _buildPlaceholderCard, _buildNoClassCard remain exactly the same) ...
  Widget _buildNextClassCard(BuildContext context, {required String subject, required String time, required String location, required String countdown, required String building, required double floor}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MiniMapPreview(roomId: location, floor: floor),
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
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => MapScreen(targetRoomId: location, targetFloor: floor)));
                      },
                      icon: const Icon(Icons.location_on, size: 18),
                      label: const Text("View on Map"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )
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
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF1F3F5), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.black54)),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : const Text("No Classes Today", style: TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildNoClassCard() => _buildPlaceholderCard(false);
}