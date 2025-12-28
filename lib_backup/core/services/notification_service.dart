import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';

/// Service for handling all notification-related functionality
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (kIsWeb) return; // Skip on web
    
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    
    // Request notification permission on Android 13+
    await _requestPermission();
  }

  Future<void> _requestPermission() async {
    if (kIsWeb) return;
    await Permission.notification.request();
    
    // Request to ignore battery optimization for reliable notifications
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  Future<void> schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
  }) async {
    if (kIsWeb) return;
    
    // Don't schedule if time has passed
    if (prayerTime.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'adzan_channel',
      'Waktu Sholat',
      channelDescription: 'Notifikasi waktu sholat',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@drawable/ic_notification',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      'Waktu $prayerName',
      'Saatnya menunaikan sholat $prayerName',
      tz.TZDateTime.from(prayerTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleAllPrayerNotifications(PrayerTimes prayerTimes) async {
    if (kIsWeb) return;

    // Cancel all existing notifications first
    await _notifications.cancelAll();

    final prayers = {
      0: {'name': 'Subuh', 'time': prayerTimes.fajr},
      1: {'name': 'Dzuhur', 'time': prayerTimes.dhuhr},
      2: {'name': 'Ashar', 'time': prayerTimes.asr},
      3: {'name': 'Maghrib', 'time': prayerTimes.maghrib},
      4: {'name': 'Isya', 'time': prayerTimes.isha},
    };

    for (var entry in prayers.entries) {
      await schedulePrayerNotification(
        id: entry.key,
        prayerName: entry.value['name'] as String,
        prayerTime: entry.value['time'] as DateTime,
      );
    }
  }

  Future<void> showInstantNotification(String title, String body) async {
    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      'adzan_channel',
      'Waktu Sholat',
      channelDescription: 'Notifikasi waktu sholat',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(99, title, body, details);
  }

  /// Ongoing notification with countdown timer
  Future<void> showOngoingTimerNotification({
    required String nextPrayerName,
    required Duration countdown,
  }) async {
    if (kIsWeb) return;

    final hours = countdown.inHours;
    final minutes = (countdown.inMinutes % 60);
    final seconds = (countdown.inSeconds % 60);
    
    String timeString;
    if (hours > 0) {
      timeString = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    debugPrint('Showing timer notification: $nextPrayerName - $timeString');

    final androidDetails = AndroidNotificationDetails(
      'timer_channel_v2',
      'Timer Waktu Sholat',
      channelDescription: 'Countdown timer ke waktu sholat berikutnya',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      playSound: false,
      enableVibration: false,
      icon: '@drawable/ic_notification',
      visibility: NotificationVisibility.public,
    );

    final details = NotificationDetails(android: androidDetails);
    await _notifications.show(
      100, // ID khusus untuk timer notification
      '$nextPrayerName dalam $timeString',
      'Menuju waktu $nextPrayerName',
      details,
    );
  }

  /// Cancel ongoing timer notification
  Future<void> cancelOngoingNotification() async {
    if (kIsWeb) return;
    await _notifications.cancel(100);
  }
}

/// Global notification service instance
final notificationService = NotificationService();
