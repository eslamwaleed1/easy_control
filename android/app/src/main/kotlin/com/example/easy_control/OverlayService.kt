package com.example.easy_control

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.util.Log
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import androidx.lifecycle.Observer

class OverlayService : Service() {
    private var windowManager: WindowManager? = null
    private var overlayView: FrameLayout? = null
    private var dotView: DotView? = null
    private var stopButton: Button? = null
    private var isRunning = false
    private val TAG = "OverlayService"

    // For voice recognition & gesture simulation:
    private val NOTIFICATION_ID = 2
    private val CHANNEL_ID = "OverlayServiceChannel"
    private var currentX: Float = 0f
    private var currentY: Float = 0f

    private val knownCommands = listOf("tap")
    private val recognizedWordObserver = Observer<String> { recognizedWord ->
        val word = recognizedWord.lowercase()
        Log.d(TAG, "Received recognized word: $word")
        if (word in knownCommands) {
            Log.d(TAG, "Command matched: $word at ($currentX, $currentY)")
            // Send (x, y) to GestureService to simulate tap
            val gestureIntent = Intent(this@OverlayService, GestureService::class.java).apply {
                putExtra("command", word)
                putExtra("x", currentX)
                putExtra("y", currentY)
            }
            startService(gestureIntent)
        }
    }
    // ----------------------

    override fun onBind(intent: Intent?): IBinder? = null

    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    override fun onCreate() {
        super.onCreate()

        // For voice recognition & gesture simulation:
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        // ----------------------
        if (isRunning) {
            //Log.d(TAG, "OverlayService already running, skipping onCreate")
            return
        }
        //Log.d(TAG, "OverlayService created")
        isRunning = true

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        overlayView = FrameLayout(this).apply {
            setBackgroundColor(Color.TRANSPARENT)
        }

        stopButton = Button(this).apply {
            text = "Stop Overlay"
            setBackgroundColor(Color.BLACK)
            setTextColor(Color.WHITE)
            textSize = 12f
            val params = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.TOP or Gravity.END
                setMargins(16, 16, 16, 16)
            }
            layoutParams = params
            setOnClickListener {
                //Log.d(TAG, "Stop button clicked")
                stopSelf()
            }
        }

        dotView = DotView(this).apply {
            setDotColor(Color.RED)
        }

        // Add views to overlay
        overlayView?.addView(dotView)
        overlayView?.addView(stopButton)

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )

        try {
            windowManager?.addView(overlayView, params)
            //Log.d(TAG, "Overlay added successfully")
        } catch (e: Exception) {
            //Log.e(TAG, "Failed to add overlay: $e")
            stopSelf()
        }

        // For voice recognition & gesture simulation:
        setupXYReceiver()
        SpeechRecognitionLiveData.recognizedWord.observeForever(recognizedWordObserver)
        // -------------------------------------------
    }

    // For voice reco. & gesture simulation:
    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    private fun setupXYReceiver() {
        // Placeholder for receiving (x, y) pairs from MainActivity
        // This should already be implemented in your app
        val xyReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                currentX = intent?.getFloatExtra("x", 0f) ?: 0f
                currentY = intent?.getFloatExtra("y", 0f) ?: 0f
                Log.d(TAG, "Received (x, y): ($currentX, $currentY)")
            }
        }
        val xyFilter = IntentFilter("com.example.easy_control.XY_UPDATE")
        registerReceiver(xyReceiver, xyFilter, RECEIVER_NOT_EXPORTED)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Overlay Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Channel for overlay service"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Overlay Service")
            .setContentText("Overlay active...")
            //.setSmallIcon(android.R.drawable.ic_notification_active)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
    // -------------------------

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!isRunning) {
            //Log.d(TAG, "Service not running, ignoring onStartCommand")
            return START_NOT_STICKY
        }

        intent?.let {
            when (it.action) {
                "UPDATE_GAZE" -> {
                    val x = it.getFloatExtra("x", 0f)
                    val y = it.getFloatExtra("y", 0f)
                    val isCalibrated = it.getBooleanExtra("isCalibrated", false)
                    val screenState = it.getStringExtra("screenState")!!
                    //Log.d(TAG, "Updating dot: ($x, $y), Calibrated: $isCalibrated, ScreenState: $screenState.")
                    dotView?.updateDot(x, y, isCalibrated, screenState)
                }

                else -> {}
            }
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            windowManager?.removeView(overlayView)
            SpeechRecognitionLiveData.recognizedWord.removeObserver(recognizedWordObserver)
            stopForeground(true)
            //Log.d(TAG, "Overlay removed successfully")
        } catch (e: Exception) {
            //Log.e(TAG, "Failed to remove overlay: $e")
        }
        overlayView = null
        dotView = null
        stopButton = null
        windowManager = null
        isRunning = false
        //Log.d(TAG, "OverlayService destroyed")
    }
}