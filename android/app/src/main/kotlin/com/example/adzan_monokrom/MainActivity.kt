package com.example.adzan_monokrom

import android.content.Intent
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "adzan/native_service"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startTimer" -> {
                    val targetTime = call.argument<Long>("targetTime")
                    val prayerName = call.argument<String>("prayerName") ?: "Sholat"

                    val intent = Intent(this, AdzanService::class.java).apply {
                        putExtra("targetTime", targetTime)
                        putExtra("prayerName", prayerName)
                    }

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }

                    result.success("Service Started")
                }
                "stopTimer" -> {
                    val intent = Intent(this, AdzanService::class.java)
                    stopService(intent)
                    result.success("Service Stopped")
                }
                else -> result.notImplemented()
            }
        }
    }
}
