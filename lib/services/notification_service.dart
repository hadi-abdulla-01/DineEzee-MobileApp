import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/order.dart' as models;
import 'firebase_config_service.dart';

// Callback type for showing notifications
typedef NotificationCallback = void Function(models.Order order);

class NotificationService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<QuerySnapshot>? _orderSubscription;
  Set<String> _knownOrderIds = {};
  bool _isInitialized = false;
  String? _currentBranchId;
  NotificationCallback? _onNewOrder;

  /// Initialize the notification service for a specific branch
  Future<void> initialize(String branchId, {NotificationCallback? onNewOrder}) async {
    if (_isInitialized && _currentBranchId == branchId) {
      print('📢 NotificationService already initialized for branch: $branchId');
      return;
    }

    print('📢 Initializing NotificationService for branch: $branchId');
    _currentBranchId = branchId;
    _onNewOrder = onNewOrder;

    // Get restaurant ID
    final restaurantId = await FirebaseConfigService.getRestaurantId();
    if (restaurantId == null) {
      print('❌ No restaurant ID found');
      return;
    }

    // Get all current active orders to populate known IDs
    final initialSnapshot = await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .collection('orders')
        .where('branchId', isEqualTo: branchId)
        .where('status', whereIn: ['received', 'preparing', 'ready'])
        .get();

    _knownOrderIds = initialSnapshot.docs.map((doc) => doc.id).toSet();
    print('📋 Initial known orders: ${_knownOrderIds.length}');

    // Listen for new orders
    _orderSubscription = FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .collection('orders')
        .where('branchId', isEqualTo: branchId)
        .where('status', whereIn: ['received', 'preparing', 'ready'])
        .snapshots()
        .listen((snapshot) {
      _handleOrderSnapshot(snapshot);
    });

    _isInitialized = true;
    print('✅ NotificationService initialized');
  }

  /// Handle order snapshot changes
  void _handleOrderSnapshot(QuerySnapshot snapshot) {
    for (var change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        final orderId = change.doc.id;
        
        // Only notify if this is a truly new order (not from initial load)
        if (!_knownOrderIds.contains(orderId)) {
          print('🔔 New order detected: $orderId');
          _playNotificationSound();
          
          // Parse order and trigger callback
          try {
            final orderData = change.doc.data() as Map<String, dynamic>;
            final order = models.Order.fromFirestore(change.doc.id, orderData);
            _onNewOrder?.call(order);
          } catch (e) {
            print('❌ Error parsing order for notification: $e');
          }
        }
        
        _knownOrderIds.add(orderId);
      }
    }
  }

  /// Play notification sound
  Future<void> _playNotificationSound() async {
    try {
      // Use a built-in system sound or asset
      // For now, we'll use a simple beep sound from assets
      await _audioPlayer.play(AssetSource('notification.mp3'));
      print('🔊 Notification sound played');
    } catch (e) {
      print('❌ Error playing notification sound: $e');
      // Fallback: try to play from URL if asset fails
      try {
        await _audioPlayer.play(UrlSource(
          'https://www.soundjay.com/misc/sounds/bell-ringing-05.mp3'
        ));
      } catch (e2) {
        print('❌ Fallback sound also failed: $e2');
      }
    }
  }


  /// Dispose the service
  void dispose() {
    print('🛑 Disposing NotificationService');
    _orderSubscription?.cancel();
    _audioPlayer.dispose();
    _isInitialized = false;
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
