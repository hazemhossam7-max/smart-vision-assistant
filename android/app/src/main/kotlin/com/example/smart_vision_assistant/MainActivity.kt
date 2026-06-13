package com.example.smart_vision_assistant

import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "smart_vision_assistant/device_security"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isRootRiskDetected" -> result.success(isRootRiskDetected())
                else -> result.notImplemented()
            }
        }
    }

    private fun isRootRiskDetected(): Boolean {
        val buildTags = Build.TAGS ?: ""
        if (buildTags.contains("test-keys")) {
            return true
        }

        val suspiciousPaths = listOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su",
            "/su/bin/su"
        )

        return suspiciousPaths.any { File(it).exists() }
    }
}
