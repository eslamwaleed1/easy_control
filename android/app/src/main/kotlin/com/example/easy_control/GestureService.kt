package com.example.easy_control

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Intent
import android.graphics.Path
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.os.Handler
import android.os.Looper

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import androidx.core.app.NotificationCompat


class GestureService : AccessibilityService() {
    private val TAG = "GestureService"

    companion object {
        private var instance: GestureService? = null
        private const val TAG = "GestureService"
        private const val NOTIFICATION_ID = 2
        private const val CHANNEL_ID = "GestureServiceChannel"

        fun isServiceRunning(): Boolean {
            val isRunning = instance != null
            Log.d(TAG, "isServiceRunning: $isRunning")
            return isRunning
        }

        fun simulateTouch(x: Float, y: Float) {
            Log.d(TAG, "simulateTouch called with x=$x, y=$y")
            instance?.performTouch(x, y)
        }
    }

    override fun onServiceConnected() {
        instance = this
        Log.d(TAG, "GestureService connected successfully.")
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        super.onServiceConnected()
    }

    override fun onUnbind(intent: Intent?): Boolean {
        instance = null
        Log.d(TAG, "Service unbound")
        return super.onUnbind(intent)
    }
    override fun onDestroy() {
        Log.d(TAG, "GestureService destroyed")
        instance = null
        stopForeground(true)
        super.onDestroy()
    }

    private fun performTouch(x: Float, y: Float) {
        val builder = GestureDescription.Builder()
        var cause: String = "Just the initialization.."
        val path = Path().apply {
            moveTo(x, y)
            lineTo(x, y)
        }
        val stroke = GestureDescription.StrokeDescription(path, 0, 200)
        val gesture = builder
            .addStroke(stroke)
            .build()
        val handler = Handler(Looper.getMainLooper())
        val dispatched = try {
            dispatchGesture(
                gesture,
                object : GestureResultCallback() {
                    override fun onCompleted(gestureDescription: GestureDescription?) {
                        Log.d(TAG, "Gesture completed at x=$x, y=$y")
                    }

                    override fun onCancelled(gestureDescription: GestureDescription?) {
                        Log.e(TAG, "Gesture cancelled at x=$x, y=$y, reason: $gestureDescription")
                        cause = gestureDescription?.toString() ?: "Unknown cancellation reason"
                    }
                },
                handler
            )
        } catch (e: Exception) {
            Log.e(TAG, "Exception during dispatchGesture: ${e.message}", e)
            false
        }
        if (dispatched) {
            Log.d(TAG, "Dispatched tap at ($x, $y) successfully! reason: $cause")
        } else {
            Log.e(TAG, "Dispatched tap at ($x, $y) failed -_-. $cause")
            // Fallback to GLOBAL_ACTION_HOME
            try {
                performGlobalAction(GLOBAL_ACTION_HOME)
                Log.d(TAG, "Performed GLOBAL_ACTION_HOME as fallback")
            } catch (e: Exception) {
                Log.e(TAG, "Error performing GLOBAL_ACTION_HOME: ${e.message}", e)
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand called with intent: $intent")
        intent?.let {
            val command = it.getStringExtra("command")?.lowercase()
            val x = it.getFloatExtra("x", 0f)
            val y = it.getFloatExtra("y", 0f)
            if (x < 0 || y < 0) {
                Log.e(TAG, "Negative coordinates detected: x=$x, y=$y")
            }
            if (command == null || x == 0f || y == 0f) {
                Log.e(TAG, "Dispatched tap at ($x, $y) is invalid.")
                return@let
            }
            when (command) {
                "open" -> performTouch(x, y)
                else -> Log.e(TAG, "Unknown command: $command")
            }
        } ?: Log.e(TAG, "Received null intent")
        return START_STICKY
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        //Log.d(TAG, "Accessibility event received: $event")
    }

    override fun onInterrupt() {
        Log.d(TAG, "GestureService interrupted")
    }
    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Gesture Service",
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "Channel for Gesture Service"
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Gesture Service")
            .setContentText("Running accessibility service...")
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()
    }
}