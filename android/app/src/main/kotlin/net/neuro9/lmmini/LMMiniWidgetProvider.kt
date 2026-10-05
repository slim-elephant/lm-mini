package net.neuro9.lmmini

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class LMMiniWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val msgCount = widgetData.getInt("total_messages", 0)
        val tokensIn = widgetData.getInt("total_tokens_in", 0)
        val tokensOut = widgetData.getInt("total_tokens_out", 0)
        val isPremium = widgetData.getBoolean("is_premium", false)
        val prompt = widgetData.getString("automated_prompt", null)
            ?: context.getString(R.string.widget_tap_to_chat)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                setTextViewText(R.id.widget_header, context.getString(R.string.widget_app_stats))
                setTextViewText(
                    R.id.widget_stat_messages,
                    context.getString(R.string.widget_messages, msgCount),
                )
                setTextViewText(
                    R.id.widget_stat_tokens_in,
                    context.getString(R.string.widget_tokens_in, tokensIn / 1000),
                )
                setTextViewText(
                    R.id.widget_stat_tokens_out,
                    context.getString(R.string.widget_tokens_out, tokensOut / 1000),
                )
                setTextViewText(R.id.widget_subtitle, prompt)
                setViewVisibility(
                    R.id.widget_premium_badge,
                    if (isPremium) View.VISIBLE else View.GONE,
                )

                val newChatUri = Uri.parse("lmmini://newchat")
                val baseCode = widgetId * 100
                setOnClickPendingIntent(
                    R.id.widget_container,
                    WidgetHelpers.launchIntent(context, newChatUri, baseCode),
                )
                setOnClickPendingIntent(
                    R.id.widget_new_chat,
                    WidgetHelpers.launchIntent(context, newChatUri, baseCode + 1),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
