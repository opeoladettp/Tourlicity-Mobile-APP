class CalendarEntry {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? activityType;
  final String? customTourId;
  final String? providerId;
  final bool isDefaultActivity;
  final DateTime createdDate;
  final DateTime updatedDate;

  CalendarEntry({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.activityType,
    this.customTourId,
    this.providerId,
    required this.isDefaultActivity,
    required this.createdDate,
    required this.updatedDate,
  });

  factory CalendarEntry.fromJson(Map<String, dynamic> json) {
    return CalendarEntry(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      location: json['location'],
      activityType: json['activity_type'],
      customTourId: json['custom_tour_id'],
      providerId: json['provider_id'],
      isDefaultActivity: json['is_default_activity'] ?? false,
      createdDate: DateTime.parse(json['created_date'] ?? DateTime.now().toIso8601String()),
      updatedDate: DateTime.parse(json['updated_date'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'location': location,
      'activity_type': activityType,
      'custom_tour_id': customTourId,
      'provider_id': providerId,
      'is_default_activity': isDefaultActivity,
      'created_date': createdDate.toIso8601String(),
      'updated_date': updatedDate.toIso8601String(),
    };
  }
}