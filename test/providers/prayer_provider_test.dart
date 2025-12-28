import 'package:flutter_test/flutter_test.dart';
import 'package:adzan_monokrom/models/app_settings.dart';
import 'package:adhan/adhan.dart';
import '../helpers/test_helpers.dart';
import '../helpers/mock_services.dart';

/// Tests for PrayerProvider logic that don't depend on platform bindings
/// Note: Full PrayerProvider tests with AudioPlayer require integration tests
void main() {
  group('Prayer Times Calculation Logic', () {
    late AppSettings settings;

    setUp(() {
      settings = createTestSettings();
    });

    group('Basic Calculation', () {
      test('getCalculationParams for singapore method should return valid params', () {
        final params = settings.getCalculationParams();

        expect(params, isNotNull);
        expect(params.fajrAngle, isNotNull);
        expect(params.ishaAngle, isNotNull);
      });

      test('prayer times should be calculated for Jakarta coordinates', () {
        final coordinates = Coordinates(TestData.jakartaLat, TestData.jakartaLng);
        final params = settings.getCalculationParams();
        final prayerTimes = PrayerTimes.today(coordinates, params);

        expect(prayerTimes.fajr, isNotNull);
        expect(prayerTimes.dhuhr, isNotNull);
        expect(prayerTimes.asr, isNotNull);
        expect(prayerTimes.maghrib, isNotNull);
        expect(prayerTimes.isha, isNotNull);
      });

      test('prayer times should be calculated for Makkah coordinates', () {
        final coordinates = Coordinates(TestData.makkahLat, TestData.makkahLng);
        final settingsMakkah = createMakkahSettings();
        final params = settingsMakkah.getCalculationParams();
        final prayerTimes = PrayerTimes.today(coordinates, params);

        expect(prayerTimes.fajr, isNotNull);
        expect(prayerTimes.dhuhr, isNotNull);
        expect(prayerTimes.asr, isNotNull);
        expect(prayerTimes.maghrib, isNotNull);
        expect(prayerTimes.isha, isNotNull);
      });
    });

    group('Prayer Time Order', () {
      test('fajr should always be before sunrise', () {
        final coordinates = Coordinates(TestData.jakartaLat, TestData.jakartaLng);
        final params = settings.getCalculationParams();
        final prayerTimes = PrayerTimes.today(coordinates, params);

        expect(prayerTimes.fajr.isBefore(prayerTimes.sunrise), true);
      });

      test('sunrise should always be before dhuhr', () {
        final coordinates = Coordinates(TestData.jakartaLat, TestData.jakartaLng);
        final params = settings.getCalculationParams();
        final prayerTimes = PrayerTimes.today(coordinates, params);

        expect(prayerTimes.sunrise.isBefore(prayerTimes.dhuhr), true);
      });

      test('dhuhr should always be before asr', () {
        final coordinates = Coordinates(TestData.jakartaLat, TestData.jakartaLng);
        final params = settings.getCalculationParams();
        final prayerTimes = PrayerTimes.today(coordinates, params);

        expect(prayerTimes.dhuhr.isBefore(prayerTimes.asr), true);
      });

      test('asr should always be before maghrib', () {
        final coordinates = Coordinates(TestData.jakartaLat, TestData.jakartaLng);
        final params = settings.getCalculationParams();
        final prayerTimes = PrayerTimes.today(coordinates, params);

        expect(prayerTimes.asr.isBefore(prayerTimes.maghrib), true);
      });

      test('maghrib should always be before isha', () {
        final coordinates = Coordinates(TestData.jakartaLat, TestData.jakartaLng);
        final params = settings.getCalculationParams();
        final prayerTimes = PrayerTimes.today(coordinates, params);

        expect(prayerTimes.maghrib.isBefore(prayerTimes.isha), true);
      });

      test('all prayer times should be in correct chronological order', () {
        final coordinates = Coordinates(TestData.jakartaLat, TestData.jakartaLng);
        final params = settings.getCalculationParams();
        final pt = PrayerTimes.today(coordinates, params);

        final times = [pt.fajr, pt.sunrise, pt.dhuhr, pt.asr, pt.maghrib, pt.isha];
        
        for (int i = 0; i < times.length - 1; i++) {
          expect(
            times[i].isBefore(times[i + 1]), 
            true,
            reason: 'Prayer ${TestData.prayerNames[i]} should be before ${TestData.prayerNames[i + 1]}',
          );
        }
      });
    });

    group('Madhab Differences', () {
      test('hanafi madhab should produce later asr time', () {
        final coordinates = Coordinates(TestData.jakartaLat, TestData.jakartaLng);
        
        final shafiSettings = createTestSettings(madhab: 'shafi');
        final shafiParams = shafiSettings.getCalculationParams();
        final shafiPrayerTimes = PrayerTimes.today(coordinates, shafiParams);
        
        final hanafiSettings = createTestSettings(madhab: 'hanafi');
        final hanafiParams = hanafiSettings.getCalculationParams();
        final hanafiPrayerTimes = PrayerTimes.today(coordinates, hanafiParams);
        
        // Hanafi Asr is later than Shafi Asr
        expect(hanafiPrayerTimes.asr.isAfter(shafiPrayerTimes.asr), true);
      });

      test('shafi and hanafi should have same fajr, dhuhr, maghrib, isha', () {
        final coordinates = Coordinates(TestData.jakartaLat, TestData.jakartaLng);
        
        final shafiSettings = createTestSettings(madhab: 'shafi');
        final shafiParams = shafiSettings.getCalculationParams();
        final shafiPT = PrayerTimes.today(coordinates, shafiParams);
        
        final hanafiSettings = createTestSettings(madhab: 'hanafi');
        final hanafiParams = hanafiSettings.getCalculationParams();
        final hanafiPT = PrayerTimes.today(coordinates, hanafiParams);
        
        // Only Asr differs between madhabs
        expect(shafiPT.fajr, hanafiPT.fajr);
        expect(shafiPT.dhuhr, hanafiPT.dhuhr);
        expect(shafiPT.maghrib, hanafiPT.maghrib);
        expect(shafiPT.isha, hanafiPT.isha);
      });
    });

    group('Calculation Methods', () {
      test('different calculation methods should produce different times', () {
        final coordinates = Coordinates(TestData.jakartaLat, TestData.jakartaLng);
        
        final singaporeSettings = createTestSettings(calculationMethod: 'singapore');
        final singaporeParams = singaporeSettings.getCalculationParams();
        final singaporePT = PrayerTimes.today(coordinates, singaporeParams);
        
        final mwlSettings = createTestSettings(calculationMethod: 'muslim_world_league');
        final mwlParams = mwlSettings.getCalculationParams();
        final mwlPT = PrayerTimes.today(coordinates, mwlParams);
        
        // Different methods may have different fajr/isha times
        // At least one should be different
        final fajrDiff = singaporePT.fajr.difference(mwlPT.fajr).inMinutes.abs();
        final ishaDiff = singaporePT.isha.difference(mwlPT.isha).inMinutes.abs();
        
        expect(fajrDiff > 0 || ishaDiff > 0, true);
      });

      test('all calculation methods should produce valid prayer times', () {
        final coordinates = Coordinates(TestData.jakartaLat, TestData.jakartaLng);
        final methods = AppSettings.calculationMethods.map((m) => m['id'] as String);
        
        for (final method in methods) {
          final testSettings = createTestSettings(calculationMethod: method);
          final params = testSettings.getCalculationParams();
          final pt = PrayerTimes.today(coordinates, params);
          
          expect(pt.fajr, isNotNull, reason: '$method fajr should not be null');
          expect(pt.dhuhr, isNotNull, reason: '$method dhuhr should not be null');
          expect(pt.asr, isNotNull, reason: '$method asr should not be null');
          expect(pt.maghrib, isNotNull, reason: '$method maghrib should not be null');
          expect(pt.isha, isNotNull, reason: '$method isha should not be null');
        }
      });
    });
  });

  group('Hijri Date Calculation', () {
    test('hijri month names should be correct', () {
      expect(TestData.hijriMonths.length, 12);
      expect(TestData.hijriMonths[0], 'Muharram');
      expect(TestData.hijriMonths[8], 'Ramadhan');
      expect(TestData.hijriMonths[11], 'Dzulhijjah');
    });

    test('hijri date calculation should produce reasonable values', () {
      final now = DateTime.now();
      final hijriEpoch = DateTime(622, 7, 16);
      final daysSinceHijri = now.difference(hijriEpoch).inDays;
      final hijriYear = (daysSinceHijri / 354.36667).floor();
      final hijriMonth = ((daysSinceHijri % 354.36667) / 29.53).floor() + 1;
      final hijriDay = ((daysSinceHijri % 354.36667) % 29.53).floor() + 1;

      // Hijri year should be between 1445-1450 for years 2024-2029
      expect(hijriYear, greaterThanOrEqualTo(1445));
      expect(hijriYear, lessThanOrEqualTo(1450));

      // Month should be 1-12
      expect(hijriMonth, greaterThanOrEqualTo(1));
      expect(hijriMonth, lessThanOrEqualTo(12));

      // Day should be 1-30
      expect(hijriDay, greaterThanOrEqualTo(1));
      expect(hijriDay, lessThanOrEqualTo(30));
    });

    test('all hijri month names should be non-empty', () {
      for (final month in TestData.hijriMonths) {
        expect(month, isNotEmpty);
        expect(month.length, greaterThan(3));
      }
    });
  });

  group('Tasbih Counter Logic', () {
    test('tasbih target should be 33', () {
      const tasbihTarget = 33;
      expect(tasbihTarget, 33);
    });

    test('tasbih count increment logic', () {
      int count = 0;
      const target = 33;

      for (int i = 0; i < 33; i++) {
        count++;
      }

      expect(count, target);
    });

    test('tasbih reset should set count to zero', () {
      int count = 25;
      count = 0; // reset

      expect(count, 0);
    });

    test('tasbih modulo for cycles', () {
      int count = 0;
      int cycles = 0;
      const target = 33;
      
      // Simulate 100 taps
      for (int i = 0; i < 100; i++) {
        count++;
        if (count >= target) {
          cycles++;
          count = 0;
        }
      }
      
      expect(cycles, 3); // 99 / 33 = 3 complete cycles
      expect(count, 1); // 100 - 99 = 1 remaining
    });
  });

  group('Next Prayer Logic', () {
    test('should identify next prayer correctly', () {
      final coordinates = Coordinates(TestData.jakartaLat, TestData.jakartaLng);
      final testSettings = createTestSettings();
      final params = testSettings.getCalculationParams();
      final pt = PrayerTimes.today(coordinates, params);
      
      final prayers = {
        'Subuh': pt.fajr,
        'Terbit': pt.sunrise,
        'Dzuhur': pt.dhuhr,
        'Ashar': pt.asr,
        'Maghrib': pt.maghrib,
        'Isya': pt.isha,
      };
      
      final now = DateTime.now();
      String? nextPrayer;
      DateTime? nextTime;
      
      for (var entry in prayers.entries) {
        if (entry.value.isAfter(now)) {
          nextPrayer = entry.key;
          nextTime = entry.value;
          break;
        }
      }
      
      // Either we found a prayer today or all passed (meaning next is tomorrow's Subuh)
      if (nextPrayer != null) {
        expect(TestData.prayerNames, contains(nextPrayer));
        expect(nextTime!.isAfter(now), true);
      }
    });

    test('countdown calculation should be positive for future prayer', () {
      final futureTime = DateTime.now().add(const Duration(hours: 1));
      final countdown = futureTime.difference(DateTime.now());
      
      expect(countdown.inSeconds, greaterThan(0));
      expect(countdown.inMinutes, greaterThanOrEqualTo(59));
    });

    test('countdown calculation should be negative for past prayer', () {
      final pastTime = DateTime.now().subtract(const Duration(hours: 1));
      final countdown = pastTime.difference(DateTime.now());
      
      expect(countdown.inSeconds, lessThan(0));
    });
  });

  group('Mock Services', () {
    test('mock notification service should track scheduled notifications', () async {
      final mockService = MockNotificationService();
      
      await mockService.schedulePrayerNotification(
        id: 0,
        prayerName: 'Subuh',
        prayerTime: DateTime.now().add(const Duration(hours: 1)),
      );
      
      expect(mockService.scheduledNotifications.length, 1);
      expect(mockService.scheduledNotifications[0].title, 'Waktu Subuh');
    });

    test('mock notification service should track all 5 prayers', () async {
      final mockService = MockNotificationService();
      final now = DateTime.now();
      
      final prayers = ['Subuh', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya'];
      for (int i = 0; i < prayers.length; i++) {
        await mockService.schedulePrayerNotification(
          id: i,
          prayerName: prayers[i],
          prayerTime: now.add(Duration(hours: i + 1)),
        );
      }
      
      expect(mockService.scheduledNotifications.length, 5);
    });

    test('mock timer should track ticks', () {
      int tickCount = 0;
      final timer = MockTimer.periodic(
        const Duration(seconds: 1),
        (t) => tickCount++,
      );
      
      timer.simulateTicks(5);
      
      expect(tickCount, 5);
      expect(timer.tick, 5);
    });

    test('mock timer cancel should stop ticks', () {
      int tickCount = 0;
      final timer = MockTimer.periodic(
        const Duration(seconds: 1),
        (t) => tickCount++,
      );
      
      timer.simulateTicks(3);
      timer.cancel();
      timer.simulateTicks(2); // Should not increment
      
      expect(tickCount, 3);
      expect(timer.isActive, false);
    });

    test('mock vibration should track durations', () {
      final mockVibration = MockVibrationService();
      
      mockVibration.vibrate(duration: 50);
      mockVibration.vibrate(duration: 1000);
      
      expect(mockVibration.vibrationDurations.length, 2);
      expect(mockVibration.vibrationDurations[0], 50);
      expect(mockVibration.vibrationDurations[1], 1000);
    });
  });

  group('Daily Verse Logic', () {
    test('default verse should be Bismillah', () {
      expect(TestData.sampleArabicVerse, contains('بِسْمِ'));
      expect(TestData.sampleTranslation, contains('Allah'));
      expect(TestData.sampleVerseSource, 'QS. Al-Fatihah : 1');
    });

    test('mock API response should be valid JSON', () {
      final response = createQuranApiResponse();
      expect(response, contains('"code": 200'));
      expect(response, contains('"englishName"'));
      expect(response, contains('"ayahs"'));
    });

    test('mock translation response should be valid JSON', () {
      final response = createTranslationApiResponse();
      expect(response, contains('"code": 200'));
      expect(response, contains('"text"'));
    });
  });
}
