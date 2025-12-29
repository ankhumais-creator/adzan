package com.example.adzan_monokrom

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import java.util.*

class AdzanService : Service() {

    companion object {
        private const val CHANNEL_ID = "adzan_native_channel"
        private const val NOTIFICATION_ID = 999
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action

        if (action == "ACTION_PLAY_ADZAN") {
            // --- MODE AKTIF: SAAT ADZAN ---
            val prayerName = intent.getStringExtra("prayerName") ?: "Sholat"
            startForeground(NOTIFICATION_ID, buildAlertNotification(prayerName))
            playAdzanSound()
            
            // Matikan service setelah selesai (Auto-Stop untuk hemat baterai)
            stopSelf()
        } else {
            // --- MODE STANDBY: SAAT SET TIMER ---
            val targetTimeMs = intent?.getLongExtra("targetTime", 0) ?: return START_NOT_STICKY
            val prayerName = intent.getStringExtra("prayerName") ?: "Sholat"

            // Tampilkan notifikasi "Standby" sekali saja, TANPA loop update
            startForeground(NOTIFICATION_ID, buildStandbyNotification(prayerName, targetTimeMs))
            
            // Panggil AlarmManager Lalu LEPAS (CPU bisa tidur)
            AdzanAlarmScheduler.scheduleAdzan(this, targetTimeMs, prayerName)
        }

        return START_NOT_STICKY // Tidak restart jika mati
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // Notifikasi Standby (Tanpa update timer - hemat baterai)
    private fun buildStandbyNotification(prayerName: String, targetMs: Long): Notification {
        val targetDate = Date(targetMs)
        val timeStr = android.text.format.DateFormat.format("HH:mm", targetDate)
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Adzan Service Aktif")
            .setContentText("Menuju $prayerName pada $timeStr")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setShowWhen(false)
            .setPriority(NotificationCompat.PRIORITY_LOW) // Low priority = less battery
            .build()
    }

    // Notifikasi Alarm (Saat waktu tiba)
    private fun buildAlertNotification(prayerName: String): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("WAKTU SHOLAT TIBA!")
            .setContentText("Sudah waktunya Sholat $prayerName")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(false)
            .build()
    }

    private fun playAdzanSound() {
        // Logika mainkan suara adzan native
        android.util.Log.d("AdzanOptimization", "Playing Adzan Sound...")
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Adzan Native Service",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifikasi waktu sholat"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}
