package com.doyou.parentalcontrol

import android.app.AppOpsManager
import android.app.admin.DevicePolicyManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.doyou.parentalcontrol/native_admin"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val componentName = ComponentName(this, DOYouDeviceAdminReceiver::class.java)

            when (call.method) {
                "lockScreen" -> {
                    if (dpm.isAdminActive(componentName)) {
                        dpm.lockNow()
                        result.success(true)
                    } else {
                        result.error("ADMIN_NOT_ENABLED", "Device Admin is not enabled for DO you", null)
                    }
                }

                "isAdminActive" -> {
                    val isActive = dpm.isAdminActive(componentName)
                    result.success(isActive)
                }

                "requestAdminPermission" -> {
                    val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                        putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
                        putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "DO you requires device admin to lock device upon parental command.")
                    }
                    startActivity(intent)
                    result.success(true)
                }

                "hasUsagePermission" -> {
                    val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
                    val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        appOps.unsafeCheckOpNoThrow(
                            AppOpsManager.OPSTR_GET_USAGE_STATS,
                            Process.myUid(),
                            packageName
                        )
                    } else {
                        appOps.checkOpNoThrow(
                            AppOpsManager.OPSTR_GET_USAGE_STATS,
                            Process.myUid(),
                            packageName
                        )
                    }
                    result.success(mode == AppOpsManager.MODE_ALLOWED)
                }

                "requestUsagePermission" -> {
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }

                "getDailyAppUsage" -> {
                    val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                    val calendar = Calendar.getInstance()
                    calendar.set(Calendar.HOUR_OF_DAY, 0)
                    calendar.set(Calendar.MINUTE, 0)
                    calendar.set(Calendar.SECOND, 0)
                    val startTime = calendar.timeInMillis
                    val endTime = System.currentTimeMillis()

                    val queryUsageStats: List<UsageStats> = usageStatsManager.queryUsageStats(
                        UsageStatsManager.INTERVAL_DAILY,
                        startTime,
                        endTime
                    )

                    val usageList = ArrayList<Map<String, Any>>()
                    if (queryUsageStats != null) {
                        val pm = packageManager
                        for (stats in queryUsageStats) {
                            if (stats.totalTimeInForeground > 0) {
                                val pkgName = stats.packageName
                                val appLabel = try {
                                    val appInfo = pm.getApplicationInfo(pkgName, 0)
                                    pm.getApplicationLabel(appInfo).toString()
                                } catch (e: Exception) {
                                    pkgName
                                }

                                val map = HashMap<String, Any>()
                                map["packageName"] = pkgName
                                map["appName"] = appLabel
                                map["totalTimeMs"] = stats.totalTimeInForeground
                                map["lastTimeUsedMs"] = stats.lastTimeUsed
                                usageList.add(map)
                            }
                        }
                    }
                    result.success(usageList)
                }

                else -> result.notImplemented()
            }
        }
    }
}
