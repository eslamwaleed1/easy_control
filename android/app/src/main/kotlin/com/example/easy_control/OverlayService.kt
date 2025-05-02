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
    private val knownCommands = listOf("open")

    private val recognizedWordObserver = Observer<String> { recognizedWord ->
        Log.d(TAG, "Received recognized word from LiveData: $recognizedWord")
        val word = recognizedWord?.lowercase()?.trim() ?: return@Observer
        Log.d(TAG, "Normalized word: $word")
        val matchedCommand = knownCommands.find { word.contains(it) }
        if (matchedCommand != null) {
            Log.d(TAG, "Command matched: $matchedCommand at ($currentX, $currentY)")
            val gestureIntent = Intent(this@OverlayService, GestureService::class.java).apply {
                putExtra("command", matchedCommand)
                if(currentX < 1050f || currentX > 75f) {
                    putExtra("x", currentX)
                }
                else putExtra("x", 500f)
                if(currentY < 2290f || currentY > 108f) {
                    putExtra("y", currentY)
                }
                else putExtra("y", 500f)

//                putExtra("x", 530f)
//                putExtra("y", 2050f)
//                putExtra("x", 500f)
//                putExtra("y", 500f)
            }
            Log.d(TAG, "Sending intent to GestureService with command: $matchedCommand, x: $currentX, y: $currentY")
            startService(gestureIntent)
            Log.d(TAG, "Intent sent to GestureService")
        } else {
            Log.d(TAG, "No command matched in text: $word, known commands: $knownCommands")
        }
    }
    // ----------------------

    override fun onBind(intent: Intent?): IBinder? = null

    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    override fun onCreate() {
        super.onCreate()

        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())

        if (isRunning) {
            return
        }
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
                stopSelf()
            }
        }

        dotView = DotView(this).apply {
            setDotColor(Color.RED)
        }

//        dot1 = CalmDot(this)
//        dot2 = CalmDot(this)
//        dot3 = CalmDot(this)
//        dot4 = CalmDot(this)
//        dot5 = CalmDot(this)
//        dot6 = CalmDot(this)
//        dot7 = CalmDot(this)
//
//
//        // Based on Phone's direct coordinates.
//        dot1?.setSpec(100f, 100f, "white")    // Near the start.
//        dot2?.setSpec(540f, 1200f, "white")  // At the center.
//        dot3?.setSpec(1000f, 2300f, "white") // Almost near the end.
//        dot7?.setSpec(540f, 2150f, "white") // At the home button.
//
//        // Based on Eyedid post-scaled coordinates.
//        dot4?.setSpec(100f, 100f, "blue")
//        // 108 & 180
//
//        dot5?.setSpec(540f, 1097f, "blue")
//        // 550 & 1171
//
//        dot6?.setSpec(980f, 2094f, "blue")



        overlayView?.addView(dotView)
//        overlayView?.addView(dot1)
//        overlayView?.addView(dot2)
//        overlayView?.addView(dot3)
//        overlayView?.addView(dot4)
//        overlayView?.addView(dot5)
//        overlayView?.addView(dot6)
//        overlayView?.addView(dot7)
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
        } catch (e: Exception) {
            stopSelf()
        }

        SpeechRecognitionLiveData.recognizedWord.observeForever(recognizedWordObserver)

        // Test: Queue a tap at the center of the screen after a 5-second delay
//        Handler(Looper.getMainLooper()).postDelayed({
//            Log.d(TAG, "Queuing hardcoded tap command at (540.0, 960.0)")
//            GestureService.queueGesture("press", 540f, 960f)
//            val gestureIntent = Intent(this@OverlayService, GestureService::class.java).apply {
//                putExtra("command", "press")
//                putExtra("x", 540f)
//                putExtra("y", 960f)
//            }
//            startService(gestureIntent)
//        }, 5000)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!isRunning) {
            return START_NOT_STICKY
        }



        intent?.let {
            when (it.action) {
                "UPDATE_GAZE" -> {
                    val x = it.getFloatExtra("x", 0f)
                    val y = it.getFloatExtra("y", 0f)
                    currentX = x
                    currentY = y
                    val isCalibrated = it.getBooleanExtra("isCalibrated", false)
                    val screenState = it.getStringExtra("screenState")!!
                    Log.d(TAG, "Updating dot: ($x, $y), Calibrated: $isCalibrated, ScreenState: $screenState")
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
            // Remove unregisterReceiver since we're not using the BroadcastReceiver
            stopForeground(true)
            Log.d(TAG, "Overlay service destroyed")
        } catch (e: Exception) {
            //Log.e(TAG, "Failed to remove overlay: $e")
        }
        overlayView = null
        dotView = null
//        dot1 = null
//        dot2 = null
//        dot3 = null
//        dot4 = null
//        dot5 = null
//        dot6 = null
//        dot7 = null
        stopButton = null
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