import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Native alarm service for reliable prayer notifications using platform channels.
/// This communicates with Kotlin native code for AlarmManager scheduling.
class NativeAlarmService {
  static const _alarmChannel = MethodChannel('com.adzan_monokrom/alarm');
  
  /// Prayer name to alarm ID mapping
  static const Map<String, int> prayerAlarmIds = {
    'Subuh': 0,
    'Terbit': 1,
    'Dzuhur': 2,
    'Ashar': 3,
    'Maghrib': 4,
    'Isya': 5,
  };
  
  /// Schedule an exact alarm for a prayer time
  static Future<bool> scheduleAlarm({
    required String prayerName,
    required DateTime prayerTime,
    bool playSound = true,
    bool vibrate = true,
  }) async {
    if (kIsWeb) return false;
    
    try {
      final alarmId = prayerAlarmIds[prayerName] ?? 0;
      final triggerTime = prayerTime.millisecondsSinceEpoch;
      final formattedTime = '${prayerTime.hour.toString().padLeft(2, '0')}:${prayerTime.minute.toString().padLeft(2, '0')}';
      
      final result = await _alarmChannel.invokeMethod<bool>('scheduleAlarm', {
        'alarmId': alarmId,
        'triggerTime': triggerTime,
        'prayerName': prayerName,
        'prayerTime': formattedTime,
        'playSound': playSound,
        'vibrate': vibrate,
      });
      
      debugPrint('NativeAlarmService: Scheduled $prayerName at $triggerTime');
      return result ?? false;
    } catch (e) {
      debugPrint('NativeAlarmService: Error scheduling alarm - $e');
      return false;
    }
  }
  
  /// Schedule all prayer alarms for the day
  static Future<void> scheduleAllPrayerAlarms({
    required DateTime fajr,
    required DateTime dhuhr,
    required DateTime asr,
    required DateTime maghrib,
    required DateTime isha,
    bool playSound = true,
    bool vibrate = true,
  }) async {
    if (kIsWeb) return;
    
    final now = DateTime.now();
    
    // Only schedule future prayers
    if (fajr.isAfter(now)) {
      await scheduleAlarm(prayerName: 'Subuh', prayerTime: fajr, playSound: playSound, vibrate: vibrate);
    }
    if (dhuhr.isAfter(now)) {
      await scheduleAlarm(prayerName: 'Dzuhur', prayerTime: dhuhr, playSound: playSound, vibrate: vibrate);
    }
    if (asr.isAfter(now)) {
      await scheduleAlarm(prayerName: 'Ashar', prayerTime: asr, playSound: playSound, vibrate: vibrate);
    }
    if (maghrib.isAfter(now)) {
      await scheduleAlarm(prayerName: 'Maghrib', prayerTime: maghrib, playSound: playSound, vibrate: vibrate);
    }
    if (isha.isAfter(now)) {
      await scheduleAlarm(prayerName: 'Isya', prayerTime: isha, playSound: playSound, vibrate: vibrate);
    }
    
    debugPrint('NativeAlarmService: All prayer alarms scheduled');
  }
  
  /// Cancel a specific prayer alarm
  static Future<bool> cancelAlarm(String prayerName) async {
    if (kIsWeb) return false;
    
    try {
      final alarmId = prayerAlarmIds[prayerName] ?? 0;
      final result = await _alarmChannel.invokeMethod<bool>('cancelAlarm', {
        'alarmId': alarmId,
      });
      
      debugPrint('NativeAlarmService: Cancelled $prayerName alarm');
      return result ?? false;
    } catch (e) {
      debugPrint('NativeAlarmService: Error cancelling alarm - $e');
      return false;
    }
  }
  
  /// Cancel all prayer alarms
  static Future<bool> cancelAllAlarms() async {
    if (kIsWeb) return false;
    
    try {
      final result = await _alarmChannel.invokeMethod<bool>('cancelAllAlarms');
      debugPrint('NativeAlarmService: All alarms cancelled');
      return result ?? false;
    } catch (e) {
      debugPrint('NativeAlarmService: Error cancelling all alarms - $e');
      return false;
    }
  }
  
  /// Check if exact alarms can be scheduled (Android 12+)
  static Future<bool> canScheduleExactAlarms() async {
    if (kIsWeb) return true;
    
    try {
      final result = await _alarmChannel.invokeMethod<bool>('canScheduleExactAlarms');
      return result ?? true;
    } catch (e) {
      return true;
    }
  }
  
  /// Open settings to allow exact alarms (Android 12+)
  static Future<void> openExactAlarmSettings() async {
    if (kIsWeb) return;
    
    try {
      await _alarmChannel.invokeMethod('openExactAlarmSettings');
    } catch (e) {
      debugPrint('NativeAlarmService: Error opening settings - $e');
    }
  }
  
  /// Start the foreground service
  static Future<bool> startForegroundService() async {
    if (kIsWeb) return false;
    
    try {
      final result = await _alarmChannel.invokeMethod<bool>('startForegroundService');
      debugPrint('NativeAlarmService: Foreground service started');
      return result ?? false;
    } catch (e) {
      debugPrint('NativeAlarmService: Error starting foreground service - $e');
      return false;
    }
  }
  
  /// Stop the foreground service
  static Future<bool> stopForegroundService() async {
    if (kIsWeb) return false;
    
    try {
      final result = await _alarmChannel.invokeMethod<bool>('stopForegroundService');
      debugPrint('NativeAlarmService: Foreground service stopped');
      return result ?? false;
    } catch (e) {
      debugPrint('NativeAlarmService: Error stopping foreground service - $e');
      return false;
    }
  }
}
