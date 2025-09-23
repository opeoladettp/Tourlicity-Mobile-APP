class RoleChangeRequest {
  final String id;
  final String requestType;
  final String status;
  final String? requestMessage;
  final String? adminNotes;
  final DateTime createdDate;
  final DateTime? processedDate;
  final Map<String, dynamic>? proposedProviderData;
  final String? providerId;

  RoleChangeRequest({
    required this.id,
    required this.requestType,
    required this.status,
    this.requestMessage,
    this.adminNotes,
    required this.createdDate,
    this.processedDate,
    this.proposedProviderData,
    this.providerId,
  });

  factory RoleChangeRequest.fromJson(Map<String, dynamic> json) {
    return RoleChangeRequest(
      id: json['_id'] ?? json['id'] ?? '',
      requestType: json['request_type'] ?? '',
      status: json['status'] ?? '',
      requestMessage: json['request_message'],
      adminNotes: json['admin_notes'],
      createdDate: DateTime.parse(json['created_date'] ?? DateTime.now().toIso8601String()),
      processedDate: json['processed_date'] != null 
          ? DateTime.parse(json['processed_date'])
          : null,
      proposedProviderData: json['proposed_provider_data'],
      providerId: json['provider_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'request_type': requestType,
      'status': status,
      'request_message': requestMessage,
      'admin_notes': adminNotes,
      'created_date': createdDate.toIso8601String(),
      'processed_date': processedDate?.toIso8601String(),
      'proposed_provider_data': proposedProviderData,
      'provider_id': providerId,
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';

  String get statusDisplayName {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get requestTypeDisplayName {
    switch (requestType) {
      case 'become_new_provider':
        return 'Become New Provider';
      case 'join_existing_provider':
        return 'Join Existing Provider';
      default:
        return requestType;
    }
  }
}