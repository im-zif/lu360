import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late List<DateTime> weekDays;
  int selectedDayIndex = 0;

  final List<String> dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri"];

  @override
  void initState() {
    super.initState();
    _generateWeekDays();
  }

  // ================= Generate WeekDays and Auto Select Today =================
  void _generateWeekDays() {
    final now = DateTime.now();

    // Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));

    weekDays = List.generate(5, (index) {
      return monday.add(Duration(days: index));
    });

    // Automatically select today if it's Mon-Fri
    if (now.weekday >= 1 && now.weekday <= 5) {
      selectedDayIndex = now.weekday - 1; // Monday = 1, index = 0
    } else {
      selectedDayIndex = 0; // default to Monday if weekend
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = dayNames[selectedDayIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0F132D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F132D),
        title: const Text("My Schedule"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _daySelector(),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Schedule>>(
                future: ScheduleService().getScheduleByDay(selectedDay),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Error: ${snapshot.error}",
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        "No classes today",
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return ScheduleCard(item: snapshot.data![index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= Day Selector =================
  Widget _daySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(weekDays.length, (index) {
        final isSelected = index == selectedDayIndex;
        final date = weekDays[index];

        return GestureDetector(
          onTap: () {
            setState(() => selectedDayIndex = index);
          },
          child: Container(
            width: 55,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blueAccent : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  dayNames[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date.day.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ================= Schedule Card =================
class ScheduleCard extends StatelessWidget {
  final Schedule item;

  const ScheduleCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              item.startTime,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F3C),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 70,
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${item.courseCode} - ${item.title}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${item.startTime} - ${item.endTime}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.white54),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.location,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
