package net.neuro9.lmmini

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class FoldersWidgetProvider : HomeWidgetProvider() {
    private data class RowIds(val row: Int, val accent: Int, val name: Int, val count: Int)

    private val rows = listOf(
        RowIds(R.id.folder_0, R.id.folder_0_accent, R.id.folder_0_name, R.id.folder_0_count),
        RowIds(R.id.folder_1, R.id.folder_1_accent, R.id.folder_1_name, R.id.folder_1_count),
        RowIds(R.id.folder_2, R.id.folder_2_accent, R.id.folder_2_name, R.id.folder_2_count),
        RowIds(R.id.folder_3, R.id.folder_3_accent, R.id.folder_3_name, R.id.folder_3_count),
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val folders = WidgetHelpers.jsonArray(widgetData, "folders_json")
        val count = folders.length().coerceAtMost(rows.size)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_folders_layout)
            val baseCode = widgetId * 100 + 40

            if (count == 0) {
                views.setViewVisibility(R.id.folders_empty, View.VISIBLE)
                rows.forEach { views.setViewVisibility(it.row, View.GONE) }
            } else {
                views.setViewVisibility(R.id.folders_empty, View.GONE)
                rows.forEachIndexed { index, row ->
                    if (index < count) {
                        val obj = folders.getJSONObject(index)
                        val id = WidgetHelpers.jsonString(obj, "id") ?: return@forEachIndexed
                        val name = WidgetHelpers.jsonString(obj, "name") ?: id
                        val chatCount = WidgetHelpers.jsonInt(obj, "count")
                        val color = WidgetHelpers.colorFromHex(WidgetHelpers.jsonString(obj, "color"))

                        views.setViewVisibility(row.row, View.VISIBLE)
                        views.setTextViewText(row.name, name)
                        views.setTextViewText(row.count, chatCount.toString())
                        views.setInt(row.accent, "setBackgroundColor", color)
                        views.setOnClickPendingIntent(
                            row.row,
                            WidgetHelpers.launchIntent(
                                context,
                                Uri.parse("lmmini://folder?id=$id"),
                                baseCode + index,
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
