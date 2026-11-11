package com.ksppspasti.mobile

import android.app.ActivityManager
import android.app.ApplicationExitInfo
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val CHANNEL = "com.ksppspasti.mobile/app_lifecycle"
        private const val PREFS_NAME = "app_lifecycle_prefs"
        private const val KEY_LAST_VERSION_CODE = "last_version_code"
    }

    private var shouldSkipSplash: Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        shouldSkipSplash = determineShouldSkipSplash(savedInstanceState)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shouldSkipSplash" -> result.success(shouldSkipSplash)
                    else -> result.notImplemented()
                }
            }
    }

    private fun determineShouldSkipSplash(savedInstanceState: Bundle?): Boolean {
        val currentVersionCode = getCurrentVersionCode()
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val lastVersionCode = prefs.getLong(KEY_LAST_VERSION_CODE, -1L)
        if (lastVersionCode != currentVersionCode) {
            prefs.edit().putLong(KEY_LAST_VERSION_CODE, currentVersionCode).apply()
            return false
        }

        // Android sedang memulihkan Activity/Task yang hanya di-minimize (belum benar-benar ditutup)
        if (savedInstanceState != null) {
            return true
        }

        val launchedFromHistory =
            ((intent?.flags ?: 0) and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
            val lastExit = activityManager
                ?.getHistoricalProcessExitReasons(packageName, 0, 1)
                ?.firstOrNull()

            if (lastExit != null) {
                return when (lastExit.reason) {
                    ApplicationExitInfo.REASON_LOW_MEMORY,
                    ApplicationExitInfo.REASON_EXCESSIVE_RESOURCE_USAGE,
                    14 /* ApplicationExitInfo.REASON_FREEZER (API 34+) */ -> true
                    ApplicationExitInfo.REASON_OTHER -> launchedFromHistory
                    else -> false
                }
            }
        }

        return launchedFromHistory
    }

    private fun getCurrentVersionCode(): Long {
        return try {
            val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, 0)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                info.longVersionCode
            } else {
                @Suppress("DEPRECATION")
                info.versionCode.toLong()
            }
        } catch (_: Exception) {
            -1L
        }
    }
}
