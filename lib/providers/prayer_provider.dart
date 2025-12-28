import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:adhan/adhan.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:http/http.dart' as http;
import 'package:hijri/hijri_calendar.dart';

import '../models/app_settings.dart';
import '../core/services/notification_service.dart';
import '../core/services/native_alarm_service.dart';

/// Provider for managing prayer times state
class PrayerProvider extends ChangeNotifier {
  PrayerTimes? _prayerTimes;
  String _nextPrayer = '';
  DateTime? _nextPrayerTime;
  Duration _countdown = Duration.zero;
  String _hijriDate = '';
  
  // Daily verse
  String _dailyVerse = '';
  String _dailyVerseTranslation = '';
  String _dailyVerseSource = '';

  // Tasbih
  int _tasbihCount = 0;
  final int _tasbihTarget = 33;

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Timers
  Timer? _countdownTimer;
  Timer? _prayerCheckTimer;

  // Getters
  PrayerTimes? get prayerTimes => _prayerTimes;
  String get nextPrayer => _nextPrayer;
  DateTime? get nextPrayerTime => _nextPrayerTime;
  Duration get countdown => _countdown;
  String get hijriDate => _hijriDate;
  String get dailyVerse => _dailyVerse;
  String get dailyVerseTranslation => _dailyVerseTranslation;
  String get dailyVerseSource => _dailyVerseSource;
  int get tasbihCount => _tasbihCount;
  int get tasbihTarget => _tasbihTarget;

  /// Calculate prayer times based on coordinates and settings
  void calculatePrayerTimes({
    required double latitude,
    required double longitude,
    required AppSettings settings,
  }) {
    final coordinates = Coordinates(latitude, longitude);
    final params = settings.getCalculationParams();
    _prayerTimes = PrayerTimes.today(coordinates, params);

    _updateNextPrayer(DateTime.now(), latitude, longitude, settings);
    _calculateHijriDate();
    
    // Schedule notifications if enabled
    if (settings.notificationEnabled && _prayerTimes != null) {
      notificationService.scheduleAllPrayerNotifications(_prayerTimes!);
      
      // Also schedule with native AlarmManager for more reliability
      _scheduleNativeAlarms(settings);
    }

    notifyListeners();
  }
  
  /// Schedule alarms using native Android AlarmManager
  Future<void> _scheduleNativeAlarms(AppSettings settings) async {
    if (_prayerTimes == null) return;
    
    try {
      await NativeAlarmService.scheduleAllPrayerAlarms(
        fajr: _prayerTimes!.fajr,
        dhuhr: _prayerTimes!.dhuhr,
        asr: _prayerTimes!.asr,
        maghrib: _prayerTimes!.maghrib,
        isha: _prayerTimes!.isha,
        playSound: settings.adzanSoundEnabled,
        vibrate: settings.vibrationEnabled,
      );
      debugPrint('PrayerProvider: Native alarms scheduled');
    } catch (e) {
      debugPrint('PrayerProvider: Error scheduling native alarms - $e');
    }
  }

  void _updateNextPrayer(DateTime now, double lat, double lng, AppSettings settings) {
    if (_prayerTimes == null) return;

    final prayers = {
      'Subuh': _prayerTimes!.fajr,
      'Terbit': _prayerTimes!.sunrise,
      'Dzuhur': _prayerTimes!.dhuhr,
      'Ashar': _prayerTimes!.asr,
      'Maghrib': _prayerTimes!.maghrib,
      'Isya': _prayerTimes!.isha,
    };

    String nextPrayerName = '';
    DateTime? nextTime;

    for (var entry in prayers.entries) {
      if (entry.value.isAfter(now)) {
        nextPrayerName = entry.key;
        nextTime = entry.value;
        break;
      }
    }

    // If no prayer left today, get tomorrow's Fajr
    if (nextPrayerName.isEmpty) {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowCoords = Coordinates(lat, lng);
      final params = settings.getCalculationParams();
      final tomorrowPrayers = PrayerTimes(tomorrowCoords, DateComponents.from(tomorrow), params);
      nextPrayerName = 'Subuh';
      nextTime = tomorrowPrayers.fajr;
    }

    _nextPrayer = nextPrayerName;
    _nextPrayerTime = nextTime;
    if (nextTime != null) {
      _countdown = nextTime.difference(now);
    }
  }

  void _calculateHijriDate() {
    try {
      final hijri = HijriCalendar.now();
      
      // Use Indonesian month names
      const hijriMonths = [
        'Muharram', 'Safar', 'Rabiul Awal', 'Rabiul Akhir',
        'Jumadil Awal', 'Jumadil Akhir', 'Rajab', 'Syaban',
        'Ramadhan', 'Syawal', 'Dzulqaidah', 'Dzulhijjah'
      ];

      final monthIndex = (hijri.hMonth - 1).clamp(0, 11);
      _hijriDate = '${hijri.hDay} ${hijriMonths[monthIndex]} ${hijri.hYear} H';
    } catch (e) {
      // Fallback to simple calculation if library fails
      final now = DateTime.now();
      final hijriEpoch = DateTime(622, 7, 16);
      final daysSinceHijri = now.difference(hijriEpoch).inDays;
      final hijriYear = (daysSinceHijri / 354.36667).floor();
      final hijriMonth = ((daysSinceHijri % 354.36667) / 29.53).floor() + 1;
      final hijriDay = ((daysSinceHijri % 354.36667) % 29.53).floor() + 1;

      const hijriMonths = [
        'Muharram', 'Safar', 'Rabiul Awal', 'Rabiul Akhir',
        'Jumadil Awal', 'Jumadil Akhir', 'Rajab', 'Syaban',
        'Ramadhan', 'Syawal', 'Dzulqaidah', 'Dzulhijjah'
      ];

      _hijriDate = '$hijriDay ${hijriMonths[(hijriMonth - 1) % 12]} $hijriYear H';
    }
  }

