package net.neuro9.lmmini

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class NewsWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val isPremium = widgetData.getBoolean("is_premium", false)
        val hasPrompt = !widgetData.getString("news_prompt", null).isNullOrBlank()
        val title = widgetData.getString("news_title", null).orEmpty()
        val body = widgetData.getString("news_content", null).orEmpty()
        val generatedAt = widgetData.getInt("news_generated_at", 0).toLong()

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_news_layout)
            val newsUri = Uri.parse("lmmini://news")
            views.setOnClickPendingIntent(
                R.id.news_container,
                WidgetHelpers.launchIntent(context, newsUri, widgetId * 100 + 20),
            )

            views.setViewVisibility(R.id.news_body, View.GONE)
            views.setViewVisibility(R.id.news_time, View.GONE)
            views.setViewVisibility(R.id.news_message, View.VISIBLE)

            when {
                !isPremium -> {
                    views.setTextViewText(
                        R.id.news_message,
                        "${context.getString(R.string.widget_news_pro_locked)}\n${context.getString(R.string.widget_news_pro_hint)}",
                    )
                }
                !hasPrompt -> {
                    views.setTextViewText(
                        R.id.news_message,
                        "${context.getString(R.string.widget_news_setup)}\n${context.getString(R.string.widget_news_setup_hint)}",
                    )
                }
                title.isEmpty() && body.isEmpty() -> {
                    views.setTextViewText(
                        R.id.news_message,
                        context.getString(R.string.widget_news_refreshing),
                    )
                }
                else -> {
                    val headlines = resolveHeadlines(title, body, limit = 5).ifEmpty {
                        listOf(
                            title.ifEmpty {
                                context.getString(R.string.widget_news_default_title)
                            },
                        )
                    }
                    // Renumber 1…n so a missing/stripped "1." never shows as 2–5.
                    val numbered = headlines.mapIndexed { i, t -> "${i + 1}. $t" }
                    views.setViewVisibility(R.id.news_message, View.GONE)
                    views.setViewVisibility(R.id.news_body, View.VISIBLE)
                    views.setTextViewText(R.id.news_body, numbered.joinToString("\n"))
                    if (generatedAt > 0L) {
                        views.setViewVisibility(R.id.news_time, View.VISIBLE)
                        views.setTextViewText(
                            R.id.news_time,
                            WidgetHelpers.relativeTime(context, generatedAt),
                        )
                    }
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    /**
     * Bare headline titles (no leading numbers). Recovers item 1 when an older
     * save put `1. …` into [title] and left it out of [body].
     */
    private fun resolveHeadlines(title: String, body: String, limit: Int): List<String> {
        val fromBody = newsHeadlines(body, limit)
        val recovered = newsTitleAsHeadline(title)
        val merged = ArrayList<String>(limit)
        if (recovered != null &&
            fromBody.none { it.equals(recovered, ignoreCase = true) }
        ) {
            merged.add(recovered)
        }
        for (t in fromBody) {
            if (merged.size >= limit) break
            merged.add(t)
        }
        if (merged.isNotEmpty()) return merged.take(limit)
        val fallback = title.trim()
        return if (fallback.isEmpty()) emptyList() else listOf(fallback)
    }

    /** Extract bare titles from `1. Headline` lines; skip summaries / Source / URLs. */
    private fun newsHeadlines(body: String, limit: Int): List<String> {
        val pattern = Regex("""^\s*(\d+)\.\s+(.+?)\s*$""")
        val out = ArrayList<String>(limit)
        for (raw in body.lineSequence()) {
            val line = raw.trim()
            if (line.isEmpty()) continue
            val lower = line.lowercase()
            if (lower.startsWith("source:")) continue
            if (lower.startsWith("http://") || lower.startsWith("https://")) continue
            val match = pattern.matchEntire(line) ?: continue
            var headline = match.groupValues[2].trim()
            if (headline.length > 72) {
                headline = headline.take(71).trimEnd() + "…"
            }
            out.add(headline)
            if (out.size >= limit) break
        }
        return out
    }

    private fun newsTitleAsHeadline(title: String): String? {
        val match = Regex("""^\s*\d+\.\s+(.+?)\s*$""").matchEntire(title.trim())
            ?: return null
        return match.groupValues[1].trim().ifEmpty { null }
    }
}
