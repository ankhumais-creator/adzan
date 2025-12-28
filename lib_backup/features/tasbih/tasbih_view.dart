import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tasbih (Digital counter) view for dzikr counting
class TasbihView extends StatelessWidget {
  final int count;
  final int target;
  final VoidCallback onTap;
  final VoidCallback onReset;

  const TasbihView({
    super.key,
    required this.count,
    required this.target,
    required this.onTap,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'DZIKIR',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              letterSpacing: 6,
              fontWeight: FontWeight.w300,
            ),
          ),

          const SizedBox(height: 48),

          // Counter
          Stack(
            alignment: Alignment.center,
            children: [
              // Progress Ring (cycles every 33)
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: (count % target) / target,
                  strokeWidth: 2,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),

              // Count Text
              Column(
                children: [
                  Text(
                    count.toString(),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.w100,
                    ),
                  ).animate(key: ValueKey(count))
                    .scaleXY(
                      begin: 1.2,
                      end: 1.0,
                      duration: 150.ms,
                      curve: Curves.easeOut,
                    ),
                  Text(
                    'Set ${(count / target).floor() + 1} • ${count % target == 0 && count > 0 ? target : count % target}/$target',
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 48),

          Text(
            'Tap di mana saja untuk menghitung',
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 24),

          // Reset Button
          TextButton(
            onPressed: onReset,
            child: Text(
              'RESET',
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 12,
                letterSpacing: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
