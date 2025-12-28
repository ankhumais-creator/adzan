import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Fungsi inisialisasi service harus berada di top-level
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // 1. Konfigurasi Notifikasi untuk Foreground Service (Ikon di status bar)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'adzan_channel', // ID
    'Adzan Service', // Nama
    description: 'Menjaga notifikasi adzan tetap aktif',
    importance: Importance.low, // Low agar tidak berbunyi terus menerus (hanya visual)
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // 2. Konfigurasi Service
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // onStart dijalankan saat service dimulai
      onStart: onStart,
      
      // Nama service di AndroidManifest
      autoStart: true,
      isForegroundMode: true,
      
      // Notifikasi yang akan muncul terus selama service aktif
      notificationChannelId: 'adzan_channel',
      initialNotificationTitle: 'Layanan Adzan Aktif',
      initialNotificationContent: 'Menunggu waktu sholat...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
  
  // Mulai service
  service.startService();
}

// Logika berjalan di Isolate terpisah (Background)
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Inisialisasi plugin notifikasi di dalam background isolate
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Jika service di Foreground
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  // Timer untuk mengecek waktu setiap detik/menit
  // Disini Anda harus masukkan logika pengecekan waktu sholat
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Contoh Loop sederhana
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    // --- LOGIKA PENGECEKAN WAKTU SHOLAT ANDA DI SINI ---
    // Misal: if (currentTime == adzanTime) { playAdzan(); }
    
    // Contoh: Jika waktu adzan tiba, jalankan kode berikut:
    // String namaSholat = "Dzuhur"; // Ganti dengan nama sholat yang sesuai
    // bool waktuAdzanTiba = false; // Ganti dengan logika pengecekan waktu Anda
    // 
    // if (waktuAdzanTiba) {
    //   const AndroidNotificationDetails adzanDetails = AndroidNotificationDetails(
    //     'adzan_sound_channel', // Channel ID berbeda khusus suara
    //     'Adzan Alarm',
    //     channelDescription: 'Memainkan suara adzan',
    //     importance: Importance.max,
    //     priority: Priority.high,
    //     playSound: true,
    //     sound: RawResourceAndroidNotificationSound('adzan'), // Nama file tanpa ekstensi
    //     fullScreenIntent: true, // Muncul di layar kunci (Fullscreen)
    //     ongoing: false, // Bisa dihapus setelah adzan selesai
    //   );
    //   
    //   await flutterLocalNotificationsPlugin.show(
    //     123, // Notification ID unik
    //     "ADZAN TELAH BERKUMANDANG",
    //     "Sudah waktunya sholat $namaSholat",
    //     const NotificationDetails(android: adzanDetails),
    //   );
    // }
    
    // Update notifikasi foreground agar user tahu aplikasi masih hidup
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        flutterLocalNotificationsPlugin.show(
          888,
          'Adzan Service',
          'Aktif menunggu waktu sholat...',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'adzan_channel',
              'Adzan Service',
              icon: '@mipmap/ic_launcher',
              ongoing: true, // Tidak bisa dihapus user
            ),
          ),
        );
      }
    }
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}
