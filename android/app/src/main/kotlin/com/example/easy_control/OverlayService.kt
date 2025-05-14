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
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import androidx.lifecycle.Observer

class OverlayService : Service() {
    private var stopButtonView: FrameLayout? = null
    private var windowManager: WindowManager? = null
    private var overlayView: FrameLayout? = null
    private var dotView: DotView? = null
    //    private var dot1: CalmDot? = null
//    private var dot2: CalmDot? = null
//    private var dot3: CalmDot? = null
//    private var dot4: CalmDot? = null
//    private var dot5: CalmDot? = null
//    private var dot6: CalmDot? = null
//    private var dot7: CalmDot? = null
    private var stopButton: Button? = null
    private var isRunning = false
    private val TAG = "OverlayService"

    // For voice recognition & gesture simulation:
    private val NOTIFICATION_ID = 2
    private val CHANNEL_ID = "OverlayServiceChannel"
    private var currentX: Float = 0f
    private var currentY: Float = 0f
    private lateinit var xyReceiver: BroadcastReceiver
    private val knownCommands = listOf("open","disable")

    private val recognizedWordObserver = Observer<String> { recognizedWord ->
        val word = recognizedWord?.lowercase()?.trim() ?: return@Observer
        val matchedCommand = knownCommands.find { word.contains(it) }
        if (matchedCommand != null) {
            when (matchedCommand) {
                "open" -> {
                    val displayMetrics = resources.displayMetrics
                    val safeX = currentX.coerceIn(75f, displayMetrics.widthPixels.toFloat() - 75f)
                    val safeY = currentY.coerceIn(108f, displayMetrics.heightPixels.toFloat() - 108f)
                    val gestureIntent = Intent(this@OverlayService, GestureService::class.java).apply {
                        putExtra("command", matchedCommand)
                        putExtra("x", safeX)
                        putExtra("y", safeY)
                    }
                    startService(gestureIntent)
                }
                "disable" -> {
                    stopSelf()
                }
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        if (isRunning) return
        isRunning = true

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        overlayView = FrameLayout(this).apply {
            setBackgroundColor(Color.TRANSPARENT)
        }

        dotView = DotView(this).apply {
            setDotColor(Color.RED)
        }

        stopButtonView = FrameLayout(this)
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
            setOnClickListener { stopSelf() }
        }
        stopButtonView?.addView(stopButton)

        val displayMetrics = resources.displayMetrics
        val screenWidth = displayMetrics.widthPixels.toFloat()
        val screenHeight = displayMetrics.heightPixels.toFloat()

        val overlayParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )

        val buttonParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.END
        }

        try {
            windowManager?.addView(overlayView, overlayParams)
            windowManager?.addView(stopButtonView, buttonParams)
            overlayView?.addView(dotView)
        } catch (e: Exception) {
            stopSelf()
        }

        SpeechRecognitionLiveData.recognizedWord.observeForever(recognizedWordObserver)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!isRunning) return START_NOT_STICKY
        intent?.let {
            when (it.action) {
                "UPDATE_GAZE" -> {
                    val displayMetrics = resources.displayMetrics
                    val screenWidth = displayMetrics.widthPixels.toFloat()
                    val screenHeight = displayMetrics.heightPixels.toFloat()
                    // Assume input x is in range 0 to 540, y is in range 0 to 1097
                    val rawX = it.getFloatExtra("x", 0f).coerceIn(0f, 540f)
                    val rawY = it.getFloatExtra("y", 0f).coerceIn(0f, 1097f)
                    // Scale to screen dimensions
                    val scaledX = (rawX / 540f) * screenWidth
                    val scaledY = (rawY / 1097f) * screenHeight
                    if (scaledX == currentX && scaledY == currentY) return@let
                    currentX = scaledX
                    currentY = scaledY
                    val isCalibrated = it.getBooleanExtra("isCalibrated", false)
                    val screenState = it.getStringExtra("screenState") ?: "unknown"
                    Log.d(TAG, "Updating dot to ($scaledX, $scaledY), calibrated: $isCalibrated, state: $screenState")
                    dotView?.updateDot(scaledX, scaledY, isCalibrated, screenState)
                }
            }
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            windowManager?.removeView(overlayView)
            windowManager?.removeView(stopButtonView)
            SpeechRecognitionLiveData.recognizedWord.removeObserver(recognizedWordObserver)
            stopForeground(true)
        } catch (e: Exception) {}
        overlayView = null
        dotView = null
        stopButton = null
        stopButtonView = null
        windowManager = null
        isRunning = false
    }

    // For voice recognition & gesture simulation:
    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    private fun setupXYReceiver() {
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
}