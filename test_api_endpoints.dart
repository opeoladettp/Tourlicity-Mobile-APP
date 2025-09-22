import 'dart:io';
import 'dart:convert';
import 'lib/utils/logger.dart';

/// Test specific API endpoints that the Flutter app will use
void main() async {
  Logger.test('🧪 Testing Tourlicity API Endpoints...\n');
  
  const baseUrl = 'http://localhost:3000';
  final client = HttpClient();
  
  try {
    // Test 1: Basic health check
    Logger.test('1. Testing basic health endpoint...');
    await testEndpoint(client, '$baseUrl/health', 'GET');
    
    // Test 2: API v1 health (if it exists)
    Logger.test('\n2. Testing API v1 health endpoint...');
    await testEndpoint(client, '$baseUrl/api/v1/health', 'GET');
    
    // Test 3: Google OAuth verify endpoint (should accept POST)
    Logger.test('\n3. Testing Google OAuth verify endpoint...');
    await testEndpoint(client, '$baseUrl/api/v1/auth/google/verify', 'POST', {
      'idToken': 'test_token'
    });
    
    // Test 4: Auth profile endpoint (should require auth)
    Logger.test('\n4. Testing auth profile endpoint...');
    await testEndpoint(client, '$baseUrl/api/v1/auth/profile', 'GET');
    
    // Test 5: Tours endpoint
    Logger.test('\n5. Testing tours endpoint...');
    await testEndpoint(client, '$baseUrl/api/v1/tours', 'GET');
    
    Logger.test('\n✅ API endpoint testing complete!');
    Logger.test('\n📱 Flutter app should now be able to:');
    Logger.test('- Connect to backend at localhost:3000');
    Logger.test('- Send Google OAuth tokens for verification');
    Logger.test('- Make authenticated API calls');
    Logger.test('\n🚀 Ready to test in Flutter app!');
    
  } catch (e) {
    Logger.error('❌ Test failed: $e');
  } finally {
    client.close();
  }
}

Future<void> testEndpoint(HttpClient client, String url, String method, [Map<String, dynamic>? data]) async {
  try {
    late HttpClientRequest request;
    
    switch (method.toUpperCase()) {
      case 'GET':
        request = await client.getUrl(Uri.parse(url));
        break;
      case 'POST':
        request = await client.postUrl(Uri.parse(url));
        request.headers.set('Content-Type', 'application/json');
        if (data != null) {
          request.write(json.encode(data));
        }
        break;
      default:
        throw Exception('Unsupported method: $method');
    }
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    Logger.test('   $method $url');
    Logger.test('   Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      try {
        final jsonData = json.decode(responseBody);
        if (jsonData is Map && jsonData.containsKey('success')) {
          Logger.test('   Response: ${jsonData['success'] ? 'Success' : 'Error'}');
          if (jsonData.containsKey('message')) {
            Logger.test('   Message: ${jsonData['message']}');
          }
        } else {
          Logger.test('   Response: Valid JSON');
        }
      } catch (e) {
        Logger.test('   Response: ${responseBody.length > 100 ? '${responseBody.substring(0, 100)}...' : responseBody}');
      }
    } else if (response.statusCode == 401) {
      Logger.test('   Response: Unauthorized (expected for protected endpoints)');
    } else if (response.statusCode == 404) {
      Logger.test('   Response: Not Found');
    } else {
      Logger.test('   Response: ${responseBody.length > 100 ? '${responseBody.substring(0, 100)}...' : responseBody}');
    }
    
  } catch (e) {
    Logger.test('   ❌ Error: $e');
  }
}