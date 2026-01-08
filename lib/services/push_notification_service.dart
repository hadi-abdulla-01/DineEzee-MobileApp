import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/order.dart' as models;
import 'firebase_config_service.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background message received: ${message.messageId}');
  print('📦 Title: ${message.notification?.title}');
  print('📝 Body: ${message.notification?.body}');
  print('📊 Data: ${message.data}');
}

// Callback type for showing notifications
typedef NotificationCallback = void Function(models.Order order);

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  StreamSubscription<QuerySnapshot>? _orderSubscription;
  Set<String> _knownOrderIds = {};
  bool _isInitialized = false;
  String? _currentBranchId;
  String? _fcmToken;
  NotificationCallback? _onNewOrder;

  /// Initialize push notifications
  Future<void> initialize(String branchId, {NotificationCallback? onNewOrder}) async {
    if (_isInitialized && _currentBranchId == branchId) {
      print('📢 PushNotificationService already initialized for branch: $branchId');
      return;
    }

    print('📢 Initializing PushNotificationService for branch: $branchId');
    _currentBranchId = branchId;
    _onNewOrder = onNewOrder;

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Request notification permissions
    await _requestPermissions();

    // Get FCM token
    await _getFCMToken();

    // Setup message handlers
    _setupMessageHandlers();

    // Setup Firestore listener for real-time updates
    await _setupFirestoreListener(branchId);

    _isInitialized = true;
    print('✅ PushNotificationService initialized');
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    // Create Android notification channel with high importance
    const androidChannel = AndroidNotificationChannel(
      'kitchen_orders',
      'Kitchen Orders',
      description: 'Notifications for new kitchen orders',
      importance: Importance.max,  // Maximum importance for heads-up
      playSound: true,
      enableVibration: true,
      showBadge: true,
      // Using system default sound (works reliably)
    );

    // Create the channel on the device
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    print('✅ Local notifications initialized');
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    print('📱 Requesting notification permissions...');
    
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('📱 Notification permission status: ${settings.authorizationStatus}');
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted notification permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ User granted provisional notification permission');
    } else {
      print('❌ User declined or has not accepted notification permission');
    }
    
    // Also request Android 13+ runtime permission for local notifications
    if (_localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>() != null) {
      final granted = await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!
          .requestNotificationsPermission();
      print('📱 Android local notification permission: ${granted ?? false}');
    }
  }

  /// Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('🔑 FCM Token: $_fcmToken');
      
      // Save token to Firestore for server-side notifications
      if (_fcmToken != null) {
        await _saveFCMToken(_fcmToken!);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('🔄 FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        _saveFCMToken(newToken);
      });
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    try {
      final restaurantId = await FirebaseConfigService.getRestaurantId();
      if (restaurantId == null || _currentBranchId == null) return;

      // Save token associated with this device/branch
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .collection('fcmTokens')
          .doc(token)
          .set({
        'token': token,
        'branchId': _currentBranchId,
        'platform': 'android', // or detect platform
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ FCM token saved to Firestore');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Foreground message received: ${message.messageId}');
      _handleMessage(message, isBackground: false);
    });

    // Background messages (app in background but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Background message opened: ${message.messageId}');
      _handleMessage(message, isBackground: true);
    });

    // Check if app was opened from a terminated state
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('🔔 App opened from terminated state: ${message.messageId}');
        _handleMessage(message, isBackground: true);
      }
    });
  }

  /// Handle incoming message
  void _handleMessage(RemoteMessage message, {required bool isBackground}) {
    print('📨 Handling message: ${message.notification?.title}');
    
    // Show local notification
    _showLocalNotification(
      title: message.notification?.title ?? 'New Order',
      body: message.notification?.body ?? 'You have a new order',
      payload: message.data['orderId'],
    );

    // Play sound
    _playNotificationSound();

    // Trigger callback if provided
    if (message.data['orderId'] != null && _onNewOrder != null) {
      _fetchAndNotifyOrder(message.data['orderId']);
    }
  }

  /// Fetch order and trigger callback
  Future<void> _fetchAndNotifyOrder(String orderId) async {
    try {
      final restaurantId = await FirebaseConfigService.getRestaurantId();
      if (restaurantId == null) return;

      final orderDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .collection('orders')
          .doc(orderId)
          .get();

      if (orderDoc.exists) {
        final order = models.Order.fromFirestore(orderDoc.id, orderDoc.data()!);
        _onNewOrder?.call(order);
      }
    } catch (e) {
      print('❌ Error fetching order for notification: $e');
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'kitchen_orders',
      'Kitchen Orders',
      channelDescription: 'Notifications for new kitchen orders',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    print('📬 Local notification shown: $title');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('👆 Notification tapped: ${response.payload}');
    // Navigate to order details or kitchen screen
    // This would require navigation context
  }

  /// Setup Firestore listener for real-time updates
  Future<void> _setupFirestoreListener(String branchId) async {
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

    print('✅ Firestore listener setup');
  }

  /// Handle order snapshot changes
  void _handleOrderSnapshot(QuerySnapshot snapshot) {
    for (var change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        final orderId = change.doc.id;
        
        // Only notify if this is a truly new order (not from initial load)
        if (!_knownOrderIds.contains(orderId)) {
          print('🔔 New order detected: $orderId');
          
          try {
            final orderData = change.doc.data() as Map<String, dynamic>;
            final order = models.Order.fromFirestore(change.doc.id, orderData);
            
            // Show notification
            _showLocalNotification(
              title: '🍽️ New Order - ${order.orderType}',
              body: '${order.customerName} - ${order.items.length} items',
              payload: orderId,
            );
            
            // Play sound
            _playNotificationSound();
            
            // Trigger callback
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
    print('🛑 Disposing PushNotificationService');
    _orderSubscription?.cancel();
    _audioPlayer.dispose();
    _isInitialized = false;
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get FCM token
  String? get fcmToken => _fcmToken;
}
