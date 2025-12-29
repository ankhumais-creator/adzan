import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Native Kotlin Adzan Service
/// 
/// Service utama untuk timer notifikasi menggunakan MethodChannel.
/// Berkomunikasi dengan AdzanService.kt native Android.
/// 
/// Features:
/// - Live countdown timer di notifikasi
/// - Anti-kill foreground service
/// - Native Kotlin coroutine (efficient)
class NativeAdzanService {
  // Singleton pattern untuk mencegah multiple instances
  static final NativeAdzanService _instance = NativeAdzanService._internal();
  factory NativeAdzanService() => _instance;
  NativeAdzanService._internal();

  // MethodChannel ke native Kotlin
  static const MethodChannel _channel = MethodChannel('adzan/native_service');
  
  // State tracking
  bool _isRunning = false;
  String? _currentPrayer;
  DateTime? _targetTime;

  // Getters
  bool get isRunning => _isRunning;
  String? get currentPrayer => _currentPrayer;
  DateTime? get targetTime => _targetTime;

  /// Start native timer dengan target waktu dan nama sholat
  /// 
  /// [targetTime] - DateTime target waktu sholat
  /// [prayerName] - Nama sholat (Subuh, Dzuhur, Ashar, Maghrib, Isya)
  static Future<bool> startTimer({
    required DateTime targetTime,
    required String prayerName,
  }) async {
    if (kIsWeb) return false;
    
    // Skip if target time has passed
    if (targetTime.isBefore(DateTime.now())) {
      debugPrint('NativeAdzanService: Target time has passed, skipping');
      return false;
    }

    try {
      final result = await _channel.invokeMethod('startTimer', {
        'targetTime': targetTime.millisecondsSinceEpoch,
        'prayerName': prayerName,
      });
      
      // Update state
      _instance._isRunning = true;
      _instance._currentPrayer = prayerName;
      _instance._targetTime = targetTime;
      
      debugPrint('NativeAdzanService: Timer started for $prayerName');
      return result == 'Service Started';
    } on PlatformException catch (e) {
      debugPrint('NativeAdzanService: Failed to start - ${e.message}');
      return false;
    } on MissingPluginException {
      debugPrint('NativeAdzanService: Native plugin not available');
      return false;
    }
  }

  /// Stop native timer dan foreground service
  static Future<bool> stopTimer() async {
    if (kIsWeb) return false;

    try {
      await _channel.invokeMethod('stopTimer');
      
      // Reset state
      _instance._isRunning = false;
      _instance._currentPrayer = null;
      _instance._targetTime = null;
      
      debugPrint('NativeAdzanService: Timer stopped');
      return true;
    } on PlatformException catch (e) {
      debugPrint('NativeAdzanService: Failed to stop - ${e.message}');
      return false;
    } on MissingPluginException {
      debugPrint('NativeAdzanService: Native plugin not available');
      return false;
    }
  }

  /// Update timer dengan waktu sholat berikutnya
  /// 
  /// Convenience method yang menghentikan timer lama dan memulai yang baru
  static Future<bool> updateNextPrayer({
    required DateTime nextTime,
    required String prayerName,
  }) async {
    // Stop existing timer first
    await stopTimer();
    
    // Start new timer
    return await startTimer(
      targetTime: nextTime,
      prayerName: prayerName,
    );
  }

  /// Dispose - clean up resources
  /// Panggil saat app ditutup
  static Future<void> dispose() async {
    await stopTimer();
    debugPrint('NativeAdzanService: Disposed');
  }
}
