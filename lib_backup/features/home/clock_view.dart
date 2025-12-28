import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

/// Clock view showing countdown to next prayer time
class ClockView extends StatefulWidget {
  final String nextPrayer;
  final Duration countdown;

  const ClockView({
    super.key,
    required this.nextPrayer,
    required this.countdown,
  });

  @override
  State<ClockView> createState() => _ClockViewState();
}

class _ClockViewState extends State<ClockView> with SingleTickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _breathController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = widget.countdown.inHours;
    final minutes = widget.countdown.inMinutes.remainder(60);
    final seconds = widget.countdown.inSeconds.remainder(60);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Next Prayer Name with Glow
        Text(
          widget.nextPrayer.toUpperCase(),
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            letterSpacing: 8,
            fontWeight: FontWeight.w300,
          ),
        ).animate(onPlay: (controller) => controller.repeat())
          .shimmer(
            color: Colors.white54,
            duration: 2000.ms,
          ),

        const SizedBox(height: 24),

        // Countdown Timer with Breath Animation
        AnimatedBuilder(
          animation: _breathAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _breathAnimation.value,
              child: Opacity(
                opacity: 0.7 + (_breathAnimation.value - 0.95) * 3, // 0.7 to 1.0
                child: child,
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeUnit(hours.toString().padLeft(2, '0'), 'JAM'),
              _buildSeparator(),
              _buildTimeUnit(minutes.toString().padLeft(2, '0'), 'MENIT'),
              _buildSeparator(),
              _buildTimeUnit(seconds.toString().padLeft(2, '0'), 'DETIK'),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'menuju waktu sholat',
          style: GoogleFonts.inter(
            color: Colors.white38,
            fontSize: 12,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 64,
            fontWeight: FontWeight.w200,
            letterSpacing: 4,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white38,
            fontSize: 10,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        ':',
        style: GoogleFonts.inter(
          color: Colors.white24,
          fontSize: 48,
          fontWeight: FontWeight.w100,
        ),
      ).animate(onPlay: (controller) => controller.repeat())
        .fadeIn(duration: 500.ms)
        .then()
        .fadeOut(duration: 500.ms),
    );
  }
}
