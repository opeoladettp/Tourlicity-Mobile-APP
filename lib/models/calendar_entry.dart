import 'default_activity.dart';
import 'custom_tour.dart';

class CalendarEntry {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? activityType;
  final String? customTourId;
  final CustomTour? customTour; // Populated tour data
  final String? providerId;
  final bool isDefaultActivity;
  final String? defaultActivityId; // Reference to DefaultActivity
  final DefaultActivity? defaultActivity; // Populated default activity data
  final String? category; // Activity category for better organization
  final String? featuredImage;
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
    this.customTour,
    this.providerId,
    required this.isDefaultActivity,
    this.defaultActivityId,
    this.defaultActivity,
    this.category,
    this.featuredImage,
    required this.createdDate,
    required this.updatedDate,
  });

  factory CalendarEntry.fromJson(Map<String, dynamic> json) {
    // Handle custom_tour_id - can be string or populated object
    String? customTourId;
    CustomTour? customTour;
    if (json['custom_tour_id'] is Map) {
      final tourData = json['custom_tour_id'] as Map<String, dynamic>;
      customTourId = tourData['_id'] ?? tourData['id'];
      customTour = CustomTour.fromJson(tourData);
    } else {
      customTourId = json['custom_tour_id'];
    }

    // Handle default_activity_id - can be string or populated object
    String? defaultActivityId;
    DefaultActivity? defaultActivity;
    if (json['default_activity_id'] is Map) {
      final activityData = json['default_activity_id'] as Map<String, dynamic>;
      defaultActivityId = activityData['_id'] ?? activityData['id'];
      defaultActivity = DefaultActivity.fromJson(activityData);
    } else {
      defaultActivityId = json['default_activity_id'];
    }

    return CalendarEntry(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? json['activity'] ?? '',
      description: json['description'] ?? json['activity_description'],
      startTime: DateTime.tryParse(json['start_time'] ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['end_time'] ?? '') ?? DateTime.now(),
      location: json['location'],
      activityType: json['activity_type'] ?? (json['is_default_activity'] == true ? 'default' : 'custom'),
      customTourId: customTourId,
      customTour: customTour,
      providerId: json['provider_id'],
      isDefaultActivity: json['is_default_activity'] ?? false,
      defaultActivityId: defaultActivityId,
      defaultActivity: defaultActivity,
      category: json['category'] ?? defaultActivity?.category,
      featuredImage: json['featured_image'],
      createdDate: DateTime.tryParse(json['created_date'] ?? '') ?? DateTime.now(),
      updatedDate: DateTime.tryParse(json['updated_date'] ?? '') ?? DateTime.now(),
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
      'custom_tour_id': customTour?.toJson() ?? customTourId,
      'provider_id': providerId,
      'is_default_activity': isDefaultActivity,
      if (defaultActivityId != null) 'default_activity_id': defaultActivity?.toJson() ?? defaultActivityId,
      if (category != null) 'category': category,
      if (featuredImage != null) 'featured_image': featuredImage,
      'created_date': createdDate.toIso8601String(),
      'updated_date': updatedDate.toIso8601String(),
    };
  }

  CalendarEntry copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? activityType,
    String? customTourId,
    CustomTour? customTour,
    String? providerId,
    bool? isDefaultActivity,
    String? defaultActivityId,
    DefaultActivity? defaultActivity,
    String? category,
    String? featuredImage,
    DateTime? createdDate,
    DateTime? updatedDate,
  }) {
    return CalendarEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      activityType: activityType ?? this.activityType,
      customTourId: customTourId ?? this.customTourId,
      customTour: customTour ?? this.customTour,
      providerId: providerId ?? this.providerId,
      isDefaultActivity: isDefaultActivity ?? this.isDefaultActivity,
      defaultActivityId: defaultActivityId ?? this.defaultActivityId,
      defaultActivity: defaultActivity ?? this.defaultActivity,
      category: category ?? this.category,
      featuredImage: featuredImage ?? this.featuredImage,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }

  // Helper getters
  Duration get duration => endTime.difference(startTime);
  
  String get durationDisplayText {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  String get timeDisplayText {
    final startHour = startTime.hour.toString().padLeft(2, '0');
    final startMinute = startTime.minute.toString().padLeft(2, '0');
    final endHour = endTime.hour.toString().padLeft(2, '0');
    final endMinute = endTime.minute.toString().padLeft(2, '0');
    
    return '$startHour:$startMinute - $endHour:$endMinute';
  }

  String get categoryDisplayName {
    if (category == null) return 'General';
    
    switch (category!) {
      case 'sightseeing':
        return 'Sightseeing';
      case 'cultural':
        return 'Cultural';
      case 'adventure':
        return 'Adventure';
      case 'dining':
        return 'Dining';
      case 'transportation':
        return 'Transportation';
      case 'accommodation':
        return 'Accommodation';
      case 'entertainment':
        return 'Entertainment';
      case 'shopping':
        return 'Shopping';
      case 'educational':
        return 'Educational';
      case 'religious':
        return 'Religious';
      case 'nature':
        return 'Nature';
      case 'other':
        return 'Other';
      default:
        return category!.toUpperCase();
    }
  }

  String get activityTypeDisplayName {
    switch (activityType) {
      case 'default':
        return 'Template Activity';
      case 'custom':
        return 'Custom Activity';
      default:
        return isDefaultActivity ? 'Template Activity' : 'Custom Activity';
    }
  }

  // Check if this entry conflicts with another
  bool conflictsWith(CalendarEntry other) {
    return startTime.isBefore(other.endTime) && endTime.isAfter(other.startTime);
  }

  // Check if this entry is on a specific date
  bool isOnDate(DateTime date) {
    final entryDate = DateTime(startTime.year, startTime.month, startTime.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    return entryDate.isAtSameMomentAs(checkDate);
  }
}