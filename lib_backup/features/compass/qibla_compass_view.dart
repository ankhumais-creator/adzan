import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

/// Qibla compass view showing direction to Ka'bah
class QiblaCompassView extends StatefulWidget {
  final Position? currentPosition;

  const QiblaCompassView({super.key, this.currentPosition});

  @override
  State<QiblaCompassView> createState() => _QiblaCompassViewState();
}

class _QiblaCompassViewState extends State<QiblaCompassView>
    with SingleTickerProviderStateMixin {
  double _qiblaDirection = 0;
  double _deviceHeading = 0;
  StreamSubscription<CompassEvent>? _compassSubscription;
  bool _hasCompassSupport = true;

  // Ka'bah coordinates
  static const double kaabaLat = 21.4225;
  static const double kaabaLng = 39.8262;

  @override
  void initState() {
    super.initState();
    _calculateQiblaDirection();
    _initCompass();
  }

  Future<void> _initCompass() async {
    // Check if compass is available
    final isSupported = FlutterCompass.events != null;
    if (!isSupported) {
      setState(() => _hasCompassSupport = false);
      return;
    }

    _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
      if (event.heading != null) {
        setState(() {
          _deviceHeading = event.heading!;
        });
      }
    });
  }

  void _calculateQiblaDirection() {
    if (widget.currentPosition == null) return;

    final lat1 = widget.currentPosition!.latitude * (math.pi / 180);
    final lng1 = widget.currentPosition!.longitude * (math.pi / 180);
    const lat2 = kaabaLat * (math.pi / 180);
    const lng2 = kaabaLng * (math.pi / 180);

    final dLng = lng2 - lng1;

    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    var bearing = math.atan2(y, x);
    bearing = bearing * (180 / math.pi);
    bearing = (bearing + 360) % 360;

    setState(() => _qiblaDirection = bearing);
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate qibla relative to device heading
    final qiblaRelative = (_qiblaDirection - _deviceHeading + 360) % 360;
    
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
        Text(
          'ARAH KIBLAT',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            letterSpacing: 6,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 32),

        if (!_hasCompassSupport)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Sensor kompas tidak tersedia di perangkat ini',
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else ...[
          // Compass Widget
          SizedBox(
            width: 250,
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Compass Circle - rotates with device heading
                Transform.rotate(
                  angle: -_deviceHeading * (math.pi / 180),
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    child: CustomPaint(
                      painter: CompassPainter(),
                    ),
                  ),
                ),

                // Qibla Arrow - points to Qibla relative to device
                Transform.rotate(
                  angle: qiblaRelative * (math.pi / 180),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white,
                              Colors.white.withAlpha(50),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Icon(
                        Icons.mosque,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),
                ),

                // Center dot
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Text(
            '${_qiblaDirection.toStringAsFixed(1)}°',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w200,
              letterSpacing: 4,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'dari arah utara',
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Heading: ${_deviceHeading.toStringAsFixed(0)}°',
            style: GoogleFonts.inter(
              color: Colors.white24,
              fontSize: 10,
            ),
          ),
        ],
      ],
        ),
      ),
    );
  }
}

/// CustomPainter for compass dial
class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    final paint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw tick marks
    for (int i = 0; i < 360; i += 15) {
      final angle = i * (math.pi / 180);
      final isCardinal = i % 90 == 0;
      final tickLength = isCardinal ? 15.0 : 8.0;

      final start = Offset(
        center.dx + (radius - tickLength) * math.sin(angle),
        center.dy - (radius - tickLength) * math.cos(angle),
      );
      final end = Offset(
        center.dx + radius * math.sin(angle),
        center.dy - radius * math.cos(angle),
      );

      canvas.drawLine(start, end, paint);
    }

    // Draw cardinal directions
    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    final directions = ['N', 'E', 'S', 'W'];
    for (int i = 0; i < 4; i++) {
      final angle = (i * 90) * (math.pi / 180);
      final textOffset = Offset(
        center.dx + (radius - 30) * math.sin(angle) - 6,
        center.dy - (radius - 30) * math.cos(angle) - 8,
      );

      textPainter.text = TextSpan(
        text: directions[i],
        style: GoogleFonts.inter(
          color: Colors.white54,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
