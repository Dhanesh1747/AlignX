package com.example.alignx_frontend

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.widget.Toast

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.alignx/notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "showPostureReminder") {
                Toast.makeText(this, "⚠️ AlignX Posture Check: Sit up straight and align your spine!", Toast.LENGTH_LONG).show()
                result.success("Notification Delivered")
            } else {
                result.notImplemented()
            }
        }
    }
}
