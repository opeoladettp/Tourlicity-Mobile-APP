import 'dart:io';
import 'dart:developer' as developer;

/// Simple logger for test scripts
void testLog(String message) {
  developer.log(message, name: 'TestScript');
}

/// Simple script to test backend connectivity
void main() async {
  testLog('🚀 Testing Tourlicity Backend Integration...\n');

  const baseUrl = 'http://localhost:5000';
  final client = HttpClient();

  try {
    // Test 1: Health Check
    testLog('1. Testing health endpoint...');
    final healthRequest = await client.getUrl(Uri.parse('$baseUrl/health'));
    final healthResponse = await healthRequest.close();

    if (healthResponse.statusCode == 200) {
      testLog('✅ Health check passed');
    } else {
      testLog('❌ Health check failed: ${healthResponse.statusCode}');
    }

    // Test 2: API Documentation
    testLog('\n2. Testing API documentation...');
    final docsRequest = await client.getUrl(
      Uri.parse('$baseUrl/api-docs.json'),
    );
    final docsResponse = await docsRequest.close();

    if (docsResponse.statusCode == 200) {
      testLog('✅ API documentation accessible');
    } else {
      testLog('❌ API documentation not accessible: ${docsResponse.statusCode}');
    }

    // Test 3: API v1 Base
    testLog('\n3. Testing API v1 base...');
    final apiRequest = await client.getUrl(Uri.parse('$baseUrl/api/v1/health'));
    final apiResponse = await apiRequest.close();

    if (apiResponse.statusCode == 200) {
      testLog('✅ API v1 endpoint accessible');
    } else {
      testLog('❌ API v1 endpoint not accessible: ${apiResponse.statusCode}');
    }

    testLog('\n🎉 Backend integration test completed!');
    testLog('\nNext steps:');
    testLog('1. Run: flutter run');
    testLog('2. Test Google OAuth flow');
    testLog('3. Create a test tour');
    testLog('4. Test registration flow');
  } catch (e) {
    testLog('❌ Connection failed: $e');
    testLog('\nTroubleshooting:');
    testLog('1. Ensure backend is running on port 3000');
    testLog('2. Check if localhost:3000 is accessible');
    testLog('3. Verify CORS configuration');
  } finally {
    client.close();
  }
}
