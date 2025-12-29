package com.example.adzan_monokrom

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Boot Receiver - Reschedule alarm setelah HP restart
 * Alarm yang dijadwalkan dengan AlarmManager akan hilang saat HP mati/restart
 * Receiver ini akan mereschedule ulang dari SharedPreferences
 */
class BootReceiver : BroadcastReceiver() {
    
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            
            Log.d("AdzanOptimization", "Boot completed - checking for pending alarms")
            
            // TODO: Baca dari SharedPreferences dan reschedule alarm
            // Untuk saat ini, biarkan Flutter app yang reschedule saat dibuka
        }
    }
}
