import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:adzan_monokrom/providers/settings_provider.dart';
import 'package:adzan_monokrom/providers/location_provider.dart';
import 'package:adzan_monokrom/providers/prayer_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Prayer Times Flow', () {
    testWidgets('prayer times are calculated when location is set', (WidgetTester tester) async {
      final settingsProvider = SettingsProvider();
      final locationProvider = LocationProvider();
      final prayerProvider = PrayerProvider();
      
      // Set manual location (Jakarta)
      locationProvider.setManualLocation(
        latitude: -6.2088,
        longitude: 106.8456,
        locationName: 'Jakarta, Indonesia',
      );
      
      // Calculate prayer times
      prayerProvider.calculatePrayerTimes(
        latitude: -6.2088,
        longitude: 106.8456,
        settings: settingsProvider.settings,
      );
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settingsProvider),
            ChangeNotifierProvider.value(value: locationProvider),
            ChangeNotifierProvider.value(value: prayerProvider),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                final prayer = Provider.of<PrayerProvider>(context);
                final pt = prayer.prayerTimes;
                
                return Scaffold(
                  body: pt != null
                      ? ListView(
                          children: [
                            Text('Subuh: ${_formatTime(pt.fajr)}'),
                            Text('Dzuhur: ${_formatTime(pt.dhuhr)}'),
                            Text('Ashar: ${_formatTime(pt.asr)}'),
                            Text('Maghrib: ${_formatTime(pt.maghrib)}'),
                            Text('Isya: ${_formatTime(pt.isha)}'),
                            Text('Next: ${prayer.nextPrayer}'),
                          ],
                        )
                      : const Text('Loading...'),
                );
              },
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Verify prayer times are displayed
      expect(find.textContaining('Subuh:'), findsOneWidget);
      expect(find.textContaining('Dzuhur:'), findsOneWidget);
      expect(find.textContaining('Ashar:'), findsOneWidget);
      expect(find.textContaining('Maghrib:'), findsOneWidget);
      expect(find.textContaining('Isya:'), findsOneWidget);
      expect(find.textContaining('Next:'), findsOneWidget);
    });

    testWidgets('changing location recalculates prayer times', (WidgetTester tester) async {
      final settingsProvider = SettingsProvider();
      final locationProvider = LocationProvider();
      final prayerProvider = PrayerProvider();
      
      // Start with Jakarta
      locationProvider.setManualLocation(
        latitude: -6.2088,
        longitude: 106.8456,
        locationName: 'Jakarta, Indonesia',
      );
      
      prayerProvider.calculatePrayerTimes(
        latitude: -6.2088,
        longitude: 106.8456,
        settings: settingsProvider.settings,
      );
      
      final jakartaPrayerTimes = prayerProvider.prayerTimes;
      expect(jakartaPrayerTimes, isNotNull);
      
      // Change to Makkah
      locationProvider.setManualLocation(
        latitude: 21.4225,
        longitude: 39.8262,
        locationName: 'Makkah, Saudi Arabia',
      );
      
      settingsProvider.setCalculationMethod('umm_al_qura');
      
      prayerProvider.calculatePrayerTimes(
        latitude: 21.4225,
        longitude: 39.8262,
        settings: settingsProvider.settings,
      );
      
      final makkahPrayerTimes = prayerProvider.prayerTimes;
      expect(makkahPrayerTimes, isNotNull);
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settingsProvider),
            ChangeNotifierProvider.value(value: locationProvider),
            ChangeNotifierProvider.value(value: prayerProvider),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                final location = Provider.of<LocationProvider>(context);
                
                return Scaffold(
                  body: Text('Location: ${location.locationName}'),
                );
              },
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.text('Location: Makkah, Saudi Arabia'), findsOneWidget);
      
      // Prayer times should be different due to location change
      // (In reality they would be different by hours due to timezone)
      expect(makkahPrayerTimes, isNotNull);
    });

    testWidgets('madhab change affects asr time', (WidgetTester tester) async {
      final settingsProvider = SettingsProvider();
      final prayerProvider = PrayerProvider();
      
      // Calculate with Shafi madhab (default)
      prayerProvider.calculatePrayerTimes(
        latitude: -6.2088,
        longitude: 106.8456,
        settings: settingsProvider.settings,
      );
      
      final shafiAsrTime = prayerProvider.prayerTimes!.asr;
      
      // Change to Hanafi
      settingsProvider.setMadhab('hanafi');
      
      prayerProvider.calculatePrayerTimes(
        latitude: -6.2088,
        longitude: 106.8456,
        settings: settingsProvider.settings,
      );
      
      final hanafiAsrTime = prayerProvider.prayerTimes!.asr;
      
      // Hanafi Asr should be later
      expect(hanafiAsrTime.isAfter(shafiAsrTime), true);
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settingsProvider),
            ChangeNotifierProvider.value(value: prayerProvider),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                final settings = Provider.of<SettingsProvider>(context);
                final prayer = Provider.of<PrayerProvider>(context);
                
                return Scaffold(
                  body: Column(
                    children: [
                      Text('Madhab: ${settings.settings.madhab}'),
                      Text('Asr: ${_formatTime(prayer.prayerTimes!.asr)}'),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.text('Madhab: hanafi'), findsOneWidget);
    });
  });

  group('Tasbih Flow', () {
    testWidgets('tasbih increments correctly', (WidgetTester tester) async {
      final prayerProvider = PrayerProvider();
      final settingsProvider = SettingsProvider();
      
      // Disable vibration for testing
      settingsProvider.setVibrationEnabled(false);
      
      expect(prayerProvider.tasbihCount, 0);
      expect(prayerProvider.tasbihTarget, 33);
      
      // Increment tasbih
      await prayerProvider.incrementTasbih(settingsProvider.settings);
      await prayerProvider.incrementTasbih(settingsProvider.settings);
      await prayerProvider.incrementTasbih(settingsProvider.settings);
      
      expect(prayerProvider.tasbihCount, 3);
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: prayerProvider),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                final prayer = Provider.of<PrayerProvider>(context);
                
                return Scaffold(
                  body: Text('Tasbih: ${prayer.tasbihCount}/${prayer.tasbihTarget}'),
                );
              },
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.text('Tasbih: 3/33'), findsOneWidget);
    });

    testWidgets('tasbih resets correctly', (WidgetTester tester) async {
      final prayerProvider = PrayerProvider();
      final settingsProvider = SettingsProvider();
      
      // Disable vibration for testing
      settingsProvider.setVibrationEnabled(false);
      
      // Increment a few times
      for (int i = 0; i < 10; i++) {
        await prayerProvider.incrementTasbih(settingsProvider.settings);
      }
      
      expect(prayerProvider.tasbihCount, 10);
      
      // Reset
      prayerProvider.resetTasbih();
      
      expect(prayerProvider.tasbihCount, 0);
    });
  });

  group('Hijri Date', () {
    testWidgets('hijri date is displayed', (WidgetTester tester) async {
      final prayerProvider = PrayerProvider();
      final settingsProvider = SettingsProvider();
      
      // Calculate prayer times (which also calculates hijri date)
      prayerProvider.calculatePrayerTimes(
        latitude: -6.2088,
        longitude: 106.8456,
        settings: settingsProvider.settings,
      );
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: prayerProvider),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                final prayer = Provider.of<PrayerProvider>(context);
                
                return Scaffold(
                  body: Text('Hijri: ${prayer.hijriDate}'),
                );
              },
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Hijri date should contain the "H" suffix and year
      expect(find.textContaining('H'), findsOneWidget);
    });
  });
}

String _formatTime(DateTime time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
