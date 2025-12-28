import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

/// Background service for monitoring prayer times and triggering adzan.
/// Uses flutter_background_service for reliable background execution.
class PrayerBackgroundService {
  static const String _channelId = 'adzan_service_channel';
  static const String _channelName = 'Pengingat Waktu Sholat';
  
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  /// Initialize the background service
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();
    
    // Create notification channel for Android
    await _createNotificationChannel();
    
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false, // Disabled autoStart to prevent crash
        isForegroundMode: false, // Start in background mode first
        notificationChannelId: _channelId,
        initialNotificationTitle: 'Adzan Monokrom',
        initialNotificationContent: 'Menunggu waktu sholat berikutnya...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }
  
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifikasi pengingat waktu sholat',
      importance: Importance.low,
    );
    
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
  
  /// Start the background service
  static Future<void> startService() async {
    final service = FlutterBackgroundService();
    await service.startService();
    debugPrint('PrayerBackgroundService: Service started');
  }
  
  /// Stop the background service
  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
    debugPrint('PrayerBackgroundService: Service stopped');
  }
  
  /// Check if service is running
  static Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }
  
  /// Update prayer times in background service
  static void updatePrayerTimes({
    required double latitude,
    required double longitude,
    required String calculationMethod,
    required String madhab,
  }) {
    final service = FlutterBackgroundService();
    service.invoke('updateLocation', {
      'latitude': latitude,
      'longitude': longitude, 
      'calculationMethod': calculationMethod,
      'madhab': madhab,
    });
  }
}

/// iOS background handler
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

/// Main background service entry point
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  debugPrint('PrayerBackgroundService: onStart called');
  
  // Initialize notifications
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );
  await notificationsPlugin.initialize(initSettings);
  
  // Audio player for adzan
  final audioPlayer = AudioPlayer();
  
  // Location and settings storage
  double latitude = -6.2088;  // Default Jakarta
  double longitude = 106.8456;
  String calculationMethod = 'singapore';
  String madhab = 'shafi';
  String? lastNotifiedPrayer;
  
  // Load saved location
  final prefs = await SharedPreferences.getInstance();
  latitude = prefs.getDouble('latitude') ?? latitude;
  longitude = prefs.getDouble('longitude') ?? longitude;
  calculationMethod = prefs.getString('calculationMethod') ?? calculationMethod;
  madhab = prefs.getString('madhab') ?? madhab;
  
  // Listen for location updates from UI
  service.on('updateLocation').listen((event) {
    if (event != null) {
      latitude = event['latitude'] ?? latitude;
      longitude = event['longitude'] ?? longitude;
      calculationMethod = event['calculationMethod'] ?? calculationMethod;
      madhab = event['madhab'] ?? madhab;
      
      // Reset last notified prayer to allow new notifications
      lastNotifiedPrayer = null;
      
      debugPrint('PrayerBackgroundService: Location updated - $latitude, $longitude');
    }
  });
  
  // Listen for stop command
  service.on('stopService').listen((event) {
    service.stopSelf();
    debugPrint('PrayerBackgroundService: Service stopped by command');
  });
  
  // Main prayer time monitoring loop
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    final now = DateTime.now();
    
    // Calculate prayer times
    final coordinates = Coordinates(latitude, longitude);
    final params = _getCalculationParams(calculationMethod, madhab);
    final prayerTimes = PrayerTimes.today(coordinates, params);
    
    // Prayer times map
    final prayers = {
      'Subuh': prayerTimes.fajr,
      'Dzuhur': prayerTimes.dhuhr,
      'Ashar': prayerTimes.asr,
      'Maghrib': prayerTimes.maghrib,
      'Isya': prayerTimes.isha,
    };
    
    // Find next prayer and check if any prayer time just arrived
    String? nextPrayerName;
    DateTime? nextPrayerTime;
    
    for (var entry in prayers.entries) {
      final prayerTime = entry.value;
      final prayerName = entry.key;
      
      // Check if it's prayer time (within 1 minute window)
      final diff = now.difference(prayerTime).inSeconds.abs();
      if (diff < 60 && lastNotifiedPrayer != prayerName) {
        // It's prayer time! Trigger notification and adzan
        await _triggerPrayerNotification(
          notificationsPlugin, 
          audioPlayer,
          prayerName,
          prayerTime,
        );
        lastNotifiedPrayer = prayerName;
      }
      
      // Track next prayer
      if (prayerTime.isAfter(now) && nextPrayerTime == null) {
        nextPrayerName = prayerName;
        nextPrayerTime = prayerTime;
      }
    }
    
    // Update foreground notification with next prayer info
    if (service is AndroidServiceInstance) {
      if (nextPrayerName != null && nextPrayerTime != null) {
        final countdown = nextPrayerTime.difference(now);
        final hours = countdown.inHours;
        final minutes = countdown.inMinutes % 60;
        
        service.setForegroundNotificationInfo(
          title: 'Adzan Monokrom',
          content: '$nextPrayerName dalam ${hours}j ${minutes}m',
        );
      } else {
        service.setForegroundNotificationInfo(
          title: 'Adzan Monokrom',
          content: 'Menunggu jadwal sholat besok...',
        );
      }
    }
    
    // Send status to UI
    service.invoke('prayerStatus', {
      'nextPrayer': nextPrayerName,
      'nextPrayerTime': nextPrayerTime?.toIso8601String(),
      'isRunning': true,
    });
  });
}

