package com.example.adzan_monokrom

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class AdzanReceiver : BroadcastReceiver() {
    
    override fun onReceive(context: Context, intent: Intent) {
        val prayerName = intent.getStringExtra("prayerName") ?: "Sholat"
        
        Log.d("AdzanOptimization", "ALARM BERBUNYI! Waktunya $prayerName")

        // 1. Ambil Wakelock Cepat (Kunci CPU supaya tidak mati saat bunyi adzan)
        val wakeLock = BatteryManager.acquireWakeLock(context)

        // 2. Lakukan Tugas Berat (Play Sound & Update Notifikasi)
        val serviceIntent = Intent(context, AdzanService::class.java).apply {
            action = "ACTION_PLAY_ADZAN"
            putExtra("prayerName", prayerName)
        }
        
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }

        // Wakelock akan otomatis lepas setelah 10 detik (sudah di-set di BatteryManager)
    }
}
