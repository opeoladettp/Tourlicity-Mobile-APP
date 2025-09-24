class PushSubscription {
  final String endpoint;
  final PushKeys keys;
  final String? userAgent;
  final String? deviceType;
  final String? browser;

  PushSubscription({
    required this.endpoint,
    required this.keys,
    this.userAgent,
    this.deviceType,
    this.browser,
  });

  factory PushSubscription.fromJson(Map<String, dynamic> json) {
    return PushSubscription(
      endpoint: json['endpoint'],
      keys: PushKeys.fromJson(json['keys']),
      userAgent: json['userAgent'],
      deviceType: json['deviceType'],
      browser: json['browser'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'endpoint': endpoint,
      'keys': keys.toJson(),
      'userAgent': userAgent,
      'deviceType': deviceType,
      'browser': browser,
    };
  }
}

class PushKeys {
  final String p256dh;
  final String auth;

  PushKeys({
    required this.p256dh,
    required this.auth,
  });

  factory PushKeys.fromJson(Map<String, dynamic> json) {
    return PushKeys(
      p256dh: json['p256dh'],
      auth: json['auth'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'p256dh': p256dh,
      'auth': auth,
    };
  }
}

class NotificationPayload {
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;

  NotificationPayload({
    required this.title,
    required this.body,
    required this.type,
    this.data,
  });

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      title: json['title'],
      body: json['body'],
      type: json['type'],
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'data': data,
    };
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    required this.isRead,
    this.data,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      body: json['body'],
      type: json['type'],
      timestamp: DateTime.parse(json['timestamp'] ?? json['created_date'] ?? DateTime.now().toIso8601String()),
      isRead: json['is_read'] ?? false,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'data': data,
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}

class NotificationQueueStats {
  final QueueTypeStats email;
  final QueueTypeStats push;
  final DateTime timestamp;

  NotificationQueueStats({
    required this.email,
    required this.push,
    required this.timestamp,
  });

  factory NotificationQueueStats.fromJson(Map<String, dynamic> json) {
    return NotificationQueueStats(
      email: QueueTypeStats.fromJson(json['stats']['email']),
      push: QueueTypeStats.fromJson(json['stats']['push']),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class QueueTypeStats {
  final int waiting;
  final int active;
  final int completed;
  final int failed;

  QueueTypeStats({
    required this.waiting,
    required this.active,
    required this.completed,
    required this.failed,
  });

  factory QueueTypeStats.fromJson(Map<String, dynamic> json) {
    return QueueTypeStats(
      waiting: json['waiting'],
      active: json['active'],
      completed: json['completed'],
      failed: json['failed'],
    );
  }
}