class Announcement {
  final String title;
  final String description;
  final String image;

  Announcement(this.title, this.description, this.image);

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      json['title'],
      json['description'],
      json['image'],
    );
  }
}
Future<List<Announcement>> getAnnouncements() async {
  final res = await supabase.from('announcements').select();

  return res.map<Announcement>((e) => Announcement.fromJson(e)).toList();
}
