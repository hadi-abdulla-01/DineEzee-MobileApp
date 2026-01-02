import 'package:flutter/foundation.dart';

class MealSession {
  final String id;
  final String name;
  final String greeting;
  final String displayMessage;
  final String startTime; // Format: "HH:mm"
  final String endTime;
  final bool isActive;

  MealSession({
    required this.id,
    required this.name,
    required this.greeting,
    required this.displayMessage,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  factory MealSession.fromMap(String id, Map<String, dynamic> map) {
    return MealSession(
      id: map['id'] ?? id, // Prefer id from map (web app format), fallback to parameter
      name: map['name'] ?? '',
      greeting: map['greeting'] ?? '',
      displayMessage: map['displayMessage'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id, // Include id for web app compatibility
      'name': name,
      'greeting': greeting,
      'displayMessage': displayMessage,
      'startTime': startTime,
      'endTime': endTime,
      'isActive': isActive,
    };
  }
}

class ManualSessionOverride {
  final bool enabled;
  final String? sessionId;

  ManualSessionOverride({
    required this.enabled,
    this.sessionId,
  });

  factory ManualSessionOverride.fromMap(Map<String, dynamic> map) {
    return ManualSessionOverride(
      enabled: map['enabled'] ?? false,
      sessionId: map['sessionId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'sessionId': sessionId,
    };
  }
}

class Tax {
  final String id;
  final String name;
  final double rate;

  Tax({
    required this.id,
    required this.name,
    required this.rate,
  });

  factory Tax.fromMap(String id, Map<String, dynamic> map) {
    return Tax(
      id: id,
      name: map['name'] ?? '',
      rate: (map['rate'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'rate': rate,
    };
  }
}

class RestaurantSettings {
  final String currencySymbol;
  final int currencyDecimalPlaces;
  final String timezone;
  final List<MealSession> mealSessions;
  final List<Tax> taxes;
  final ManualSessionOverride? manualSessionOverride;
  final String? restaurantName;
  final String? restaurantAddress;
  final List<String>? menuCategories; // Web app format

  RestaurantSettings({
    required this.currencySymbol,
    required this.currencyDecimalPlaces,
    required this.timezone,
    required this.mealSessions,
    required this.taxes,
    this.manualSessionOverride,
    this.restaurantName,
    this.restaurantAddress,
    this.menuCategories,
  });

  factory RestaurantSettings.fromMap(Map<String, dynamic> map) {
    List<MealSession> sessions = [];
    if (map['mealSessions'] != null) {
      debugPrint('📋 Raw mealSessions type: ${map['mealSessions'].runtimeType}');
      debugPrint('📋 Raw mealSessions data: ${map['mealSessions']}');
      
      try {
        // Handle both formats: array (from web app) and map (from mobile app)
        if (map['mealSessions'] is List) {
          debugPrint('✅ Detected array format');
          // Web app format: array of objects with id field
          final sessionsList = map['mealSessions'] as List;
          debugPrint('📋 Array length: ${sessionsList.length}');
          
          sessions = sessionsList
              .map((session) {
                debugPrint('📋 Processing session: $session');
                final sessionMap = session as Map<String, dynamic>;
                return MealSession.fromMap(
                  sessionMap['id'] ?? '',
                  sessionMap,
                );
              })
              .toList();
          debugPrint('✅ Parsed ${sessions.length} sessions from array');
        } else if (map['mealSessions'] is Map) {
          debugPrint('✅ Detected map format');
          // Mobile app format: map with id as key
          final sessionsMap = map['mealSessions'] as Map<String, dynamic>;
          sessions = sessionsMap.entries
              .map((e) => MealSession.fromMap(e.key, e.value as Map<String, dynamic>))
              .toList();
          debugPrint('✅ Parsed ${sessions.length} sessions from map');
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Error parsing mealSessions: $e');
        debugPrint('Stack: $stackTrace');
      }
    } else {
      debugPrint('⚠️ mealSessions is null in settings');
    }

    List<Tax> taxList = [];
    if (map['taxes'] != null) {
      final taxesMap = map['taxes'] as Map<String, dynamic>;
      taxList = taxesMap.entries
          .map((e) => Tax.fromMap(e.key, e.value as Map<String, dynamic>))
          .toList();
    }

    return RestaurantSettings(
      currencySymbol: map['currencySymbol'] ?? '\$',
      currencyDecimalPlaces: map['currencyDecimalPlaces'] ?? 2,
      timezone: map['timezone'] ?? 'Asia/Kolkata',
      mealSessions: sessions,
      taxes: taxList,
      manualSessionOverride: map['manualSessionOverride'] != null
          ? ManualSessionOverride.fromMap(map['manualSessionOverride'])
          : null,
      restaurantName: map['restaurantName'],
      restaurantAddress: map['restaurantAddress'],
      menuCategories: map['menuCategories'] != null
          ? List<String>.from(map['menuCategories'])
          : null,
    );
  }
}
