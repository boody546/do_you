package com.doyou.parentalcontrol

import android.app.AppOpsManager
import android.app.NotificationManager
import android.app.admin.DevicePolicyManager
import android.app.usage.UsageStatsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Process
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.doyou.parentalcontrol/native_admin"
    private var sirenRingtone: Ringtone? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
                val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                val notifMgr = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                val adminComponent = ComponentName(this, DOYouDeviceAdminReceiver::class.java)

                when (call.method) {

                    // ── 1. Hardware Screen Lock ──────────────────────────────
                    "lockScreen" -> {
                        if (dpm.isAdminActive(adminComponent)) {
                            dpm.lockNow()
                            result.success(true)
                        } else {
                            result.error("ADMIN_NOT_ENABLED", "Device Admin is not active", null)
                        }
                    }

                    // ── 2. FACTORY RESET — wipeData(0) ──────────────────────
                    "factoryReset" -> {
                        if (dpm.isAdminActive(adminComponent)) {
                            Log.w("DOYou", "EXECUTING FACTORY RESET via wipeData(0)")
                            dpm.wipeData(0)          // 0 = wipe internal storage only
                            result.success(true)
                        } else {
                            result.error("ADMIN_NOT_ENABLED",
                                "Device Admin must be active to perform factory reset", null)
                        }
                    }

                    // ── 3. Anti-Theft SIREN — Override DND & Silent ──────────
                    "playSirenAlarm" -> {
                        try {
                            // Step 1: lift Do Not Disturb if permitted
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                if (notifMgr.isNotificationPolicyAccessGranted) {
                                    notifMgr.setInterruptionFilter(
                                        NotificationManager.INTERRUPTION_FILTER_ALL
                                    )
                                }
                            }
                            // Step 2: max out alarm stream volume
                            audio.setStreamVolume(
                                AudioManager.STREAM_ALARM,
                                audio.getStreamMaxVolume(AudioManager.STREAM_ALARM),
                                0
                            )
                            // Step 3: play ringtone on alarm stream
                            if (sirenRingtone == null) {
                                val uri: Uri =
                                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                                        ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                                sirenRingtone = RingtoneManager.getRingtone(applicationContext, uri)
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                                    sirenRingtone?.audioAttributes = android.media.AudioAttributes.Builder()
                                        .setUsage(android.media.AudioAttributes.USAGE_ALARM)
                                        .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SONIFICATION)
                                        .build()
                                }
                            }
                            sirenRingtone?.play()
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ALARM_ERROR", e.message, null)
                        }
                    }

                    "stopSirenAlarm" -> {
                        try {
                            sirenRingtone?.stop()
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ALARM_STOP_ERROR", e.message, null)
                        }
                    }

                    // ── 4. Camera Lock ───────────────────────────────────────
                    "setCameraDisabled" -> {
                        val disabled = call.argument<Boolean>("disabled") ?: false
                        if (dpm.isAdminActive(adminComponent)) {
                            dpm.setCameraDisabled(adminComponent, disabled)
                            result.success(true)
                        } else {
                            result.error("ADMIN_NOT_ENABLED",
                                "Device Admin required to disable camera", null)
                        }
                    }

                    // ── 5. Remote Ringer Mute ────────────────────────────────
                    "setRingerMute" -> {
                        val mute = call.argument<Boolean>("mute") ?: false
                        audio.ringerMode = if (mute)
                            AudioManager.RINGER_MODE_SILENT
                        else
                            AudioManager.RINGER_MODE_NORMAL
                        result.success(true)
                    }

                    // ── 6. Wi-Fi Kill Switch ─────────────────────────────────
                    "toggleWifi" -> {
                        val enable = call.argument<Boolean>("enable") ?: true
                        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                            @Suppress("DEPRECATION")
                            wifi.isWifiEnabled = enable
                        } else {
                            startActivity(Intent(Settings.Panel.ACTION_WIFI))
                        }
                        result.success(true)
                    }

                    // ── 7. Accessibility Service Status ──────────────────────
                    "isAccessibilityEnabled" -> {
                        val svcName =
                            "$packageName/${DOYouAccessibilityService::class.java.canonicalName}"
                        val enabled = Settings.Secure.getString(
                            contentResolver,
                            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
                        ) ?: ""
                        result.success(enabled.contains(svcName))
                    }

                    "requestAccessibilityPermission" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(true)
                    }

                    "getLastBrowserUrl" -> {
                        result.success(DOYouAccessibilityService.lastCapturedUrl ?: "")
                    }

                    // ── 8. DND Permission ────────────────────────────────────
                    "hasDNDPermission" -> {
                        val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                            notifMgr.isNotificationPolicyAccessGranted
                        else true
                        result.success(granted)
                    }

                    "requestDNDPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            startActivity(Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
                        }
                        result.success(true)
                    }

                    // ── 9. Device Admin ──────────────────────────────────────
                    "isAdminActive" -> result.success(dpm.isAdminActive(adminComponent))

                    "requestAdminPermission" -> {
                        val i = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                            putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
                            putExtra(
                                DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                                "DO you requires Device Admin for hardware lock, camera protection, and anti-theft wipe."
                            )
                        }
                        startActivity(i)
                        result.success(true)
                    }

                    // ── 10. Usage Stats ──────────────────────────────────────
                    "hasUsagePermission" -> {
                        val ops = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
                        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
                            ops.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
                        else
                            @Suppress("DEPRECATION")
                            ops.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
                        result.success(mode == AppOpsManager.MODE_ALLOWED)
                    }

                    "requestUsagePermission" -> {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(true)
                    }

                    "getDailyAppUsage" -> {
                        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                        val cal = Calendar.getInstance().apply {
                            set(Calendar.HOUR_OF_DAY, 0)
                            set(Calendar.MINUTE, 0)
                            set(Calendar.SECOND, 0)
                        }
                        val stats = usm.queryUsageStats(
                            UsageStatsManager.INTERVAL_DAILY,
                            cal.timeInMillis,
                            System.currentTimeMillis()
                        )
                        val pm = packageManager
                        val list = ArrayList<Map<String, Any>>()
                        stats?.filter { it.totalTimeInForeground > 0 }?.forEach { s ->
                            val label = try {
                                pm.getApplicationLabel(pm.getApplicationInfo(s.packageName, 0)).toString()
                            } catch (_: Exception) { s.packageName }
                            list.add(mapOf(
                                "packageName" to s.packageName,
                                "appName" to label,
                                "totalTimeMs" to s.totalTimeInForeground,
                                "lastTimeUsedMs" to s.lastTimeUsed
                            ))
                        }
                        result.success(list)
                    }

                    // ── 11. Start Firebase Command Listener Service ───────────
                    "startCommandListener" -> {
                        val deviceId = call.argument<String>("deviceId") ?: ""
                        val intent = Intent(this, CommandListenerService::class.java)
                            .putExtra("deviceId", deviceId)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    }

                    "stopCommandListener" -> {
                        stopService(Intent(this, CommandListenerService::class.java))
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
