package com.example.easy_control

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import androidx.core.app.NotificationCompat

class SpeechRecognitionService : Service() {
    private val TAG = "SpeechRecognitionService"
    private var speechRecognizer: SpeechRecognizer? = null
    private var recognizerIntent: Intent? = null
    private val NOTIFICATION_ID = 1
    private val CHANNEL_ID = "SpeechRecognitionChannel"
    private var isListening = false

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")
        setupSpeechRecognizer()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        startListening()
    }

    private fun setupSpeechRecognizer() {
        // Check if SpeechRecognizer is available
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            Log.e(TAG, "Speech recognition not available on this device")
            stopSelf() // Stop the service if recognition isn't available
            return
        }

        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        if (speechRecognizer == null) {
            Log.e(TAG, "Failed to create SpeechRecognizer")
            stopSelf()
            return
        }
        Log.d(TAG, "SpeechRecognizer created successfully")

        recognizerIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, packageName)
            // Removed EXTRA_PREFER_OFFLINE to improve compatibility; use online if needed
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 10000L) // 10 seconds
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 2000L) // 2 seconds
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 2000L) // 2 seconds
        }

        speechRecognizer?.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                Log.d(TAG, "Ready for speech")
                isListening = true
            }

            override fun onBeginningOfSpeech() {
                Log.d(TAG, "Beginning of speech")
            }

            override fun onRmsChanged(rmsdB: Float) {
                // Optional: Log for debugging audio levels
                //Log.v(TAG, "RMS changed: $rmsdB")
            }

            override fun onBufferReceived(buffer: ByteArray?) {
                //Log.d(TAG, "Buffer received, length: ${buffer?.size ?: 0}")
            }

            override fun onEndOfSpeech() {
                Log.d(TAG, "End of speech")
                isListening = false
                Handler(Looper.getMainLooper()).postDelayed({
                    if (!isListening) startListening()
                }, 1000) // Reduced delay to 1 second for faster restart
            }

            override fun onError(error: Int) {
                val errorMsg = when (error) {
                    SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
                    SpeechRecognizer.ERROR_CLIENT -> "Client side error"
                    SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
                    SpeechRecognizer.ERROR_NETWORK -> "Network error"
                    SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
                    SpeechRecognizer.ERROR_NO_MATCH -> "No match"
                    SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognizer busy"
                    SpeechRecognizer.ERROR_SERVER -> "Server error"
                    SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "Speech timeout"
                    else -> "Unknown error: $error"
                }
                Log.e(TAG, "Speech recognition error: $errorMsg")
                isListening = false
                Handler(Looper.getMainLooper()).postDelayed({
                    if (!isListening) startListening()
                }, 2000)
            }

            override fun onResults(results: Bundle?) {
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                matches?.firstOrNull()?.let { text ->
                    Log.d(TAG, "Heard (final): $text")
                    Log.d(TAG, "Posting to LiveData: $text")
                    SpeechRecognitionLiveData.postRecognizedWord(text)
                } ?: Log.w(TAG, "No matches in final results")
            }

            override fun onPartialResults(partialResults: Bundle?) {
                Log.d(TAG, "Partial results received (ignored)")
            }

            override fun onEvent(eventType: Int, params: Bundle?) {
                Log.d(TAG, "Event: $eventType")
            }
        })
    }

    private fun startListening() {
        if (speechRecognizer == null) {
            Log.e(TAG, "SpeechRecognizer is null, reinitializing")
            setupSpeechRecognizer()
            if (speechRecognizer == null) {
                Log.e(TAG, "Failed to reinitialize SpeechRecognizer, stopping service")
                stopSelf()
                return
            }
        }
        try {
            if (!isListening) {
                speechRecognizer?.startListening(recognizerIntent)
                Log.d(TAG, "Started listening")
            } else {
                Log.w(TAG, "Already listening, skipping start")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error starting listening: ${e.message}", e)
            isListening = false
            Handler(Looper.getMainLooper()).postDelayed({
                if (!isListening) startListening()
            }, 2000)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Speech Recognition Service",
                NotificationManager.IMPORTANCE_DEFAULT // Increased to DEFAULT for better visibility
            ).apply {
                description = "Channel for speech recognition service"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Speech Recognition")
            .setContentText("Listening for speech...")
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand called")
        return START_STICKY
    }

    override fun onDestroy() {
        speechRecognizer?.stopListening()
        speechRecognizer?.destroy()
        speechRecognizer = null
        isListening = false
        stopForeground(true)
        Log.d(TAG, "Service destroyed")
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): Nothing? {
        return null
    }
}
//package com.example.easy_control
//
//import android.app.Notification
//import android.app.NotificationChannel
//import android.app.NotificationManager
//import android.app.Service
//import android.content.Intent
//import android.os.Build
//import android.os.Bundle
//import android.os.Handler
//import android.os.Looper
//import android.speech.RecognitionListener
//import android.speech.RecognizerIntent
//import android.speech.SpeechRecognizer
//import android.util.Log
//import androidx.core.app.NotificationCompat
//
//class SpeechRecognitionService : Service() {
//    private val TAG = "SpeechRecognitionService"
//    private var speechRecognizer: SpeechRecognizer? = null
//    private var recognizerIntent: Intent? = null
//    private val NOTIFICATION_ID = 1
//    private val CHANNEL_ID = "SpeechRecognitionChannel"
//    private var isListening = false
//
//    override fun onCreate() {
//        super.onCreate()
//        Log.d(TAG, "Service created")
//        setupSpeechRecognizer()
//        createNotificationChannel()
//        startForeground(NOTIFICATION_ID, createNotification())
//        startListening()
//    }
//
//    private fun setupSpeechRecognizer() {
//        // Check if SpeechRecognizer is available
//        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
//            Log.e(TAG, "Speech recognition not available on this device")
//            stopSelf() // Stop the service if recognition isn't available
//            return
//        }
//
//        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
//        if (speechRecognizer == null) {
//            Log.e(TAG, "Failed to create SpeechRecognizer")
//            stopSelf()
//            return
//        }
//        Log.d(TAG, "SpeechRecognizer created successfully")
//
//        recognizerIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
//            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
//            putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, packageName)
//            // Removed EXTRA_PREFER_OFFLINE to improve compatibility; use online if needed
//            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 10000L) // 10 seconds
//            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 2000L) // 2 seconds
//            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 2000L) // 2 seconds
//        }
//
//        speechRecognizer?.setRecognitionListener(object : RecognitionListener {
//            override fun onReadyForSpeech(params: Bundle?) {
//                Log.d(TAG, "Ready for speech")
//                isListening = true
//            }
//
//            override fun onBeginningOfSpeech() {
//                Log.d(TAG, "Beginning of speech")
//            }
//
//            override fun onRmsChanged(rmsdB: Float) {
//                // Optional: Log for debugging audio levels
//                Log.v(TAG, "RMS changed: $rmsdB")
//            }
//
//            override fun onBufferReceived(buffer: ByteArray?) {
//                Log.d(TAG, "Buffer received, length: ${buffer?.size ?: 0}")
//            }
//
//            override fun onEndOfSpeech() {
//                Log.d(TAG, "End of speech")
//                isListening = false
//                Handler(Looper.getMainLooper()).postDelayed({
//                    if (!isListening) startListening()
//                }, 1000) // Reduced delay to 1 second for faster restart
//            }
//
//            override fun onError(error: Int) {
//                val errorMsg = when (error) {
//                    SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
//                    SpeechRecognizer.ERROR_CLIENT -> "Client side error"
//                    SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
//                    SpeechRecognizer.ERROR_NETWORK -> "Network error"
//                    SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
//                    SpeechRecognizer.ERROR_NO_MATCH -> "No match"
//                    SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognizer busy"
//                    SpeechRecognizer.ERROR_SERVER -> "Server error"
//                    SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "Speech timeout"
//                    else -> "Unknown error: $error"
//                }
//                Log.e(TAG, "Speech recognition error: $errorMsg")
//                isListening = false
//                Handler(Looper.getMainLooper()).postDelayed({
//                    if (!isListening) startListening()
//                }, 2000)
//            }
//
//            override fun onResults(results: Bundle?) {
//                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
//                matches?.firstOrNull()?.let { text ->
//                    Log.d(TAG, "Heard (final): $text")
//                    Log.d(TAG, "Posting to LiveData: $text")
//                    SpeechRecognitionLiveData.postRecognizedWord(text)
//                } ?: Log.w(TAG, "No matches in final results")
//            }
//
//            override fun onPartialResults(partialResults: Bundle?) {
//                Log.d(TAG, "Partial results received (ignored)")
//            }
//
//            override fun onEvent(eventType: Int, params: Bundle?) {
//                Log.d(TAG, "Event: $eventType")
//            }
//        })
//    }
//
//    private fun startListening() {
//        if (speechRecognizer == null) {
//            Log.e(TAG, "SpeechRecognizer is null, reinitializing")
//            setupSpeechRecognizer()
//            if (speechRecognizer == null) {
//                Log.e(TAG, "Failed to reinitialize SpeechRecognizer, stopping service")
//                stopSelf()
//                return
//            }
//        }
//        try {
//            if (!isListening) {
//                speechRecognizer?.startListening(recognizerIntent)
//                Log.d(TAG, "Started listening")
//            } else {
//                Log.w(TAG, "Already listening, skipping start")
//            }
//        } catch (e: Exception) {
//            Log.e(TAG, "Error starting listening: ${e.message}", e)
//            isListening = false
//            Handler(Looper.getMainLooper()).postDelayed({
//                if (!isListening) startListening()
//            }, 2000)
//        }
//    }
//
//    private fun createNotificationChannel() {
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//            val channel = NotificationChannel(
//                CHANNEL_ID,
//                "Speech Recognition Service",
//                NotificationManager.IMPORTANCE_DEFAULT // Increased to DEFAULT for better visibility
//            ).apply {
//                description = "Channel for speech recognition service"
//            }
//            val manager = getSystemService(NotificationManager::class.java)
//            manager.createNotificationChannel(channel)
//        }
//    }
//
//    private fun createNotification(): Notification {
//        return NotificationCompat.Builder(this, CHANNEL_ID)
//            .setContentTitle("Speech Recognition")
//            .setContentText("Listening for speech...")
//            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
//            .build()
//    }
//
//    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
//        Log.d(TAG, "onStartCommand called")
//        return START_STICKY
//    }
//
//    override fun onDestroy() {
//        speechRecognizer?.stopListening()
//        speechRecognizer?.destroy()
//        speechRecognizer = null
//        isListening = false
//        stopForeground(true)
//        Log.d(TAG, "Service destroyed")
//        super.onDestroy()
//    }
//
//    override fun onBind(intent: Intent?): Nothing? {
//        return null
//    }
//}