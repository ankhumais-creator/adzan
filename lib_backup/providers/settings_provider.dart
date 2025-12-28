import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';

/// Provider for managing application settings state
class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = AppSettings();
  bool _isLoading = true;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  /// Load settings from SharedPreferences
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _settings = await AppSettings.load();
      
      // On web, default to manual location if not set
      if (kIsWeb && !_settings.useManualLocation) {
        _settings.useManualLocation = true;
        await _settings.save();
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      _settings = AppSettings();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Update settings and save to SharedPreferences
  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await _settings.save();
    notifyListeners();
  }

  /// Update calculation method
  void setCalculationMethod(String method) {
    _settings.calculationMethod = method;
    _settings.save();
    notifyListeners();
  }

  /// Update madhab
  void setMadhab(String madhab) {
    _settings.madhab = madhab;
    _settings.save();
    notifyListeners();
  }

  /// Toggle adzan sound
  void setAdzanSoundEnabled(bool enabled) {
    _settings.adzanSoundEnabled = enabled;
    _settings.save();
    notifyListeners();
  }

  /// Set adzan volume
  void setAdzanVolume(int volume) {
    _settings.adzanVolume = volume;
    _settings.save();
    notifyListeners();
  }

  /// Toggle vibration
  void setVibrationEnabled(bool enabled) {
    _settings.vibrationEnabled = enabled;
    _settings.save();
    notifyListeners();
  }

  /// Toggle notification
  void setNotificationEnabled(bool enabled) {
    _settings.notificationEnabled = enabled;
    _settings.save();
    notifyListeners();
  }

  /// Toggle manual location
  void setUseManualLocation(bool useManual) {
    _settings.useManualLocation = useManual;
    _settings.save();
    notifyListeners();
  }

  /// Update manual location
  void setManualLocation({
    required double latitude,
    required double longitude,
    required String locationName,
  }) {
    _settings.manualLatitude = latitude;
    _settings.manualLongitude = longitude;
    _settings.manualLocationName = locationName;
    _settings.save();
    notifyListeners();
  }
}
