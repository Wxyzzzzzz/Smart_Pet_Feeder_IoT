# Notification Feature Guide

## Overview
The Smart Pet Feeder now includes comprehensive notification features to keep you informed about your pet's feeding status and device health.

## Notification Types

### 1. 🍽️ Low Food Level Alert
**Trigger:** Food level drops below 30%
**Purpose:** Reminds you to refill the food container before it runs empty

**Example:**
```
Title: "🍽️ Food Level Low!"
Body: "Food is at 25.0%. Please refill the container soon."
```

**Features:**
- Automatic monitoring via dashboard sensor stream
- 30-minute cooldown to avoid spam
- Resets when food level returns above threshold

---

### 2. ✅ Scheduled Feeding Complete
**Trigger:** When a scheduled feeding completes successfully
**Purpose:** Confirms your pet was fed on schedule

**Example:**
```
Title: "✅ Scheduled Feeding Complete"
Body: "Morning Feed completed! Fed 25g. Food remaining: 45.0%"
```

**Features:**
- Shows schedule name and portion size
- Displays remaining food level
- Automatically checks if refill is needed

---

### 3. 🎯 Manual Feeding Complete
**Trigger:** When you manually feed your pet via the app
**Purpose:** Confirms the manual feeding action

**Example:**
```
Title: "🎯 Manual Feeding Complete"
Body: "Fed 20g. Food remaining: 50.0%"
```

**Features:**
- Immediate notification after manual feed
- Shows portion dispensed
- Checks if food level is low

---

### 4. ⚠️ High Moisture Alert
**Trigger:** Humidity exceeds 60%
**Purpose:** Warns about potential food contamination

**Example:**
```
Title: "⚠️ High Moisture Alert!"
Body: "Moisture is at 65.0%. Food might be contaminated. Please check the container."
```

**Features:**
- Monitors humidity sensor continuously
- 30-minute cooldown between alerts
- Helps prevent feeding spoiled food to your pet

---

## Setup Instructions

### 1. Install Dependencies
Run the following command to install notification packages:
```bash
flutter pub get
```

This will install:
- `flutter_local_notifications` - For local device notifications
- `firebase_messaging` - For push notifications

### 2. Android Configuration
The Android manifest has been updated with necessary permissions:
- `POST_NOTIFICATIONS` - For Android 13+ notification permission
- `RECEIVE_BOOT_COMPLETED` - For persistent notifications
- `VIBRATE` - For notification vibration

### 3. iOS Configuration
For iOS, notification permissions are requested automatically on first launch.

### 4. Backend Monitoring (Optional)
For remote push notifications, run the notification monitor script:
```bash
cd cloud
python notification_monitor.py
```

This script monitors Firestore and sends FCM notifications for:
- Scheduled feeding completions
- Low food alerts
- High moisture warnings

---

## Notification Thresholds

You can customize these thresholds in [notification_service.dart](lib/services/notification_service.dart):

```dart
// Thresholds for notifications
static const double LOW_FOOD_THRESHOLD = 30.0;       // Below 30%
static const double HIGH_MOISTURE_THRESHOLD = 60.0;  // Above 60%

// Cooldown period (in minutes)
static const int NOTIFICATION_COOLDOWN_MINUTES = 30;
```

---

## How It Works

### Local Notifications
1. **Dashboard Monitoring**: The dashboard continuously monitors sensor data
2. **Automatic Checks**: Each data update triggers notification checks
3. **Smart Cooldown**: Prevents notification spam with 30-minute cooldown
4. **Local Display**: Notifications appear in device notification tray

### In-App Alerts
Use the `showInAppAlert()` method for immediate in-app dialogs:
```dart
_notificationService.showInAppAlert(
  context: context,
  title: 'Alert Title',
  message: 'Alert message',
  icon: Icons.warning,
  iconColor: Colors.orange,
);
```

### Remote Push Notifications (FCM)
1. Backend monitors Firestore changes
2. Detects threshold violations or events
3. Sends FCM message to user devices
4. App displays notification even when closed

---

## Testing Notifications

### Test Low Food Alert
1. Manually set food level below 30 in Firebase Console
2. Open dashboard to trigger monitoring
3. Notification should appear

### Test High Moisture Alert
1. Set humidity above 60 in Firebase Console
2. Open dashboard
3. Notification should appear

### Test Manual Feed Notification
1. Tap "FEED NOW" button
2. Notification confirms feeding
3. May trigger low food alert if level drops below 30%

### Test Scheduled Feed Notification
1. Create a schedule for current time
2. Wait for backend to execute
3. Notification appears when feeding completes

---

## Troubleshooting

### Notifications Not Appearing

**Check Permissions:**
- Android 13+: Go to Settings > Apps > Smart Pet Feeder > Notifications
- iOS: Settings > Smart Pet Feeder > Notifications

**Check Notification Service:**
- Verify initialization in `main.dart`
- Check console for error messages

**Check Cooldown:**
- Notifications have 30-minute cooldown
- Reset state: `_notificationService.resetNotificationStates()`

### FCM Push Not Working

**Check Backend:**
- Ensure `notification_monitor.py` is running
- Check Firebase console for FCM errors
- Verify `serviceAccountKey.json` has messaging permissions

**Check Device Token:**
- Token is printed on app launch
- Subscribe device to 'all_users' topic

---

## Code Examples

### Manual Notification
```dart
await _notificationService.showLocalNotification(
  id: 1,
  title: 'Custom Alert',
  body: 'This is a custom notification',
  payload: 'custom_action',
);
```

### Check Food Level
```dart
await _notificationService.checkFoodLevel(foodPercentage);
```

### Check Moisture
```dart
await _notificationService.checkMoistureLevel(moisturePercentage);
```

### Notify Manual Feed
```dart
await _notificationService.notifyManualFeed(
  portionSize: 20.0,
  foodRemaining: 45.0,
);
```

### Notify Scheduled Feed
```dart
await _notificationService.notifyScheduledFeed(
  scheduleName: 'Morning Feed',
  portionSize: 25.0,
  foodRemaining: 50.0,
);
```

---

## Security Considerations

1. **Permissions**: App requests minimal required permissions
2. **Privacy**: Notifications are local by default
3. **FCM Security**: Uses Firebase authentication
4. **Data Protection**: No sensitive data in notification bodies

---

## Future Enhancements

Potential improvements:
- [ ] Customizable notification sounds
- [ ] Notification scheduling preferences
- [ ] Daily summary notifications
- [ ] Pet eating pattern alerts
- [ ] Low battery warnings (if battery-powered)
- [ ] Offline mode notifications
- [ ] Multi-device support
- [ ] Custom notification channels

---

## Support

For issues or questions:
1. Check console logs for errors
2. Verify Firebase configuration
3. Test notification permissions
4. Review this guide for setup steps

---

## Related Files

- [notification_service.dart](lib/services/notification_service.dart) - Core notification logic
- [dashboard_screen.dart](lib/dashboard_screen.dart) - Monitoring integration
- [main.dart](lib/main.dart) - Service initialization
- [notification_monitor.py](cloud/notification_monitor.py) - Backend FCM monitor
- [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml) - Android permissions
