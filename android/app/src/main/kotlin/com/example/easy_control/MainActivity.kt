package com.example.easy_control

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.easy_control/overlay"
    private val OVERLAY_PERMISSION_REQUEST_CODE = 1001
    private val TAG = "MainActivity"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val channel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startOverlay" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST_CODE)
                        result.success(false)
                    } else {
                        startService(Intent(this, OverlayService::class.java))
                        result.success(true)
                    }
                }
                "stopOverlay" -> {
                    stopService(Intent(this, OverlayService::class.java))
                    result.success(true)
                }
                "updateGaze" -> {
                    val rawX = call.argument<Double>("x")?.toFloat() ?: 0f
                    val rawY = call.argument<Double>("y")?.toFloat() ?: 0f
                    val isCalibrated = call.argument<Boolean>("isCalibrated") ?: false
                    val screenState = call.argument<String>("screenState") ?: "unknown"
                    Log.d(TAG, "Sending gaze update: ($rawX, $rawY), calibrated: $isCalibrated, state: $screenState")
                    val intent = Intent(this, OverlayService::class.java).apply {
                        action = "UPDATE_GAZE"
                        putExtra("x", rawX)
                        putExtra("y", rawY)
                        putExtra("isCalibrated", isCalibrated)
                        putExtra("screenState", screenState)
                    }
                    startService(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == OVERLAY_PERMISSION_REQUEST_CODE) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && Settings.canDrawOverlays(this)) {
                //Log.d(TAG, "Overlay permission granted, starting OverlayService")
                startService(Intent(this, OverlayService::class.java))
            } else {
                //Log.d(TAG, "Overlay permission denied")
            }
        }
    }

    // For voice recognition:
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Start the speech recognition service
        val serviceIntent = Intent(this, SpeechRecognitionService::class.java)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }
    // -----------------------
}