package com.anamm.mylibrary.widget

import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import org.json.JSONArray
import org.json.JSONObject

/** What the widget shows for one book, prepared by the Flutter side. */
data class WidgetBook(
    val id: Int,
    val title: String,
    val subtitle: String,
    val progressText: String,
    val percent: Int,
    val remaining: String,
    val coverPath: String?,
)

data class WidgetColors(
    val background: Int,
    val text: Int,
    val textMuted: Int,
    val header: Int,
    val primary: Int,
    val onPrimary: Int,
    val track: Int,
)

/**
 * Widget data pushed by the app: book snapshots, the Started books ordered by
 * latest reading activity, the app theme and the strings in the app language.
 * Also keeps which book each widget instance is pinned to.
 */
class WidgetStore(context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    private val uiMode = context.resources.configuration.uiMode

    fun saveSync(payload: JSONObject) {
        prefs.edit()
            .putString(KEY_BOOKS, payload.optJSONObject("books")?.toString() ?: "{}")
            .putString(KEY_STARTED, payload.optJSONArray("started")?.toString() ?: "[]")
            .putString(KEY_THEME, payload.optJSONObject("theme")?.toString() ?: "{}")
            .putString(KEY_STRINGS, payload.optJSONObject("strings")?.toString() ?: "{}")
            .apply()
    }

    fun book(id: Int): WidgetBook? {
        val o = JSONObject(prefs.getString(KEY_BOOKS, "{}")!!).optJSONObject(id.toString())
            ?: return null
        return WidgetBook(
            id = id,
            title = o.optString("title"),
            subtitle = o.optString("subtitle"),
            progressText = o.optString("progressText"),
            percent = o.optInt("percent", -1),
            remaining = o.optString("remaining"),
            coverPath = o.optString("cover").takeIf { it.isNotEmpty() },
        )
    }

    /** Started books, most recently read first. */
    fun startedBookIds(): List<Int> {
        val arr = JSONArray(prefs.getString(KEY_STARTED, "[]"))
        return (0 until arr.length()).map { arr.getInt(it) }
    }

    fun startedBooks(): List<WidgetBook> = startedBookIds().mapNotNull { book(it) }

    fun pinnedBook(appWidgetId: Int): Int? =
        prefs.getInt(pinKey(appWidgetId), -1).takeIf { it >= 0 }

    fun pin(appWidgetId: Int, bookId: Int) {
        prefs.edit().putInt(pinKey(appWidgetId), bookId).apply()
    }

    fun unpin(appWidgetId: Int) {
        prefs.edit().remove(pinKey(appWidgetId)).apply()
    }

    /**
     * Book the widget should show. A pinned book that is no longer Started
     * (finished, abandoned, deleted) is replaced by the Started book read most
     * recently, which becomes the new pin.
     */
    fun resolveBook(appWidgetId: Int): WidgetBook? {
        val started = startedBookIds()
        val pinned = pinnedBook(appWidgetId)
        if (pinned != null && started.contains(pinned)) return book(pinned)
        if (!prefs.contains(KEY_STARTED)) return pinned?.let { book(it) }
        val next = started.firstOrNull() ?: return null
        pin(appWidgetId, next)
        return book(next)
    }

    fun colors(): WidgetColors {
        val theme = JSONObject(prefs.getString(KEY_THEME, "{}")!!)
        val mode = theme.optString("mode", "system")
        val dark = when (mode) {
            "dark" -> true
            "light" -> false
            else -> (uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
                Configuration.UI_MODE_NIGHT_YES
        }
        val p = theme.optJSONObject(if (dark) "dark" else "light")
        val d = if (dark) DEFAULT_DARK else DEFAULT_LIGHT
        fun c(name: String, fallback: Int) =
            if (p != null && p.has(name)) p.getLong(name).toInt() else fallback
        return WidgetColors(
            background = c("background", d.background),
            text = c("text", d.text),
            textMuted = c("textMuted", d.textMuted),
            header = c("header", d.header),
            primary = c("primary", d.primary),
            onPrimary = c("onPrimary", d.onPrimary),
            track = c("track", d.track),
        )
    }

    fun string(key: String): String {
        val s = JSONObject(prefs.getString(KEY_STRINGS, "{}")!!).optString(key)
        return s.ifEmpty { DEFAULT_STRINGS[key] ?: key }
    }

    private fun pinKey(appWidgetId: Int) = "pin_$appWidgetId"

    companion object {
        private const val PREFS = "reading_widget"
        private const val KEY_BOOKS = "books"
        private const val KEY_STARTED = "started"
        private const val KEY_THEME = "theme"
        private const val KEY_STRINGS = "strings"

        private val DEFAULT_LIGHT = WidgetColors(
            background = 0xFFFDF8F6.toInt(),
            text = 0xFF1C1B1A.toInt(),
            textMuted = 0xFF76656B.toInt(),
            header = 0xFF894B67.toInt(),
            primary = 0xFF43102B.toInt(),
            onPrimary = 0xFFFFFFFF.toInt(),
            track = 0xFFECE7E5.toInt(),
        )
        private val DEFAULT_DARK = WidgetColors(
            background = 0xFF393E46.toInt(),
            text = 0xFFEEEEEE.toInt(),
            textMuted = 0xFFB9A2AB.toInt(),
            header = 0xFFF6B5D4.toInt(),
            primary = 0xFFB9A2AB.toInt(),
            onPrimary = 0xFF4D213A.toInt(),
            track = 0xFF222831.toInt(),
        )

        private val DEFAULT_STRINGS = mapOf(
            "header" to "CURRENTLY READING",
            "startTimer" to "Start timer",
            "noBooks" to "No books in progress",
            "openApp" to "Tap to open My Book Vault",
            "pickTitle" to "Choose a book",
            "pickEmpty" to "Mark a book as Started in My Book Vault to show it here.",
            "timerRunning" to "Timer already running for %s",
            "sessionSaved" to "Reading session saved: %s",
            "paused" to "Paused",
            "pause" to "Pause",
            "resume" to "Resume",
            "stop" to "Stop",
            "channel" to "Reading timer",
        )
    }
}
