import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:adzan_monokrom/models/app_settings.dart';
import 'package:adzan_monokrom/providers/settings_provider.dart';
import 'package:adzan_monokrom/providers/location_provider.dart';
import 'package:adzan_monokrom/providers/prayer_provider.dart';

/// Creates a test AppSettings with customizable values
AppSettings createTestSettings({
  String calculationMethod = 'singapore',
  String madhab = 'shafi',
  bool adzanSoundEnabled = true,
  bool vibrationEnabled = true,
  bool notificationEnabled = false, // Disabled by default for tests
  int adzanVolume = 100,
  bool useManualLocation = true,
  double manualLatitude = -6.2088,
  double manualLongitude = 106.8456,
  String manualLocationName = 'Jakarta, Indonesia',
}) {
  return AppSettings(
    calculationMethod: calculationMethod,
    madhab: madhab,
    adzanSoundEnabled: adzanSoundEnabled,
    vibrationEnabled: vibrationEnabled,
    notificationEnabled: notificationEnabled,
    adzanVolume: adzanVolume,
    useManualLocation: useManualLocation,
    manualLatitude: manualLatitude,
    manualLongitude: manualLongitude,
    manualLocationName: manualLocationName,
  );
}

/// Creates test settings for Makkah location
AppSettings createMakkahSettings() {
  return createTestSettings(
    calculationMethod: 'umm_al_qura',
    manualLatitude: 21.4225,
    manualLongitude: 39.8262,
    manualLocationName: 'Makkah, Saudi Arabia',
  );
}

/// Creates test settings for Madinah location
AppSettings createMadinahSettings() {
  return createTestSettings(
    calculationMethod: 'umm_al_qura',
    manualLatitude: 24.5247,
    manualLongitude: 39.5692,
    manualLocationName: 'Madinah, Saudi Arabia',
  );
}

/// Widget wrapper for testing with providers
Widget createTestableWidget({
  required Widget child,
  SettingsProvider? settingsProvider,
  LocationProvider? locationProvider,
  PrayerProvider? prayerProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settingsProvider ?? SettingsProvider(),
      ),
      ChangeNotifierProvider<LocationProvider>.value(
        value: locationProvider ?? LocationProvider(),
      ),
      ChangeNotifierProvider<PrayerProvider>.value(
        value: prayerProvider ?? PrayerProvider(),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

/// Widget wrapper for simple widget testing
Widget wrapWithMaterialApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

/// Pump widget and settle
extension WidgetTesterExtension on WidgetTester {
  /// Pumps the widget and advances frames
  Future<void> pumpAndAdvance([Duration duration = const Duration(milliseconds: 100)]) async {
    await pump(duration);
  }
  
  /// Pumps until all animations are complete with timeout
  Future<void> pumpUntilSettled({Duration timeout = const Duration(seconds: 5)}) async {
    final endTime = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(endTime)) {
      await pump(const Duration(milliseconds: 16));
      if (!hasRunningAnimations) break;
    }
  }
}

/// Test data constants
class TestData {
  // Jakarta coordinates
  static const double jakartaLat = -6.2088;
  static const double jakartaLng = 106.8456;
  static const String jakartaName = 'Jakarta, Indonesia';
  
  // Makkah coordinates  
  static const double makkahLat = 21.4225;
  static const double makkahLng = 39.8262;
  static const String makkahName = 'Makkah, Saudi Arabia';
  
  // Madinah coordinates
  static const double madinahLat = 24.5247;
  static const double madinahLng = 39.5692;
  static const String madinahName = 'Madinah, Saudi Arabia';
  
  // Surabaya coordinates
  static const double surabayaLat = -7.2575;
  static const double surabayaLng = 112.7521;
  static const String surabayaName = 'Surabaya, Indonesia';
  
  // Prayer names in Indonesian
  static const List<String> prayerNames = [
    'Subuh', 'Terbit', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya'
  ];
  
  // Hijri month names
  static const List<String> hijriMonths = [
    'Muharram', 'Safar', 'Rabiul Awal', 'Rabiul Akhir',
    'Jumadil Awal', 'Jumadil Akhir', 'Rajab', 'Syaban',
    'Ramadhan', 'Syawal', 'Dzulqaidah', 'Dzulhijjah'
  ];
  
  // Sample daily verse
  static const String sampleArabicVerse = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
  static const String sampleTranslation = 'Dengan nama Allah Yang Maha Pengasih, Maha Penyayang.';
  static const String sampleVerseSource = 'QS. Al-Fatihah : 1';
}
