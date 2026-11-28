package com.anamm.mylibrary.widget

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BitmapShader
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import java.io.File

/** Bitmaps for the parts RemoteViews can't style on every Android version. */
object WidgetBitmaps {
    private const val COVER_W_DP = 72f
    private const val COVER_H_DP = 108f

    fun cover(path: String?, title: String, colors: WidgetColors, density: Float): Bitmap {
        val w = (COVER_W_DP * density).toInt()
        val h = (COVER_H_DP * density).toInt()
        val source = path?.let { decode(it, w, h) }
        val out = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(out)
        val rect = RectF(0f, 0f, w.toFloat(), h.toFloat())
        val radius = 8f * density
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        if (source != null) {
            val scale = maxOf(w / source.width.toFloat(), h / source.height.toFloat())
            val matrix = Matrix().apply {
                setScale(scale, scale)
                postTranslate((w - source.width * scale) / 2f, (h - source.height * scale) / 2f)
            }
            paint.shader = BitmapShader(source, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP)
                .apply { setLocalMatrix(matrix) }
            canvas.drawRoundRect(rect, radius, radius, paint)
            return out
        }
        paint.color = colors.primary
        canvas.drawRoundRect(rect, radius, radius, paint)
        val text = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = colors.onPrimary
            textSize = 11f * density
            typeface = Typeface.DEFAULT_BOLD
        }
        val pad = (6 * density).toInt()
        @Suppress("DEPRECATION")
        val layout = StaticLayout(title, text, w - pad * 2, Layout.Alignment.ALIGN_NORMAL, 1f, 0f, false)
        canvas.save()
        canvas.translate(pad.toFloat(), (h - pad - layout.height).coerceAtLeast(pad).toFloat())
        layout.draw(canvas)
        canvas.restore()
        return out
    }

    fun progressBar(percent: Int, colors: WidgetColors, widthDp: Int, density: Float): Bitmap {
        val w = (widthDp * density).toInt().coerceAtLeast(1)
        val h = (6 * density).toInt().coerceAtLeast(1)
        val out = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(out)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val r = h / 2f
        paint.color = colors.track
        canvas.drawRoundRect(RectF(0f, 0f, w.toFloat(), h.toFloat()), r, r, paint)
        val filled = w * percent.coerceIn(0, 100) / 100f
        if (filled > 0) {
            paint.color = colors.primary
            canvas.drawRoundRect(RectF(0f, 0f, filled.coerceAtLeast(h.toFloat()), h.toFloat()), r, r, paint)
        }
        return out
    }

    fun decode(path: String, reqW: Int, reqH: Int): Bitmap? {
        val file = File(path)
        if (!file.exists()) return null
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
        var sample = 1
        while (bounds.outWidth / (sample * 2) >= reqW && bounds.outHeight / (sample * 2) >= reqH) sample *= 2
        return BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample })
    }

}
