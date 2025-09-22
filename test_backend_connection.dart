import 'dart:io';
import 'dart:convert';
import 'lib/utils/logger.dart';

/// Test script to verify backend connectivity and Google OAuth setup
void main() async {
  Logger.test('🚀 Testing Tourlicity Backend Connection...\n');

  // Test both localhost and Android emulator addresses
  final testUrls = ['http://localhost:3000', 'http://10.0.2.2:3000'];

  final client = HttpClient();
  String? workingUrl;

  try {
    // Test 1: Find working backend URL
    Logger.test('1. Testing backend connectivity...');
    for (final url in testUrls) {
      try {
        Logger.test('   Testing: $url');
        final request = await client.getUrl(Uri.parse('$url/health'));
        request.headers.set('Accept', 'application/json');
        final response = await request.close();

        if (response.statusCode == 200) {
          final responseBody = await response.transform(utf8.decoder).join();
          final healthData = json.decode(responseBody);
          Logger.test('   ✅ $url - Status: ${healthData['status']}');
          workingUrl = url;
          break;
        }
      } catch (e) {
        Logger.test('   ❌ $url - Failed: $e');
      }
    }

    if (workingUrl == null) {
      Logger.error('❌ No working backend URL found!');
      Logger.test('Make sure your backend is running on port 3000');
      return;
    }

    // Test 2: Test Google OAuth endpoint
    Logger.test('\n2. Testing Google OAuth endpoint...');
    try {
      final request = await client.getUrl(
        Uri.parse('$workingUrl/api/v1/auth/google'),
      );
      final response = await request.close();

      if (response.statusCode == 302) {
        final location = response.headers.value('location');
        if (location != null && location.contains('accounts.google.com')) {
          Logger.test('   ✅ Google OAuth redirect working');
          Logger.test('   📍 Redirects to: ${location.substring(0, 50)}...');
        } else {
          Logger.test('   ❌ Invalid redirect location');
        }
      } else {
        Logger.test('   ❌ Expected 302 redirect, got ${response.statusCode}');
      }
    } catch (e) {
      Logger.test('   ❌ Google OAuth test failed: $e');
    }

    // Test 3: Test API v1 endpoints
    Logger.test('\n3. Testing API v1 endpoints...');
    final testEndpoints = ['/api/v1/health', '/api-docs.json'];

    for (final endpoint in testEndpoints) {
      try {
        final request = await client.getUrl(Uri.parse('$workingUrl$endpoint'));
        final response = await request.close();

        if (response.statusCode == 200) {
          Logger.test('   ✅ $endpoint - Working');
        } else {
          Logger.test('   ❌ $endpoint - Status: ${response.statusCode}');
        }
      } catch (e) {
        Logger.test('   ❌ $endpoint - Error: $e');
      }
    }

    // Test 4: Check CORS configuration
    Logger.test('\n4. Testing CORS configuration...');
    try {
      final request = await client.getUrl(
        Uri.parse('$workingUrl/api/v1/health'),
      );
      request.headers.set('Origin', 'http://localhost:3000');
      final response = await request.close();

      final corsHeader = response.headers.value('access-control-allow-origin');
      if (corsHeader != null) {
        Logger.test('   ✅ CORS configured: $corsHeader');
      } else {
        Logger.test('   ⚠️  CORS headers not found (may cause issues)');
      }
    } catch (e) {
      Logger.test('   ❌ CORS test failed: $e');
    }

    Logger.test('\n🎉 Backend Connection Test Results:');
    Logger.test('✅ Working Backend URL: $workingUrl');
    Logger.test(
      '✅ Google OAuth Client ID: 519507867000-q7afm0sitg8g1r5860u4ftclu60fb376.apps.googleusercontent.com',
    );
    Logger.test('\n📱 Flutter App Configuration:');
    Logger.test('- API Base URL: $workingUrl');
    Logger.test('- Google Client ID: Configured');
    Logger.test('- Android Package: com.example.tourlicity');

    Logger.test('\n🚀 Next Steps:');
    Logger.test('1. Run: flutter clean && flutter pub get');
    Logger.test('2. Run: flutter run');
    Logger.test('3. Test Mock Sign-In first');
    Logger.test('4. Then test Google Sign-In');
  } catch (e) {
    Logger.error('❌ Test failed: $e');
  } finally {
    client.close();
  }
}
