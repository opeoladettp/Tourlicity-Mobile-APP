class Tour {
  final String id;
  final String tourName;
  final String? description;
  final String status;
  final String joinCode;
  final String providerId;
  final String? providerName;
  final String? tourTemplateId;
  final String? tourTemplateName;
  final DateTime? startDate;
  final DateTime? endDate;
  final int maxTourists;
  final int remainingTourists;
  final String? groupChatLink;
  final String? featuresImage;
  final List<String> teaserImages;
  final DateTime createdDate;
  final DateTime updatedDate;

  Tour({
    required this.id,
    required this.tourName,
    this.description,
    required this.status,
    required this.joinCode,
    required this.providerId,
    this.providerName,
    this.tourTemplateId,
    this.tourTemplateName,
    this.startDate,
    this.endDate,
    required this.maxTourists,
    required this.remainingTourists,
    this.groupChatLink,
    this.featuresImage,
    required this.teaserImages,
    required this.createdDate,
    required this.updatedDate,
  });

  factory Tour.fromJson(Map<String, dynamic> json) {
    // Handle nested provider and template objects
    String providerId = '';
    String? providerName;
    String? tourTemplateId;
    String? tourTemplateName;
    
    // Handle provider_id (can be String or Map)
    if (json['provider_id'] is Map) {
      final providerData = json['provider_id'] as Map<String, dynamic>;
      providerId = providerData['_id'] ?? providerData['id'] ?? '';
      providerName = providerData['provider_name'];
    } else if (json['provider_id'] is String) {
      providerId = json['provider_id'];
    }
    
    // Handle tour_template_id (can be String or Map)
    if (json['tour_template_id'] is Map) {
      final templateData = json['tour_template_id'] as Map<String, dynamic>;
      tourTemplateId = templateData['_id'] ?? templateData['id'];
      tourTemplateName = templateData['template_name'];
    } else if (json['tour_template_id'] is String) {
      tourTemplateId = json['tour_template_id'];
    }

    return Tour(
      id: json['_id'] ?? json['id'],
      tourName: json['tour_name'],
      description: json['description'],
      status: json['status'] ?? 'draft',
      joinCode: json['join_code'] ?? '',
      providerId: providerId,
      providerName: providerName,
      tourTemplateId: tourTemplateId,
      tourTemplateName: tourTemplateName,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      maxTourists: json['max_tourists'] ?? 0,
      remainingTourists: json['remaining_tourists'] ?? 0,
      groupChatLink: json['group_chat_link'],
      featuresImage: json['features_image'],
      teaserImages: List<String>.from(json['teaser_images'] ?? []),
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
      'remaining_tourists': remainingTourists,
      'group_chat_link': groupChatLink,
      'features_image': featuresImage,
      'teaser_images': teaserImages,
      'created_date': createdDate.toIso8601String(),
      'updated_date': updatedDate.toIso8601String(),
    };
  }

  // Helper getters for backward compatibility
  String get name => tourName;
  int get currentRegistrations => maxTourists - remainingTourists;
  int get remainingSpots => remainingTourists;
  int get durationDays => startDate != null && endDate != null 
      ? endDate!.difference(startDate!).inDays + 1 
      : 1;
}