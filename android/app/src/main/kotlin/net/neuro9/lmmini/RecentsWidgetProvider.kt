package net.neuro9.lmmini

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class RecentsWidgetProvider : HomeWidgetProvider() {
    private data class RowIds(val row: Int, val title: Int, val time: Int)

    private val rows = listOf(
        RowIds(R.id.recent_0, R.id.recent_0_title, R.id.recent_0_time),
        RowIds(R.id.recent_1, R.id.recent_1_title, R.id.recent_1_time),
        RowIds(R.id.recent_2, R.id.recent_2_title, R.id.recent_2_time),
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val conversations = WidgetHelpers.jsonArray(widgetData, "recent_conversations_json")
        val count = conversations.length().coerceAtMost(rows.size)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_recents_layout)
            val baseCode = widgetId * 100 + 50
            val newChatUri = Uri.parse("lmmini://newchat")

            views.setOnClickPendingIntent(
                R.id.recents_new_chat,
                WidgetHelpers.launchIntent(context, newChatUri, baseCode),
            )

            if (count == 0) {
                views.setViewVisibility(R.id.recents_empty, View.VISIBLE)
                rows.forEach { views.setViewVisibility(it.row, View.GONE) }
            } else {
                views.setViewVisibility(R.id.recents_empty, View.GONE)
                rows.forEachIndexed { index, row ->
                    if (index < count) {
                        val obj = conversations.getJSONObject(index)
                        val id = WidgetHelpers.jsonString(obj, "id") ?: return@forEachIndexed
                        val title = WidgetHelpers.jsonString(obj, "title").orEmpty()
                        val updatedAt = WidgetHelpers.jsonInt(obj, "updatedAt").toLong()

                        views.setViewVisibility(row.row, View.VISIBLE)
                        views.setTextViewText(
                            row.title,
                            title.ifEmpty { context.getString(R.string.widget_untitled_chat) },
                        )
                        if (updatedAt > 0L) {
                            views.setTextViewText(
                                row.time,
                                WidgetHelpers.relativeTime(context, updatedAt),
                            )
                        } else {
                            views.setTextViewText(row.time, "")
                        }
                        views.setOnClickPendingIntent(
                            row.row,
                            WidgetHelpers.launchIntent(
                                context,
                                Uri.parse("lmmini://chat?id=$id"),
                                baseCode + index + 1,
                            ),
                        )
                    } else {
                        views.setViewVisibility(row.row, View.GONE)
                    }
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
