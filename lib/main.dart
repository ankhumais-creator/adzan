import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Core services (Native Kotlin only)
import 'core/services/native_adzan_service.dart';

// Models
import 'models/app_settings.dart';

// Providers
import 'providers/settings_provider.dart';
import 'providers/location_provider.dart';
import 'providers/prayer_provider.dart';

// Widgets
import 'widgets/particle_background.dart';
import 'widgets/loading_widget.dart';

// Features
import 'features/home/clock_view.dart';
import 'features/compass/qibla_compass_view.dart';
import 'features/tasbih/tasbih_view.dart';
import 'features/settings/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Native Kotlin Adzan Service akan dipanggil dari PrayerProvider
  // saat menghitung waktu sholat berikutnya (no initialization needed)
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const AdzanMonokromApp());
}

class AdzanMonokromApp extends StatelessWidget {
  const AdzanMonokromApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => PrayerProvider()),
      ],
      child: MaterialApp(
        title: 'Adzan Monokrom',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF000000),
          textTheme: GoogleFonts.interTextTheme(
            ThemeData.dark().textTheme,
          ),
        ),
        home: const HomePage(),
      ),
    );
  }
}

// ==================== HOME PAGE ====================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // View Mode: 0 = Clock, 1 = Compass, 2 = Tasbih
  int _viewMode = 0;

  // Loading & Error States
  bool _isLoading = true;
  String? _errorMessage;

  // Animation Controllers
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    _initBreathingAnimation();
    _initializeApp();
  }

  void _initBreathingAnimation() {
    _breathingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeApp() async {
    final settingsProvider = context.read<SettingsProvider>();
    final locationProvider = context.read<LocationProvider>();
    final prayerProvider = context.read<PrayerProvider>();

    try {
      // Load settings
      await settingsProvider.loadSettings();
      final settings = settingsProvider.settings;
      
      // Request permissions and get location
      await locationProvider.requestPermissions();
      
      if (settings.useManualLocation) {
        locationProvider.setManualLocation(
          latitude: settings.manualLatitude,
          longitude: settings.manualLongitude,
          locationName: settings.manualLocationName,
        );
      } else {
        await locationProvider.getCurrentLocation();
        
        // If location failed, fallback to manual
        if (locationProvider.errorMessage != null) {
          locationProvider.setManualLocation(
            latitude: settings.manualLatitude,
            longitude: settings.manualLongitude,
            locationName: settings.manualLocationName,
          );
        }
      }

      // Calculate prayer times
      if (locationProvider.currentPosition != null) {
        prayerProvider.calculatePrayerTimes(
          latitude: locationProvider.currentPosition!.latitude,
          longitude: locationProvider.currentPosition!.longitude,
          settings: settings,
        );
        
        // Start timers
        prayerProvider.startCountdownTimer(
          latitude: locationProvider.currentPosition!.latitude,
          longitude: locationProvider.currentPosition!.longitude,
          settings: settings,
        );
        prayerProvider.startPrayerCheckTimer(settings);
      }

      // Fetch daily verse
      await prayerProvider.fetchDailyVerse();

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Init error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _openSettings() async {
    final settingsProvider = context.read<SettingsProvider>();
    final locationProvider = context.read<LocationProvider>();
    final prayerProvider = context.read<PrayerProvider>();
    
    final result = await Navigator.push<AppSettings>(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsPage(settings: settingsProvider.settings),
      ),
    );
    
    if (result != null) {
      await settingsProvider.updateSettings(result);
      
      // If manual location changed, update location and recalculate
      if (result.useManualLocation) {
        locationProvider.setManualLocation(
          latitude: result.manualLatitude,
          longitude: result.manualLongitude,
          locationName: result.manualLocationName,
        );
      }
      
      // Recalculate prayer times with new settings
      if (locationProvider.currentPosition != null) {
        prayerProvider.calculatePrayerTimes(
          latitude: locationProvider.currentPosition!.latitude,
          longitude: locationProvider.currentPosition!.longitude,
          settings: result,
        );
      }
    }
  }

  void _refreshLocation() async {
    final settingsProvider = context.read<SettingsProvider>();
    final locationProvider = context.read<LocationProvider>();
    final prayerProvider = context.read<PrayerProvider>();
    
    setState(() => _isLoading = true);
    
    try {
      if (settingsProvider.settings.useManualLocation) {
        locationProvider.setManualLocation(
          latitude: settingsProvider.settings.manualLatitude,
          longitude: settingsProvider.settings.manualLongitude,
          locationName: settingsProvider.settings.manualLocationName,
        );
      } else {
        await locationProvider.getCurrentLocation();
      }
      
      if (locationProvider.currentPosition != null) {
        prayerProvider.calculatePrayerTimes(
          latitude: locationProvider.currentPosition!.latitude,
          longitude: locationProvider.currentPosition!.longitude,
          settings: settingsProvider.settings,
        );
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Layer 0: Black Background
          Container(color: const Color(0xFF000000)),

          // Layer 1: Floating Particles
          const ParticleBackground(),

          // Layer 2: Breathing Gradient
          AnimatedBuilder(
            animation: _breathingAnimation,
            builder: (context, child) {
              return Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withAlpha((25 * _breathingAnimation.value).round()),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Main Content
          SafeArea(
            child: _isLoading
                ? const Center(child: LoadingWidget())
                : _errorMessage != null
                    ? _buildErrorView()
                    : _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.white38),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _initializeApp();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white12,
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Consumer3<SettingsProvider, LocationProvider, PrayerProvider>(
      builder: (context, settingsProvider, locationProvider, prayerProvider, _) {
        return Column(
          children: [
            // Header
            _buildHeader(locationProvider, prayerProvider),

            // Main View - use IndexedStack for proper view isolation (no ghosting)
            Expanded(
              child: ClipRect(
                child: IndexedStack(
                  index: _viewMode,
                  sizing: StackFit.expand,
                  children: [
                    // View 0: Clock with Daily Verse
                    Column(
                      children: [
                        Expanded(
                          child: ClockView(
                            key: const ValueKey('clock'),
                            nextPrayer: prayerProvider.nextPrayer,
                            countdown: prayerProvider.countdown,
                          ),
                        ),
                        // Daily Verse Widget inside clock view
                        _buildDailyVerseWidget(prayerProvider),
                      ],
                    ),
                    // View 1: Compass
                    QiblaCompassView(
                      key: const ValueKey('compass'),
                      currentPosition: locationProvider.currentPosition,
                    ),
                    // View 2: Tasbih
                    TasbihView(
                      key: const ValueKey('tasbih'),
                      count: prayerProvider.tasbihCount,
                      target: prayerProvider.tasbihTarget,
                      onTap: () => prayerProvider.incrementTasbih(settingsProvider.settings),
                      onReset: prayerProvider.resetTasbih,
                    ),
                  ],
                ),
              ),
            ),

            // Prayer Times Footer
            _buildPrayerTimesFooter(prayerProvider),
          ],
        );
      },
    );
  }

  Widget _buildHeader(LocationProvider locationProvider, PrayerProvider prayerProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Location & Date
          Expanded(
            child: GestureDetector(
              onTap: _refreshLocation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.white54),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          locationProvider.locationName,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.refresh, size: 12, color: Colors.white38),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    prayerProvider.hijriDate,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // View Mode Buttons & Settings
          Row(
            children: [
              _buildModeButton(0, Icons.access_time_rounded),
              _buildModeButton(1, Icons.explore_rounded),
              _buildModeButton(2, Icons.radio_button_unchecked),
              const SizedBox(width: 8),
              // Settings Button
              GestureDetector(
                onTap: _openSettings,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    size: 22,
                    color: Colors.white54,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(int mode, IconData icon) {
    final isActive = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white12 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.white24 : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          size: 22,
          color: isActive ? Colors.white : Colors.white38,
        ),
      ),
    ).animate(target: isActive ? 1 : 0)
      .scaleXY(begin: 1.0, end: 1.1, duration: 200.ms);
  }

  Widget _buildDailyVerseWidget(PrayerProvider prayerProvider) {
    if (prayerProvider.dailyVerse.isEmpty) return const SizedBox();

    return GestureDetector(
      onTap: prayerProvider.fetchDailyVerse,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Text(
              prayerProvider.dailyVerse,
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                color: Colors.white,
                fontSize: 20,
                height: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              prayerProvider.dailyVerseTranslation,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  prayerProvider.dailyVerseSource,
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.refresh_rounded,
                  size: 14,
                  color: Colors.white24,
                ),
              ],
            ),
          ],
        ),
      ).animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.1, end: 0, duration: 600.ms),
    );
  }

  Widget _buildPrayerTimesFooter(PrayerProvider prayerProvider) {
    if (prayerProvider.prayerTimes == null) return const SizedBox();

    final prayers = [
      {'name': 'Imsak', 'time': prayerProvider.prayerTimes!.fajr.subtract(const Duration(minutes: 10))},
      {'name': 'Subuh', 'time': prayerProvider.prayerTimes!.fajr},
      {'name': 'Terbit', 'time': prayerProvider.prayerTimes!.sunrise},
      {'name': 'Dzuhur', 'time': prayerProvider.prayerTimes!.dhuhr},
      {'name': 'Ashar', 'time': prayerProvider.prayerTimes!.asr},
      {'name': 'Maghrib', 'time': prayerProvider.prayerTimes!.maghrib},
      {'name': 'Isya', 'time': prayerProvider.prayerTimes!.isha},
    ];

    // Calculate total width needed
    const itemWidth = 75.0;
    const itemMargin = 8.0;
    final totalWidth = prayers.length * (itemWidth + itemMargin);

    return Container(
      height: 90,
      margin: const EdgeInsets.only(bottom: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shouldCenter = totalWidth <= constraints.maxWidth;
          
          if (shouldCenter) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: prayers.map((prayer) {
                return _buildPrayerTimeItem(prayer, prayerProvider.nextPrayer);
              }).toList(),
            );
          } else {
            // Scrollable with fade indicator on right edge
            return ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.white, Colors.white, Colors.white, Colors.transparent],
                  stops: [0.0, 0.1, 0.9, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: prayers.length,
                itemBuilder: (context, index) {
                  return _buildPrayerTimeItem(prayers[index], prayerProvider.nextPrayer);
                },
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildPrayerTimeItem(Map<String, dynamic> prayer, String nextPrayer) {
    final isActive = prayer['name'] == nextPrayer;
    final time = prayer['time'] as DateTime;

    return Container(
      width: 75,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withAlpha(25) : Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.white24 : Colors.transparent,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            prayer['name'] as String,
            style: GoogleFonts.inter(
              color: isActive ? Colors.white : Colors.white54,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('HH:mm').format(time),
            style: GoogleFonts.inter(
              color: isActive ? Colors.white : Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate(target: isActive ? 1 : 0)
      .scaleXY(begin: 1.0, end: 1.05, duration: 300.ms);
  }
}
