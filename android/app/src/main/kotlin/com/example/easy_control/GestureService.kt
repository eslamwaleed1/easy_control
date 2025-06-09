package com.example.easy_control

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Intent
import android.graphics.Path
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.accessibilityservice.AccessibilityServiceInfo
import android.annotation.SuppressLint
import android.os.Handler
import android.os.Looper
import android.content.pm.PackageManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
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

    private fun performTouch(x: Float, y: Float, hold: Boolean = false) {
        val builder = GestureDescription.Builder()
        val duration = if (hold) 500L else 50L
        val path = Path().apply {
            moveTo(x, y)
            lineTo(x, y)
        }

        val stroke = GestureDescription.StrokeDescription(path, 0, duration.toLong())  // OR REMOVE ".toLong()".
        val gesture = builder
            .addStroke(stroke)
            .build()
        val handler = Handler(Looper.getMainLooper())
        val dispatched = try {
            dispatchGesture(
                gesture,
                object : GestureResultCallback() {
                    override fun onCompleted(gestureDescription: GestureDescription?) {
                        Log.d(TAG, "Touch ${if (hold) "hold" else "tap"} completed at x=$x, y=$y")
                    }

                    override fun onCancelled(gestureDescription: GestureDescription?) {
                        Log.e(TAG, "Touch ${if (hold) "hold" else "tap"} cancelled at x=$x, y=$y")
                    }
                },
                handler
            )
        } catch (e: Exception) {
            Log.e(TAG, "Exception during dispatchGesture: ${e.message}", e)
            false
        }
        if (dispatched) {
            Log.d(TAG, "Dispatched ${if (hold) "hold" else "tap"} at ($x, $y) successfully!")
        } else {
            Log.e(TAG, "Dispatched ${if (hold) "hold" else "tap"} at ($x, $y) failed.")
        }
    }
    private fun performSwipe(
        startX: Float,
        startY: Float,
        endX: Float,
        endY: Float,
        durationMs: Long = 500L // Default swipe duration
    ) {
        val builder = GestureDescription.Builder()

        val path = Path().apply {
            moveTo(startX, startY)
            lineTo(endX, endY)
        }

        val stroke = GestureDescription.StrokeDescription(path, 0, durationMs)
        val gesture = builder
            .addStroke(stroke)
            .build()

        val handler = Handler(Looper.getMainLooper())
        val dispatched = try {
            dispatchGesture(
                gesture,
                object : GestureResultCallback() {
                    override fun onCompleted(gestureDescription: GestureDescription?) {
                        Log.d(TAG, "Swipe completed from ($startX, $startY) to ($endX, $endY)")
                    }

                    override fun onCancelled(gestureDescription: GestureDescription?) {
                        Log.e(TAG, "Swipe cancelled from ($startX, $startY) to ($endX, $endY)")
                    }
                },
                handler
            )
        } catch (e: Exception) {
            Log.e(TAG, "Exception during swipe gesture: ${e.message}", e)
            false
        }

        if (dispatched) {
            Log.d(TAG, "Dispatched swipe from ($startX, $startY) to ($endX, $endY) successfully!")
        } else {
            Log.e(TAG, "Dispatched swipe from ($startX, $startY) to ($endX, $endY) failed.")
        }
    }

    // Convenience function for directional swipes
    enum class SwipeDirection { UP, DOWN, LEFT, RIGHT }

    fun performDirectionalSwipe(
        startX: Float,
        startY: Float,
        distance: Float = 400f, // Default swipe distance
        direction: SwipeDirection,
        durationMs: Long = 500L,
        speedFactor: Float = 1.0f,
    ) {
        val (endX, endY) = when (direction) {
            SwipeDirection.UP -> startX to startY - distance
            SwipeDirection.DOWN -> startX to startY + distance
            SwipeDirection.LEFT -> startX - distance to startY
            SwipeDirection.RIGHT -> startX + distance to startY
        }

        performSwipe(startX, startY, endX, endY, durationMs)
    }

    private fun AccessibilityService.openAppByName(appName: String) {
        Log.d(TAG, "Attempting to open app: $appName")
        val packageManager = packageManager
        val intent: Intent? = try {
            // Simple mapping of common app names to package names
            val packageName = when (appName.lowercase()) {
                "calculator" -> "advanced.scientific.calculator.calc991.plus"
                "calendar" -> "com.samsung.android.calendar"
                "settings" -> "com.android.settings"
                "chrome" -> "com.android.chrome"
                "youtube" -> "com.google.android.youtube"
                "gallery" -> "com.google.android.gallery3d"


                else -> {
                    // Try to find the app by display name
                    packageManager.getLaunchIntentForPackage(appName.lowercase())
                        ?.let { return@let appName.lowercase() }
                        ?: run {
                            // Search for app by name (approximate match)
                            packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
                                .find { it.loadLabel(packageManager).toString().lowercase().contains(appName.lowercase()) }
                                ?.packageName
                        }
                }
            }
            if (packageName != null) {
                packageManager.getLaunchIntentForPackage(packageName)
            } else {
                Log.e(TAG, "No package found for app name: $appName")
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error resolving app: ${e.message}", e)
            null
        }

        intent?.let {
            Log.d(TAG, "Launching intent for app: $appName with package: ${it.component?.packageName}")
            it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            try {
                startActivity(it)
                Log.d(TAG, "Successfully launched app: $appName")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start activity for app: $appName, error: ${e.message}", e)
            }
        } ?: Log.e(TAG, "No valid intent to launch app: $appName")
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
                "tap", "press", "open" -> performTouch(x, y)
                "hold", "long tap", "long press" -> performTouch(x, y, true)
                "swipe left" -> performDirectionalSwipe(x, y, 500f, SwipeDirection.LEFT, 500L, 1.5f)
                "swipe right" -> performDirectionalSwipe(x, y, 500f, SwipeDirection.RIGHT, 500L, 1.5f)
                "swipe up" -> performDirectionalSwipe(x, y, 500f, SwipeDirection.UP, 500L, 1.5f)
                "swipe down" -> performDirectionalSwipe(x, y, 500f, SwipeDirection.DOWN, 500L, 1.5f)
                "back", "go back" -> performGlobalAction(1)
                "home" -> performGlobalAction(2)
                "notifications" -> performGlobalAction(3)
                "calendar", "open calendar" -> openAppByName("calendar")
                "calculator", "open calculator" -> openAppByName("calculator")
                "settings", "open settings" -> openAppByName("settings")

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

