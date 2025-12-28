import 'dart:async';
import 'package:mocktail/mocktail.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

// ============================================================================
// Audio Player Mocks
// ============================================================================

/// Mock AudioPlayer for testing adzan and sound playback
class MockAudioPlayer extends Mock implements AudioPlayer {
  @override
  Future<void> setVolume(double volume) async {}
  
  @override
  Future<void> play(Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {}
  
  @override
  Future<void> stop() async {}
  
  @override
  Future<void> dispose() async {}
}

// ============================================================================
// HTTP Client Mocks
// ============================================================================

/// Mock HTTP Client for testing API calls
class MockHttpClient extends Mock implements http.Client {}

/// Creates a fake HTTP response
http.Response createMockResponse(String body, {int statusCode = 200}) {
  return http.Response(body, statusCode);
}

/// Sample Quran API response for daily verse
String createQuranApiResponse({
  int surahNumber = 1,
  String surahName = 'Al-Fatihah',
  int ayahNumber = 1,
  String arabicText = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
}) {
  return '''
{
  "code": 200,
  "status": "OK",
  "data": {
    "number": $surahNumber,
    "englishName": "$surahName",
    "ayahs": [
      {
        "number": $ayahNumber,
        "text": "$arabicText",
        "numberInSurah": $ayahNumber
      }
    ]
  }
}
''';
}

/// Sample translation API response
String createTranslationApiResponse({
  String translationText = 'Dengan nama Allah Yang Maha Pengasih, Maha Penyayang.',
}) {
  return '''
{
  "code": 200,
  "status": "OK",
  "data": {
    "text": "$translationText"
  }
}
''';
}

// ============================================================================
// GPS / Location Mocks
// ============================================================================

/// Creates a mock Position for testing
Position createMockPosition({
  double latitude = -6.2088,
  double longitude = 106.8456,
  double accuracy = 10.0,
  double altitude = 0.0,
  double speed = 0.0,
  DateTime? timestamp,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: timestamp ?? DateTime.now(),
    accuracy: accuracy,
    altitude: altitude,
    altitudeAccuracy: 0.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: speed,
    speedAccuracy: 0.0,
  );
}

/// Mock Geolocator wrapper for unit testing
/// Note: Direct Geolocator mocking requires plugin channel mocking in integration tests
class MockGeolocatorWrapper {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.always;
  Position? currentPosition;
  Exception? errorToThrow;
  
  Future<bool> isLocationServiceEnabled() async {
    return serviceEnabled;
  }
  
  Future<LocationPermission> checkPermission() async {
    return permission;
  }
  
  Future<LocationPermission> requestPermission() async {
    return permission;
  }
  
  Future<Position> getCurrentPosition() async {
    if (errorToThrow != null) throw errorToThrow!;
    return currentPosition ?? createMockPosition();
  }
}

// ============================================================================
// Notification Service Mocks
// ============================================================================

/// Mock notification service for testing
class MockNotificationService {
  bool initialized = false;
  List<ScheduledNotification> scheduledNotifications = [];
  List<String> shownNotifications = [];
  bool ongoingNotificationActive = false;
  
  Future<void> init() async {
    initialized = true;
  }
  
  Future<void> schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
  }) async {
    scheduledNotifications.add(ScheduledNotification(
      id: id,
      title: 'Waktu $prayerName',
      body: 'Saatnya menunaikan sholat $prayerName',
      scheduledTime: prayerTime,
    ));
  }
  
  Future<void> showInstantNotification(String title, String body) async {
    shownNotifications.add('$title: $body');
  }
  
  Future<void> showOngoingTimerNotification({
    required String nextPrayerName,
    required Duration countdown,
  }) async {
    ongoingNotificationActive = true;
  }
  
  Future<void> cancelOngoingNotification() async {
    ongoingNotificationActive = false;
  }
  
  Future<void> cancelAll() async {
    scheduledNotifications.clear();
    shownNotifications.clear();
    ongoingNotificationActive = false;
  }
}

/// Data class for scheduled notifications
class ScheduledNotification {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  
  ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
  });
}

// ============================================================================
// Timer Mocks
// ============================================================================

/// Mock timer for testing countdown logic
class MockTimer implements Timer {
  final Duration duration;
  final void Function(Timer) callback;
  bool _isActive = true;
  int _tick = 0;
  
  MockTimer(this.duration, this.callback);
  
  MockTimer.periodic(this.duration, this.callback);
  
  @override
  void cancel() {
    _isActive = false;
  }
  
  @override
  bool get isActive => _isActive;
  
  @override
  int get tick => _tick;
  
  /// Simulate timer tick
  void simulateTick() {
    if (_isActive) {
      _tick++;
      callback(this);
    }
  }
  
  /// Simulate multiple ticks
  void simulateTicks(int count) {
    for (int i = 0; i < count; i++) {
      simulateTick();
    }
  }
}

// ============================================================================
// Vibration Mocks
// ============================================================================

/// Mock vibration service
class MockVibrationService {
  bool hasVibrator = true;
  List<int> vibrationDurations = [];
  
  Future<bool?> checkHasVibrator() async {
    return hasVibrator;
  }
  
  void vibrate({int duration = 500}) {
    vibrationDurations.add(duration);
  }
  
  void reset() {
    vibrationDurations.clear();
  }
}
