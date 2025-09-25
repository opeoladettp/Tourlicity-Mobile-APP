class DefaultActivity {
  final String id;
  final String activityName;
  final String description;
  final double typicalDurationHours;
  final String category;
  final bool isActive;
  final DefaultActivityCreator? createdBy;
  final DateTime createdDate;
  final DateTime updatedDate;

  DefaultActivity({
    required this.id,
    required this.activityName,
    required this.description,
    required this.typicalDurationHours,
    required this.category,
    required this.isActive,
    this.createdBy,
    required this.createdDate,
    required this.updatedDate,
  });

  factory DefaultActivity.fromJson(Map<String, dynamic> json) {
    return DefaultActivity(
      id: json['_id'] ?? json['id'] ?? '',
      activityName: json['activity_name'] ?? '',
      description: json['description'] ?? '',
      typicalDurationHours: (json['typical_duration_hours'] ?? 0.0).toDouble(),
      category: json['category'] ?? 'other',
      isActive: json['is_active'] ?? true,
      createdBy: json['created_by'] != null 
          ? DefaultActivityCreator.fromJson(json['created_by'])
          : null,
      createdDate: DateTime.tryParse(json['created_date'] ?? '') ?? DateTime.now(),
      updatedDate: DateTime.tryParse(json['updated_date'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_name': activityName,
      'description': description,
      'typical_duration_hours': typicalDurationHours,
      'category': category,
      'is_active': isActive,
      if (createdBy != null) 'created_by': createdBy!.toJson(),
      'created_date': createdDate.toIso8601String(),
      'updated_date': updatedDate.toIso8601String(),
    };
  }

  DefaultActivity copyWith({
    String? id,
    String? activityName,
    String? description,
    double? typicalDurationHours,
    String? category,
    bool? isActive,
    DefaultActivityCreator? createdBy,
    DateTime? createdDate,
    DateTime? updatedDate,
  }) {
    return DefaultActivity(
      id: id ?? this.id,
      activityName: activityName ?? this.activityName,
      description: description ?? this.description,
      typicalDurationHours: typicalDurationHours ?? this.typicalDurationHours,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }

  // Helper getters
  String get categoryDisplayName {
    switch (category) {
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
        return category.toUpperCase();
    }
  }

  String get durationDisplayText {
    if (typicalDurationHours < 1) {
      final minutes = (typicalDurationHours * 60).round();
      return '$minutes min';
    } else if (typicalDurationHours == typicalDurationHours.toInt()) {
      return '${typicalDurationHours.toInt()}h';
    } else {
      return '${typicalDurationHours}h';
    }
  }

  String get statusDisplayName => isActive ? 'Active' : 'Inactive';

  // Calculate suggested end time based on start time and duration
  DateTime calculateEndTime(DateTime startTime) {
    final durationMinutes = (typicalDurationHours * 60).round();
    return startTime.add(Duration(minutes: durationMinutes));
  }

  // Check if activity fits within a time slot
  bool fitsInTimeSlot(DateTime startTime, DateTime endTime) {
    final requiredDuration = Duration(minutes: (typicalDurationHours * 60).round());
    final availableDuration = endTime.difference(startTime);
    return availableDuration >= requiredDuration;
  }
}

class DefaultActivityCreator {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;

  DefaultActivityCreator({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
  });

  factory DefaultActivityCreator.fromJson(Map<String, dynamic> json) {
    return DefaultActivityCreator(
      id: json['_id'] ?? json['id'] ?? '',
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      if (email != null) 'email': email,
    };
  }

  String get fullName => '$firstName $lastName';
}

class ActivityCategory {
  final String name;
  final int count;

  ActivityCategory({
    required this.name,
    required this.count,
  });

  factory ActivityCategory.fromJson(Map<String, dynamic> json) {
    return ActivityCategory(
      name: json['name'] ?? '',
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'count': count,
    };
  }

  String get displayName {
    switch (name) {
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
        return name.toUpperCase();
    }
  }
}

class DefaultActivityCreateRequest {
  final String activityName;
  final String description;
  final double typicalDurationHours;
  final String category;
  final bool isActive;

  DefaultActivityCreateRequest({
    required this.activityName,
    required this.description,
    required this.typicalDurationHours,
    required this.category,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'activity_name': activityName,
      'description': description,
      'typical_duration_hours': typicalDurationHours,
      'category': category,
      'is_active': isActive,
    };
  }
}

class DefaultActivityUpdateRequest {
  final String? activityName;
  final String? description;
  final double? typicalDurationHours;
  final String? category;
  final bool? isActive;

  DefaultActivityUpdateRequest({
    this.activityName,
    this.description,
    this.typicalDurationHours,
    this.category,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (activityName != null) json['activity_name'] = activityName;
    if (description != null) json['description'] = description;
    if (typicalDurationHours != null) json['typical_duration_hours'] = typicalDurationHours;
    if (category != null) json['category'] = category;
    if (isActive != null) json['is_active'] = isActive;
    return json;
  }
}