import 'package:flutter/material.dart';
import 'package:lu_360/screens/schedule_page.dart';

import 'map_screen.dart';
import 'package:lu_360/screens/routine_screen.dart';



class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F132D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ================= Next Class Title =================

              const Text(
                'Your Next Class',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              // ================= Next Class From Database =================

              FutureBuilder<NextClass?>(
                future: SupabaseService().getNextClass(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.redAccent),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Text(
                      "No upcoming class",
                      style: TextStyle(color: Colors.white70),
                    );
                  }

                  final c = snapshot.data!;
                  return nextClassCard(
                    time: c.time,
                    subject: c.subject,
                    location: c.location,
                    teacher: c.teacher,
                    image: c.image,
                  );
                },
              ),

              const SizedBox(height: 25),
              // ================= Shortcut Buttons =================

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [

                  shortcutButton(
                    icon: Icons.calendar_today,
                    label: "Full Schedule",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SchedulePage()),
                      );
                        //goes to routine_screen
                    },
                  ),

                  shortcutButton(
                    icon: Icons.map,
                    label: "Campus Map",
                    onTap: () {
                      Navigator.push(context,
                         MaterialPageRoute(builder: (_) => MapScreen()));
                    },
                  ),

                  shortcutButton(
                    icon: Icons.search,
                    label: "Search",
                    onTap: () {},
                    // you can change feature
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ================= Announcements Title =================

              const Text(
                "Announcements",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              // Later you can replace this with FutureBuilder also

              announcementTile(
                title: "Library Extended Hours",
                subtitle: "Library will be open 24/7 for finals week",
                time: "2 days ago",
              ),

              announcementTile(
                title: "Spring Fest This Friday",
                subtitle: "Live music, food and games",
                time: "4 days ago",
              ),

              announcementTile(
                title: "Parking Lot C Closure",
                subtitle: "Closed for maintenance on May 25",
                time: "1 week ago",
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================================================
  // NEXT CLASS CARD UI
  // ======================================================

  Widget nextClassCard({
    required String time,
    required String subject,
    required String location,
    required String teacher,
    required String image,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Image.network(
              image,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.lightBlueAccent,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  subject,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "$location\n$teacher",
                  style: const TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 12),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: () {},
                  child: const Text("View Details"),

                  // donno ki add korbo
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // SHORTCUT BUTTON
  // ======================================================

  Widget shortcutButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.blueAccent,
              size: 26,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ======================================================
  // ANNOUNCEMENT TILE
  // ======================================================

  Widget announcementTile({
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios,
              color: Colors.white38, size: 16),
        ],
      ),
    );
  }
}
