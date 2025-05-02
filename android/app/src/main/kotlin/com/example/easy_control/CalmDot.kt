package com.example.easy_control

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.view.View

class CalmDot(context: Context) : View(context) {
    private val paint = Paint().apply {
        isAntiAlias = true
    }

    private var x: Float = 0f
    private var y: Float = 0f
    private var dotColor: Int = Color.RED
    private val dotRadius = 20f

    fun setSpec(x: Float, y: Float, color: String) {
        this.x = x;
        this.y = y;
        if(color == "white") setDotColorWhite(Color.WHITE)
        if(color == "blue") setDotColorBlue(Color.BLUE)
    }

    private fun setDotColorWhite(color: Int) {
        dotColor = color
        invalidate()
    }
    private fun setDotColorBlue(color: Int) {
        dotColor = color
        invalidate()
    }
    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        paint.color = dotColor
        canvas.drawCircle(x, y, dotRadius, paint)
    }
}