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


    private var maxX: Float = 1.0f
    private var minX: Float = 1.0f
    private var maxY: Float = 1.0f
    private var minY: Float = 1.0f

    private var maxXWithSuccess: Float = 1.0f
    private var minXWithSuccess: Float = 1.0f
    private var maxYWithSuccess: Float = 1.0f
    private var minYWithSuccess: Float = 1.0f


//    private var gazeMinX = Float.MAX_VALUE
//    private var gazeMinY = Float.MAX_VALUE
//    private var gazeMaxX = -Float.MAX_VALUE
//    private var gazeMaxY = -Float.MAX_VALUE
//    private val gazeRangeX: Float
//        get() = if (gazeMaxX > gazeMinX) gazeMaxX - gazeMinX else 0f
//    private val gazeRangeY: Float
//        get() = if (gazeMaxY > gazeMinY) gazeMaxY - gazeMinY else 0f
//    private val normalizedX = (x - gazeMinX) / gazeRangeX
//    private val normalizedY = (y - gazeMinY) / gazeRangeY

    // SM-Width: 1080.0F    SM-Height: 2194.0F.
    // Eyedid starts with Width then Height.

    //private val scale: Float = min(1080.0F / 1280.0F, 2194.0F / 720.0F);
    //private val offsetX = (screenWidth - 1280 * scale) / 2
    //private val offsetY = (screenHeight - 720 * scale) / 2



    //private val displayMetrics: DisplayMetrics = context.resources.displayMetrics
    //private val screenWidth = displayMetrics.widthPixels
    //private val screenHeight = displayMetrics.heightPixels


    fun setDotColor(color: Int) {
        dotColor = color
        invalidate()
    }

    fun updateDot(x: Float, y: Float, isCalibrated: Boolean, screenState: String) {
        // Awesome
//        this.x = (x / 540f) * 1080f
//        this.y = (y / 1097f) * 2194f

        this.x = x;
        this.y = y;

        this.x = this.x.coerceIn(0f, 1080.0F)
        this.y = this.y.coerceIn(0f, 2194.0F)




//
//        if(x > maxX) maxX = x
//        if(x < minX) minX = x
//        if(y > maxY) maxY = y
//        if(y < minY) minY = y
//
//        if (isCalibrated && screenState == "inside") {
//            if(x > maxXWithSuccess) maxXWithSuccess = x
//            if(x < minXWithSuccess) minXWithSuccess = x
//            if(y > maxYWithSuccess) maxYWithSuccess = y
//            if(y < minYWithSuccess) minYWithSuccess = y
//        }


        setDotColor(if (isCalibrated) Color.GREEN else Color.RED)
        //Log.d("DotView", "Updating dot to ($x, $y) -> Screen ($this.x, $this.y), Calibrated: $isCalibrated, ScreenState: $screenState")
        //Log.d("DotView", "max X: $maxX, minX: $minX, maxY: $maxY, minY: $minY, sucMaxX: $maxXWithSuccess, sucMinX: $minXWithSuccess, sucMaxY: $maxYWithSuccess, sucMinY: $minYWithSuccess, ")
    }


    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        paint.color = dotColor
        canvas.drawCircle(x, y, dotRadius, paint)
    }
}