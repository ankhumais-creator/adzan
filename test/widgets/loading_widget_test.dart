import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adzan_monokrom/widgets/loading_widget.dart';

void main() {
  group('LoadingWidget', () {
    group('Basic Rendering', () {
      testWidgets('displays loading text', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LoadingWidget(),
            ),
          ),
        );
        
        // Pump a few frames to allow animations to start
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('MEMUAT...'), findsOneWidget);
      });

      testWidgets('contains circular progress indicator', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LoadingWidget(),
            ),
          ),
        );
        
        // Pump a few frames
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('is a Column widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LoadingWidget(),
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));

        // The LoadingWidget should contain a Column
        expect(find.byType(Column), findsWidgets);
      });
    });

    group('Styling', () {
      testWidgets('progress indicator has correct size', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LoadingWidget(),
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));

        // Find the SizedBox containing the CircularProgressIndicator
        final sizedBox = tester.widget<SizedBox>(
          find.ancestor(
            of: find.byType(CircularProgressIndicator),
            matching: find.byType(SizedBox),
          ).first,
        );

        expect(sizedBox.width, 40);
        expect(sizedBox.height, 40);
      });

      testWidgets('text styling uses uppercase', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LoadingWidget(),
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));

        // The text should be uppercase
        final textWidget = tester.widget<Text>(find.text('MEMUAT...'));
        expect(textWidget.data, 'MEMUAT...');
      });
    });

    group('Animation', () {
      testWidgets('widget renders after animation delay', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LoadingWidget(),
            ),
          ),
        );
        
        // Initially pump
        await tester.pump();
        
        // Advance through fade animation (600ms)
        await tester.pump(const Duration(milliseconds: 600));
        
        // Widget should be visible
        expect(find.byType(LoadingWidget), findsOneWidget);
      });

      testWidgets('widget can be placed in Center', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: LoadingWidget(),
              ),
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));
        
        expect(find.byType(Center), findsOneWidget);
        expect(find.byType(LoadingWidget), findsOneWidget);
      });
    });

    group('Layout', () {
      testWidgets('Column has center alignment', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LoadingWidget(),
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));

        // Find the main Column in LoadingWidget
        final columns = tester.widgetList<Column>(find.byType(Column));
        
        // At least one column should have center alignment
        final hasCenter = columns.any(
          (col) => col.mainAxisAlignment == MainAxisAlignment.center,
        );
        expect(hasCenter, true);
      });

      testWidgets('has SizedBox separator', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LoadingWidget(),
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));

        // Should have SizedBox for spacing
        expect(find.byType(SizedBox), findsWidgets);
      });
    });
  });
}
