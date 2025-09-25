import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/logger.dart';
import '../config/app_config.dart';

class CustomPushNotificationService {
  static final CustomPushNotificationService _instance = CustomPushNotificationService._internal();
  factory CustomPushNotificationService() => _instance;
  CustomPushNotificationService._internal();

  
  WebSocketChannel? _webSocketChannel;
  Timer? _heartbeatTimer;
  Timer? _pollTimer;
  bool _isInitialized = false;
  String? _userId;

  /// Initialize custom push notifications
  Future<void> initialize({String? userId}) async {
    if (_isInitialized) return;

    try {
      _userId = userId;
      
      // Start WebSocket connection for real-time notifications
      await _connectWebSocket();
      
      // Fallback: Poll for notifications every 30 seconds
      _startPolling();
      
      _isInitialized = true;
      Logger.info('🔔 Custom push notifications initialized successfully');
    } catch (e) {
      Logger.error('❌ Failed to initialize custom push notifications: $e');
    }
  }



  /// Connect to WebSocket for real-time notifications
  Future<void> _connectWebSocket() async {
    if (_userId == null) return;

    try {
      // Replace HTTP with WS for WebSocket connection
      final wsUrl = AppConfig.apiBaseUrl.replaceFirst('http', 'ws');
      final uri = Uri.parse('$wsUrl/notifications/ws?userId=$_userId');
      
      _webSocketChannel = WebSocketChannel.connect(uri);
      
      // Listen for messages
      _webSocketChannel!.stream.listen(
        (message) {
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          Logger.error('WebSocket error: $error');
          _reconnectWebSocket();
        },
        onDone: () {
          Logger.info('WebSocket connection closed');
          _reconnectWebSocket();
        },
      );

      // Send heartbeat every 30 seconds to keep connection alive
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (_webSocketChannel != null) {
          _webSocketChannel!.sink.add(jsonEncode({'type': 'heartbeat'}));
        }
      });

      Logger.info('🔗 WebSocket connected for notifications');
    } catch (e) {
      Logger.error('❌ Failed to connect WebSocket: $e');
    }
  }

  /// Reconnect WebSocket after connection loss
  void _reconnectWebSocket() {
    _heartbeatTimer?.cancel();
    _webSocketChannel?.sink.close();
    
    // Retry connection after 5 seconds
    Timer(const Duration(seconds: 5), () {
      _connectWebSocket();
    });
  }

  /// Handle WebSocket messages
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      
      if (data['type'] == 'notification') {
        final notification = data['notification'];
        Logger.info('📱 Received notification: ${notification['title']}');
        // In a real implementation, you would show this via the system notification
        // or update the in-app notification state
      }
    } catch (e) {
      Logger.error('❌ Failed to handle WebSocket message: $e');
    }
  }

  /// Start polling for notifications (fallback method)
  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _pollForNotifications();
    });
  }

  /// Poll for new notifications from API
  Future<void> _pollForNotifications() async {
    if (_userId == null) return;

    try {
      // This would be a new endpoint in your backend: GET /notifications/pending
      // For now, we'll use the existing notification service
      // You would need to add this endpoint to your backend
      
      Logger.debug('🔄 Polling for notifications...');
      // Implementation would depend on your backend API structure
    } catch (e) {
      Logger.error('❌ Failed to poll for notifications: $e');
    }
  }





  /// Send test notification
  Future<void> sendTestNotification() async {
    Logger.info('📱 Test notification would be shown here');
  }

  /// Subscribe to notifications (register with backend)
  Future<void> subscribe() async {
    if (_userId == null) return;

    try {
      // Register device for custom notifications
      // This would be a custom endpoint in your backend
      Logger.info('✅ Subscribed to custom notifications');
    } catch (e) {
      Logger.error('❌ Failed to subscribe to custom notifications: $e');
      rethrow;
    }
  }

  /// Unsubscribe from notifications
  Future<void> unsubscribe() async {
    try {
      _heartbeatTimer?.cancel();
      _pollTimer?.cancel();
      _webSocketChannel?.sink.close();
      Logger.info('✅ Unsubscribed from custom notifications');
    } catch (e) {
      Logger.error('❌ Failed to unsubscribe: $e');
      rethrow;
    }
  }

  /// Update user ID for notifications
  void updateUserId(String? userId) {
    if (_userId != userId) {
      _userId = userId;
      if (_isInitialized) {
        // Reconnect with new user ID
        _reconnectWebSocket();
      }
    }
  }

  /// Check if notifications are initialized
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  void dispose() {
    _heartbeatTimer?.cancel();
    _pollTimer?.cancel();
    _webSocketChannel?.sink.close();
    _isInitialized = false;
  }
}