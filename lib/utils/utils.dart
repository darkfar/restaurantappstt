// lib/utils/utils.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../data/data.dart';

class NotificationHelper {
  // Private constructor
  NotificationHelper._();

  // Static instance
  static NotificationHelper? _instance;

  // Getter for instance
  static NotificationHelper get instance {
    _instance ??= NotificationHelper._();
    return _instance!;
  }

  // Factory constructor
  factory NotificationHelper() => instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initNotifications() async {
    if (_isInitialized) {
      debugPrint('NotificationHelper already initialized');
      return;
    }

    try {
      await _configureLocalTimeZone();
      await _configureNotifications();
      _isInitialized = true;
      debugPrint('NotificationHelper initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      rethrow;
    }
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      tz.initializeTimeZones();

      // Use a more robust timezone detection
      String timeZoneName = 'UTC'; // Default fallback

      if (Platform.isAndroid) {
        timeZoneName = 'Asia/Jakarta';
      } else if (Platform.isIOS) {
        timeZoneName = 'Asia/Jakarta';
      } else {
        // For desktop platforms, use UTC as fallback
        timeZoneName = 'UTC';
      }

      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (e) {
        debugPrint('Failed to set timezone $timeZoneName, using UTC: $e');
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    } catch (e) {
      debugPrint('Error configuring timezone: $e');
      // Initialize with UTC as absolute fallback
      try {
        tz.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (fallbackError) {
        debugPrint('Failed to initialize timezone with UTC fallback: $fallbackError');
        rethrow;
      }
    }
  }

  Future<void> _configureNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initializationSettings =
      InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) async {
          final String? payload = details.payload;
          if (payload != null) {
            debugPrint('notification payload: $payload');
          }
        },
      );

      // Request permissions for mobile platforms only
      if (Platform.isIOS) {
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      } else if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

        await androidImplementation?.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('Error configuring notifications: $e');
      // Don't rethrow here as desktop platforms might not support notifications
      if (Platform.isAndroid || Platform.isIOS) {
        rethrow;
      }
    }
  }

  Future<void> scheduleDailyReminder() async {
    if (!_isInitialized) {
      debugPrint('NotificationHelper not initialized, skipping schedule');
      return;
    }

    // Skip scheduling on desktop platforms
    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint('Notifications not supported on this platform');
      return;
    }

    try {
      const int notificationId = 1;

      // Get random restaurant data
      final restaurant = await _getRandomRestaurant();

      final String title = 'Lunch Time! 🍽️';
      final String body = restaurant != null
          ? 'How about trying ${restaurant.name} in ${restaurant.city}? Rating: ${restaurant.rating}/5'
          : 'It\'s time for lunch! Discover amazing restaurants near you.';

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'daily_reminder_channel',
        'Daily Reminder',
        channelDescription: 'Daily lunch reminder notifications',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'Daily Reminder',
        styleInformation: BigTextStyleInformation(''),
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails();

      const NotificationDetails platformChannelSpecifics =
      NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      // Schedule daily at 11:00 AM
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        _nextInstanceOfElevenAM(),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: restaurant != null ? jsonEncode(restaurant.toJson()) : null,
      );

      debugPrint('Daily reminder scheduled for 11:00 AM');
    } catch (e) {
      debugPrint('Error scheduling daily reminder: $e');
      // Don't rethrow to prevent app crashes on unsupported platforms
    }
  }

  Future<Restaurant?> _getRandomRestaurant() async {
    try {
      final apiService = ApiService();
      final restaurants = await apiService.getRestaurantList();

      if (restaurants.isNotEmpty) {
        final random = Random();
        return restaurants[random.nextInt(restaurants.length)];
      }
    } catch (e) {
      debugPrint('Error fetching random restaurant: $e');
    }
    return null;
  }

  tz.TZDateTime _nextInstanceOfElevenAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      11, // 11 AM
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> cancelDailyReminder() async {
    if (!_isInitialized) {
      debugPrint('NotificationHelper not initialized, skipping cancel');
      return;
    }

    // Skip cancelling on desktop platforms
    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint('Notifications not supported on this platform');
      return;
    }

    try {
      await flutterLocalNotificationsPlugin.cancel(1);
      debugPrint('Daily reminder cancelled');
    } catch (e) {
      debugPrint('Error cancelling daily reminder: $e');
      // Don't rethrow to prevent app crashes
    }
  }

  Future<void> showInstantNotification(String title, String body) async {
    if (!_isInitialized) {
      debugPrint('NotificationHelper not initialized, skipping instant notification');
      return;
    }

    // Skip on desktop platforms
    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint('Notifications not supported on this platform');
      return;
    }

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'instant_notification_channel',
        'Instant Notifications',
        channelDescription: 'Instant notification messages',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'Instant Notification',
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails();

      const NotificationDetails platformChannelSpecifics =
      NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await flutterLocalNotificationsPlugin.show(
        0, // notification id
        title,
        body,
        platformChannelSpecifics,
      );
    } catch (e) {
      debugPrint('Error showing instant notification: $e');
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized || (!Platform.isAndroid && !Platform.isIOS)) {
      return [];
    }

    try {
      return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('Error getting pending notifications: $e');
      return [];
    }
  }

  Future<void> cancelAllNotifications() async {
    if (!_isInitialized || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }

    try {
      await flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }
}

class BackgroundService {
  // Private constructor
  BackgroundService._();

  // Static instance
  static BackgroundService? _instance;

  // Getter for instance
  static BackgroundService get instance {
    _instance ??= BackgroundService._();
    return _instance!;
  }

  // Factory constructor
  factory BackgroundService() => instance;

  NotificationHelper get _notificationHelper => NotificationHelper.instance;

  Future<void> initializeService() async {
    try {
      await _notificationHelper.initNotifications();
      debugPrint('Background service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize background service: $e');
    }
  }

  Future<void> showDailyReminderNotification() async {
    try {
      // Fetch random restaurant data
      final restaurant = await _getRandomRestaurant();

      final String title = 'Lunch Time!';
      final String body = restaurant != null
          ? 'How about trying ${restaurant.name} in ${restaurant.city}? Rating: ${restaurant.rating}/5'
          : 'It\'s time for lunch! Discover amazing restaurants near you.';

      await _notificationHelper.showInstantNotification(title, body);
    } catch (e) {
      debugPrint('Error showing daily reminder: $e');
      // Fallback notification
      await _notificationHelper.showInstantNotification(
        'Lunch Time!',
        'It\'s time for lunch! Discover amazing restaurants near you.',
      );
    }
  }

  Future<Restaurant?> _getRandomRestaurant() async {
    try {
      final apiService = ApiService();
      final restaurants = await apiService.getRestaurantList();

      if (restaurants.isNotEmpty) {
        final random = Random();
        return restaurants[random.nextInt(restaurants.length)];
      }
    } catch (e) {
      debugPrint('Error fetching random restaurant: $e');
    }
    return null;
  }

  Future<void> scheduleBackgroundTasks() async {
    try {
      await _notificationHelper.scheduleDailyReminder();
      debugPrint('Background tasks scheduled successfully');
    } catch (e) {
      debugPrint('Error scheduling background tasks: $e');
    }
  }

  Future<void> cancelAllBackgroundTasks() async {
    try {
      await _notificationHelper.cancelAllNotifications();
      debugPrint('All background tasks cancelled');
    } catch (e) {
      debugPrint('Error cancelling background tasks: $e');
    }
  }

  Future<void> handleBackgroundMessage() async {
    // This would be called by a background service like WorkManager
    await showDailyReminderNotification();
  }
}