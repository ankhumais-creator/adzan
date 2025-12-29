package com.example.adzan_monokrom

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import java.util.concurrent.TimeUnit

class AdzanService : Service() {

    companion object {
        const val CHANNEL_ID = "adzan_native_channel"
        const val NOTIFICATION_ID = 888
    }

    private val serviceScope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    private var timerJob: Job? = null
    private lateinit var notificationManager: NotificationManager

    override fun onCreate() {
        super.onCreate()
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val targetTimeMs = intent?.getLongExtra("targetTime", 0L) ?: 0L
        val prayerName = intent?.getStringExtra("prayerName") ?: "Sholat"

        // Mulai sebagai Foreground Service
        startForeground(NOTIFICATION_ID, buildNotification("Menunggu...", "Memuat timer..."))

        // Jalankan Timer
        startTimer(targetTimeMs, prayerName)

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        timerJob?.cancel()
        serviceScope.cancel()
    }

    private fun startTimer(targetTimeMs: Long, prayerName: String) {
        timerJob?.cancel()
        timerJob = serviceScope.launch {
            while (isActive) {
                val now = System.currentTimeMillis()
                val diff = targetTimeMs - now

                if (diff <= 0) {
                    // Waktu Habis
                    updateNotification("WAKTU TIBA!", "Sudah waktunya Sholat $prayerName", true)
                    playAdzanSound()
                    cancel()
                } else {
                    // Hitung Mundur
                    val hours = TimeUnit.MILLISECONDS.toHours(diff)
                    val minutes = TimeUnit.MILLISECONDS.toMinutes(diff) % 60
                    val seconds = TimeUnit.MILLISECONDS.toSeconds(diff) % 60
                    
                    val timeStr = String.format("%02d:%02d:%02d", hours, minutes, seconds)
                    updateNotification("Menuju $prayerName", "Sisa Waktu: $timeStr", false)
                }

                delay(1000)
            }
        }
    }

    private fun updateNotification(title: String, content: String, isAlert: Boolean) {
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        notificationManager.notify(NOTIFICATION_ID, notification)

        if (isAlert) {
            playAdzanSound()
        }
    }

    private fun buildNotification(title: String, content: String): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Adzan Native Service",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifikasi timer native adzan"
                setShowBadge(false)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun playAdzanSound() {
        // Implementasi pemutar suara asli
        // Bisa tambahkan MediaPlayer logic jika mau
    }
}
