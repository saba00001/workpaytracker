package com.example.workpaytracker

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager

class MainActivity : FlutterFragmentActivity() {

    private val CHANNEL = "com.example.workpaytracker/fullscreen"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Allow showing over lock screen and wake the device
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
        )

        // Ensure high-importance notification channel exists for full-screen intent
        createNotificationChannel()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleFullScreenNotification" -> {
                    val hour = call.argument<Int>("hour") ?: 20
                    val minute = call.argument<Int>("minute") ?: 0
                    scheduleFullScreenAlarm(hour, minute)
                    result.success(true)
                }
                "cancelFullScreenNotification" -> {
                    cancelFullScreenAlarm()
                    result.success(true)
                }
                "checkFullScreenPermission" -> {
                    result.success(canUseFullScreenIntent())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "workpay_daily_v4",
                "სამუშაო დღის შეხსენება",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "ყოველდღიური შეხსენება — იმუშავე დღეს?"
                enableVibration(true)
                setShowBadge(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    private fun canUseFullScreenIntent(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) { // API 34
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            return nm.canUseFullScreenIntent()
        }
        return true // Allowed by default on API < 34
    }

    private fun scheduleFullScreenAlarm(hour: Int, minute: Int) {
        // This is handled by flutter_local_notifications with fullScreenIntent: true
        // The PendingIntent in the notification will launch WorkConfirmActivity
    }

    private fun cancelFullScreenAlarm() {
        // Handled by flutter_local_notifications
    }
}
