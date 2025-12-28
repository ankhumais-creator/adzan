# 🕌 Adzan Monokrom

Aplikasi jadwal waktu sholat dengan desain monokrom minimalis dan elegan.

![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

## ✨ Fitur Utama

### 🕌 Waktu Sholat
- Kalkulasi waktu sholat akurat untuk semua lokasi di dunia
- 7 waktu sholat: Imsak, Subuh, Terbit, Dzuhur, Ashar, Maghrib, Isya
- Countdown timer ke waktu sholat berikutnya
- Multiple metode perhitungan (MWL, ISNA, Singapore, Umm Al-Qura, dll)
- Dukungan Madhab Syafi'i dan Hanafi
- Tanggal Hijriah otomatis

### 📍 Lokasi
- **GPS Otomatis** - Deteksi lokasi otomatis
- **Lokasi Manual** - Cari kota di seluruh dunia dengan nama
- Reverse geocoding untuk menampilkan nama lokasi

### 🧭 Kompas Kiblat
- Arah kiblat akurat berdasarkan koordinat
- Tampilan kompas yang elegan dengan animasi

### 📿 Tasbih Digital
- Counter dengan target 33
- Set counter (terus menghitung: 1-33, 34-66, 67-99, dst)
- Vibrasi feedback
- Tombol reset

### 📖 Ayat Harian
- Kutipan ayat random dari Al-Quran
- Teks Arab dan terjemahan
- Tap untuk mendapatkan ayat baru

### 🔔 Notifikasi (Android)
- Notifikasi otomatis saat waktu sholat
- Background service untuk notifikasi akurat
- Suara adzan
- Vibrasi

### ⚙️ Pengaturan
- Metode perhitungan waktu sholat
- Madhab (Syafi'i/Hanafi)
- Suara adzan (on/off + volume)
- Vibrasi (on/off)
- Notifikasi (on/off)
- Lokasi manual/GPS

## 🎨 Desain

- Tema monokrom hitam putih
- Partikel animasi background
- Breathing effect gradient
- Font elegan (Inter untuk UI, Amiri untuk Arab)

## 🏗️ Arsitektur

Aplikasi ini menggunakan arsitektur modular dengan pattern **Provider** untuk state management:

```
lib/
├── main.dart                    # Entry point aplikasi
├── core/
│   └── services/                # Business logic services
│       ├── adzan_service.dart   # Audio adzan
│       ├── location_service.dart
│       ├── notification_service.dart
│       └── prayer_service.dart  # Kalkulasi waktu sholat
├── features/                    # Feature-based modules
│   ├── adzan/
│   │   └── adzan_player.dart
│   ├── compass/
│   │   └── compass_view.dart
│   ├── home/
│   │   └── clock_view.dart
│   ├── settings/
│   │   ├── settings_sheet.dart
│   │   └── settings_view.dart
│   └── tasbih/
│       └── tasbih_page.dart
├── models/
│   └── app_settings.dart        # Data models
├── providers/                   # State management
│   ├── location_provider.dart
│   ├── prayer_provider.dart
│   └── settings_provider.dart
└── widgets/                     # Reusable widgets
    ├── loading_widget.dart
    └── particle_background.dart
```

## 📋 Setup

### Prerequisites
- Flutter SDK 3.24+
- Android Studio (untuk Android)
- Xcode (untuk iOS)

### Instalasi

```bash
# Clone repository
cd adzan_monokrom

# Install dependencies
flutter pub get

# Run aplikasi
flutter run -d android
```

## 📦 Dependencies

| Package | Kegunaan |
|---------|----------|
| `provider` | State management |
| `adhan` | Kalkulasi waktu sholat |
| `hijri` | Konversi tanggal Hijriah |
| `geolocator` | GPS location |
| `geocoding` | Reverse geocoding |
| `flutter_animate` | Animasi UI |
| `google_fonts` | Font custom |
| `audioplayers` | Play audio adzan |
| `vibration` | Feedback haptic |
| `flutter_local_notifications` | Notifikasi |
| `flutter_background_service` | Background tasks |
| `flutter_compass` | Kompas kiblat |
| `shared_preferences` | Simpan settings |
| `http` | API requests |
| `intl` | Format tanggal |
| `timezone` | Timezone support |

## 🔑 Permissions (Android)

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>
```

## 🧪 Testing

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/
```

## 🚀 Build Release

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ipa --release
```

## 📝 Troubleshooting

### Lokasi tidak terdeteksi
- Aktifkan GPS di device
- Berikan izin lokasi ke aplikasi
- Gunakan lokasi manual jika tetap tidak bisa

### Notifikasi tidak muncul
- Pastikan izin notifikasi diaktifkan
- Pastikan toggle notifikasi di Settings aktif
- Untuk Android 13+, izinkan POST_NOTIFICATIONS

### Audio tidak keluar
- Pastikan file `adzan.webm` ada di `assets/audio/`
- Cek volume device tidak mute
- Toggle suara adzan di Settings

## 📄 License

MIT License

---

Made with ❤️ for the Ummah
