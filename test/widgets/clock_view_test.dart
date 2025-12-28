import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adzan_monokrom/features/home/clock_view.dart';

void main() {
  group('ClockView', () {
    group('Basic Rendering', () {
      testWidgets('renders with required parameters', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ClockView(
                nextPrayer: 'Dzuhur',
                countdown: Duration(hours: 2, minutes: 30, seconds: 15),
              ),
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));
        
        expect(find.byType(ClockView), findsOneWidget);
      });

      testWidgets('displays prayer name in uppercase', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ClockView(
                nextPrayer: 'dzuhur',
                countdown: Duration(hours: 1),
              ),
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));
        
        expect(find.text('DZUHUR'), findsOneWidget);
      });

      testWidgets('displays footer text', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ClockView(
                nextPrayer: 'Ashar',
                countdown: Duration(hours: 1),
              ),
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));
        
        expect(find.text('menuju waktu sholat'), findsOneWidget);
      });
    });

    group('Countdown Display', () {
      testWidgets('displays hours correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ClockView(
                nextPrayer: 'Subuh',
                countdown: Duration(hours: 5, minutes: 30, seconds: 45),
              ),
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));
        
        // Should display "05" for hours
        expect(find.text('05'), findsOneWidget);
      });

      testWidgets('displays minutes correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ClockView(
                nextPrayer: 'Maghrib',
                countdown: Duration(hours: 0, minutes: 45, seconds: 30),
              ),
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));
        
        // Should display "45" for minutes
        expect(find.text('45'), findsOneWidget);
      });

      testWidgets('displays seconds correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ClockView(
                nextPrayer: 'Isya',
                countdown: Duration(hours: 0, minutes: 0, seconds: 30),
              ),
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));
        
        // Should display "30" for seconds
        expect(find.text('30'), findsOneWidget);
      });

      testWidgets('pads single digit values with zero', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ClockView(
                nextPrayer: 'Dzuhur',
                countdown: Duration(hours: 1, minutes: 5, seconds: 9),
              ),
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));
        
        // Should display "01", "05", "09" with leading zeros
        expect(find.text('01'), findsOneWidget);
        expect(find.text('05'), findsOneWidget);
        expect(find.text('09'), findsOneWidget);
      });

      testWidgets('displays zero duration correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ClockView(
                nextPrayer: 'Subuh',
                countdown: Duration.zero,
              ),
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));
        
        // Should display "00" for all
        expect(find.text('00'), findsNWidgets(3));
      });
    });

    group('Labels', () {
      testWidgets('displays JAM label', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ClockView(
                nextPrayer: 'Dzuhur',
                countdown: Duration(hours: 1),
              ),
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));
        
        expect(find.text('JAM'), findsOneWidget);
      });

      testWidgets('displays MENIT label', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ClockView(
                nextPrayer: 'Dzuhur',
                countdown: Duration(hours: 1),
              ),
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));
        
        expect(find.text('MENIT'), findsOneWidget);
      });

      testWidgets('displays DETIK label', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ClockView(
                nextPrayer: 'Dzuhur',
                countdown: Duration(hours: 1),
              ),
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));
        
        expect(find.text('DETIK'), findsOneWidget);
      });
    });

    group('Structure', () {
      testWidgets('uses Column layout', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ClockView(
                nextPrayer: 'Ashar',
                countdown: Duration(hours: 2),
              ),
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));
        
        expect(find.byType(Column), findsWidgets);
      });

      testWidgets('uses Row for countdown display', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ClockView(
                nextPrayer: 'Maghrib',
                countdown: Duration(hours: 1),
              ),
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));
        
        expect(find.byType(Row), findsWidgets);
      });

      testWidgets('contains separators', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ClockView(
                nextPrayer: 'Isya',
                countdown: Duration(hours: 3),
              ),
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));
        
        // Should have two colon separators
        expect(find.text(':'), findsNWidgets(2));
      });
    });

    group('Animation', () {
      testWidgets('disposes animation controller without errors', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ClockView(
                nextPrayer: 'Subuh',
                countdown: Duration(hours: 1),
              ),
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));
        
        // Replace widget to trigger dispose
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(),
            ),
          ),
        );
        
        // Should dispose without errors
        expect(find.byType(ClockView), findsNothing);
      });

      testWidgets('animation runs over time', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ClockView(
                nextPrayer: 'Dzuhur',
                countdown: Duration(hours: 2),
              ),
            ),
          ),
        );
        
        // Advance through animation
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        
        // Widget should still be rendering
        expect(find.byType(ClockView), findsOneWidget);
      });
    });

    group('Prayer Names', () {
      final prayerNames = ['Subuh', 'Terbit', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya'];
      
      for (final prayer in prayerNames) {
        testWidgets('renders $prayer correctly', (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ClockView(
                  nextPrayer: prayer,
                  countdown: const Duration(hours: 1),
                ),
              ),
            ),
          );
          
          await tester.pump(const Duration(milliseconds: 100));
          
          expect(find.text(prayer.toUpperCase()), findsOneWidget);
        });
      }
    });
  });
}
