package net.neuro9.lmmini

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.TimeUnit

object WidgetHelpers {
    const val DEFAULT_PURPLE = 0xFF7E57C2.toInt()

    fun launchIntent(context: Context, uri: Uri, requestCode: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            data = uri
            action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }
        return PendingIntent.getActivity(context, requestCode, intent, flags)
    }

    fun jsonArray(widgetData: SharedPreferences, key: String): JSONArray {
        val raw = widgetData.getString(key, null) ?: return JSONArray()
        return try {
            JSONArray(raw)
        } catch (_: Exception) {
            JSONArray()
        }
    }

    fun colorFromHex(hex: String?): Int {
        if (hex.isNullOrBlank()) return DEFAULT_PURPLE
        var value = hex.trim().removePrefix("#")
        if (value.length == 6) value = "FF$value"
        if (value.length != 8) return DEFAULT_PURPLE
        return try {
            value.toLong(16).toInt()
        } catch (_: Exception) {
            DEFAULT_PURPLE
        }
    }

    fun relativeTime(context: Context, epochMs: Long): String {
        if (epochMs <= 0L) return ""
        val seconds = TimeUnit.MILLISECONDS.toSeconds(
            System.currentTimeMillis() - epochMs,
        ).coerceAtLeast(0)
        return when {
            seconds < 60 -> context.getString(R.string.widget_time_just_now)
            seconds < 3600 -> context.getString(
                R.string.widget_time_minutes,
                (seconds / 60).toInt(),
            )
            seconds < 86_400 -> context.getString(
                R.string.widget_time_hours,
                (seconds / 3600).toInt(),
            )
            else -> context.getString(
                R.string.widget_time_days,
                (seconds / 86_400).toInt(),
            )
        }
    }

    fun jsonString(obj: JSONObject, key: String): String? {
        if (!obj.has(key) || obj.isNull(key)) return null
        val value = obj.optString(key, "")
        return value.ifEmpty { null }
    }

    fun jsonInt(obj: JSONObject, key: String): Int = obj.optInt(key, 0)
}
