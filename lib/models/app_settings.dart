import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Application settings model with persistence
class AppSettings {
  String calculationMethod;
  String madhab;
  bool adzanSoundEnabled;
  bool vibrationEnabled;
  bool notificationEnabled;
  int adzanVolume;
  // Manual Location
  bool useManualLocation;
  double manualLatitude;
  double manualLongitude;
  String manualLocationName;

  AppSettings({
    this.calculationMethod = 'singapore',
    this.madhab = 'shafi',
    this.adzanSoundEnabled = true,
    this.vibrationEnabled = true,
    this.notificationEnabled = true,
    this.adzanVolume = 100,
    this.useManualLocation = false,
    this.manualLatitude = -6.2088,
    this.manualLongitude = 106.8456,
    this.manualLocationName = 'Jakarta, Indonesia',
  });

  static const List<Map<String, String>> calculationMethods = [
    {'id': 'muslim_world_league', 'name': 'Muslim World League'},
    {'id': 'egyptian', 'name': 'Egyptian General Authority'},
    {'id': 'karachi', 'name': 'University of Islamic Sciences, Karachi'},
    {'id': 'umm_al_qura', 'name': 'Umm Al-Qura University, Makkah'},
    {'id': 'dubai', 'name': 'Dubai'},
    {'id': 'qatar', 'name': 'Qatar'},
    {'id': 'kuwait', 'name': 'Kuwait'},
    {'id': 'singapore', 'name': 'Singapore / Indonesia / Malaysia'},
    {'id': 'turkey', 'name': 'Turkey'},
    {'id': 'tehran', 'name': 'Tehran'},
    {'id': 'north_america', 'name': 'ISNA (North America)'},
  ];

  static const List<Map<String, String>> madhabs = [
    {'id': 'shafi', 'name': 'Syafi\'i'},
    {'id': 'hanafi', 'name': 'Hanafi'},
  ];

  // Popular cities with coordinates
  static const List<Map<String, dynamic>> popularCities = [
    {'name': 'Jakarta', 'lat': -6.2088, 'lng': 106.8456, 'country': 'Indonesia'},
    {'name': 'Surabaya', 'lat': -7.2575, 'lng': 112.7521, 'country': 'Indonesia'},
    {'name': 'Bandung', 'lat': -6.9175, 'lng': 107.6191, 'country': 'Indonesia'},
    {'name': 'Medan', 'lat': 3.5952, 'lng': 98.6722, 'country': 'Indonesia'},
    {'name': 'Semarang', 'lat': -6.9666, 'lng': 110.4196, 'country': 'Indonesia'},
    {'name': 'Makassar', 'lat': -5.1477, 'lng': 119.4327, 'country': 'Indonesia'},
    {'name': 'Palembang', 'lat': -2.9761, 'lng': 104.7754, 'country': 'Indonesia'},
    {'name': 'Yogyakarta', 'lat': -7.7956, 'lng': 110.3695, 'country': 'Indonesia'},
    {'name': 'Denpasar', 'lat': -8.6705, 'lng': 115.2126, 'country': 'Indonesia'},
    {'name': 'Balikpapan', 'lat': -1.2654, 'lng': 116.8311, 'country': 'Indonesia'},
    {'name': 'Makkah', 'lat': 21.4225, 'lng': 39.8262, 'country': 'Saudi Arabia'},
    {'name': 'Madinah', 'lat': 24.5247, 'lng': 39.5692, 'country': 'Saudi Arabia'},
  ];

  CalculationParameters getCalculationParams() {
    CalculationParameters params;
    switch (calculationMethod) {
      case 'muslim_world_league':
        params = CalculationMethod.muslim_world_league.getParameters();
        break;
      case 'egyptian':
        params = CalculationMethod.egyptian.getParameters();
        break;
      case 'karachi':
        params = CalculationMethod.karachi.getParameters();
        break;
      case 'umm_al_qura':
        params = CalculationMethod.umm_al_qura.getParameters();
        break;
      case 'dubai':
        params = CalculationMethod.dubai.getParameters();
        break;
      case 'qatar':
        params = CalculationMethod.qatar.getParameters();
        break;
      case 'kuwait':
        params = CalculationMethod.kuwait.getParameters();
        break;
      case 'turkey':
        params = CalculationMethod.turkey.getParameters();
        break;
      case 'tehran':
        params = CalculationMethod.tehran.getParameters();
        break;
      case 'north_america':
        params = CalculationMethod.north_america.getParameters();
        break;
      case 'singapore':
      default:
        params = CalculationMethod.singapore.getParameters();
    }
    params.madhab = madhab == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
    return params;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('calculationMethod', calculationMethod);
    await prefs.setString('madhab', madhab);
    await prefs.setBool('adzanSoundEnabled', adzanSoundEnabled);
    await prefs.setBool('vibrationEnabled', vibrationEnabled);
    await prefs.setBool('notificationEnabled', notificationEnabled);
    await prefs.setInt('adzanVolume', adzanVolume);
    await prefs.setBool('useManualLocation', useManualLocation);
    await prefs.setDouble('manualLatitude', manualLatitude);
    await prefs.setDouble('manualLongitude', manualLongitude);
    await prefs.setString('manualLocationName', manualLocationName);
  }

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      calculationMethod: prefs.getString('calculationMethod') ?? 'singapore',
      madhab: prefs.getString('madhab') ?? 'shafi',
      adzanSoundEnabled: prefs.getBool('adzanSoundEnabled') ?? true,
      vibrationEnabled: prefs.getBool('vibrationEnabled') ?? true,
      notificationEnabled: prefs.getBool('notificationEnabled') ?? true,
      adzanVolume: prefs.getInt('adzanVolume') ?? 100,
      useManualLocation: prefs.getBool('useManualLocation') ?? false,
      manualLatitude: prefs.getDouble('manualLatitude') ?? -6.2088,
      manualLongitude: prefs.getDouble('manualLongitude') ?? 106.8456,
      manualLocationName: prefs.getString('manualLocationName') ?? 'Jakarta, Indonesia',
    );
  }

  /// Creates a copy with the same values
  AppSettings copyWith({
    String? calculationMethod,
    String? madhab,
    bool? adzanSoundEnabled,
    bool? vibrationEnabled,
    bool? notificationEnabled,
    int? adzanVolume,
    bool? useManualLocation,
    double? manualLatitude,
    double? manualLongitude,
    String? manualLocationName,
  }) {
    return AppSettings(
      calculationMethod: calculationMethod ?? this.calculationMethod,
      madhab: madhab ?? this.madhab,
      adzanSoundEnabled: adzanSoundEnabled ?? this.adzanSoundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      adzanVolume: adzanVolume ?? this.adzanVolume,
      useManualLocation: useManualLocation ?? this.useManualLocation,
      manualLatitude: manualLatitude ?? this.manualLatitude,
      manualLongitude: manualLongitude ?? this.manualLongitude,
      manualLocationName: manualLocationName ?? this.manualLocationName,
    );
  }
}
