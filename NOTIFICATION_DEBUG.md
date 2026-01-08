# Push Notification Debugging Guide

## 🔍 Step-by-Step Debugging

### Step 1: Check if App is Running with Updated Code

Run the app in debug mode to see console logs:

```bash
flutter run -d R5CT111JZNW
```

or if device not found:

```bash
flutter devices
flutter run -d [your_device_id]
```

### Step 2: Check Console Logs

When the app starts, you should see:

```
🔔 Initializing push notifications for branch: branch_xxx
📱 Notification permission status: authorized
🔑 FCM Token: [long_token_string]
✅ FCM token saved to Firestore
✅ Push notifications initialized
```

**If you DON'T see these logs:**
- The PushNotificationService is not being initialized
- Check if you're logged in as a kitchen user with a branchId

### Step 3: Test Firestore Listener

Create a test order and watch the console. You should see:

```
🔔 New order detected: order_123
📬 Local notification shown: New Order - Dine-in
🔊 Notification sound played
```

**If you see these logs but NO notification:**
- Notification permissions are denied
- Go to Settings → Apps → DineEasy → Notifications → Enable

### Step 4: Check Notification Permissions

The app should request permissions on first launch. If it didn't:

**Manually grant permissions:**
1. Open Settings
2. Go to Apps → DineEasy
3. Tap Permissions → Notifications
4. Enable "Allow notifications"

### Step 5: Test Different Scenarios

#### Test 1: App in Foreground
1. Keep app open
2. Create order from web
3. Should see: Visual overlay + Sound + Console logs

#### Test 2: App in Background
1. Press home button (don't close app)
2. Create order from web
3. Should see: Notification in notification tray

#### Test 3: App Completely Closed
1. Swipe app from recent apps
2. Wait 5 seconds
3. Create order from web
4. Should see: Push notification appears

## 🐛 Common Issues

### Issue 1: No Console Logs at All

**Problem:** PushNotificationService not initialized

**Solution:**
```bash
# Rebuild the app
flutter clean
flutter pub get
flutter run -d [device_id]
```

### Issue 2: "Permission Denied" in Logs

**Problem:** User denied notification permissions

**Solution:**
1. Uninstall the app
2. Reinstall
3. When prompted for permissions, tap "Allow"

### Issue 3: FCM Token Not Generated

**Problem:** Firebase not configured or Google Play Services missing

**Check:**
```
- Is google-services.json in android/app/?
- Is device running Google Play Services?
- Is internet connected?
```

### Issue 4: Notifications Only Work When App is Open

**Problem:** Background notifications not configured

**Check:**
- Is `FirebaseMessaging.onBackgroundMessage` registered in main.dart?
- Is core library desugaring enabled in build.gradle.kts?

## 🧪 Quick Test Script

Run this to verify everything:

```bash
# 1. Clean build
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Run in debug mode
flutter run -d [device_id]

# 4. Watch logs for:
# - "🔔 Initializing push notifications"
# - "🔑 FCM Token: ..."
# - "✅ Push notifications initialized"

# 5. Create test order from web app

# 6. Check for:
# - "🔔 New order detected"
# - "📬 Local notification shown"
```

## 📋 Checklist

Before reporting "not working", verify:

- [ ] App rebuilt after code changes
- [ ] Running latest version (check version in About)
- [ ] Logged in as kitchen user
- [ ] User has a branchId assigned
- [ ] Notification permissions granted
- [ ] Internet connection active
- [ ] Google Play Services installed
- [ ] Battery optimization disabled for app
- [ ] Console shows initialization logs
- [ ] FCM token saved to Firestore

## 🔧 Manual Verification

### Check 1: Is PushNotificationService Being Used?

Look at the code in `lib/features/kitchen/kitchen_dashboard_screen.dart`:

Line 6 should be:
```dart
import '../../services/push_notification_service.dart';
```

Line 24 should be:
```dart
final PushNotificationService _notificationService = PushNotificationService();
```

### Check 2: Is FCM Token in Firestore?

1. Open Firebase Console
2. Go to Firestore Database
3. Navigate to: `restaurants/{your_restaurant_id}/fcmTokens`
4. Should see documents with tokens

### Check 3: Is Background Handler Registered?

Look at `lib/main.dart`:

Should have:
```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/push_notification_service.dart';

void main() async {
  // ...
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  // ...
}
```

## 🚨 Emergency Debug Mode

If nothing works, add this debug code to see what's happening:

In `lib/services/push_notification_service.dart`, add print statements:

```dart
Future<void> initialize(String branchId, {NotificationCallback? onNewOrder}) async {
  print('DEBUG: initialize() called with branchId: $branchId');
  
  if (_isInitialized && _currentBranchId == branchId) {
    print('DEBUG: Already initialized, skipping');
    return;
  }

  print('DEBUG: Starting initialization...');
  _currentBranchId = branchId;
  _onNewOrder = onNewOrder;

  print('DEBUG: Initializing local notifications...');
  await _initializeLocalNotifications();
  
  print('DEBUG: Requesting permissions...');
  await _requestPermissions();
  
  print('DEBUG: Getting FCM token...');
  await _getFCMToken();
  
  print('DEBUG: Setup complete!');
}
```

## 📞 What to Share for Help

If still not working, share:

1. **Console logs** from app startup
2. **Console logs** when creating test order
3. **Screenshot** of notification permissions
4. **Firestore screenshot** showing fcmTokens collection
5. **Device info**: Android version, manufacturer
6. **App version**: Check in About screen

---

**Most Common Fix:** Rebuild the app and grant permissions!

```bash
flutter clean
flutter pub get
flutter build apk --release
flutter install
```

Then open app and **allow notifications** when prompted!
