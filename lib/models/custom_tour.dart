import 'provider.dart';
import 'tour_template.dart';

class CustomTour {
  final String id;
  final Provider? provider;
  final TourTemplate? tourTemplate;
  final String tourName;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String joinCode;
  final int maxTourists;
  final int remainingTourists;
  final String? groupChatLink;
  final String? featuresImage;
  final List<String> teaserImages;
  final DateTime createdDate;
  final DateTime? updatedDate;

  CustomTour({
    required this.id,
    this.provider,
    this.tourTemplate,
    required this.tourName,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.joinCode,
    required this.maxTourists,
    required this.remainingTourists,
    this.groupChatLink,
    this.featuresImage,
    required this.teaserImages,
    required this.createdDate,
    this.updatedDate,
  });

  factory CustomTour.fromJson(Map<String, dynamic> json) {
    return CustomTour(
      id: json['_id'] ?? '',
      provider: json['provider_id'] != null 
          ? Provider.fromJson(json['provider_id']) 
          : null,
      tourTemplate: json['tour_template_id'] != null 
          ? TourTemplate.fromJson(json['tour_template_id']) 
          : null,
      tourName: json['tour_name'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: json['status'] ?? '',
      joinCode: json['join_code'] ?? '',
      maxTourists: json['max_tourists'] ?? 0,
      remainingTourists: json['remaining_tourists'] ?? 0,
      groupChatLink: json['group_chat_link'],
      featuresImage: json['features_image'],
      teaserImages: List<String>.from(json['teaser_images'] ?? []),
      createdDate: DateTime.parse(json['created_date']),
      updatedDate: json['updated_date'] != null 
          ? DateTime.parse(json['updated_date']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'provider_id': provider?.toJson(),
      'tour_template_id': tourTemplate?.toJson(),
      'tour_name': tourName,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status,
      'join_code': joinCode,
      'max_tourists': maxTourists,
      'remaining_tourists': remainingTourists,
      'group_chat_link': groupChatLink,
      'features_image': featuresImage,
      'teaser_images': teaserImages,
      'created_date': createdDate.toIso8601String(),
      'updated_date': updatedDate?.toIso8601String(),
    };
  }

  bool get isDraft => status == 'draft';
  bool get isPublished => status == 'published';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  
  int get registeredTourists => maxTourists - remainingTourists;
  bool get isFull => remainingTourists <= 0;
  int get durationDays => endDate.difference(startDate).inDays + 1;
  
  String get statusDisplayName {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'published':
        return 'Published';
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}