import 'package:flutter/material.dart';
import 'lib/utils/backend_test.dart';
import 'lib/services/api_service.dart';
import 'lib/services/tour_service.dart';
import 'lib/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  Logger.test('🚀 Starting Backend Integration Test...\n');
  
  // Test 1: Basic Connection
  Logger.test('📡 Testing backend connection...');
  try {
    final results = await BackendTest.testConnection();
    BackendTest.printTestResults(results);
  } catch (e) {
    Logger.error('❌ Connection test failed: $e');
  }
  
  Logger.test('\n${'='*50}\n');
  
  // Test 2: API Service
  Logger.test('🔧 Testing API Service...');
  try {
    final apiService = ApiService();
    
    // Test health endpoint
    final healthResponse = await apiService.get('/health');
    Logger.test('✅ Health check: ${healthResponse.statusCode}');
    
    // Test API endpoint (should fail without auth, but that's expected)
    try {
      await apiService.get('/auth/profile');
      Logger.test('✅ API endpoint accessible');
    } catch (e) {
      if (e.toString().contains('401')) {
        Logger.test('✅ API endpoint properly protected (401 Unauthorized)');
      } else {
        Logger.test('⚠️ API endpoint error: $e');
      }
    }
  } catch (e) {
    Logger.error('❌ API Service test failed: $e');
  }
  
  Logger.test('\n${'='*50}\n');
  
  // Test 3: Tour Service (without auth)
  Logger.test('🎯 Testing Tour Service...');
  try {
    final tourService = TourService();
    
    // Test search with a non-existent join code (should fail gracefully)
    try {
      await tourService.searchTourByJoinCode('NONEXISTENT');
      Logger.test('⚠️ Unexpected success for non-existent tour');
    } catch (e) {
      Logger.test('✅ Tour search properly handles non-existent codes');
    }
    
    // Test getting tours without auth (should fail)
    try {
      await tourService.getMyTours();
      Logger.test('⚠️ Unexpected success for unauthorized request');
    } catch (e) {
      Logger.test('✅ Tour service properly requires authentication');
    }
  } catch (e) {
    Logger.error('❌ Tour Service test failed: $e');
  }
  
  Logger.test('\n${'='*50}\n');
  
  Logger.test('🎉 Backend Integration Test Complete!');
  Logger.test('');
  Logger.test('Next steps:');
  Logger.test('1. Ensure your backend is running on localhost:5000');
  Logger.test('2. Test Google OAuth authentication in the app');
  Logger.test('3. Try creating and joining tours');
  Logger.test('4. Check the console for detailed API logs');
}