import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/battery_optimization_helper.dart';
import '../../core/services/native_alarm_service.dart';

/// Settings page section for configuring reliable notifications.
/// Includes battery optimization and exact alarm permission guidance.
class NotificationSettingsSection extends StatefulWidget {
  const NotificationSettingsSection({super.key});

  @override
  State<NotificationSettingsSection> createState() => _NotificationSettingsSectionState();
}

class _NotificationSettingsSectionState extends State<NotificationSettingsSection> {
  bool _isIgnoringBatteryOptimization = false;
  bool _canScheduleExactAlarms = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final ignoring = await BatteryOptimizationHelper.isIgnoringBatteryOptimizations();
    final canSchedule = await NativeAlarmService.canScheduleExactAlarms();
    
    if (mounted) {
      setState(() {
        _isIgnoringBatteryOptimization = ignoring;
        _canScheduleExactAlarms = canSchedule;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }
    
    final needsAttention = !_isIgnoringBatteryOptimization || !_canScheduleExactAlarms;
    
    if (!needsAttention) {
      return _buildAllGoodCard();
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade300,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pengaturan Notifikasi',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Untuk memastikan notifikasi waktu sholat berjalan tepat waktu, mohon aktifkan pengaturan berikut:',
            style: GoogleFonts.inter(
              color: Colors.white60,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          
          // Battery Optimization
          if (!_isIgnoringBatteryOptimization)
            _buildPermissionCard(
              icon: Icons.battery_saver,
              title: 'Penghemat Baterai',
              description: 'Izinkan aplikasi berjalan di latar belakang',
              status: 'Belum Diizinkan',
              statusColor: Colors.red.shade300,
              onTap: () async {
                await BatteryOptimizationHelper.requestIgnoreBatteryOptimization();
                await Future.delayed(const Duration(seconds: 1));
                _checkPermissions();
              },
            ),
          
          // Exact Alarm Permission
          if (!_canScheduleExactAlarms)
            _buildPermissionCard(
              icon: Icons.alarm,
              title: 'Alarm Tepat Waktu',
              description: 'Izinkan alarm untuk waktu yang tepat',
              status: 'Belum Diizinkan',
              statusColor: Colors.red.shade300,
              onTap: () async {
                await NativeAlarmService.openExactAlarmSettings();
                await Future.delayed(const Duration(seconds: 1));
                _checkPermissions();
              },
            ),
          
          const SizedBox(height: 12),
          
          // Show detailed instructions
          GestureDetector(
            onTap: _showDetailedInstructions,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.help_outline,
                  color: Colors.white38,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Lihat petunjuk lengkap',
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 400.ms)
      .slideY(begin: -0.1);
  }

  Widget _buildAllGoodCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withAlpha(100)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green.shade300,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Notifikasi sudah dikonfigurasi dengan optimal',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 400.ms);
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required String status,
    required Color statusColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white54, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(50),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: GoogleFonts.inter(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailedInstructions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Petunjuk Pengaturan',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                BatteryOptimizationHelper.getManufacturerInstructions(),
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await BatteryOptimizationHelper.openAppSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white12,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Buka Pengaturan Aplikasi',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
