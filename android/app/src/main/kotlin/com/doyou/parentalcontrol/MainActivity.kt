package com.doyou.parentalcontrol

import android.app.AppOpsManager
import android.app.NotificationManager
import android.app.admin.DevicePolicyManager
import android.app.usage.UsageStats
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
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.doyou.parentalcontrol/native_admin"
    private var sirenRingtone: Ringtone? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->

            val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val componentName = ComponentName(this, DOYouDeviceAdminReceiver::class.java)

            when (call.method) {

                // ──────────────────────────────────────────
                // 1. Hardware Screen Lock
                // ──────────────────────────────────────────
                "lockScreen" -> {
                    if (dpm.isAdminActive(componentName)) {
                        dpm.lockNow()
                        result.success(true)
                    } else {
                        result.error("ADMIN_NOT_ENABLED", "Device Admin is not active", null)
                    }
                }

                // ──────────────────────────────────────────
                // 2. FACTORY RESET (wipeData) – Anti-Theft
                // ──────────────────────────────────────────
                "factoryReset" -> {
                    if (dpm.isAdminActive(componentName)) {
                        dpm.wipeData(0)
                        result.success(true)
                    } else {
                        result.error("ADMIN_NOT_ENABLED", "Device Admin required for factory reset", null)
                    }
                }

                // ──────────────────────────────────────────
                // 3. ANTI-THEFT SIREN – Override DND/Silent
                // ──────────────────────────────────────────
                "playSirenAlarm" -> {
                    try {
                        // Override Do Not Disturb if we have permission
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            if (notificationManager.isNotificationPolicyAccessGranted) {
                                notificationManager.setInterruptionFilter(
                                    NotificationManager.INTERRUPTION_FILTER_ALL
                                )
                            }
                        }
                        // Force max alarm volume
                        audioManager.setStreamVolume(
                            AudioManager.STREAM_ALARM,
                            audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM),
                            0
                        )
                        if (sirenRingtone == null) {
                            val alarmUri: Uri =
                                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                                    ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                            sirenRingtone = RingtoneManager.getRingtone(applicationContext, alarmUri)
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
                        result.error("ALARM_ERROR", e.message, null)
                    }
                }

                // ──────────────────────────────────────────
                // 4. Camera Lock
                // ──────────────────────────────────────────
                "setCameraDisabled" -> {
                    val disabled = call.argument<Boolean>("disabled") ?: false
                    if (dpm.isAdminActive(componentName)) {
                        dpm.setCameraDisabled(componentName, disabled)
                        result.success(true)
                    } else {
                        result.error("ADMIN_NOT_ENABLED", "Device Admin required to disable camera", null)
                    }
                }

                // ──────────────────────────────────────────
                // 5. Remote Mute
                // ──────────────────────────────────────────
                "setRingerMute" -> {
                    val mute = call.argument<Boolean>("mute") ?: false
                    audioManager.ringerMode = if (mute)
                        AudioManager.RINGER_MODE_SILENT
                    else
                        AudioManager.RINGER_MODE_NORMAL
                    result.success(true)
                }

                // ──────────────────────────────────────────
                // 6. Wi-Fi Kill Switch
                // ──────────────────────────────────────────
                "toggleWifi" -> {
                    val enable = call.argument<Boolean>("enable") ?: true
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                        @Suppress("DEPRECATION")
                        wifiManager.isWifiEnabled = enable
                        result.success(true)
                    } else {
                        // On Android 10+ open Wi-Fi panel
                        val intent = Intent(Settings.Panel.ACTION_WIFI)
                        startActivity(intent)
                        result.success(true)
                    }
                }

                // ──────────────────────────────────────────
                // 7. Accessibility Service Status Check
                // ──────────────────────────────────────────
                "isAccessibilityEnabled" -> {
                    val serviceName = "$packageName/${DOYouAccessibilityService::class.java.canonicalName}"
                    val enabledServices = Settings.Secure.getString(
                        contentResolver,
                        Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
                    ) ?: ""
                    result.success(enabledServices.contains(serviceName))
                }

                "requestAccessibilityPermission" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }

                // ──────────────────────────────────────────
                // 8. Accessibility - Get Latest Browser URL
                // ──────────────────────────────────────────
                "getLastBrowserUrl" -> {
                    result.success(DOYouAccessibilityService.lastCapturedUrl ?: "")
                }

                // ──────────────────────────────────────────
                // 9. DND Permission
                // ──────────────────────────────────────────
                "hasDNDPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(notificationManager.isNotificationPolicyAccessGranted)
                    } else {
                        result.success(true)
                    }
                }

                "requestDNDPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                        startActivity(intent)
                    }
                    result.success(true)
                }

                // ──────────────────────────────────────────
                // 10. Device Admin Checks
                // ──────────────────────────────────────────
                "isAdminActive" -> {
                    result.success(dpm.isAdminActive(componentName))
                }

                "requestAdminPermission" -> {
                    val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                        putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
                        putExtra(
                            DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                            "DO you requires Device Admin for hardware lock, camera protection and anti-theft wipe."
                        )
                    }
                    startActivity(intent)
                    result.success(true)
                }

                // ──────────────────────────────────────────
                // 11. Usage Stats Permission & Data
                // ──────────────────────────────────────────
                "hasUsagePermission" -> {
                    val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
                    val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        appOps.unsafeCheckOpNoThrow(
                            AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName
                        )
                    } else {
                        @Suppress("DEPRECATION")
                        appOps.checkOpNoThrow(
                            AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName
                        )
                    }
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
                    val stats: List<UsageStats> = usm.queryUsageStats(
                        UsageStatsManager.INTERVAL_DAILY, cal.timeInMillis, System.currentTimeMillis()
                    )
                    val pm = packageManager
                    val list = ArrayList<Map<String, Any>>()
                    stats.filter { it.totalTimeInForeground > 0 }.forEach { s ->
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

                else -> result.notImplemented()
            }
        }
    }
}
