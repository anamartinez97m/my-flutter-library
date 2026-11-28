package com.anamm.mylibrary.widget

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.graphics.Typeface
import android.os.Bundle
import android.text.TextUtils
import android.view.Gravity
import android.view.View
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

/** Lets you pick which Started book a widget shows, when adding or reconfiguring it. */
class ReadingWidgetConfigureActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        setResult(RESULT_CANCELED, resultIntent())
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }
        setContentView(buildContent())
    }

    private fun buildContent(): View {
        val store = WidgetStore(this)
        val colors = store.colors()
        val density = resources.displayMetrics.density
        fun px(dp: Int) = (dp * density).toInt()

        val list = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(px(20), px(20), px(20), px(20))
        }
        list.addView(TextView(this).apply {
            text = store.string("pickTitle")
            textSize = 22f
            setTypeface(typeface, Typeface.BOLD)
            setTextColor(colors.text)
            setPadding(0, px(8), 0, px(16))
        })

        val books = store.startedBooks()
        if (books.isEmpty()) {
            list.addView(TextView(this).apply {
                text = store.string("pickEmpty")
                textSize = 15f
                setTextColor(colors.textMuted)
            })
        }
        val pinned = store.pinnedBook(appWidgetId)
        books.forEach { book ->
            val row = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setPadding(px(8), px(10), px(8), px(10))
                isClickable = true
                isFocusable = true
                if (book.id == pinned) setBackgroundColor(colors.track)
                setOnClickListener { choose(book.id) }
            }
            row.addView(
                ImageView(this).apply {
                    setImageBitmap(WidgetBitmaps.cover(book.coverPath, book.title, colors, density * 0.6f))
                },
                LinearLayout.LayoutParams(px(43), px(65)),
            )
            val texts = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(px(14), 0, 0, 0)
            }
            texts.addView(TextView(this).apply {
                text = book.title
                textSize = 16f
                setTypeface(typeface, Typeface.BOLD)
                setTextColor(colors.text)
                maxLines = 2
                ellipsize = TextUtils.TruncateAt.END
            })
            if (book.subtitle.isNotEmpty()) {
                texts.addView(TextView(this).apply {
                    text = book.subtitle
                    textSize = 13f
                    setTextColor(colors.textMuted)
                    maxLines = 1
                    ellipsize = TextUtils.TruncateAt.END
                })
            }
            val progress = listOf(book.progressText, if (book.percent >= 0) "${book.percent}%" else "")
                .filter { it.isNotEmpty() }.distinct().joinToString(" · ")
            if (progress.isNotEmpty()) {
                texts.addView(TextView(this).apply {
                    text = progress
                    textSize = 12f
                    setTextColor(colors.header)
                })
            }
            row.addView(texts, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
            list.addView(row)
        }

        return ScrollView(this).apply {
            setBackgroundColor(colors.background)
            fitsSystemWindows = true
            addView(list)
        }
    }

    private fun choose(bookId: Int) {
        WidgetStore(this).pin(appWidgetId, bookId)
        ReadingWidgetProvider.render(this, AppWidgetManager.getInstance(this), appWidgetId)
        setResult(RESULT_OK, resultIntent())
        finish()
    }

    private fun resultIntent() = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
}
