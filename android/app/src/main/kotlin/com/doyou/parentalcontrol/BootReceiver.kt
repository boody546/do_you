package com.doyou.parentalcontrol

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * BootReceiver — restarts CommandListenerService automatically after device reboot.
 * This ensures the parental control shield stays active even if the phone restarts.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("DOYouBootReceiver", "Device rebooted — restarting DO you CommandListenerService")

            // Retrieve last known deviceId from SharedPreferences
            val prefs = context.getSharedPreferences("DOYouPrefs", Context.MODE_PRIVATE)
            val deviceId = prefs.getString("deviceId", "") ?: ""

            if (deviceId.isNotBlank()) {
                val serviceIntent = Intent(context, CommandListenerService::class.java)
                    .putExtra("deviceId", deviceId)

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            }
        }
    }
}
