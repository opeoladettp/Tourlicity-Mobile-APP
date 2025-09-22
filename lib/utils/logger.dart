import 'dart:developer' as developer;

/// Logger utility to replace print statements with proper logging
class Logger {
  static const String _name = 'Tourlicity';
  
  /// Log info messages
  static void info(String message) {
    developer.log(message, name: _name, level: 800);
  }
  
  /// Log warning messages
  static void warning(String message) {
    developer.log(message, name: _name, level: 900);
  }
  
  /// Log error messages
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _name,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Log debug messages (only in debug mode)
  static void debug(String message) {
    assert(() {
      developer.log(message, name: _name, level: 700);
      return true;
    }());
  }
  
  /// Log test messages (for test scripts)
  static void test(String message) {
    developer.log(message, name: _name, level: 600);
  }
}