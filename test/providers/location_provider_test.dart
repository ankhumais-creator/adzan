import 'package:flutter_test/flutter_test.dart';
import 'package:adzan_monokrom/providers/location_provider.dart';
import '../helpers/test_helpers.dart';
import '../helpers/mock_services.dart';

void main() {
  group('LocationProvider', () {
    late LocationProvider locationProvider;

    setUp(() {
      locationProvider = LocationProvider();
    });

    group('Initial State', () {
      test('initial values should be correct', () {
        expect(locationProvider.currentPosition, isNull);
        expect(locationProvider.locationName, 'Mencari lokasi...');
        expect(locationProvider.isLoading, false);
        expect(locationProvider.errorMessage, isNull);
      });
    });

    group('setManualLocation', () {
      test('should update position and name', () {
        bool notified = false;
        locationProvider.addListener(() => notified = true);
        
        locationProvider.setManualLocation(
          latitude: TestData.jakartaLat,
          longitude: TestData.jakartaLng,
          locationName: TestData.jakartaName,
        );
        
        expect(locationProvider.currentPosition, isNotNull);
        expect(locationProvider.currentPosition!.latitude, TestData.jakartaLat);
        expect(locationProvider.currentPosition!.longitude, TestData.jakartaLng);
        expect(locationProvider.locationName, TestData.jakartaName);
        expect(locationProvider.errorMessage, isNull);
        expect(notified, true);
      });

      test('for Makkah should work correctly', () {
        locationProvider.setManualLocation(
          latitude: TestData.makkahLat,
          longitude: TestData.makkahLng,
          locationName: TestData.makkahName,
        );
        
        expect(locationProvider.currentPosition!.latitude, TestData.makkahLat);
        expect(locationProvider.currentPosition!.longitude, TestData.makkahLng);
        expect(locationProvider.locationName, TestData.makkahName);
      });

      test('for Madinah should work correctly', () {
        locationProvider.setManualLocation(
          latitude: TestData.madinahLat,
          longitude: TestData.madinahLng,
          locationName: TestData.madinahName,
        );
        
        expect(locationProvider.currentPosition!.latitude, TestData.madinahLat);
        expect(locationProvider.currentPosition!.longitude, TestData.madinahLng);
        expect(locationProvider.locationName, TestData.madinahName);
      });

      test('should clear error message', () {
        locationProvider.setManualLocation(
          latitude: TestData.jakartaLat,
          longitude: TestData.jakartaLng,
          locationName: TestData.jakartaName,
        );
        
        expect(locationProvider.errorMessage, isNull);
      });

      test('multiple calls should update correctly', () {
        // Set Jakarta
        locationProvider.setManualLocation(
          latitude: TestData.jakartaLat,
          longitude: TestData.jakartaLng,
          locationName: TestData.jakartaName,
        );
        expect(locationProvider.locationName, TestData.jakartaName);
        
        // Change to Surabaya
        locationProvider.setManualLocation(
          latitude: TestData.surabayaLat,
          longitude: TestData.surabayaLng,
          locationName: TestData.surabayaName,
        );
        expect(locationProvider.locationName, TestData.surabayaName);
        expect(locationProvider.currentPosition!.latitude, TestData.surabayaLat);
        
        // Change to Makkah
        locationProvider.setManualLocation(
          latitude: TestData.makkahLat,
          longitude: TestData.makkahLng,
          locationName: TestData.makkahName,
        );
        expect(locationProvider.locationName, TestData.makkahName);
        expect(locationProvider.currentPosition!.latitude, TestData.makkahLat);
      });
    });

    group('Position Properties', () {
      test('position should have all required fields', () {
        locationProvider.setManualLocation(
          latitude: TestData.jakartaLat,
          longitude: TestData.jakartaLng,
          locationName: TestData.jakartaName,
        );
        
        final position = locationProvider.currentPosition!;
        expect(position.latitude, isNotNull);
        expect(position.longitude, isNotNull);
        expect(position.timestamp, isNotNull);
        expect(position.accuracy, 0);
        expect(position.altitude, 0);
        expect(position.speed, 0);
      });

      test('position timestamp should be recent', () {
        final before = DateTime.now();
        
        locationProvider.setManualLocation(
          latitude: TestData.jakartaLat,
          longitude: TestData.jakartaLng,
          locationName: TestData.jakartaName,
        );
        
        final after = DateTime.now();
        final timestamp = locationProvider.currentPosition!.timestamp;
        
        expect(timestamp.isAfter(before) || timestamp.isAtSameMomentAs(before), true);
        expect(timestamp.isBefore(after) || timestamp.isAtSameMomentAs(after), true);
      });
    });

    group('clearError', () {
      test('should set errorMessage to null and notify', () {
        bool notified = false;
        locationProvider.addListener(() => notified = true);
        
        locationProvider.clearError();
        
        expect(locationProvider.errorMessage, isNull);
        expect(notified, true);
      });
    });

    group('Coordinate Boundary Tests', () {
      test('equator coordinates should work', () {
        locationProvider.setManualLocation(
          latitude: 0.0,
          longitude: 0.0,
          locationName: 'Equator, Prime Meridian',
        );
        
        expect(locationProvider.currentPosition!.latitude, 0.0);
        expect(locationProvider.currentPosition!.longitude, 0.0);
      });

      test('extreme latitude should work', () {
        // Near North Pole
        locationProvider.setManualLocation(
          latitude: 89.0,
          longitude: 0.0,
          locationName: 'Near North Pole',
        );
        expect(locationProvider.currentPosition!.latitude, 89.0);

        // Near South Pole
        locationProvider.setManualLocation(
          latitude: -89.0,
          longitude: 0.0,
          locationName: 'Near South Pole',
        );
        expect(locationProvider.currentPosition!.latitude, -89.0);
      });

      test('extreme longitude should work', () {
        locationProvider.setManualLocation(
          latitude: 0.0,
          longitude: 179.0,
          locationName: 'Near Date Line East',
        );
        expect(locationProvider.currentPosition!.longitude, 179.0);

        locationProvider.setManualLocation(
          latitude: 0.0,
          longitude: -179.0,
          locationName: 'Near Date Line West',
        );
        expect(locationProvider.currentPosition!.longitude, -179.0);
      });
    });

    group('Notification Count', () {
      test('each setManualLocation should notify once', () {
        int notifyCount = 0;
        locationProvider.addListener(() => notifyCount++);

        locationProvider.setManualLocation(
          latitude: TestData.jakartaLat,
          longitude: TestData.jakartaLng,
          locationName: TestData.jakartaName,
        );

        locationProvider.setManualLocation(
          latitude: TestData.makkahLat,
          longitude: TestData.makkahLng,
          locationName: TestData.makkahName,
        );

        expect(notifyCount, 2);
      });
    });

    group('Mock Geolocator Wrapper', () {
      test('mock should return position', () async {
        final mockGeo = MockGeolocatorWrapper();
        mockGeo.currentPosition = createMockPosition(
          latitude: TestData.jakartaLat,
          longitude: TestData.jakartaLng,
        );

        final position = await mockGeo.getCurrentPosition();
        
        expect(position.latitude, TestData.jakartaLat);
        expect(position.longitude, TestData.jakartaLng);
      });

      test('mock should handle disabled service', () async {
        final mockGeo = MockGeolocatorWrapper();
        mockGeo.serviceEnabled = false;

        final enabled = await mockGeo.isLocationServiceEnabled();
        expect(enabled, false);
      });

      test('mock should throw exception when configured', () async {
        final mockGeo = MockGeolocatorWrapper();
        mockGeo.errorToThrow = Exception('GPS tidak aktif');

        expect(
          () => mockGeo.getCurrentPosition(),
          throwsException,
        );
      });
    });
  });
}