/// Trigger prayer notification and adzan sound
Future<void> _triggerPrayerNotification(
  FlutterLocalNotificationsPlugin notificationsPlugin,
  AudioPlayer audioPlayer,
  String prayerName,
  DateTime prayerTime,
) async {
  debugPrint('PrayerBackgroundService: PRAYER TIME - $prayerName');
  
  // Show high-priority notification
  const androidDetails = AndroidNotificationDetails(
    'adzan_alarm_channel',
    'Waktu Sholat',
    channelDescription: 'Notifikasi waktu sholat',
    importance: Importance.max,
    priority: Priority.max,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
    playSound: false, // We play our own sound
  );
  
  const notificationDetails = NotificationDetails(android: androidDetails);
  
  await notificationsPlugin.show(
    1001,
    'Waktu $prayerName',
    'Saatnya menunaikan sholat $prayerName',
    notificationDetails,
  );
  
  // Vibrate
  try {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);
    }
  } catch (e) {
    debugPrint('PrayerBackgroundService: Vibration error - $e');
  }
  
  // Play adzan sound
  try {
    await audioPlayer.play(AssetSource('audio/adzan.webm'));
    debugPrint('PrayerBackgroundService: Adzan playing');
  } catch (e) {
    debugPrint('PrayerBackgroundService: Audio error - $e');
  }
}

/// Get calculation parameters from method and madhab strings
CalculationParameters _getCalculationParams(String method, String madhab) {
  CalculationParameters params;
  
  switch (method.toLowerCase()) {
    case 'mwl':
      params = CalculationMethod.muslim_world_league.getParameters();
      break;
    case 'isna':
      params = CalculationMethod.north_america.getParameters();
      break;
    case 'egyptian':
      params = CalculationMethod.egyptian.getParameters();
      break;
    case 'makkah':
      params = CalculationMethod.umm_al_qura.getParameters();
      break;
    case 'karachi':
      params = CalculationMethod.karachi.getParameters();
      break;
    case 'tehran':
      params = CalculationMethod.tehran.getParameters();
      break;
    case 'jafari':
    case 'shia':
      params = CalculationMethod.tehran.getParameters();
      break;
    case 'singapore':
    default:
      params = CalculationMethod.singapore.getParameters();
  }
  
  // Set madhab
  params.madhab = madhab.toLowerCase() == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
  
  return params;
}
