class Announcement {
  final String title;
  final String subtitle;
  final String time;
  final String? iconType; // e.g., 'event', 'warning', 'info'

  Announcement({
    required this.title,
    required this.subtitle,
    required this.time,
    this.iconType,
  });

  // Converts Supabase/JSON data into an Announcement object
  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      title: json['title'] ?? 'No Title',
      subtitle: json['description'] ?? '',
      // If your DB uses Timestamps, you'd use intl here to format it
      time: json['created_at_human'] ?? 'Just now',
      iconType: json['category'],
    );
  }
}