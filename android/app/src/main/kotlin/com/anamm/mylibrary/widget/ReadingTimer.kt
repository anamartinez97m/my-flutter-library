package com.anamm.mylibrary.widget

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** A chronometer session in progress, as the in-app chronometer stores it. */
data class TimerState(
    val bookId: Int,
    val startTime: String?,
    val elapsedSeconds: Long,
    val isRunning: Boolean,
    val savedAtMillis: Long,
) {
    fun elapsedNow(now: Long = System.currentTimeMillis()): Long =
        if (isRunning) elapsedSeconds + maxOf(0L, (now - savedAtMillis) / 1000) else elapsedSeconds
}

/**
 * Starts, pauses, resumes and stops reading sessions without the app running.
 * Writes the same data the in-app chronometer uses: the
 * `chronometer_session_<bookId>` entry in the app's shared preferences and
 * the active row in `reading_sessions`, so both always show the same session.
 */
class ReadingTimer(private val context: Context) {
    private val flutterPrefs =
        context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

    fun state(bookId: Int): TimerState? {
        val raw = flutterPrefs.getString(prefsKey(bookId), null) ?: return null
        return try {
            val o = JSONObject(raw)
            if (o.optInt("bookId", -1) != bookId) return null
            TimerState(
                bookId = bookId,
                startTime = o.optString("startTime").takeIf { it.isNotEmpty() && it != "null" },
                elapsedSeconds = o.optLong("elapsedSeconds", 0),
                isRunning = o.optBoolean("isRunning", false),
                savedAtMillis = parseIso(o.optString("savedAt")) ?: System.currentTimeMillis(),
            )
        } catch (e: Exception) {
            null
        }
    }

    /** Every session in progress (running or paused), newest first. */
    fun allStates(): List<TimerState> =
        flutterPrefs.all.keys
            .filter { it.startsWith(PREFS_PREFIX) }
            .mapNotNull { it.removePrefix(PREFS_PREFIX).toIntOrNull() }
            .mapNotNull { state(it) }
            .sortedByDescending { it.startTime ?: "" }

    /** Returns the book that already has a session in progress, if any. */
    fun otherSessionInProgress(bookId: Int): Int? =
        allStates().firstOrNull { it.bookId != bookId }?.bookId

    fun start(bookId: Int) {
        val now = iso(System.currentTimeMillis())
        withDb { db ->
            val values = ContentValues().apply {
                put("book_id", bookId)
                put("start_time", now)
                put("is_active", 1)
                put("did_read", 1)
                put("clicked_at", now)
            }
            db.insertOrThrow("reading_sessions", null, values)
        }
        save(TimerState(bookId, now, 0, true, System.currentTimeMillis()))
    }

    fun pause(bookId: Int) {
        val s = state(bookId) ?: return
        val elapsed = s.elapsedNow()
        save(s.copy(elapsedSeconds = elapsed, isRunning = false, savedAtMillis = System.currentTimeMillis()))
        withDb { db ->
            val values = ContentValues().apply { put("duration_seconds", elapsed) }
            db.update("reading_sessions", values, "book_id = ? AND is_active = 1", arrayOf(bookId.toString()))
        }
    }

    fun resume(bookId: Int) {
        val s = state(bookId) ?: return
        save(s.copy(isRunning = true, savedAtMillis = System.currentTimeMillis()))
    }

    /** Saves the session like the chronometer's stop button. Returns its length in seconds. */
    fun stop(bookId: Int): Long {
        val s = state(bookId) ?: return 0
        val elapsed = s.elapsedNow()
        val end = iso(System.currentTimeMillis())
        withDb { db ->
            val values = ContentValues().apply {
                put("end_time", end)
                put("duration_seconds", elapsed)
                put("is_active", 0)
                put("did_read", 1)
            }
            val updated = db.update(
                "reading_sessions", values, "book_id = ? AND is_active = 1", arrayOf(bookId.toString()),
            )
            if (updated == 0 && s.startTime != null) {
                values.put("book_id", bookId)
                values.put("start_time", s.startTime)
                db.insertOrThrow("reading_sessions", null, values)
            }
        }
        flutterPrefs.edit().remove(prefsKey(bookId)).commit()
        return elapsed
    }

    private fun save(s: TimerState) {
        val json = JSONObject()
            .put("bookId", s.bookId)
            .put("startTime", s.startTime ?: JSONObject.NULL)
            .put("elapsedSeconds", s.elapsedSeconds)
            .put("isRunning", s.isRunning)
            .put("appPausedTime", JSONObject.NULL)
            .put("savedAt", iso(s.savedAtMillis))
        flutterPrefs.edit().putString(prefsKey(s.bookId), json.toString()).commit()
    }

    private fun withDb(block: (SQLiteDatabase) -> Unit) {
        val file = context.getDatabasePath(DB_NAME)
        if (!file.exists()) return
        val db = SQLiteDatabase.openDatabase(file.path, null, SQLiteDatabase.OPEN_READWRITE)
        try {
            db.rawQuery("PRAGMA busy_timeout = 3000", null).close()
            block(db)
        } finally {
            db.close()
        }
    }

    companion object {
        private const val DB_NAME = "my_library.db"
        private const val PREFS_PREFIX = "flutter.chronometer_session_"

        private fun prefsKey(bookId: Int) = "$PREFS_PREFIX$bookId"

        // Same shape as Dart's DateTime.toIso8601String() for local times.
        private fun format() = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US)

        fun iso(millis: Long): String = format().format(Date(millis))

        fun parseIso(value: String?): Long? {
            if (value.isNullOrEmpty() || value.length < 19) return null
            return try {
                val base = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US)
                    .parse(value.substring(0, 19))?.time ?: return null
                val fraction = value.drop(20).takeWhile { it.isDigit() }.take(3).padEnd(3, '0')
                base + if (value.getOrNull(19) == '.') fraction.toLong() else 0L
            } catch (e: Exception) {
                null
            }
        }

        fun formatDuration(seconds: Long): String {
            val h = seconds / 3600
            val m = (seconds % 3600) / 60
            val s = seconds % 60
            return if (h > 0) String.format(Locale.US, "%02d:%02d:%02d", h, m, s)
            else String.format(Locale.US, "%02d:%02d", m, s)
        }
    }
}
