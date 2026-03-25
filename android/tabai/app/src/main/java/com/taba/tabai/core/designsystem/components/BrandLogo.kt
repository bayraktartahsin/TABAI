package com.taba.tabai.core.designsystem.components

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.Rect
import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.taba.tabai.R

private val brandColors = listOf(
    Color(0xFF3366FF),
    Color(0xFF7340F2),
    Color(0xFFB333BF),
    Color(0xFFE66680),
    Color(0xFFF29940),
    Color(0xFFF2CC4D),
    Color(0xFF3366FF),
)

private val brandColorsInt = intArrayOf(
    0xFF3366FF.toInt(),
    0xFF7340F2.toInt(),
    0xFFB333BF.toInt(),
    0xFFE66680.toInt(),
    0xFFF29940.toInt(),
    0xFFF2CC4D.toInt(),
    0xFF3366FF.toInt(),
)

/**
 * Animated brain logo — rotating sweep gradient visible ONLY through the brain wires.
 * iOS equivalent: AngularGradient masked by Image("TAILogo")
 *
 * How it works:
 * 1. Create an offscreen bitmap
 * 2. Draw a SweepGradient (rotating) onto it
 * 3. Apply the brain PNG as a mask using PorterDuff.Mode.DST_IN
 *    → gradient pixels survive only where brain image has opaque alpha
 * 4. Draw the result onto the Compose canvas
 */
@Composable
fun AnimatedBrandLogoSimple(size: Dp = 72.dp) {
    val context = LocalContext.current
    val maskBitmap = remember {
        BitmapFactory.decodeResource(context.resources, R.drawable.tai_logo)
    }

    val infiniteTransition = rememberInfiniteTransition(label = "logo")
    val angle by infiniteTransition.animateFloat(
        initialValue = 0f, targetValue = 360f,
        animationSpec = infiniteRepeatable(tween(6000, easing = LinearEasing)),
        label = "rotation",
    )

    val gradientPaint = remember { Paint(Paint.ANTI_ALIAS_FLAG) }
    val maskPaint = remember {
        Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG).apply {
            xfermode = PorterDuffXfermode(PorterDuff.Mode.DST_IN)
        }
    }

    Canvas(modifier = Modifier.size(size)) {
        val w = this.size.width.toInt()
        val h = this.size.height.toInt()
        if (w <= 0 || h <= 0) return@Canvas
        val cx = w / 2f
        val cy = h / 2f

        drawIntoCanvas { canvas ->
            val nativeCanvas = canvas.nativeCanvas

            // Save a transparent layer
            val layer = nativeCanvas.saveLayer(0f, 0f, w.toFloat(), h.toFloat(), null)

            // 1. Draw rotating sweep gradient
            gradientPaint.shader = android.graphics.SweepGradient(cx, cy, brandColorsInt, null).apply {
                val matrix = android.graphics.Matrix()
                matrix.setRotate(angle, cx, cy)
                setLocalMatrix(matrix)
            }
            nativeCanvas.drawRect(0f, 0f, w.toFloat(), h.toFloat(), gradientPaint)

            // 2. Mask: keep gradient only where brain PNG is opaque
            nativeCanvas.drawBitmap(maskBitmap, null, Rect(0, 0, w, h), maskPaint)

            nativeCanvas.restoreToCount(layer)
        }
    }
}

/**
 * Animated "TABAI" text with flowing gradient.
 */
@Composable
fun AnimatedBrandText(fontSize: Float = 20f) {
    val infiniteTransition = rememberInfiniteTransition(label = "brand_text")
    val phase by infiniteTransition.animateFloat(
        initialValue = -1f, targetValue = 2f,
        animationSpec = infiniteRepeatable(tween(4000, easing = LinearEasing)),
        label = "text_phase",
    )

    Text(
        text = "TABAI",
        fontSize = fontSize.sp,
        fontWeight = FontWeight.Bold,
        letterSpacing = 1.5.sp,
        textAlign = TextAlign.Center,
        style = androidx.compose.ui.text.TextStyle(
            brush = Brush.linearGradient(
                colors = brandColors,
                start = Offset(phase * 300f, 0f),
                end = Offset((phase + 1f) * 300f, 0f),
            ),
        ),
    )
}

/**
 * Small static logo for headers.
 */
@Composable
fun BrandLogoMark(size: Dp = 24.dp) {
    val context = LocalContext.current
    val bitmap = remember { BitmapFactory.decodeResource(context.resources, R.drawable.tai_logo) }
    Canvas(modifier = Modifier.size(size)) {
        drawIntoCanvas { canvas ->
            canvas.nativeCanvas.drawBitmap(
                bitmap, null,
                Rect(0, 0, this@Canvas.size.width.toInt(), this@Canvas.size.height.toInt()),
                null,
            )
        }
    }
}
