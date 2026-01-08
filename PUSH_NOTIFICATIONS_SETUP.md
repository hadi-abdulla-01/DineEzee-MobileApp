# Push Notifications Setup Guide - Flutter App

## 🔔 Overview

The Flutter app now supports **Firebase Cloud Messaging (FCM)** push notifications, allowing kitchen users to receive order notifications even when:
- ✅ App is in background
- ✅ App is closed/terminated
- ✅ Device screen is off
- ✅ App is removed from recent apps

## 📦 What's Included

### 1. **Push Notification Service**
- `lib/services/push_notification_service.dart`
- Handles FCM token registration
- Manages background and foreground notifications
- Plays notification sounds
- Shows local notifications with order details

### 2. **Features**
- **Foreground Notifications**: When app is open
- **Background Notifications**: When app is in background
- **Terminated State Notifications**: When app is completely closed
- **Local Notifications**: Visual notifications with sound
- **Sound Alerts**: Audio notification for new orders
- **Real-time Firestore Listener**: Immediate order detection

## 🚀 Setup Instructions

### Step 1: Install Dependencies

Run in the `dine_easy_mobile` directory:
```bash
flutter pub get
```

This will install:
- `firebase_messaging: ^15.1.3`
- `flutter_local_notifications: ^18.0.1`

### Step 2: Android Configuration

#### A. Update `android/app/build.gradle`

Add this to the `defaultConfig` section:
```gradle
android {
    defaultConfig {
        // ... existing config
        minSdkVersion 21  // Required for FCM
    }
}
```

#### B. Update `android/app/src/main/AndroidManifest.xml`

Add these permissions and metadata:
```xml
<manifest>
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    
    <application>
        <!-- Add this metadata for default notification icon -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@mipmap/ic_launcher" />
        
        <!-- Add this metadata for default notification color -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/notification_color" />
    </application>
</manifest>
```

#### C. Create notification color resource

Create `android/app/src/main/res/values/colors.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="notification_color">#CB1E1D</color>
</resources>
```

### Step 3: iOS Configuration (if supporting iOS)

#### A. Update `ios/Runner/Info.plist`

Add notification permissions:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

#### B. Enable Push Notifications in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target
3. Go to "Signing & Capabilities"
4. Click "+ Capability"
5. Add "Push Notifications"
6. Add "Background Modes" and check "Remote notifications"

### Step 4: Firebase Console Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Cloud Messaging**
4. Note your **Server Key** (for backend notifications)

## 💻 Usage in Code

### Initialize in Kitchen Dashboard

Replace the old `NotificationService` with `PushNotificationService`:

```dart
import '../services/push_notification_service.dart';

class KitchenDashboardScreen extends StatefulWidget {
  // ...
}

class _KitchenDashboardScreenState extends State<KitchenDashboardScreen> {
  final PushNotificationService _notificationService = PushNotificationService();
  
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }
  
  Future<void> _initializeNotifications() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user?.branchId != null) {
      await _notificationService.initialize(
        user!.branchId!,
        onNewOrder: (order) {
          // Handle new order callback
          setState(() {
            // Refresh orders list
          });
        },
      );
    }
  }
  
  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }
}
```

## 🔧 How It Works

### 1. **App Initialization**
```
User logs in
    ↓
PushNotificationService.initialize(branchId)
    ↓
Request notification permissions
    ↓
Get FCM token
    ↓
Save token to Firestore (restaurants/{id}/fcmTokens/{token})
    ↓
Setup message handlers
    ↓
Setup Firestore listener
```

### 2. **New Order Flow**

#### When App is Open (Foreground):
```
New order created in Firestore
    ↓
Firestore listener detects change
    ↓
Show local notification
    ↓
Play sound
    ↓
Trigger callback to update UI
```

#### When App is Closed (Background/Terminated):
```
New order created in Firestore
    ↓
Server sends FCM push notification
    ↓
FCM wakes up app
    ↓
Background handler processes message
    ↓
Show local notification
    ↓
User taps notification
    ↓
App opens to kitchen screen
```

## 📱 Notification Types

