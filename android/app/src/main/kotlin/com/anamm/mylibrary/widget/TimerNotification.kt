package com.anamm.mylibrary.widget

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.graphics.drawable.Icon
import android.os.Build
import com.anamm.mylibrary.R

/** Ongoing notification for each reading session in progress. */
object TimerNotification {
    private const val CHANNEL_ID = "reading_timer"
    private const val ID_BASE = 7_300_000
    private const val PREFS = "reading_widget_notifications"

    fun refresh(context: Context) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val store = WidgetStore(context)
        val states = ReadingTimer(context).allStates()
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val shown = prefs.getStringSet("ids", emptySet())!!.mapNotNull { it.toIntOrNull() }.toSet()
        val active = states.map { it.bookId }.toSet()
        (shown - active).forEach { manager.cancel(ID_BASE + it) }
        prefs.edit().putStringSet("ids", active.map { it.toString() }.toSet()).apply()
        if (states.isEmpty()) return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, store.string("channel"), NotificationManager.IMPORTANCE_LOW)
                    .apply { setShowBadge(false) },
            )
        }
        states.forEach { manager.notify(ID_BASE + it.bookId, build(context, store, it)) }
    }

    private fun build(context: Context, store: WidgetStore, state: TimerState): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context).setPriority(Notification.PRIORITY_LOW)
        }
        val elapsed = state.elapsedNow()
        val toggleAction = if (state.isRunning) ReadingWidgetProvider.ACTION_PAUSE else ReadingWidgetProvider.ACTION_RESUME
        builder
            .setSmallIcon(R.drawable.widget_ic_timer)
            .setContentTitle(store.book(state.bookId)?.title ?: store.string("channel"))
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(Notification.CATEGORY_STOPWATCH)
            .setContentIntent(ReadingWidgetProvider.openAppIntent(context, ID_BASE + state.bookId, state.bookId))
            .addAction(
                Notification.Action.Builder(
                    Icon.createWithResource(context, if (state.isRunning) R.drawable.widget_ic_pause else R.drawable.widget_ic_play),
                    store.string(if (state.isRunning) "pause" else "resume"),
                    ReadingWidgetProvider.actionIntent(context, toggleAction, state.bookId),
                ).build(),
            )
            .addAction(
                Notification.Action.Builder(
                    Icon.createWithResource(context, R.drawable.widget_ic_stop),
                    store.string("stop"),
                    ReadingWidgetProvider.actionIntent(context, ReadingWidgetProvider.ACTION_STOP, state.bookId),
                ).build(),
            )
        if (state.isRunning) {
            builder.setUsesChronometer(true)
                .setShowWhen(true)
                .setWhen(System.currentTimeMillis() - elapsed * 1000)
        } else {
            builder.setUsesChronometer(false)
                .setShowWhen(false)
                .setContentText("${store.string("paused")} · ${ReadingTimer.formatDuration(elapsed)}")
        }
        return builder.build()
    }
}
