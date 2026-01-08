# Kitchen Notification System

## Overview
The Kitchen Panel now includes a real-time notification system that alerts kitchen users when new orders arrive.

## Features

### 🔔 Audio Notifications
- **Sound Alert**: Plays a bell sound when a new order is received
- **Asset-based**: Uses `assets/notification.mp3` for reliable playback
- **Fallback**: Falls back to online sound if asset fails to load

### 📢 Visual Notifications
- **Animated Overlay**: Slides in from the top with smooth animations
- **Order Details**: Shows customer name, order type, and item count
- **Auto-dismiss**: Automatically disappears after 5 seconds
- **Manual Dismiss**: Can be closed by tapping the X button
- **Premium Design**: Gradient background with shadow effects

### 🔄 Real-time Updates
- **Firestore Listeners**: Monitors orders collection in real-time
- **Smart Detection**: Only notifies for truly new orders (not initial load)
- **Session Persistence**: Works across app restarts with saved login sessions

## How It Works

1. **Initialization**: When a kitchen user logs in, the notification service initializes
2. **Monitoring**: Listens to Firestore for new orders with status 'received', 'preparing', or 'ready'
3. **Detection**: Compares incoming orders against known order IDs
4. **Notification**: When a new order is detected:
   - Plays notification sound
   - Shows visual overlay with order details
   - Logs order information to console

## Technical Implementation

### Files Modified/Created
- `lib/services/notification_service.dart` - Core notification logic
- `lib/widgets/order_notification_overlay.dart` - Visual notification UI
- `lib/features/kitchen/kitchen_dashboard_screen.dart` - Integration
- `pubspec.yaml` - Added `audioplayers` package
- `assets/notification.mp3` - Notification sound file

### Dependencies
- `audioplayers: ^6.0.0` - For playing notification sounds
- `cloud_firestore` - For real-time order monitoring

## Usage

The notification system works automatically when:
1. Kitchen user is logged in
2. Kitchen Dashboard screen is active
3. A new order is placed through the web app or customer interface

No additional configuration required!

## Customization

### Change Notification Sound
Replace `assets/notification.mp3` with your preferred sound file.

### Adjust Auto-dismiss Duration
In `order_notification_overlay.dart`, modify:
```dart
Future.delayed(const Duration(seconds: 5), () {
  // Change 5 to your preferred duration
});
```

### Customize Visual Appearance
Edit `order_notification_overlay.dart` to change:
- Colors (gradient, text)
- Animation duration and curves
- Layout and spacing
- Icon and styling