### Local Notification
- **Title**: "🍽️ New Order #INV-001"
- **Body**: "Table 5 - 3 items"
- **Sound**: ✅ Enabled
- **Vibration**: ✅ Enabled
- **Priority**: High

### FCM Push Notification
- **Channel**: "kitchen_orders"
- **Importance**: Max
- **Persistent**: Yes (stays until dismissed)

## 🔐 FCM Token Management

Tokens are automatically:
- ✅ Generated on first app launch
- ✅ Saved to Firestore
- ✅ Refreshed when expired
- ✅ Associated with branch ID
- ✅ Updated on token refresh

### Firestore Structure:
```
restaurants/{restaurantId}/fcmTokens/{token}
  - token: "fcm_token_string"
  - branchId: "branch_001"
  - platform: "android"
  - updatedAt: timestamp
```

## 🌐 Server-Side Integration (Optional)

To send push notifications from your backend (e.g., when order is created via web):

### Using Firebase Admin SDK (Node.js):

```javascript
const admin = require('firebase-admin');

// Get all tokens for a branch
const tokensSnapshot = await admin.firestore()
  .collection('restaurants')
  .doc(restaurantId)
  .collection('fcmTokens')
  .where('branchId', '==', branchId)
  .get();

const tokens = tokensSnapshot.docs.map(doc => doc.data().token);

// Send notification
const message = {
  notification: {
    title: '🍽️ New Order #INV-001',
    body: 'Table 5 - 3 items',
  },
  data: {
    orderId: 'order_id_here',
    branchId: branchId,
  },
  tokens: tokens,
};

await admin.messaging().sendMulticast(message);
```

## 🧪 Testing

### Test Foreground Notifications:
1. Open app and log in as kitchen user
2. Create a new order from web app
3. Should see notification + hear sound

### Test Background Notifications:
1. Open app and log in
2. Press home button (app goes to background)
3. Create a new order from web app
4. Should receive push notification
5. Tap notification → app opens

### Test Terminated State:
1. Open app and log in
2. Close app completely (swipe from recent apps)
3. Create a new order from web app
4. Should receive push notification
5. Tap notification → app opens

## 🐛 Troubleshooting

### No Notifications Received

**Check:**
1. ✅ Notification permissions granted
2. ✅ FCM token generated (check logs)
3. ✅ Token saved to Firestore
4. ✅ Internet connection active
5. ✅ Firebase project configured correctly

**Logs to check:**
```
🔑 FCM Token: [token_string]
✅ FCM token saved to Firestore
📢 PushNotificationService initialized
🔔 New order detected: [order_id]
```

### Sound Not Playing

**Check:**
1. ✅ Device not in silent mode
2. ✅ Notification sound enabled in app settings
3. ✅ `assets/notification.mp3` exists
4. ✅ Asset declared in `pubspec.yaml`

### Notifications Only Work When App is Open

**Check:**
1. ✅ Background message handler registered in `main.dart`
2. ✅ Android permissions added to manifest
3. ✅ FCM server key configured
4. ✅ App has background execution permissions

## 📊 Monitoring

### Check FCM Token Status:
```dart
final token = PushNotificationService().fcmToken;
print('Current FCM Token: $token');
```

### Check Notification Service Status:
```dart
final isInitialized = PushNotificationService().isInitialized;
print('Notification Service: ${isInitialized ? "Running" : "Stopped"}');
```

## 🔒 Security Considerations

1. **Token Security**: FCM tokens are stored in Firestore with branch association
2. **Branch Isolation**: Only users from the same branch receive notifications
3. **Permission-Based**: Users must grant notification permissions
4. **Token Refresh**: Tokens automatically refresh when expired

## 🚀 Next Steps

1. **Install dependencies**: `flutter pub get`
2. **Configure Android**: Update manifest and gradle
3. **Test notifications**: Create test orders
4. **Monitor logs**: Check FCM token generation
5. **Deploy**: Build and test on physical device

## 📝 Notes

- **Background notifications require Google Play Services** on Android
- **iOS requires APNs certificate** for push notifications
- **Notifications work best on physical devices** (emulators may have issues)
- **FCM tokens expire** and are automatically refreshed
- **Sound plays even when device is on silent** (configurable)

---

**Your kitchen staff will never miss an order again!** 🎉
