import 'package:flutter_test/flutter_test.dart';
import '../helpers/mock_services.dart';

/// Tests for NotificationService logic
/// Note: Full notification tests require platform channels and are in integration tests
void main() {
  group('NotificationService Logic', () {
    late MockNotificationService mockService;

    setUp(() {
      mockService = MockNotificationService();
    });

    group('Initialization', () {
      test('init should set initialized to true', () async {
        expect(mockService.initialized, false);
        
        await mockService.init();
        
        expect(mockService.initialized, true);
      });
    });

    group('Prayer Notifications', () {
      test('schedulePrayerNotification should add to list', () async {
        await mockService.schedulePrayerNotification(
          id: 0,
          prayerName: 'Subuh',
          prayerTime: DateTime.now().add(const Duration(hours: 1)),
        );
        
        expect(mockService.scheduledNotifications.length, 1);
        expect(mockService.scheduledNotifications[0].id, 0);
        expect(mockService.scheduledNotifications[0].title, 'Waktu Subuh');
        expect(mockService.scheduledNotifications[0].body, 'Saatnya menunaikan sholat Subuh');
      });

      test('should schedule all 5 prayer notifications', () async {
        final now = DateTime.now();
        final prayers = [
          {'id': 0, 'name': 'Subuh', 'offset': 1},
          {'id': 1, 'name': 'Dzuhur', 'offset': 6},
          {'id': 2, 'name': 'Ashar', 'offset': 9},
          {'id': 3, 'name': 'Maghrib', 'offset': 12},
          {'id': 4, 'name': 'Isya', 'offset': 14},
        ];
        
        for (final prayer in prayers) {
          await mockService.schedulePrayerNotification(
            id: prayer['id'] as int,
            prayerName: prayer['name'] as String,
            prayerTime: now.add(Duration(hours: prayer['offset'] as int)),
          );
        }
        
        expect(mockService.scheduledNotifications.length, 5);
        
        // Verify each prayer
        expect(mockService.scheduledNotifications[0].title, 'Waktu Subuh');
        expect(mockService.scheduledNotifications[1].title, 'Waktu Dzuhur');
        expect(mockService.scheduledNotifications[2].title, 'Waktu Ashar');
        expect(mockService.scheduledNotifications[3].title, 'Waktu Maghrib');
        expect(mockService.scheduledNotifications[4].title, 'Waktu Isya');
      });

      test('scheduled time should be in future', () async {
        final futureTime = DateTime.now().add(const Duration(hours: 2));
        
        await mockService.schedulePrayerNotification(
          id: 0,
          prayerName: 'Dzuhur',
          prayerTime: futureTime,
        );
        
        expect(
          mockService.scheduledNotifications[0].scheduledTime.isAfter(DateTime.now()),
          true,
        );
      });
    });

    group('Instant Notifications', () {
      test('showInstantNotification should add to shown list', () async {
        await mockService.showInstantNotification('Test Title', 'Test Body');
        
        expect(mockService.shownNotifications.length, 1);
        expect(mockService.shownNotifications[0], 'Test Title: Test Body');
      });

      test('multiple instant notifications should all be tracked', () async {
        await mockService.showInstantNotification('Title 1', 'Body 1');
        await mockService.showInstantNotification('Title 2', 'Body 2');
        await mockService.showInstantNotification('Title 3', 'Body 3');
        
        expect(mockService.shownNotifications.length, 3);
      });
    });

    group('Ongoing Timer Notification', () {
      test('showOngoingTimerNotification should set active flag', () async {
        expect(mockService.ongoingNotificationActive, false);
        
        await mockService.showOngoingTimerNotification(
          nextPrayerName: 'Ashar',
          countdown: const Duration(hours: 1, minutes: 30),
        );
        
        expect(mockService.ongoingNotificationActive, true);
      });

      test('cancelOngoingNotification should clear active flag', () async {
        await mockService.showOngoingTimerNotification(
          nextPrayerName: 'Maghrib',
          countdown: const Duration(minutes: 45),
        );
        expect(mockService.ongoingNotificationActive, true);
        
        await mockService.cancelOngoingNotification();
        expect(mockService.ongoingNotificationActive, false);
      });
    });

    group('Cancel All', () {
      test('cancelAll should clear all lists and flags', () async {
        // Add some data
        await mockService.schedulePrayerNotification(
          id: 0,
          prayerName: 'Subuh',
          prayerTime: DateTime.now().add(const Duration(hours: 1)),
        );
        await mockService.showInstantNotification('Test', 'Body');
        await mockService.showOngoingTimerNotification(
          nextPrayerName: 'Dzuhur',
          countdown: const Duration(hours: 2),
        );
        
        // Verify data exists
        expect(mockService.scheduledNotifications.length, 1);
        expect(mockService.shownNotifications.length, 1);
        expect(mockService.ongoingNotificationActive, true);
        
        // Cancel all
        await mockService.cancelAll();
        
        // Verify all cleared
        expect(mockService.scheduledNotifications.length, 0);
        expect(mockService.shownNotifications.length, 0);
        expect(mockService.ongoingNotificationActive, false);
      });
    });
  });

  group('Countdown Timer Formatting', () {
    test('format hours minutes seconds correctly', () {
      const countdown = Duration(hours: 2, minutes: 30, seconds: 45);
      
      final hours = countdown.inHours;
      final minutes = (countdown.inMinutes % 60);
      final seconds = (countdown.inSeconds % 60);
      
      String timeString;
      if (hours > 0) {
        timeString = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      } else {
        timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }
      
      expect(timeString, '02:30:45');
    });

    test('format minutes seconds only when hours is 0', () {
      const countdown = Duration(minutes: 15, seconds: 30);
      
      final hours = countdown.inHours;
      final minutes = (countdown.inMinutes % 60);
      final seconds = (countdown.inSeconds % 60);
      
      String timeString;
      if (hours > 0) {
        timeString = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      } else {
        timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }
      
      expect(timeString, '15:30');
    });

    test('format with single digits should pad correctly', () {
      const countdown = Duration(hours: 1, minutes: 5, seconds: 9);
      
      final hours = countdown.inHours;
      final minutes = (countdown.inMinutes % 60);
      final seconds = (countdown.inSeconds % 60);
      
      final timeString = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      
      expect(timeString, '01:05:09');
    });

    test('format zero duration', () {
      const countdown = Duration.zero;
      
      final hours = countdown.inHours;
      final minutes = (countdown.inMinutes % 60);
      final seconds = (countdown.inSeconds % 60);
      
      final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      
      expect(timeString, '00:00');
      expect(hours, 0);
    });
  });

  group('ScheduledNotification Data Class', () {
    test('should store all properties correctly', () {
      final scheduledTime = DateTime.now().add(const Duration(hours: 1));
      
      final notification = ScheduledNotification(
        id: 42,
        title: 'Test Title',
        body: 'Test Body',
        scheduledTime: scheduledTime,
      );
      
      expect(notification.id, 42);
      expect(notification.title, 'Test Title');
      expect(notification.body, 'Test Body');
      expect(notification.scheduledTime, scheduledTime);
    });
  });
}
