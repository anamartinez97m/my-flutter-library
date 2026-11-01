package com.anamm.mylibrary

import android.os.Build
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsAnimation
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    private var resyncInsetsOnFocus = false

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
