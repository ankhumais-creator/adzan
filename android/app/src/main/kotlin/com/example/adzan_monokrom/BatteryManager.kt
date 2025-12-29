package com.example.adzan_monokrom

import android.content.Context
import android.os.PowerManager
import android.os.Build

object BatteryManager {

    // Fungsi cek baterai
    fun isBatteryLow(context: Context): Boolean {
        val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as android.os.BatteryManager
        val level = batteryManager.getIntProperty(android.os.BatteryManager.BATTERY_PROPERTY_CAPACITY)
        return level <= 15 // Ambang batas 15%
    }

    // Fungsi ambil Wakelock dengan timeout otomatis (Anti-lupa lepas)
    fun acquireWakeLock(context: Context): PowerManager.WakeLock {
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK, // CPU nyala, Layar mati (hemat)
            "AdzanApp:AdzanWakeLock"
        )
        
        // Set flag agar bisa dipakai saat screen off
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            wakeLock.setReferenceCounted(false)
        }

        // Safety Mechanism: Matikan wakelock otomatis setelah 10 detik
        wakeLock.acquire(10000L) 
        return wakeLock
    }
}
