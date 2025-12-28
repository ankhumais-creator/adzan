import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adzan_monokrom/providers/settings_provider.dart';
import '../helpers/test_helpers.dart';

void main() {
  late Map<String, Object> storedValues;
  
  // Set up mock SharedPreferences before tests
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    storedValues = <String, Object>{};
    
    // Mock SharedPreferences
    const channel = MethodChannel('plugins.flutter.io/shared_preferences');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getAll':
          return storedValues;
        case 'setString':
          final args = methodCall.arguments as Map<Object?, Object?>;
          storedValues[args['key'] as String] = args['value'] as String;
          return true;
        case 'setInt':
          final args = methodCall.arguments as Map<Object?, Object?>;
          storedValues[args['key'] as String] = args['value'] as int;
          return true;
        case 'setBool':
          final args = methodCall.arguments as Map<Object?, Object?>;
          storedValues[args['key'] as String] = args['value'] as bool;
          return true;
        case 'setDouble':
          final args = methodCall.arguments as Map<Object?, Object?>;
          storedValues[args['key'] as String] = args['value'] as double;
          return true;
        case 'remove':
          final key = methodCall.arguments as String;
          storedValues.remove(key);
          return true;
        case 'clear':
          storedValues.clear();
          return true;
        default:
          return null;
      }
    });
  });

  setUp(() {
    storedValues.clear();
  });

  group('SettingsProvider', () {
    late SettingsProvider settingsProvider;

    setUp(() {
      settingsProvider = SettingsProvider();
    });

    group('Initial State', () {
      test('initial settings should have default values', () {
        expect(settingsProvider.settings.calculationMethod, 'singapore');
        expect(settingsProvider.settings.madhab, 'shafi');
        expect(settingsProvider.settings.adzanSoundEnabled, true);
        expect(settingsProvider.settings.vibrationEnabled, true);
        expect(settingsProvider.settings.notificationEnabled, true);
        expect(settingsProvider.settings.adzanVolume, 100);
        expect(settingsProvider.settings.useManualLocation, false);
      });

      test('isLoading should be true initially', () {
        expect(settingsProvider.isLoading, true);
      });

      test('settings getter should return AppSettings instance', () {
        expect(settingsProvider.settings, isNotNull);
        expect(settingsProvider.settings.calculationMethod, isNotEmpty);
      });

      test('settings should have valid default location', () {
        expect(settingsProvider.settings.manualLatitude, TestData.jakartaLat);
        expect(settingsProvider.settings.manualLongitude, TestData.jakartaLng);
        expect(settingsProvider.settings.manualLocationName, TestData.jakartaName);
      });
    });

    group('Setter Methods - Notifications', () {
      test('setCalculationMethod should update and notify', () {
        bool notified = false;
        settingsProvider.addListener(() => notified = true);

        settingsProvider.setCalculationMethod('egyptian');

        expect(settingsProvider.settings.calculationMethod, 'egyptian');
        expect(notified, true);
      });

      test('setMadhab should update and notify', () {
        bool notified = false;
        settingsProvider.addListener(() => notified = true);

        settingsProvider.setMadhab('hanafi');

        expect(settingsProvider.settings.madhab, 'hanafi');
        expect(notified, true);
      });

      test('setAdzanSoundEnabled should toggle and notify', () {
        bool notified = false;
        settingsProvider.addListener(() => notified = true);

        settingsProvider.setAdzanSoundEnabled(false);

        expect(settingsProvider.settings.adzanSoundEnabled, false);
        expect(notified, true);
      });

      test('setAdzanVolume should update and notify', () {
        bool notified = false;
        settingsProvider.addListener(() => notified = true);

        settingsProvider.setAdzanVolume(75);

        expect(settingsProvider.settings.adzanVolume, 75);
        expect(notified, true);
      });

      test('setVibrationEnabled should toggle and notify', () {
        bool notified = false;
        settingsProvider.addListener(() => notified = true);

        settingsProvider.setVibrationEnabled(false);

        expect(settingsProvider.settings.vibrationEnabled, false);
        expect(notified, true);
      });

      test('setNotificationEnabled should toggle and notify', () {
        bool notified = false;
        settingsProvider.addListener(() => notified = true);

        settingsProvider.setNotificationEnabled(false);

        expect(settingsProvider.settings.notificationEnabled, false);
        expect(notified, true);
      });

      test('setUseManualLocation should toggle and notify', () {
        bool notified = false;
        settingsProvider.addListener(() => notified = true);

        settingsProvider.setUseManualLocation(true);

        expect(settingsProvider.settings.useManualLocation, true);
        expect(notified, true);
      });
    });

    group('Location Settings', () {
      test('setManualLocation should update all location fields', () {
        bool notified = false;
        settingsProvider.addListener(() => notified = true);

        settingsProvider.setManualLocation(
          latitude: TestData.makkahLat,
          longitude: TestData.makkahLng,
          locationName: TestData.makkahName,
        );

        expect(settingsProvider.settings.manualLatitude, TestData.makkahLat);
        expect(settingsProvider.settings.manualLongitude, TestData.makkahLng);
        expect(settingsProvider.settings.manualLocationName, TestData.makkahName);
        expect(notified, true);
      });

      test('setManualLocation for different cities', () {
        // Set Jakarta
        settingsProvider.setManualLocation(
          latitude: TestData.jakartaLat,
          longitude: TestData.jakartaLng,
          locationName: TestData.jakartaName,
        );
        expect(settingsProvider.settings.manualLocationName, TestData.jakartaName);

        // Change to Surabaya
        settingsProvider.setManualLocation(
          latitude: TestData.surabayaLat,
          longitude: TestData.surabayaLng,
          locationName: TestData.surabayaName,
        );
        expect(settingsProvider.settings.manualLocationName, TestData.surabayaName);
        expect(settingsProvider.settings.manualLatitude, TestData.surabayaLat);
      });
    });

    group('Multiple Updates', () {
      test('multiple setters should notify each time', () {
        int notifyCount = 0;
        settingsProvider.addListener(() => notifyCount++);

        settingsProvider.setCalculationMethod('egyptian');
        settingsProvider.setMadhab('hanafi');
        settingsProvider.setAdzanVolume(50);

        expect(notifyCount, 3);
      });

      test('settings should reflect all changes correctly', () {
        settingsProvider.setCalculationMethod('umm_al_qura');
        settingsProvider.setMadhab('hanafi');
        settingsProvider.setAdzanVolume(75);
        settingsProvider.setVibrationEnabled(false);
        settingsProvider.setNotificationEnabled(false);

        expect(settingsProvider.settings.calculationMethod, 'umm_al_qura');
        expect(settingsProvider.settings.madhab, 'hanafi');
        expect(settingsProvider.settings.adzanVolume, 75);
        expect(settingsProvider.settings.vibrationEnabled, false);
        expect(settingsProvider.settings.notificationEnabled, false);
      });
    });

    group('Calculation Parameter Integration', () {
      test('changing calculation method should affect prayer params', () {
        settingsProvider.setCalculationMethod('muslim_world_league');
        final mwlParams = settingsProvider.settings.getCalculationParams();

        settingsProvider.setCalculationMethod('umm_al_qura');
        final uaqParams = settingsProvider.settings.getCalculationParams();

        // Different methods have different angles
        expect(mwlParams.fajrAngle != uaqParams.fajrAngle || 
               mwlParams.ishaAngle != uaqParams.ishaAngle, true);
      });

      test('changing madhab should affect asr calculation', () {
        settingsProvider.setMadhab('shafi');
        final shafiParams = settingsProvider.settings.getCalculationParams();

        settingsProvider.setMadhab('hanafi');
        final hanafiParams = settingsProvider.settings.getCalculationParams();

        expect(shafiParams.madhab.name, 'shafi');
        expect(hanafiParams.madhab.name, 'hanafi');
      });
    });

    group('Volume Boundary Tests', () {
      test('volume at 0 should be valid', () {
        settingsProvider.setAdzanVolume(0);
        expect(settingsProvider.settings.adzanVolume, 0);
      });

      test('volume at 100 should be valid', () {
        settingsProvider.setAdzanVolume(100);
        expect(settingsProvider.settings.adzanVolume, 100);
      });

      test('volume at 50 should be valid', () {
        settingsProvider.setAdzanVolume(50);
        expect(settingsProvider.settings.adzanVolume, 50);
      });
    });
  });
}
