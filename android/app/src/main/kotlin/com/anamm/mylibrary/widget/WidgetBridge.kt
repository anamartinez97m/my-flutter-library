package com.anamm.mylibrary.widget

import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

/**
 * Channel between the app and the widget: the app pushes widget data and
 * learns about widget taps and timer changes made outside the app.
 */
object WidgetBridge {
    private const val CHANNEL = "com.anamm.mylibrary/home_widget"
    private var channel: MethodChannel? = null
    private var pendingBookId: Int? = null

    fun attach(context: Context, messenger: BinaryMessenger) {
        val appContext = context.applicationContext
        channel = MethodChannel(messenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "sync" -> {
                        WidgetStore(appContext).saveSync(JSONObject(call.arguments as String))
                        ReadingWidgetProvider.updateAll(appContext)
                        TimerNotification.refresh(appContext)
                        result.success(null)
                    }
                    "consumeLaunchBookId" -> {
                        result.success(pendingBookId)
                        pendingBookId = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    /** Returns true when the intent came from a widget or timer notification tap. */
    fun handleIntent(intent: Intent?, appRunning: Boolean): Boolean {
        if (intent?.action != ReadingWidgetProvider.ACTION_OPEN_BOOK) return false
        val bookId = intent.getIntExtra(ReadingWidgetProvider.EXTRA_BOOK_ID, -1)
        if (bookId < 0) return false
        intent.action = null
        val ch = channel
        if (appRunning && ch != null) ch.invokeMethod("openBook", bookId) else pendingBookId = bookId
        return true
    }

    fun notifyTimerChanged(bookId: Int) {
        channel?.invokeMethod("timerChanged", bookId)
    }
}
