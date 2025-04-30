package com.example.easy_control

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Intent
import android.graphics.Path
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class GestureService : AccessibilityService() {
    private val TAG = "GestureService"

    companion object {
        const val TAP_DURATION_MS = 50L // Duration of a tap in milliseconds
    }

    override fun onServiceConnected() {
        Log.d(TAG, "GestureService connected")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.let {
            val command = it.getStringExtra("command")?.lowercase()
            val x = it.getFloatExtra("x", 0f)
            val y = it.getFloatExtra("y", 0f)
            Log.d(TAG, "Received command: $command at ($x, $y)")

            when (command) {
                "tap" -> simulateTap(x, y)
                // Add more gestures (e.g., "swipe") in the future
            }
        }
        return START_NOT_STICKY
    }

    private fun simulateTap(x: Float, y: Float) {
        try {
            val path = Path().apply {
                moveTo(x, y)
                lineTo(x, y) // A tap is a single point, so start and end are the same
            }

            val stroke = GestureDescription.StrokeDescription(
                path,
                0L, // Start time
                TAP_DURATION_MS // Duration of the tap
            )

            val gesture = GestureDescription.Builder()
                .addStroke(stroke)
                .build()

            val dispatched = dispatchGesture(gesture, object : GestureResultCallback() {
                override fun onCompleted(gestureDescription: GestureDescription?) {
                    Log.d(TAG, "Tap gesture completed at ($x, $y)")
                }

                override fun onCancelled(gestureDescription: GestureDescription?) {
                    Log.e(TAG, "Tap gesture cancelled at ($x, $y)")
                }
            }, null)

            if (!dispatched) {
                Log.e(TAG, "Failed to dispatch tap gesture at ($x, $y)")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error simulating tap: ${e.message}")
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Not used for now, but required to override
    }

    override fun onInterrupt() {
        Log.d(TAG, "GestureService interrupted")
    }

    override fun onDestroy() {
        Log.d(TAG, "GestureService destroyed")
        super.onDestroy()
    }
}