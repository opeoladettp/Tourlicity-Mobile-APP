class TourTemplate {
  final String id;
  final String templateName;
  final DateTime startDate;
  final DateTime endDate;
  final String description;
  final int durationDays;
  final String? featuresImage;
  final List<String> teaserImages;
  final List<WebLink> webLinks;
  final bool isActive;
  final DateTime createdDate;
  final DateTime? updatedDate;

  TourTemplate({
    required this.id,
    required this.templateName,
    required this.startDate,
    required this.endDate,
    required this.description,
    required this.durationDays,
    this.featuresImage,
    required this.teaserImages,
    required this.webLinks,
    required this.isActive,
    required this.createdDate,
    this.updatedDate,
  });

  factory TourTemplate.fromJson(Map<String, dynamic> json) {
    return TourTemplate(
      id: json['_id'] ?? '',
      templateName: json['template_name'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      description: json['description'] ?? '',
      durationDays: json['duration_days'] ?? 0,
      featuresImage: json['features_image'],
      teaserImages: List<String>.from(json['teaser_images'] ?? []),
      webLinks: (json['web_links'] as List<dynamic>? ?? [])
          .map((link) => WebLink.fromJson(link))
          .toList(),
      isActive: json['is_active'] ?? false,
      createdDate: DateTime.parse(json['created_date']),
      updatedDate: json['updated_date'] != null 
          ? DateTime.parse(json['updated_date']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'template_name': templateName,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'description': description,
      'duration_days': durationDays,
      'features_image': featuresImage,
      'teaser_images': teaserImages,
      'web_links': webLinks.map((link) => link.toJson()).toList(),
      'is_active': isActive,
      'created_date': createdDate.toIso8601String(),
      'updated_date': updatedDate?.toIso8601String(),
    };
  }
}

class WebLink {
  final String url;
  final String description;

  WebLink({
    required this.url,
    required this.description,
  });

  factory WebLink.fromJson(Map<String, dynamic> json) {
    return WebLink(
      url: json['url'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'description': description,
    };
  }
}