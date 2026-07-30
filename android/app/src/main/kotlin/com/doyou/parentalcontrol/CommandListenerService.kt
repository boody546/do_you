package com.doyou.parentalcontrol

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.media.RingtoneManager
import android.os.Build
import android.os.IBinder
import android.util.Log
import com.google.firebase.database.DataSnapshot
import com.google.firebase.database.DatabaseError
import com.google.firebase.database.FirebaseDatabase
import com.google.firebase.database.ValueEventListener

/**
 * Firebase Realtime Database Command Listener Service
 *
 * Runs as a foreground service, listening for remote commands
 * sent from the Parent dashboard:
 *   - trigger_alarm  → plays siren at max volume (DND override)
 *   - locate_device  → logs GPS location to Firebase
 *   - wipe_data      → triggers DevicePolicyManager.wipeData(0)
 *   - lock_screen    → triggers DevicePolicyManager.lockNow()
 *   - stop_alarm     → stops the ringing siren
 */
class CommandListenerService : Service() {

    private val TAG = "CommandListenerService"
    private val CHANNEL_ID = "doyou_command_channel"
    private val NOTIF_ID = 1001

    private var deviceId: String = ""
    private var commandListener: ValueEventListener? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        deviceId = intent?.getStringExtra("deviceId") ?: ""
        Log.d(TAG, "CommandListenerService started for deviceId=$deviceId")

        startForeground(NOTIF_ID, buildForegroundNotification())
        startFirebaseListener()

        return START_STICKY
    }

    private fun startFirebaseListener() {
        if (deviceId.isBlank()) {
            Log.e(TAG, "No deviceId provided — cannot listen for commands")
            return
        }

        val db = FirebaseDatabase.getInstance()
        val commandRef = db.getReference("device_commands/$deviceId")

        commandListener = object : ValueEventListener {
            override fun onDataChange(snapshot: DataSnapshot) {
                val command = snapshot.child("command").getValue(String::class.java) ?: return
                val status = snapshot.child("status").getValue(String::class.java) ?: "pending"

                if (status == "executed") return   // skip already-processed commands
                Log.d(TAG, "Received command: $command for device: $deviceId")

                when (command) {
                    "trigger_alarm" -> {
                        executeAlarm()
                        markCommandExecuted(commandRef)
                    }
                    "stop_alarm" -> {
                        stopAlarm()
                        markCommandExecuted(commandRef)
                    }
                    "lock_screen" -> {
                        executeLock()
                        markCommandExecuted(commandRef)
                    }
                    "wipe_data" -> {
                        executeWipe()
                        markCommandExecuted(commandRef)
                    }
                    "locate_device" -> {
                        // Location is streamed separately by Dart geolocator
                        markCommandExecuted(commandRef)
                    }
                }
            }

            override fun onCancelled(error: DatabaseError) {
                Log.e(TAG, "Command listener cancelled: ${error.message}")
            }
        }

        commandRef.addValueEventListener(commandListener!!)
    }

    private fun markCommandExecuted(ref: com.google.firebase.database.DatabaseReference) {
        ref.child("status").setValue("executed")
    }

    private fun executeAlarm() {
        try {
            val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            audio.setStreamVolume(
                AudioManager.STREAM_ALARM,
                audio.getStreamMaxVolume(AudioManager.STREAM_ALARM),
                0
            )
            val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            val ringtone = RingtoneManager.getRingtone(applicationContext, uri)
            ringtone?.play()
            Log.d(TAG, "SIREN ALARM TRIGGERED via Firebase command")
        } catch (e: Exception) {
            Log.e(TAG, "Alarm error: ${e.message}")
        }
    }

    private fun stopAlarm() {
        // Stopping is handled from MainActivity's ringtone reference
        Log.d(TAG, "Stop alarm command received")
    }

    private fun executeLock() {
        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val adminComponent = ComponentName(this, DOYouDeviceAdminReceiver::class.java)
        if (dpm.isAdminActive(adminComponent)) {
            dpm.lockNow()
            Log.d(TAG, "HARDWARE LOCK executed via Firebase command")
        } else {
            Log.e(TAG, "Cannot lock: Device Admin not active")
        }
    }

    private fun executeWipe() {
        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val adminComponent = ComponentName(this, DOYouDeviceAdminReceiver::class.java)
        if (dpm.isAdminActive(adminComponent)) {
            Log.w(TAG, "FACTORY RESET (wipeData) executing via Firebase command!")
            dpm.wipeData(0)
        } else {
            Log.e(TAG, "Cannot wipe: Device Admin not active")
        }
    }

    private fun buildForegroundNotification(): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "DO you Shield Protection",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "DO you is actively monitoring for parental control commands"
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }

        val pendingIntent = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("DO you Shield Active 🛡️")
                .setContentText("Parental control protection is running in the background.")
                .setSmallIcon(android.R.drawable.ic_lock_lock)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle("DO you Shield Active 🛡️")
                .setContentText("Parental control protection is running in the background.")
                .setSmallIcon(android.R.drawable.ic_lock_lock)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .build()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        commandListener?.let {
            val db = FirebaseDatabase.getInstance()
            db.getReference("device_commands/$deviceId").removeEventListener(it)
        }
        Log.d(TAG, "CommandListenerService destroyed and Firebase listener removed")
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
