package com.example.adzan_monokrom

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.AlarmManagerCompat

object AdzanAlarmScheduler {

    // ID Unik untuk alarm sholat
    private const val REQUEST_CODE_ADZAN = 999

    fun scheduleAdzan(context: Context, targetTimeMs: Long, prayerName: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        // Intent yang akan di-trigger saat alarm berbunyi
        val intent = Intent(context, AdzanReceiver::class.java).apply {
            putExtra("prayerName", prayerName)
        }

        // PendingIntent Flags (Wajib untuk Android S+)
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val pendingIntent = PendingIntent.getBroadcast(context, REQUEST_CODE_ADZAN, intent, flags)

        // Matikan Alarm lama jika ada
        alarmManager.cancel(pendingIntent)

        try {
            // SetExactAndAllowWhileIdle: Memaksa HP bangun meski Doze Mode
            AlarmManagerCompat.setExactAndAllowWhileIdle(
                alarmManager,
                AlarmManager.RTC_WAKEUP,
                targetTimeMs,
                pendingIntent
            )
            
            android.util.Log.d("AdzanOptimization", "Alarm dijadwalkan untuk $prayerName pada $targetTimeMs")
            android.util.Log.d("AdzanOptimization", "Mode Hemat: ON (CPU tidur sampai waktunya)")

        } catch (e: SecurityException) {
            // Fallback jika user memblokir exact alarm
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                targetTimeMs,
                pendingIntent
            )
        }
    }
}
