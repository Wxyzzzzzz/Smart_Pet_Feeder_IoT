import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Thresholds for notifications
  static const double LOW_FOOD_THRESHOLD =
      30.0; // Below 30% triggers notification
  static const double HIGH_MOISTURE_THRESHOLD =
      80.0; // Above 60% triggers notification

  // Track notification states to avoid spam
  bool _lowFoodNotificationShown = false;
  bool _highMoistureNotificationShown = false;
  DateTime? _lastLowFoodNotification;
  DateTime? _lastHighMoistureNotification;

  // Cooldown period (in minutes) to avoid repeated notifications
  static const int NOTIFICATION_COOLDOWN_MINUTES = 30;

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      // Request permissions for iOS
      await _requestPermissions();

      // Initialize local notifications
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iOSSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iOSSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Setup Firebase Cloud Messaging
      await _setupFirebaseMessaging();

      print('Notification service initialized successfully');
    } catch (e) {
      print('Error initializing notification service: $e');
      // Don't throw - allow app to continue even if notifications fail
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      // Firebase Messaging permissions
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('Notification permission status: ${settings.authorizationStatus}');

      // Android 13+ requires explicit notification permission
      // Only request if we're on Android platform
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }
    } catch (e) {
      print('Error requesting notification permissions: $e');
      // Don't throw - allow app to continue even if notifications fail
    }
  }

  /// Setup Firebase Cloud Messaging
  Future<void> _setupFirebaseMessaging() async {
    try {
      // Get FCM token
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Received foreground message: ${message.messageId}');
        _handleFCMMessage(message);
      });

      // Handle background messages
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Message opened app: ${message.messageId}');
        _handleFCMMessage(message);
      });
    } catch (e) {
      print('Error setting up Firebase Messaging: $e');
      // FCM may not work on web, so just log and continue
    }
  }

  /// Handle FCM message
  void _handleFCMMessage(RemoteMessage message) {
    if (message.notification != null) {
      showLocalNotification(
        title: message.notification!.title ?? 'Pet Feeder',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Navigate to relevant screen based on payload
    // This can be expanded based on your needs
  }

  /// Show local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'pet_feeder_channel',
      'Pet Feeder Notifications',
      channelDescription: 'Notifications for pet feeder status and alerts',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Check if cooldown period has passed
  bool _canShowNotification(DateTime? lastNotification) {
    if (lastNotification == null) return true;
    final now = DateTime.now();
    final difference = now.difference(lastNotification);
    return difference.inMinutes >= NOTIFICATION_COOLDOWN_MINUTES;
  }

  /// Monitor food level and show notification if low
  Future<void> checkFoodLevel(double foodPercentage) async {
    if (foodPercentage <= LOW_FOOD_THRESHOLD) {
      if (!_lowFoodNotificationShown ||
          _canShowNotification(_lastLowFoodNotification)) {
        await showLocalNotification(
          id: 1,
          title: '🍽️ Food Level Low!',
          body:
              'Food is at ${foodPercentage.toStringAsFixed(1)}%. Please refill the container soon.',
          payload: 'low_food',
        );
        _lowFoodNotificationShown = true;
        _lastLowFoodNotification = DateTime.now();
      }
    } else {
      // Reset flag when food level is back to normal
      _lowFoodNotificationShown = false;
    }
  }

  /// Show notification when scheduled feeding occurs
  Future<void> notifyScheduledFeed({
    required String scheduleName,
    required double portionSize,
    required double foodRemaining,
  }) async {
    await showLocalNotification(
      id: 2,
      title: '✅ Scheduled Feeding Complete',
      body:
          '$scheduleName completed! Fed ${portionSize}g. Food remaining: ${foodRemaining.toStringAsFixed(1)}%',
      payload: 'scheduled_feed',
    );

    // Also check if food is low after feeding
    await checkFoodLevel(foodRemaining);
  }

  /// Show notification when manual feeding occurs
  Future<void> notifyManualFeed({
    required double portionSize,
    required double foodRemaining,
  }) async {
    await showLocalNotification(
      id: 3,
      title: '🎯 Manual Feeding Complete',
      body:
          'Fed ${portionSize}g. Food remaining: ${foodRemaining.toStringAsFixed(1)}%',
      payload: 'manual_feed',
    );

    // Also check if food is low after feeding
    await checkFoodLevel(foodRemaining);
  }

  /// Monitor moisture level and show warning if high
  Future<void> checkMoistureLevel(double moisturePercentage) async {
    if (moisturePercentage >= HIGH_MOISTURE_THRESHOLD) {
      if (!_highMoistureNotificationShown ||
          _canShowNotification(_lastHighMoistureNotification)) {
        await showLocalNotification(
          id: 4,
          title: '⚠️ High Moisture Alert!',
          body:
              'Moisture is at ${moisturePercentage.toStringAsFixed(1)}%. Food might be contaminated. Please check the container.',
          payload: 'high_moisture',
        );
        _highMoistureNotificationShown = true;
        _lastHighMoistureNotification = DateTime.now();
      }
    } else {
      // Reset flag when moisture level is back to normal
      _highMoistureNotificationShown = false;
    }
  }

  /// Show pop-up dialog for immediate alerts (in-app)
  void showInAppAlert({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.info,
    Color iconColor = Colors.blue,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Reset all notification states (useful for testing or manual reset)
  void resetNotificationStates() {
    _lowFoodNotificationShown = false;
    _highMoistureNotificationShown = false;
    _lastLowFoodNotification = null;
    _lastHighMoistureNotification = null;
  }
}

// Navigation service for global context access
class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
