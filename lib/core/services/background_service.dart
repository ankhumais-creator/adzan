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

  // 1. Create notification channel (Importance.high agar sticky)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    NOTIFICATION_CHANNEL_ID,
    'Adzan Live Timer',
    description: 'Menampilkan hitung mundur menuju waktu sholat',
    importance: Importance.high,
  );

  // Inisialisasi plugin notifikasi untuk create channel
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // 2. Configure service
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: NOTIFICATION_CHANNEL_ID,
      initialNotificationTitle: 'Adzan Timer',
      initialNotificationContent: 'Menunggu waktu sholat...',
      foregroundServiceNotificationId: ONGOING_NOTIFICATION_ID,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

/// Fungsi untuk update waktu shalat dari main app ke service
Future<void> updateNextPrayerTime(DateTime nextTime, String prayerName) async {
  final service = FlutterBackgroundService();
  
  // Simpan ke SharedPreferences agar service bisa baca saat start ulang
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('real_prayer_target', nextTime.toIso8601String());
  await prefs.setString('real_prayer_name', prayerName);

  // Kirim langsung ke service yang sedang berjalan
  if (await service.isRunning()) {
    service.invoke('setRealTime', {
      "time": nextTime.toIso8601String(),
      "name": prayerName,
    });
  }
}

// Entry Point Isolate
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Listener untuk menerima data waktu shalat dari Main App
  service.on('setRealTime').listen((event) {
    if (event != null) {
      final String timeStr = event['time'] as String;
      final String name = event['name'] as String;
      prefs.setString('real_prayer_target', timeStr);
      prefs.setString('real_prayer_name', name);
    }
  });

  // Timer setiap 1 detik
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (Platform.isIOS) return;

    // Reload prefs untuk dapat data terbaru
    await prefs.reload();

    // Ambil data waktu shalat dari SharedPreferences
    String storedTarget = prefs.getString('real_prayer_target') ?? '';
    String storedName = prefs.getString('real_prayer_name') ?? 'Waktu Sholat';

    // Jika tidak ada data, tampilkan "Menunggu..."
    if (storedTarget.isEmpty) {
      if (service is AndroidServiceInstance) {
        await flutterLocalNotificationsPlugin.show(
          ONGOING_NOTIFICATION_ID,
          'Adzan Timer',
          'Menunggu data waktu sholat...',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              NOTIFICATION_CHANNEL_ID,
              'Adzan Live Timer',
              icon: '@mipmap/ic_launcher',
              category: AndroidNotificationCategory.service,
              ongoing: true,
              showWhen: false,
              priority: Priority.high,
              playSound: false,
              enableVibration: false,
              onlyAlertOnce: true,
              autoCancel: false,
              visibility: NotificationVisibility.public,
            ),
          ),
        );
      }
      return;
    }

    final DateTime targetTime = DateTime.parse(storedTarget);
    final now = DateTime.now();
    final difference = targetTime.difference(now);

    // Format Waktu
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(difference.inHours);
    String minutes = twoDigits(difference.inMinutes.remainder(60));
    String seconds = twoDigits(difference.inSeconds.remainder(60));
    String timeString = "$hours:$minutes:$seconds";

    // Saat Waktu Tiba
    if (difference.inSeconds <= 0) {
      // WAKTU SHOLAT TIBA
      timer.cancel();
      
      // Hapus target tersimpan agar tidak looping
      await prefs.remove('real_prayer_target');
      await prefs.remove('real_prayer_name');

      // Panggil Adzan
      playAdzanSound(prayerName: storedName);

      // Update notifikasi menjadi "Sudah Waktunya"
      if (service is AndroidServiceInstance) {
        await flutterLocalNotificationsPlugin.show(
          ONGOING_NOTIFICATION_ID,
          'WAKTU SHOLAT TIBA',
          'Sudah waktunya Sholat $storedName',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              NOTIFICATION_CHANNEL_ID, 
              'Adzan Timer',
              icon: '@mipmap/ic_launcher',
              ongoing: true,
              priority: Priority.high,
              playSound: false,
            ),
          ),
        );
      }
      
      return;
    }

    // Update Notifikasi Timer Realtime
    if (service is AndroidServiceInstance) {
      await flutterLocalNotificationsPlugin.show(
        ONGOING_NOTIFICATION_ID,
        'Menuju $storedName',
        'Sisa waktu: $timeString',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            NOTIFICATION_CHANNEL_ID,
            'Adzan Live Timer',
            icon: '@mipmap/ic_launcher',
            category: AndroidNotificationCategory.service,
            ongoing: true,
            showWhen: false,
            priority: Priority.high,
            playSound: false,
            enableVibration: false,
            onlyAlertOnce: true,
            autoCancel: false,
            visibility: NotificationVisibility.public,
          ),
        ),
      );
    }
  });

  service.on('stopService').listen((event) => service.stopSelf());
}

void playAdzanSound({required String prayerName}) {
  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
  notificationsPlugin.show(
    999,
    "ADZAN $prayerName",
    "Ayo laksanakan sholat tepat waktu",
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'adzan_sound_channel',
        'Adzan Alarm',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('adzan'),
      ),
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}
