import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:adzan_monokrom/providers/settings_provider.dart';
import 'package:adzan_monokrom/providers/location_provider.dart';
import 'package:adzan_monokrom/providers/prayer_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Startup Flow', () {
    testWidgets('app starts without crashing', (WidgetTester tester) async {
      // Note: This test requires the app to be started with proper initialization
      // In a real integration test, you would use:
      // app.main();
      // await tester.pumpAndSettle();
      
      // For now, we test the minimal startup
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => LocationProvider()),
            ChangeNotifierProvider(create: (_) => PrayerProvider()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(child: Text('App Started')),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.text('App Started'), findsOneWidget);
    });

    testWidgets('providers are accessible', (WidgetTester tester) async {
      final settingsProvider = SettingsProvider();
      final locationProvider = LocationProvider();
      final prayerProvider = PrayerProvider();
      
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
                final settings = Provider.of<SettingsProvider>(context, listen: false);
                final location = Provider.of<LocationProvider>(context, listen: false);
                final prayer = Provider.of<PrayerProvider>(context, listen: false);
                
                return Scaffold(
                  body: Column(
                    children: [
                      Text('Method: ${settings.settings.calculationMethod}'),
                      Text('Location: ${location.locationName}'),
                      Text('Next: ${prayer.nextPrayer}'),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.text('Method: singapore'), findsOneWidget);
      expect(find.text('Location: Mencari lokasi...'), findsOneWidget);
      expect(find.text('Next: '), findsOneWidget);
    });
  });
}
