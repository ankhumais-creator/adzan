// Basic smoke test for Adzan Monokrom app
//
// This file ensures the app can be instantiated.
// More comprehensive tests are in the widgets/ and providers/ folders.

import 'package:flutter_test/flutter_test.dart';

import 'package:adzan_monokrom/models/app_settings.dart';

void main() {
  group('App Smoke Tests', () {
    test('AppSettings can be instantiated with defaults', () {
      final settings = AppSettings();
      expect(settings, isNotNull);
      expect(settings.calculationMethod, equals('singapore'));
      expect(settings.adzanSoundEnabled, isTrue);
    });

    test('AppSettings copyWith works correctly', () {
      final settings = AppSettings();
      final updated = settings.copyWith(adzanSoundEnabled: false);
      
      expect(updated.adzanSoundEnabled, isFalse);
      expect(updated.calculationMethod, equals(settings.calculationMethod));
    });

    test('AppSettings has correct default values', () {
      final settings = AppSettings();
      expect(settings.madhab, equals('shafi'));
      expect(settings.vibrationEnabled, isTrue);
      expect(settings.notificationEnabled, isTrue);
      expect(settings.adzanVolume, equals(100));
      expect(settings.useManualLocation, isFalse);
      expect(settings.manualLocationName, equals('Jakarta, Indonesia'));
    });
  });
}
