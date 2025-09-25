class Broadcast {
  final String id;
  final BroadcastTour customTour;
  final BroadcastProvider provider;
  final String message;
  final String status;
  final BroadcastCreator createdBy;
  final DateTime createdDate;
  final DateTime updatedDate;
  final Map<String, dynamic>? data;

  Broadcast({
    required this.id,
    required this.customTour,
    required this.provider,
    required this.message,
    required this.status,
    required this.createdBy,
    required this.createdDate,
    required this.updatedDate,
    this.data,
  });

  factory Broadcast.fromJson(Map<String, dynamic> json) {
    return Broadcast(
      id: json['_id'] ?? json['id'],
      customTour: BroadcastTour.fromJson(json['custom_tour_id'] ?? json['customTour'] ?? {}),
      provider: BroadcastProvider.fromJson(json['provider_id'] ?? json['provider'] ?? {}),
      message: json['message'] ?? '',
      status: json['status'] ?? 'draft',
      createdBy: BroadcastCreator.fromJson(json['created_by'] ?? json['createdBy'] ?? {}),
      createdDate: DateTime.tryParse(json['created_date'] ?? json['createdDate'] ?? '') ?? DateTime.now(),
      updatedDate: DateTime.tryParse(json['updated_date'] ?? json['updatedDate'] ?? '') ?? DateTime.now(),
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'custom_tour_id': customTour.toJson(),
      'provider_id': provider.toJson(),
      'message': message,
      'status': status,
      'created_by': createdBy.toJson(),
      'created_date': createdDate.toIso8601String(),
      'updated_date': updatedDate.toIso8601String(),
      if (data != null) 'data': data,
    };
  }

  Broadcast copyWith({
    String? id,
    BroadcastTour? customTour,
    BroadcastProvider? provider,
    String? message,
    String? status,
    BroadcastCreator? createdBy,
    DateTime? createdDate,
    DateTime? updatedDate,
    Map<String, dynamic>? data,
  }) {
    return Broadcast(
      id: id ?? this.id,
      customTour: customTour ?? this.customTour,
      provider: provider ?? this.provider,
      message: message ?? this.message,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
      data: data ?? this.data,
    );
  }

  bool get isPublished => status == 'published';
  bool get isDraft => status == 'draft';
  
  String get statusDisplayName {
    switch (status) {
      case 'published':
        return 'Published';
      case 'draft':
        return 'Draft';
      default:
        return status.toUpperCase();
    }
  }

  String get messagePreview {
    if (message.length <= 100) return message;
    return '${message.substring(0, 97)}...';
  }
}

class BroadcastTour {
  final String id;
  final String tourName;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? joinCode;

  BroadcastTour({
    required this.id,
    required this.tourName,
    this.startDate,
    this.endDate,
    this.joinCode,
  });

  factory BroadcastTour.fromJson(Map<String, dynamic> json) {
    return BroadcastTour(
      id: json['_id'] ?? json['id'] ?? '',
      tourName: json['tour_name'] ?? json['tourName'] ?? 'Unknown Tour',
      startDate: DateTime.tryParse(json['start_date'] ?? json['startDate'] ?? ''),
      endDate: DateTime.tryParse(json['end_date'] ?? json['endDate'] ?? ''),
      joinCode: json['join_code'] ?? json['joinCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tour_name': tourName,
      if (startDate != null) 'start_date': startDate!.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      if (joinCode != null) 'join_code': joinCode,
    };
  }
}

class BroadcastProvider {
  final String id;
  final String providerName;

  BroadcastProvider({
    required this.id,
    required this.providerName,
  });

  factory BroadcastProvider.fromJson(Map<String, dynamic> json) {
    return BroadcastProvider(
      id: json['_id'] ?? json['id'] ?? '',
      providerName: json['provider_name'] ?? json['providerName'] ?? 'Unknown Provider',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_name': providerName,
    };
  }
}

class BroadcastCreator {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;

  BroadcastCreator({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
  });

  factory BroadcastCreator.fromJson(Map<String, dynamic> json) {
    return BroadcastCreator(
      id: json['_id'] ?? json['id'] ?? '',
      firstName: json['first_name'] ?? json['firstName'] ?? 'Unknown',
      lastName: json['last_name'] ?? json['lastName'] ?? 'User',
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

class BroadcastCreateRequest {
  final String customTourId;
  final String message;
  final String status;
  final Map<String, dynamic>? data;

  BroadcastCreateRequest({
    required this.customTourId,
    required this.message,
    this.status = 'draft',
    this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'custom_tour_id': customTourId,
      'message': message,
      'status': status,
      if (data != null) 'data': data,
    };
  }
}

class BroadcastUpdateRequest {
  final String? message;
  final String? status;
  final Map<String, dynamic>? data;

  BroadcastUpdateRequest({
    this.message,
    this.status,
    this.data,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (message != null) json['message'] = message;
    if (status != null) json['status'] = status;
    if (data != null) json['data'] = data;
    return json;
  }
}