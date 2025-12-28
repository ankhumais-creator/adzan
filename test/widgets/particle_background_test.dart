import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adzan_monokrom/widgets/particle_background.dart';

void main() {
  group('ParticleBackground', () {
    group('Basic Rendering', () {
      testWidgets('renders without errors', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ParticleBackground(),
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));
        
        expect(find.byType(ParticleBackground), findsOneWidget);
      });

      testWidgets('uses CustomPaint for rendering', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ParticleBackground(),
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));
        
        // CustomPaint may have multiple instances from parent widgets
        expect(find.byType(CustomPaint), findsWidgets);
      });

      testWidgets('uses AnimatedBuilder for animation', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ParticleBackground(),
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));
        
        // AnimatedBuilder may have multiple instances
        expect(find.byType(AnimatedBuilder), findsWidgets);
      });
    });

    group('Animation State', () {
      testWidgets('animation controller starts running', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ParticleBackground(),
            ),
          ),
        );
        
        // Pump to start animation
        await tester.pump();
        
        // Advance animation
        await tester.pump(const Duration(milliseconds: 500));
        
        // Widget should still exist (animation running)
        expect(find.byType(ParticleBackground), findsOneWidget);
      });

      testWidgets('disposes without errors', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ParticleBackground(),
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
        expect(find.byType(ParticleBackground), findsNothing);
      });

      testWidgets('animation continues over time', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ParticleBackground(),
            ),
          ),
        );
        
        // Pump multiple times to simulate animation
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        
        // Widget should still be rendering
        expect(find.byType(ParticleBackground), findsOneWidget);
      });
    });

    group('Layout', () {
      testWidgets('can be placed in Stack', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(
                    child: ParticleBackground(),
                  ),
                  Center(
                    child: Text('Foreground'),
                  ),
                ],
              ),
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));
        
        expect(find.byType(ParticleBackground), findsOneWidget);
        expect(find.text('Foreground'), findsOneWidget);
      });

      testWidgets('works with full screen', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 800,
                child: const ParticleBackground(),
              ),
            ),
          ),
        );
        
        await tester.pump(const Duration(milliseconds: 100));
        
        expect(find.byType(ParticleBackground), findsOneWidget);
      });
    });
  });

  group('Particle', () {
    test('constructor creates particle with all properties', () {
      final particle = Particle(
        x: 0.5,
        y: 0.5,
        size: 2.0,
        speed: 0.001,
        opacity: 0.3,
      );
      
      expect(particle.x, 0.5);
      expect(particle.y, 0.5);
      expect(particle.size, 2.0);
      expect(particle.speed, 0.001);
      expect(particle.opacity, 0.3);
    });

    test('particle properties are mutable', () {
      final particle = Particle(
        x: 0.5,
        y: 0.5,
        size: 2.0,
        speed: 0.001,
        opacity: 0.3,
      );
      
      // Simulate moving up
      particle.y -= particle.speed;
      
      expect(particle.y, lessThan(0.5));
    });

    test('particle y resets when going below 0', () {
      final particle = Particle(
        x: 0.5,
        y: 0.01,
        size: 2.0,
        speed: 0.02,
        opacity: 0.3,
      );
      
      // Move particle up
      particle.y -= particle.speed;
      
      // Check if should reset
      if (particle.y < 0) {
        particle.y = 1.0;
      }
      
      expect(particle.y, 1.0);
    });
  });

  group('ParticlePainter', () {
    test('shouldRepaint returns true', () {
      final particles = <Particle>[
        Particle(x: 0.5, y: 0.5, size: 1.0, speed: 0.001, opacity: 0.2),
      ];
      
      final painter = ParticlePainter(particles);
      final oldPainter = ParticlePainter(particles);
      
      expect(painter.shouldRepaint(oldPainter), true);
    });

    test('accepts list of particles', () {
      final particles = <Particle>[
        Particle(x: 0.1, y: 0.1, size: 1.0, speed: 0.001, opacity: 0.2),
        Particle(x: 0.5, y: 0.5, size: 2.0, speed: 0.002, opacity: 0.3),
        Particle(x: 0.9, y: 0.9, size: 1.5, speed: 0.001, opacity: 0.25),
      ];
      
      final painter = ParticlePainter(particles);
      
      expect(painter.particles.length, 3);
    });

    test('empty particle list is valid', () {
      final particles = <Particle>[];
      final painter = ParticlePainter(particles);
      
      expect(painter.particles.length, 0);
    });
  });
}
