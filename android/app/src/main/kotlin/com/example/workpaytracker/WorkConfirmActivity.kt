package com.example.workpaytracker

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import android.graphics.Color
import android.graphics.Typeface
import android.view.Gravity
import android.widget.FrameLayout
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.StateListDrawable
import android.util.TypedValue
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.Calendar

/**
 * Full-screen work confirmation Activity.
 * Shown via Full Screen Intent when the daily reminder fires.
 * Appears over the lock screen, wakes the screen, and requires no app interaction.
 */
class WorkConfirmActivity : Activity() {

    companion object {
        const val ACTION_YES = "com.example.workpaytracker.ACTION_YES"
        const val ACTION_NO = "com.example.workpaytracker.ACTION_NO"
        const val EXTRA_NOTIFICATION_ID = "notification_id"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Show over lock screen and wake the device
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
        )

        // Full-screen immersive
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
            View.SYSTEM_UI_FLAG_FULLSCREEN
        )
        window.statusBarColor = Color.parseColor("#0A0B0D")
        window.navigationBarColor = Color.parseColor("#0A0B0D")

        setContentView(buildLayout())
    }

    private fun dp(value: Float): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP, value, resources.displayMetrics
        ).toInt()
    }

    private fun sp(value: Float): Float {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_SP, value, resources.displayMetrics
        )
    }

    private fun buildLayout(): View {
        val root = FrameLayout(this).apply {
            setBackgroundColor(Color.parseColor("#0A0B0D"))
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }

        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(32f), dp(48f), dp(32f), dp(48f))
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }

        // App label
        val appLabel = TextView(this).apply {
            text = "ხელფასის მენეჯერი"
            setTextColor(Color.parseColor("#6B7280"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            gravity = Gravity.CENTER
            typeface = Typeface.DEFAULT_BOLD
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = dp(32f) }
        }

        // Icon circle
        val iconContainer = FrameLayout(this).apply {
            val size = dp(100f)
            layoutParams = LinearLayout.LayoutParams(size, size).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = dp(32f)
            }
            val bg = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#1A2E26"))
                setStroke(dp(2f), Color.parseColor("#10B981"))
            }
            background = bg
        }

        val iconText = TextView(this).apply {
            text = "💼"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 44f)
            gravity = Gravity.CENTER
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }
        iconContainer.addView(iconText)

        // Question text
        val questionText = TextView(this).apply {
            text = "იმუშავე დღეს?"
            setTextColor(Color.parseColor("#FAFAFA"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 28f)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = dp(12f) }
        }

        // Date text
        val dateText = TextView(this).apply {
            text = getFormattedDate()
            setTextColor(Color.parseColor("#9CA3AF"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = dp(48f) }
        }

        // YES button
        val yesButton = TextView(this).apply {
            text = "✓  დიახ, ვიმუშავე"
            setTextColor(Color.parseColor("#FAFAFA"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setPadding(dp(24f), dp(20f), dp(24f), dp(20f))
            val bg = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(16f).toFloat()
                colors = intArrayOf(
                    Color.parseColor("#059669"),
                    Color.parseColor("#10B981")
                )
                gradientType = GradientDrawable.LINEAR_GRADIENT
                orientation = GradientDrawable.Orientation.LEFT_RIGHT
            }
            background = bg
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = dp(12f) }
            isClickable = true
            isFocusable = true
            setOnClickListener { handleYes() }
        }

        // NO button
        val noButton = TextView(this).apply {
            text = "✕  არა, არ მიმუშავია"
            setTextColor(Color.parseColor("#FAFAFA"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setPadding(dp(24f), dp(20f), dp(24f), dp(20f))
            val bg = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(16f).toFloat()
                setColor(Color.parseColor("#1E2028"))
                setStroke(dp(1f), Color.parseColor("#374151"))
            }
            background = bg
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            isClickable = true
            isFocusable = true
            setOnClickListener { handleNo() }
        }

        container.addView(appLabel)
        container.addView(iconContainer)
        container.addView(questionText)
        container.addView(dateText)
        container.addView(yesButton)
        container.addView(noButton)
        root.addView(container)

        return root
    }

    private fun getFormattedDate(): String {
        val geoMonths = arrayOf(
            "", "იანვარი", "თებერვალი", "მარტი", "აპრილი", "მაისი", "ივნისი",
            "ივლისი", "აგვისტო", "სექტემბერი", "ოქტომბერი", "ნოემბერი", "დეკემბერი"
        )
        val cal = Calendar.getInstance()
        val day = cal.get(Calendar.DAY_OF_MONTH)
        val month = cal.get(Calendar.MONTH) + 1
        return "დღეს, $day ${geoMonths[month]}"
    }

    private fun handleYes() {
        // Broadcast to background handler
        val intent = Intent(ACTION_YES).apply {
            setPackage(packageName)
        }
        sendBroadcast(intent)
        finishAndRemoveTask()
    }

    private fun handleNo() {
        val intent = Intent(ACTION_NO).apply {
            setPackage(packageName)
        }
        sendBroadcast(intent)
        finishAndRemoveTask()
    }

    override fun onBackPressed() {
        // Don't allow back — user must answer
    }
}
