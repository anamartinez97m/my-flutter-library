package com.anamm.mylibrary.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import android.widget.Toast
import com.anamm.mylibrary.MainActivity
import com.anamm.mylibrary.R

/** Home-screen widget for one pinned book: progress plus a chronometer. */
class ReadingWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, appWidgetIds: IntArray) {
        appWidgetIds.forEach { render(context, manager, it) }
        TimerNotification.refresh(context)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context, manager: AppWidgetManager, appWidgetId: Int, newOptions: Bundle,
    ) {
        render(context, manager, appWidgetId)
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        val store = WidgetStore(context)
        appWidgetIds.forEach { store.unpin(it) }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val bookId = intent.getIntExtra(EXTRA_BOOK_ID, -1)
        when (intent.action) {
            ACTION_START, ACTION_PAUSE, ACTION_RESUME, ACTION_STOP ->
                if (bookId >= 0) handleTimerAction(context, intent.action!!, bookId)
            else -> super.onReceive(context, intent)
        }
    }

    private fun handleTimerAction(context: Context, action: String, bookId: Int) {
        val timer = ReadingTimer(context)
        val store = WidgetStore(context)
        try {
            when (action) {
                ACTION_START -> {
                    val other = timer.otherSessionInProgress(bookId)
                    if (other != null) {
                        val title = store.book(other)?.title ?: ""
                        toast(context, store.string("timerRunning").replace("%s", title))
                        return
                    }
                    if (timer.state(bookId) == null) timer.start(bookId) else timer.resume(bookId)
                }
                ACTION_PAUSE -> timer.pause(bookId)
                ACTION_RESUME -> timer.resume(bookId)
                ACTION_STOP -> {
                    val seconds = timer.stop(bookId)
                    toast(
                        context,
                        store.string("sessionSaved").replace("%s", ReadingTimer.formatDuration(seconds)),
                    )
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("ReadingWidget", "Timer action $action failed", e)
        }
        updateAll(context)
        TimerNotification.refresh(context)
        WidgetBridge.notifyTimerChanged(bookId)
    }

    private fun toast(context: Context, text: String) {
        Toast.makeText(context, text, Toast.LENGTH_SHORT).show()
    }

    companion object {
        const val ACTION_START = "com.anamm.mylibrary.widget.START"
        const val ACTION_PAUSE = "com.anamm.mylibrary.widget.PAUSE"
        const val ACTION_RESUME = "com.anamm.mylibrary.widget.RESUME"
        const val ACTION_STOP = "com.anamm.mylibrary.widget.STOP"
        const val ACTION_OPEN_BOOK = "com.anamm.mylibrary.widget.OPEN_BOOK"
        const val EXTRA_BOOK_ID = "book_id"
        private val ACTIONS = listOf(ACTION_START, ACTION_PAUSE, ACTION_RESUME, ACTION_STOP)

        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, ReadingWidgetProvider::class.java))
            ids.forEach { render(context, manager, it) }
        }

        fun render(context: Context, manager: AppWidgetManager, appWidgetId: Int) {
            val store = WidgetStore(context)
            val colors = store.colors()
            val views = RemoteViews(context.packageName, R.layout.reading_widget)
            views.setInt(R.id.widget_bg, "setColorFilter", colors.background)

            val book = store.resolveBook(appWidgetId)
            if (book == null) {
                views.setViewVisibility(R.id.content, View.GONE)
                views.setViewVisibility(R.id.empty_view, View.VISIBLE)
                views.setTextViewText(R.id.empty_title, store.string("noBooks"))
                views.setTextViewText(R.id.empty_sub, store.string("openApp"))
                views.setTextColor(R.id.empty_title, colors.text)
                views.setTextColor(R.id.empty_sub, colors.textMuted)
                views.setOnClickPendingIntent(R.id.widget_root, openAppIntent(context, appWidgetId, null))
                manager.updateAppWidget(appWidgetId, views)
                return
            }

            views.setViewVisibility(R.id.content, View.VISIBLE)
            views.setViewVisibility(R.id.empty_view, View.GONE)
            views.setOnClickPendingIntent(R.id.widget_root, openAppIntent(context, appWidgetId, book.id))

            views.setTextViewText(R.id.header, store.string("header"))
            views.setTextColor(R.id.header, colors.header)
            views.setTextViewText(R.id.title, book.title)
            views.setTextColor(R.id.title, colors.text)
            views.setTextViewText(R.id.subtitle, book.subtitle)
            views.setTextColor(R.id.subtitle, colors.textMuted)
            views.setViewVisibility(R.id.subtitle, if (book.subtitle.isEmpty()) View.GONE else View.VISIBLE)

            val density = context.resources.displayMetrics.density
            val cover = WidgetBitmaps.cover(book.coverPath, book.title, colors, density)
            views.setImageViewBitmap(R.id.cover, cover)

            if (book.percent >= 0) {
                views.setViewVisibility(R.id.progress_bar, View.VISIBLE)
                val widthDp = barWidthDp(manager.getAppWidgetOptions(appWidgetId))
                views.setImageViewBitmap(
                    R.id.progress_bar,
                    WidgetBitmaps.progressBar(book.percent, colors, widthDp, density),
                )
                views.setTextViewText(R.id.percent_text, "${book.percent}%")
            } else {
                views.setViewVisibility(R.id.progress_bar, View.GONE)
                views.setTextViewText(R.id.percent_text, "")
            }
            views.setTextViewText(R.id.progress_text, book.progressText)
            views.setTextColor(R.id.progress_text, colors.textMuted)
            views.setTextColor(R.id.percent_text, colors.textMuted)

            val timer = ReadingTimer(context).state(book.id)
            if (timer == null) {
                views.setViewVisibility(R.id.idle_row, View.VISIBLE)
                views.setViewVisibility(R.id.timer_row, View.GONE)
                views.setInt(R.id.start_bg, "setColorFilter", colors.primary)
                views.setTextViewText(R.id.start_label, "▶  " + store.string("startTimer"))
                views.setTextColor(R.id.start_label, colors.onPrimary)
                views.setOnClickPendingIntent(R.id.start_button, actionIntent(context, ACTION_START, book.id))
                views.setTextViewText(R.id.remaining, book.remaining)
                views.setTextColor(R.id.remaining, colors.textMuted)
            } else {
                views.setViewVisibility(R.id.idle_row, View.GONE)
                views.setViewVisibility(R.id.timer_row, View.VISIBLE)
                val base = SystemClock.elapsedRealtime() - timer.elapsedNow() * 1000
                views.setChronometer(R.id.chronometer, base, null, timer.isRunning)
                views.setTextColor(R.id.chronometer, colors.text)
                views.setTextViewText(R.id.timer_state, if (timer.isRunning) "" else store.string("paused"))
                views.setTextColor(R.id.timer_state, colors.textMuted)
                views.setInt(R.id.pause_bg, "setColorFilter", colors.primary)
                views.setInt(R.id.stop_bg, "setColorFilter", colors.primary)
                views.setImageViewResource(
                    R.id.pause_icon,
                    if (timer.isRunning) R.drawable.widget_ic_pause else R.drawable.widget_ic_play,
                )
                views.setInt(R.id.pause_icon, "setColorFilter", colors.onPrimary)
                views.setInt(R.id.stop_icon, "setColorFilter", colors.onPrimary)
                views.setOnClickPendingIntent(
                    R.id.pause_button,
                    actionIntent(context, if (timer.isRunning) ACTION_PAUSE else ACTION_RESUME, book.id),
                )
                views.setOnClickPendingIntent(R.id.stop_button, actionIntent(context, ACTION_STOP, book.id))
            }
            manager.updateAppWidget(appWidgetId, views)
        }

        /** Width left for the progress bar: widget width minus cover and paddings. */
        private fun barWidthDp(options: Bundle): Int {
            val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250)
            return (width - 16 - 16 - 72 - 12).coerceAtLeast(80)
        }

        fun actionIntent(context: Context, action: String, bookId: Int): PendingIntent {
            val intent = Intent(context, ReadingWidgetProvider::class.java)
                .setAction(action)
                .putExtra(EXTRA_BOOK_ID, bookId)
            return PendingIntent.getBroadcast(
                context,
                bookId * 10 + ACTIONS.indexOf(action) + 1,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        fun openAppIntent(context: Context, requestCode: Int, bookId: Int?): PendingIntent {
            val intent = Intent(context, MainActivity::class.java)
                .setAction(if (bookId != null) ACTION_OPEN_BOOK else Intent.ACTION_MAIN)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            if (bookId != null) intent.putExtra(EXTRA_BOOK_ID, bookId)
            return PendingIntent.getActivity(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

    }
}
