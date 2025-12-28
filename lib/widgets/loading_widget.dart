import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable loading indicator widget
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 1,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white24),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'MEMUAT...',
          style: GoogleFonts.inter(
            color: Colors.white38,
            fontSize: 12,
            letterSpacing: 4,
          ),
        ),
      ],
    ).animate()
      .fadeIn(duration: 600.ms);
  }
}
