package com.example.easy_control

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.util.DisplayMetrics
import android.util.Log
import android.view.View
import java.lang.Float.min

class DotView(context: Context) : View(context) {
    private val paint = Paint().apply {
        isAntiAlias = true
    }
    private var x: Float = 0f
    private var y: Float = 0f
    private var dotColor: Int = Color.RED
    private val dotRadius = 20f

    private val displayMetrics: DisplayMetrics = context.resources.displayMetrics
    private val screenWidth = displayMetrics.widthPixels.toFloat()
    private val screenHeight = displayMetrics.heightPixels.toFloat()

    fun setDotColor(color: Int) {
        dotColor = color
        invalidate()
    }

    fun updateDot(x: Float, y: Float, isCalibrated: Boolean, screenState: String) {
        // Coerce coordinates to screen dimensions
        this.x = x.coerceIn(0f, screenWidth)
        this.y = y.coerceIn(0f, screenHeight)

        setDotColor(if (isCalibrated) Color.GREEN else Color.RED)
        Log.d("DotView", "Updating dot to ($x, $y), Calibrated: $isCalibrated, ScreenState: $screenState, Screen: ($screenWidth, $screenHeight)")
        invalidate()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        paint.color = dotColor
        canvas.drawCircle(x, y, dotRadius, paint)
    }
}