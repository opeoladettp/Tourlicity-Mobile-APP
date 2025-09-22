class Tour {
  final String id;
  final String tourName;
  final String? description;
  final String status;
  final String joinCode;
  final String providerId;
  final String? tourTemplateId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int maxTourists;
  final int currentRegistrations;
  final int remainingSpots;
  final double? pricePerPerson;
  final String? currency;
  final bool isFeatured;
  final List<String> tags;
  final int durationDays;
  final DateTime createdDate;
  final DateTime updatedDate;

  Tour({
    required this.id,
    required this.tourName,
    this.description,
    required this.status,
    required this.joinCode,
    required this.providerId,
    this.tourTemplateId,
    this.startDate,
    this.endDate,
    required this.maxTourists,
    required this.currentRegistrations,
    required this.remainingSpots,
    this.pricePerPerson,
    this.currency,
    required this.isFeatured,
    required this.tags,
    required this.durationDays,
    required this.createdDate,
    required this.updatedDate,
  });

  factory Tour.fromJson(Map<String, dynamic> json) {
    // Handle nested provider and template objects
    String providerId = json['provider_id'];
    String? tourTemplateId = json['tour_template_id'];
    
    if (json['provider_id'] is Map) {
      providerId = json['provider_id']['_id'] ?? json['provider_id']['id'];
    }
    
    if (json['tour_template_id'] is Map) {
      tourTemplateId = json['tour_template_id']['_id'] ?? json['tour_template_id']['id'];
    }

    return Tour(
      id: json['_id'] ?? json['id'],
      tourName: json['tour_name'],
      description: json['description'],
      status: json['status'] ?? 'draft',
      joinCode: json['join_code'] ?? '',
      providerId: providerId,
      tourTemplateId: tourTemplateId,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      maxTourists: json['max_tourists'] ?? 0,
      currentRegistrations: json['current_registrations'] ?? 0,
      remainingSpots: json['remaining_tourists'] ?? json['remaining_spots'] ?? 0,
      pricePerPerson: json['price_per_person']?.toDouble(),
      currency: json['currency'],
      isFeatured: json['is_featured'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      durationDays: json['duration_days'] ?? 1,
      createdDate: DateTime.parse(json['created_date'] ?? DateTime.now().toIso8601String()),
      updatedDate: DateTime.parse(json['updated_date'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tour_name': tourName,
      'description': description,
      'status': status,
      'join_code': joinCode,
      'provider_id': providerId,
      'tour_template_id': tourTemplateId,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'max_tourists': maxTourists,
      'current_registrations': currentRegistrations,
      'remaining_spots': remainingSpots,
      'price_per_person': pricePerPerson,
      'currency': currency,
      'is_featured': isFeatured,
      'tags': tags,
      'duration_days': durationDays,
      'created_date': createdDate.toIso8601String(),
      'updated_date': updatedDate.toIso8601String(),
    };
  }

  // Helper getter for backward compatibility
  String get name => tourName;
}