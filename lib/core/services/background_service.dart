import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ID Notifikasi Wajib Konsisten
const int ONGOING_NOTIFICATION_ID = 888;
const String NOTIFICATION_CHANNEL_ID = 'adzan_timer_live_channel';

// Top-level Function untuk inisialisasi service
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // 1. Create notification channel (Importance.low seperti syarat)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    NOTIFICATION_CHANNEL_ID,
    'Adzan Live Timer',
    description: 'Menampilkan hitung mundur menuju waktu sholat',
    importance: Importance.high, // Diubah ke HIGH agar Sticky
  );

  // Inisialisasi plugin notifikasi SEKADAR untuk create channel di awal
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // 2. Configure service dengan channel ID yang SAMA
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: NOTIFICATION_CHANNEL_ID,
      initialNotificationTitle: 'Adzan Timer',
      initialNotificationContent: 'Menunggu waktu sholat...',
      foregroundServiceNotificationId: ONGOING_NOTIFICATION_ID, // Syarat: ID 888
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

// Entry Point Isolate (Harus di Top-Level)
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Syarat 1: Init FlutterLocalNotificationsPlugin DI DALAM onStart
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Init SharedPreferences untuk akses data target waktu
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // Setup Initialization untuk notifikasi (Wajib agar ikon muncul)
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  // Initialize plugin di dalam isolate
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Helper listener untuk menerima data dari Main Isolate (jika perlu update target waktu)
  service.on('setTargetTime').listen((event) {
    final String newTimeStr = event?['time'] as String;
    prefs.setString('target_prayer_time', newTimeStr);
  });

  // 4. Timer.periodic (Interval 1 detik)
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    // Cek jika di Background iOS (Hemat baterai)
    if (Platform.isIOS) {
      return;
    }

    // 2. Dapatkan target waktu sholat (Contoh Logic Dummy)
    // Di real app, Anda ambil dari API dan simpan di SharedPrefs
    DateTime targetTime;
    String storedTarget = prefs.getString('target_prayer_time') ?? '';
    
    if (storedTarget.isNotEmpty) {
      targetTime = DateTime.parse(storedTarget);
    } else {
      // Fallback dummy: 5 menit dari sekarang jika belum ada data
      if (!prefs.containsKey('dummy_timer_set')) {
        targetTime = DateTime.now().add(const Duration(minutes: 5));
        await prefs.setString('target_prayer_time', targetTime.toIso8601String());
        await prefs.setBool('dummy_timer_set', true);
      } else {
        // Ambil dummy yang sudah di-set sebelumnya
        targetTime = DateTime.parse(prefs.getString('target_prayer_time')!);
      }
    }

    final now = DateTime.now();
    final difference = targetTime.difference(now);

    // 3. Logika Timer
    if (difference.isNegative) {
      // Waktu habis -> Bisa panggil fungsi playAdzan() atau reset timer
      timer.cancel(); 
      // Reset atau panggil Adzan sesuai kebutuhan
      return;
    }

    // Format ke HH:mm:ss
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(difference.inHours);
    String minutes = twoDigits(difference.inMinutes.remainder(60));
    String seconds = twoDigits(difference.inSeconds.remainder(60));
    String timeString = "$hours:$minutes:$seconds";

    // 3 & 5. Update Notifikasi
    // Syarat: ID 888, ongoing: true, showWhen: false, priority: Priority.low
    if (service is AndroidServiceInstance) {
      await flutterLocalNotificationsPlugin.show(
        ONGOING_NOTIFICATION_ID, // ID SAMA dengan foregroundServiceNotificationId
        'Menuju Waktu Sholat',   // Judul
        'Sisa waktu: $timeString', // Body (Berubah setiap detik)
        const NotificationDetails(
          android: AndroidNotificationDetails(
            NOTIFICATION_CHANNEL_ID, // Channel ID SAMA
            'Adzan Live Timer',
            icon: '@mipmap/ic_launcher',
            ongoing: true,       // Wajib: Tidak bisa di swipe
            showWhen: false,     // Sembunyikan timestamp
            priority: Priority.high, // Diubah ke HIGH agar Sticky
            playSound: false,    // Matikan bunyi agar tidak ribut saat update timer
            enableVibration: false, // Matikan getar
            autoCancel: false,   // Jangan hilang saat diklik
            onlyAlertOnce: true, // Sangat penting: Hanya alert SAAT PERTAMA KALI
            visibility: NotificationVisibility.public,
          ),
        ),
      );
    }
  });

  // Handle stop
  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}
