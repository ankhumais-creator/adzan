import 'package:flutter_test/flutter_test.dart';
import 'package:adzan_monokrom/models/app_settings.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('AppSettings', () {
    group('Default Values', () {
      test('default constructor should have correct default values', () {
        final settings = AppSettings();
        
        expect(settings.calculationMethod, 'singapore');
        expect(settings.madhab, 'shafi');
        expect(settings.adzanSoundEnabled, true);
        expect(settings.vibrationEnabled, true);
        expect(settings.notificationEnabled, true);
        expect(settings.adzanVolume, 100);
        expect(settings.useManualLocation, false);
        expect(settings.manualLatitude, -6.2088);
        expect(settings.manualLongitude, 106.8456);
        expect(settings.manualLocationName, 'Jakarta, Indonesia');
      });

      test('constructor with custom values should work correctly', () {
        final settings = AppSettings(
          calculationMethod: 'umm_al_qura',
          madhab: 'hanafi',
          adzanSoundEnabled: false,
          vibrationEnabled: false,
          notificationEnabled: false,
          adzanVolume: 50,
          useManualLocation: true,
          manualLatitude: 21.4225,
          manualLongitude: 39.8262,
          manualLocationName: 'Makkah',
        );
        
        expect(settings.calculationMethod, 'umm_al_qura');
        expect(settings.madhab, 'hanafi');
        expect(settings.adzanSoundEnabled, false);
        expect(settings.vibrationEnabled, false);
        expect(settings.notificationEnabled, false);
        expect(settings.adzanVolume, 50);
        expect(settings.useManualLocation, true);
        expect(settings.manualLatitude, 21.4225);
        expect(settings.manualLongitude, 39.8262);
        expect(settings.manualLocationName, 'Makkah');
      });
    });

    group('Static Data', () {
      test('calculationMethods should contain all 11 supported methods', () {
        expect(AppSettings.calculationMethods.length, 11);
        
        final methodIds = AppSettings.calculationMethods.map((m) => m['id']).toList();
        expect(methodIds, contains('muslim_world_league'));
        expect(methodIds, contains('egyptian'));
        expect(methodIds, contains('karachi'));
        expect(methodIds, contains('umm_al_qura'));
        expect(methodIds, contains('dubai'));
        expect(methodIds, contains('qatar'));
        expect(methodIds, contains('kuwait'));
        expect(methodIds, contains('singapore'));
        expect(methodIds, contains('turkey'));
        expect(methodIds, contains('tehran'));
        expect(methodIds, contains('north_america'));
      });

      test('each calculation method should have id and name', () {
        for (final method in AppSettings.calculationMethods) {
          expect(method.containsKey('id'), true);
          expect(method.containsKey('name'), true);
          expect(method['id'], isNotEmpty);
          expect(method['name'], isNotEmpty);
        }
      });

      test('madhabs should contain shafi and hanafi only', () {
        expect(AppSettings.madhabs.length, 2);
        
        final madhabIds = AppSettings.madhabs.map((m) => m['id']).toList();
        expect(madhabIds, contains('shafi'));
        expect(madhabIds, contains('hanafi'));
      });

      test('popularCities should contain Indonesian cities', () {
        final cityNames = AppSettings.popularCities.map((c) => c['name']).toList();
        
        expect(cityNames, contains('Jakarta'));
        expect(cityNames, contains('Surabaya'));
        expect(cityNames, contains('Bandung'));
        expect(cityNames, contains('Medan'));
        expect(cityNames, contains('Semarang'));
        expect(cityNames, contains('Makassar'));
        expect(cityNames, contains('Yogyakarta'));
      });

      test('popularCities should contain holy cities', () {
        final cityNames = AppSettings.popularCities.map((c) => c['name']).toList();
        
        expect(cityNames, contains('Makkah'));
        expect(cityNames, contains('Madinah'));
      });

      test('each popularCity should have valid coordinates', () {
        for (final city in AppSettings.popularCities) {
          expect(city.containsKey('name'), true);
          expect(city.containsKey('lat'), true);
          expect(city.containsKey('lng'), true);
          expect(city.containsKey('country'), true);
          
          final lat = city['lat'] as double;
          final lng = city['lng'] as double;
          
          // Valid latitude range: -90 to 90
          expect(lat, greaterThanOrEqualTo(-90));
          expect(lat, lessThanOrEqualTo(90));
          
          // Valid longitude range: -180 to 180
          expect(lng, greaterThanOrEqualTo(-180));
          expect(lng, lessThanOrEqualTo(180));
        }
      });
    });

    group('Calculation Parameters', () {
      test('getCalculationParams for singapore should return valid params', () {
        final settings = AppSettings(calculationMethod: 'singapore');
        final params = settings.getCalculationParams();
        
        expect(params, isNotNull);
        expect(params.fajrAngle, isNotNull);
        expect(params.ishaAngle, isNotNull);
      });

      test('getCalculationParams for all methods should return valid params', () {
        final methods = AppSettings.calculationMethods.map((m) => m['id'] as String).toList();
        
        for (final method in methods) {
          final settings = AppSettings(calculationMethod: method);
          final params = settings.getCalculationParams();
          expect(params, isNotNull, reason: 'Method $method should return valid params');
          expect(params.fajrAngle, isNotNull, reason: '$method fajrAngle should not be null');
        }
      });

      test('getCalculationParams with shafi madhab should set correct madhab', () {
        final settings = AppSettings(madhab: 'shafi');
        final params = settings.getCalculationParams();
        
        expect(params.madhab.name, 'shafi');
      });

      test('getCalculationParams with hanafi madhab should set correct madhab', () {
        final settings = AppSettings(madhab: 'hanafi');
        final params = settings.getCalculationParams();
        
        expect(params.madhab.name, 'hanafi');
      });

      test('unknown calculation method should default to singapore', () {
        final settings = AppSettings(calculationMethod: 'unknown_method');
        final params = settings.getCalculationParams();
        
        final singaporeSettings = AppSettings(calculationMethod: 'singapore');
        final singaporeParams = singaporeSettings.getCalculationParams();
        
        expect(params.fajrAngle, singaporeParams.fajrAngle);
        expect(params.ishaAngle, singaporeParams.ishaAngle);
      });
    });

    group('copyWith', () {
      test('copyWith should create new instance with updated values', () {
        final original = AppSettings();
        final copied = original.copyWith(
          calculationMethod: 'egyptian',
          adzanVolume: 75,
        );
        
        // Original should be unchanged
        expect(original.calculationMethod, 'singapore');
        expect(original.adzanVolume, 100);
        
        // Copy should have new values
        expect(copied.calculationMethod, 'egyptian');
        expect(copied.adzanVolume, 75);
        
        // Other values should be same as original
        expect(copied.madhab, original.madhab);
        expect(copied.adzanSoundEnabled, original.adzanSoundEnabled);
      });

      test('copyWith with no changes should create identical copy', () {
        final original = AppSettings(
          calculationMethod: 'umm_al_qura',
          adzanVolume: 50,
        );
        final copied = original.copyWith();
        
        expect(copied.calculationMethod, original.calculationMethod);
        expect(copied.adzanVolume, original.adzanVolume);
        expect(copied.madhab, original.madhab);
      });

      test('copyWith should allow updating all fields', () {
        final original = AppSettings();
        final copied = original.copyWith(
          calculationMethod: 'egyptian',
          madhab: 'hanafi',
          adzanSoundEnabled: false,
          vibrationEnabled: false,
          notificationEnabled: false,
          adzanVolume: 50,
          useManualLocation: true,
          manualLatitude: 21.4225,
          manualLongitude: 39.8262,
          manualLocationName: 'Makkah',
        );
        
        expect(copied.calculationMethod, 'egyptian');
        expect(copied.madhab, 'hanafi');
        expect(copied.adzanSoundEnabled, false);
        expect(copied.vibrationEnabled, false);
        expect(copied.notificationEnabled, false);
        expect(copied.adzanVolume, 50);
        expect(copied.useManualLocation, true);
        expect(copied.manualLatitude, 21.4225);
        expect(copied.manualLongitude, 39.8262);
        expect(copied.manualLocationName, 'Makkah');
      });
    });

    group('Edge Cases & Boundary Conditions', () {
      test('adzanVolume at minimum boundary (0)', () {
        final settings = AppSettings(adzanVolume: 0);
        expect(settings.adzanVolume, 0);
      });

      test('adzanVolume at maximum boundary (100)', () {
        final settings = AppSettings(adzanVolume: 100);
        expect(settings.adzanVolume, 100);
      });

      test('latitude at boundary values', () {
        // South pole
        final southPole = AppSettings(manualLatitude: -90);
        expect(southPole.manualLatitude, -90);
        
        // North pole
        final northPole = AppSettings(manualLatitude: 90);
        expect(northPole.manualLatitude, 90);
        
        // Equator
        final equator = AppSettings(manualLatitude: 0);
        expect(equator.manualLatitude, 0);
      });

      test('longitude at boundary values', () {
        // International date line west
        final west = AppSettings(manualLongitude: -180);
        expect(west.manualLongitude, -180);
        
        // International date line east
        final east = AppSettings(manualLongitude: 180);
        expect(east.manualLongitude, 180);
        
        // Prime meridian
        final prime = AppSettings(manualLongitude: 0);
        expect(prime.manualLongitude, 0);
      });

      test('empty location name should be allowed', () {
        final settings = AppSettings(manualLocationName: '');
        expect(settings.manualLocationName, '');
      });

      test('location name with special characters', () {
        final settings = AppSettings(
          manualLocationName: "Makkah Al-Mukarramah (مكة المكرمة)",
        );
        expect(settings.manualLocationName, contains('Makkah'));
        expect(settings.manualLocationName, contains('مكة'));
      });
    });

    group('Test Helper Factory', () {
      test('createTestSettings should create default test settings', () {
        final settings = createTestSettings();
        
        expect(settings.useManualLocation, true);
        expect(settings.notificationEnabled, false); // Disabled for tests
        expect(settings.calculationMethod, 'singapore');
      });

      test('createMakkahSettings should create Makkah settings', () {
        final settings = createMakkahSettings();
        
        expect(settings.calculationMethod, 'umm_al_qura');
        expect(settings.manualLatitude, TestData.makkahLat);
        expect(settings.manualLongitude, TestData.makkahLng);
        expect(settings.manualLocationName, 'Makkah, Saudi Arabia');
      });

      test('createMadinahSettings should create Madinah settings', () {
        final settings = createMadinahSettings();
        
        expect(settings.calculationMethod, 'umm_al_qura');
        expect(settings.manualLatitude, TestData.madinahLat);
        expect(settings.manualLongitude, TestData.madinahLng);
      });
    });
  });
}
