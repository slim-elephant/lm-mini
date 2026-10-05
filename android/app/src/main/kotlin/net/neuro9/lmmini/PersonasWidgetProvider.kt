package net.neuro9.lmmini

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class PersonasWidgetProvider : HomeWidgetProvider() {
    private data class SlotIds(val container: Int, val dot: Int, val name: Int)

    private val slots = listOf(
        SlotIds(R.id.persona_0, R.id.persona_0_dot, R.id.persona_0_name),
        SlotIds(R.id.persona_1, R.id.persona_1_dot, R.id.persona_1_name),
        SlotIds(R.id.persona_2, R.id.persona_2_dot, R.id.persona_2_name),
        SlotIds(R.id.persona_3, R.id.persona_3_dot, R.id.persona_3_name),
        SlotIds(R.id.persona_4, R.id.persona_4_dot, R.id.persona_4_name),
        SlotIds(R.id.persona_5, R.id.persona_5_dot, R.id.persona_5_name),
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val personas = WidgetHelpers.jsonArray(widgetData, "personas_json")
        val count = personas.length().coerceAtMost(slots.size)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_personas_layout)
            val baseCode = widgetId * 100 + 30

            if (count == 0) {
                views.setViewVisibility(R.id.personas_empty, View.VISIBLE)
                views.setViewVisibility(R.id.personas_grid, View.GONE)
                views.setOnClickPendingIntent(
                    R.id.personas_container,
                    WidgetHelpers.launchIntent(
                        context,
                        Uri.parse("lmmini://newchat"),
                        baseCode,
                    ),
                )
            } else {
                views.setViewVisibility(R.id.personas_empty, View.GONE)
                views.setViewVisibility(R.id.personas_grid, View.VISIBLE)

                slots.forEachIndexed { index, slot ->
                    if (index < count) {
                        val obj = personas.getJSONObject(index)
                        val id = WidgetHelpers.jsonString(obj, "id") ?: return@forEachIndexed
                        val name = WidgetHelpers.jsonString(obj, "name") ?: id
                        val color = WidgetHelpers.colorFromHex(WidgetHelpers.jsonString(obj, "color"))

                        views.setViewVisibility(slot.container, View.VISIBLE)
                        views.setTextViewText(slot.name, name)
                        views.setInt(slot.dot, "setBackgroundColor", color)
                        views.setOnClickPendingIntent(
                            slot.container,
                            WidgetHelpers.launchIntent(
                                context,
                                Uri.parse("lmmini://chat?persona=$id"),
                                baseCode + index,
                            ),
                        )
                    } else {
                        views.setViewVisibility(slot.container, View.GONE)
                    }
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
