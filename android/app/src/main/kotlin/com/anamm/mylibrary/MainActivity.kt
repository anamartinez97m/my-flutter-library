package com.anamm.mylibrary

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsAnimation
import com.anamm.mylibrary.widget.WidgetBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var resyncInsetsOnFocus = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        WidgetBridge.attach(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        WidgetBridge.detach()
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WidgetBridge.handleIntent(intent, appRunning = false)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        WidgetBridge.handleIntent(intent, appRunning = true)
    }

    override fun onPause() {
        super.onPause()
        resyncInsetsOnFocus = true
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus && resyncInsetsOnFocus) {
            resyncInsetsOnFocus = false
            resyncImeInsets()
        }
    }

    // Flutter holds back keyboard insets while the keyboard animates and only
    // applies them when the animation ends. When the app is left with the
    // keyboard open, some devices never deliver that end (or the new insets),
    // so the old keyboard height stays as a blank space on return. End any
    // pending keyboard animation and ask for the current insets again.
    private fun resyncImeInsets() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return
        val flutterView = findViewById<View>(FLUTTER_VIEW_ID) ?: return
        flutterView.dispatchWindowInsetsAnimationEnd(
            WindowInsetsAnimation(WindowInsets.Type.ime(), null, 0),
        )
        flutterView.requestApplyInsets()
    }
}
