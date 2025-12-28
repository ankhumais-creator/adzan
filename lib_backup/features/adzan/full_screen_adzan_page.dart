import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../widgets/particle_background.dart';

/// Full-screen adzan page that appears when prayer time arrives.
/// Shows a beautiful animation with prayer name and provides dismiss button.
class FullScreenAdzanPage extends StatefulWidget {
  final String prayerName;
  final String prayerTime;
  final VoidCallback? onDismiss;

  const FullScreenAdzanPage({
    super.key,
    required this.prayerName,
    this.prayerTime = '',
    this.onDismiss,
  });

  @override
  State<FullScreenAdzanPage> createState() => _FullScreenAdzanPageState();
}

class _FullScreenAdzanPageState extends State<FullScreenAdzanPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Auto-dismiss after 5 minutes
    _autoDismissTimer = Timer(const Duration(minutes: 5), _dismiss);
    
    // Play adzan sound
    _playAdzanSound();
  }

  Future<void> _playAdzanSound() async {
    try {
      setState(() => _isPlaying = true);
      await _audioPlayer.play(AssetSource('audio/adzan.webm'));
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() => _isPlaying = false);
        }
      });
    } catch (e) {
      debugPrint('Error playing adzan: $e');
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _stopAdzanSound() async {
    try {
      await _audioPlayer.stop();
      setState(() => _isPlaying = false);
    } catch (e) {
      debugPrint('Error stopping adzan: $e');
    }
  }

  void _dismiss() {
    _stopAdzanSound();
    _autoDismissTimer?.cancel();
    widget.onDismiss?.call();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioPlayer.dispose();
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background
          const Positioned.fill(
            child: ParticleBackground(),
          ),
          
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(200),
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Decorative crescent moon
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withAlpha(50),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.nightlight_round,
                            size: 80,
                            color: Colors.white.withAlpha(230),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // "Waktu Sholat" label
                  Text(
                    'WAKTU SHOLAT',
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 14,
                      letterSpacing: 6,
                      fontWeight: FontWeight.w300,
                    ),
                  ).animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.2),
                  
                  const SizedBox(height: 16),
                  
                  // Prayer name
                  Text(
                    widget.prayerName.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 12,
                    ),
                  ).animate()
                    .fadeIn(duration: 800.ms, delay: 200.ms)
                    .scaleXY(begin: 0.8, end: 1),
                  
                  if (widget.prayerTime.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.prayerTime,
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 32,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 4,
                      ),
                    ).animate()
                      .fadeIn(duration: 600.ms, delay: 400.ms),
                  ],
                  
                  const SizedBox(height: 60),
                  
                  // Playing indicator
                  if (_isPlaying)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.graphic_eq,
                          color: Colors.white38,
                          size: 20,
                        ).animate(onPlay: (c) => c.repeat())
                          .scaleXY(begin: 0.8, end: 1.2, duration: 500.ms)
                          .then()
                          .scaleXY(begin: 1.2, end: 0.8, duration: 500.ms),
                        const SizedBox(width: 12),
                        Text(
                          'Adzan sedang diputar...',
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 14,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ).animate()
                      .fadeIn(duration: 400.ms, delay: 600.ms),
                  
                  const SizedBox(height: 80),
                  
                  // Dismiss button
                  GestureDetector(
                    onTap: _dismiss,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white24,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'TUTUP',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 14,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ).animate()
                    .fadeIn(duration: 600.ms, delay: 800.ms)
                    .slideY(begin: 0.3),
                  
                  const SizedBox(height: 16),
                  
                  // Stop sound button
                  if (_isPlaying)
                    TextButton.icon(
                      onPressed: _stopAdzanSound,
                      icon: const Icon(
                        Icons.stop_circle_outlined,
                        color: Colors.white38,
                        size: 20,
                      ),
                      label: Text(
                        'Hentikan Adzan',
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ).animate()
                      .fadeIn(duration: 400.ms, delay: 1000.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
