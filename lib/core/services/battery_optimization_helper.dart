import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Helper for managing battery optimization settings.
/// Guides users to disable battery optimization for reliable notifications.
class BatteryOptimizationHelper {
  static const _batteryChannel = MethodChannel('com.adzan_monokrom/battery');
  
  /// Check if app is ignoring battery optimizations
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (kIsWeb) return true;
    
    try {
      final result = await _batteryChannel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return result ?? false;
    } catch (e) {
      debugPrint('BatteryOptimizationHelper: Error checking status - $e');
      return false;
    }
  }
  
  /// Request to ignore battery optimization (shows system dialog)
  static Future<bool> requestIgnoreBatteryOptimization() async {
    if (kIsWeb) return true;
    
    try {
      final result = await _batteryChannel.invokeMethod<bool>('requestIgnoreBatteryOptimization');
      return result ?? false;
    } catch (e) {
      debugPrint('BatteryOptimizationHelper: Error requesting - $e');
      return false;
    }
  }
  
  /// Open battery settings screen
  static Future<void> openBatterySettings() async {
    if (kIsWeb) return;
    
    try {
      await _batteryChannel.invokeMethod('openBatterySettings');
    } catch (e) {
      debugPrint('BatteryOptimizationHelper: Error opening settings - $e');
    }
  }
  
  /// Open app settings
  static Future<void> openAppSettings() async {
    if (kIsWeb) return;
    
    try {
      await _batteryChannel.invokeMethod('openAppSettings');
    } catch (e) {
      debugPrint('BatteryOptimizationHelper: Error opening app settings - $e');
    }
  }
  
  /// Get manufacturer-specific instructions for battery optimization
  static String getManufacturerInstructions() {
    // Common OEM-specific instructions
    return '''
📱 Petunjuk Khusus Merek HP:

🔴 Xiaomi/Redmi:
• Buka Pengaturan > Aplikasi > Kelola Aplikasi
• Cari "Adzan Monokrom"
• Izinkan "Autostart"
• Penghemat Baterai > Tanpa Batasan

🟠 OPPO/Realme:
• Pengaturan > Manajemen Aplikasi
• Cari aplikasi > Izin > Latar Belakang
• Izinkan "Mulai Otomatis"

🟢 Samsung:
• Pengaturan > Aplikasi > Adzan Monokrom
• Baterai > Tidak Terbatas

🔵 Vivo:
• i Manager > Manajer Aplikasi
• Izin Autostart > Aktifkan

⚪ Huawei:
• Pengaturan > Baterai > Peluncuran Aplikasi
• Matikan "Kelola Otomatis" > Aktifkan semua toggle
''';
  }
}