  /// Start countdown timer
  void startCountdownTimer({
    required double latitude,
    required double longitude,
    required AppSettings settings,
  }) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_nextPrayerTime != null) {
        final now = DateTime.now();
        _countdown = _nextPrayerTime!.difference(now);
        
        if (_countdown.isNegative) {
          calculatePrayerTimes(
            latitude: latitude,
            longitude: longitude,
            settings: settings,
          );
        }
        
        // Update ongoing notification with timer
        if (settings.notificationEnabled && _nextPrayer.isNotEmpty && !_countdown.isNegative) {
          notificationService.showOngoingTimerNotification(
            nextPrayerName: _nextPrayer,
            countdown: _countdown,
          );
        }
        
        notifyListeners();
      }
    });
  }

  /// Start prayer check timer
  void startPrayerCheckTimer(AppSettings settings) {
    _prayerCheckTimer?.cancel();
    _prayerCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkPrayerTime(settings);
    });
  }

  void _checkPrayerTime(AppSettings settings) {
    if (_prayerTimes == null) return;

    final now = DateTime.now();
    final prayers = [
      _prayerTimes!.fajr,
      _prayerTimes!.dhuhr,
      _prayerTimes!.asr,
      _prayerTimes!.maghrib,
      _prayerTimes!.isha,
    ];

    for (var prayerTime in prayers) {
      if (now.hour == prayerTime.hour &&
          now.minute == prayerTime.minute &&
          now.second == 0) {
        _playAdzan(settings);
        break;
      }
    }
  }

  Future<void> _playAdzan(AppSettings settings) async {
    try {
      if (settings.adzanSoundEnabled) {
        await _audioPlayer.setVolume(settings.adzanVolume / 100);
        await _audioPlayer.play(AssetSource('audio/adzan.webm'));
      }
      if (settings.vibrationEnabled && !kIsWeb) {
        try {
          final hasVibrator = await Vibration.hasVibrator();
          if (hasVibrator == true) {
            Vibration.vibrate(duration: 1000);
          }
        } catch (e) {
          debugPrint('Vibration not available: $e');
        }
      }
    } catch (e) {
      debugPrint('Error playing adzan: $e');
    }
  }

  /// Fetch daily verse from API
  Future<void> fetchDailyVerse() async {
    try {
      final random = math.Random();
      int attempts = 0;
      const maxAttempts = 5;
      const maxArabicLength = 200;
      const maxTranslationLength = 300;
      
      while (attempts < maxAttempts) {
        attempts++;
        final surah = random.nextInt(114) + 1;
        final response = await http.get(
          Uri.parse('https://api.alquran.cloud/v1/surah/$surah'),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final ayahs = data['data']['ayahs'] as List;
          final ayahIndex = random.nextInt(ayahs.length);
          final ayah = ayahs[ayahIndex];
          final arabicText = ayah['text'] as String;
          
          if (arabicText.length > maxArabicLength) continue;

          final translationResponse = await http.get(
            Uri.parse('https://api.alquran.cloud/v1/ayah/${ayah['number']}/id.indonesian'),
          ).timeout(const Duration(seconds: 10));

          if (translationResponse.statusCode == 200) {
            final translationData = json.decode(translationResponse.body);
            final translationText = translationData['data']['text'] as String;
            
            if (translationText.length > maxTranslationLength) continue;
            
            _dailyVerse = arabicText;
            _dailyVerseTranslation = translationText;
            _dailyVerseSource = 'QS. ${data['data']['englishName']} : ${ayah['numberInSurah']}';
            notifyListeners();
            return;
          }
        }
      }
      
      _setDefaultVerse();
    } catch (e) {
      _setDefaultVerse();
    }
  }
  
  void _setDefaultVerse() {
    _dailyVerse = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
    _dailyVerseTranslation = 'Dengan nama Allah Yang Maha Pengasih, Maha Penyayang.';
    _dailyVerseSource = 'QS. Al-Fatihah : 1';
    notifyListeners();
  }

  /// Increment tasbih count
  Future<void> incrementTasbih(AppSettings settings) async {
    _tasbihCount++;
    notifyListeners();

    if (settings.vibrationEnabled && !kIsWeb) {
      try {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          Vibration.vibrate(duration: 50);
        }
      } catch (e) {
        debugPrint('Vibration not available: $e');
      }
    }
  }

  /// Reset tasbih count
  void resetTasbih() {
    _tasbihCount = 0;
    notifyListeners();
  }

  /// Stop all timers
  void stopTimers() {
    _countdownTimer?.cancel();
    _prayerCheckTimer?.cancel();
  }

  @override
  void dispose() {
    stopTimers();
    _audioPlayer.dispose();
    notificationService.cancelOngoingNotification();
    super.dispose();
  }
}
