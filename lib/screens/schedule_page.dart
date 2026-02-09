import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  String selectedBatch = "61";
  String selectedSection = "E";

  final List<String> batches = ["60", "61", "62"];
  final List<String> sections = ["A", "B", "C", "D", "E"];

  late List<DateTime> weekDays;
  int selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    _generateWeekDays();
  }

  void _generateWeekDays() {
    final now = DateTime.now();
    weekDays = List.generate(7, (index) => now.add(Duration(days: index)));
    selectedDayIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedDayQuery = DateFormat('EEEE').format(weekDays[selectedDayIndex]);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Light Background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark, // Dark status bar icons
        iconTheme: const IconThemeData(color: Colors.black), // Back button color
        title: const Text(
          "My Schedule",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // ================= 1. COMPACT FILTERS =================
            Row(
              children: [
                Expanded(child: _buildDropdownFilter("Batch", selectedBatch, batches, (val) => setState(() => selectedBatch = val!))),
                const SizedBox(width: 12),
                Expanded(child: _buildDropdownFilter("Section", selectedSection, sections, (val) => setState(() => selectedSection = val!))),
              ],
            ),

            const SizedBox(height: 20),

            // ================= 2. DAY SELECTOR =================
            _daySelector(),

            const SizedBox(height: 25),

            // ================= 3. SCHEDULE LIST =================
            Expanded(
              child: FutureBuilder<List<Schedule>>(
                future: ScheduleService().getScheduleByDay(
                  dayName: selectedDayQuery,
                  batch: selectedBatch,
                  section: selectedSection,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                  }

                  if (snapshot.hasError) {
                    return _buildStatusText("Error: ${snapshot.error}");
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: Colors.black12, size: 64),
                        const SizedBox(height: 16),
                        _buildStatusText("No classes on $selectedDayQuery"),
                      ],
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) => ScheduleCard(item: snapshot.data![index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownFilter(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blueAccent, size: 20),
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text("$label $i"))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStatusText(String text) {
    return Center(child: Text(text, style: const TextStyle(color: Colors.black38, fontSize: 15, fontWeight: FontWeight.w500)));
  }

  Widget _daySelector() {
    return SizedBox(
      height: 85,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: weekDays.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final day = weekDays[index];
          final isSelected = index == selectedDayIndex;

          final String shortDay = DateFormat('E').format(day);
          final String dayNumber = DateFormat('d').format(day);

          return GestureDetector(
            onTap: () => setState(() => selectedDayIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 62,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? Colors.blueAccent.withOpacity(0.3) : Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
                border: isSelected ? null : Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    shortDay,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black45,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayNumber,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ScheduleCard extends StatelessWidget {
  final Schedule item;
  const ScheduleCard({super.key, required this.item});

  String _formatTime(String time) {
    if (time.isEmpty) return "";
    try {
      final DateTime dt = DateFormat("HH:mm:ss").parse(time);
      return DateFormat("h:mm a").format(dt);
    } catch (e) {
      return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Column
          SizedBox(
            width: 75,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _formatTime(item.startTime),
                style: const TextStyle(color: Colors.black38, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Content Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
                ],
                border: Border.all(color: Colors.black.withOpacity(0.03)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 55,
                    decoration: BoxDecoration(
                      color: item.color, // Keeps the color strip from the model
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.courseCode,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 17),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.teacherName,
                          style: const TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 14, color: Colors.blueAccent),
                            const SizedBox(width: 4),
                            Text(
                              item.roomNo,
                              style: const TextStyle(color: Colors.black45, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            if (item.isOnline)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  "ONLINE",
                                  style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
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