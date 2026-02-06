class SchoolEvent {
  String id;
  String schoolId;
  String title;
  String? description;
  DateTime startTime;
  DateTime? endTime;
  bool isAllDay;
  String? sourceUrl;
  String eventType; 

  SchoolEvent({
    required this.id,
    required this.schoolId,
    required this.title,
    this.description,
    required this.startTime,
    this.endTime,
    required this.isAllDay,
    this.sourceUrl,
    this.eventType = 'event',
  });

  static SchoolEvent fromJson(Map<String, dynamic> data) {
    // print("Loading event: " + data['title']);
    
    var start = DateTime.parse(data['start_time']);
    DateTime? end;
    if (data['end_time'] != null) {
      end = DateTime.parse(data['end_time']);
    }

    return SchoolEvent(
      id: data['id'],
      schoolId: data['school_id'],
      title: data['title'],
      description: data['description'],
      startTime: start,
      endTime: end,
      isAllDay: data['is_all_day'] ?? false,
      sourceUrl: data['source_url'],
      eventType: data['event_type'] ?? 'event',
    );
  }
}
