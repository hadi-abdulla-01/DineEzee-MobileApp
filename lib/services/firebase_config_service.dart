import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FirebaseConfigService {
  /// Check if restaurant configuration exists
  static Future<bool> hasRestaurantConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('firebase_config');
  }

  /// Get stored restaurant ID
  static Future<String?> getRestaurantId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('restaurant_id');
  }

  /// Get stored restaurant name
  static Future<String?> getRestaurantName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('restaurant_name');
  }

  /// Initialize Firebase with saved restaurant configuration
  static Future<void> initializeWithRestaurantConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString('firebase_config');
    
    if (configJson == null) {
      throw Exception('No Firebase configuration found. Please set up your restaurant first.');
    }
    
    try {
      final config = json.decode(configJson) as Map<String, dynamic>;
      
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: config['apiKey'] as String,
          authDomain: config['authDomain'] as String,
          projectId: config['projectId'] as String,
          storageBucket: config['storageBucket'] as String,
          messagingSenderId: config['messagingSenderId'] as String,
          appId: config['appId'] as String,
        ),
      );
      
      print('✅ Firebase initialized for restaurant: ${await getRestaurantName()}');
    } catch (e) {
      print('❌ Error initializing Firebase: $e');
      throw Exception('Failed to initialize Firebase: $e');
    }
  }

  /// Save restaurant configuration
  static Future<void> saveRestaurantConfig({
    required String code,
    required String restaurantId,
    required String restaurantName,
    required Map<String, dynamic> firebaseConfig,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('restaurant_code', code);
    await prefs.setString('restaurant_id', restaurantId);
    await prefs.setString('restaurant_name', restaurantName);
    await prefs.setString('firebase_config', json.encode(firebaseConfig));
    
    print('✅ Restaurant config saved: $restaurantName ($restaurantId)');
  }

  /// Clear restaurant configuration (for testing or switching restaurants)
  static Future<void> clearRestaurantConfig() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove('restaurant_code');
    await prefs.remove('restaurant_id');
    await prefs.remove('restaurant_name');
    await prefs.remove('firebase_config');
    
    print('✅ Restaurant config cleared');
  }
}
