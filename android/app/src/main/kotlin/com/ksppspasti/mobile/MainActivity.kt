package com.ksppspasti.mobile

import android.app.ActivityManager
import android.app.ApplicationExitInfo
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Address
import android.location.Geocoder
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.concurrent.thread

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val CHANNEL = "com.ksppspasti.mobile/app_lifecycle"
        private const val LOCATION_CHANNEL = "com.ksppspasti.mobile/location_address"
        private const val KYC_IMAGE_CHANNEL = "com.ksppspasti.mobile/kyc_image"
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "reverseGeocode" -> {
                        val lat = call.argument<Double>("lat")
                        val lng = call.argument<Double>("lng")
                        if (lat == null || lng == null) {
                            result.error("INVALID_ARGS", "Koordinat lokasi tidak valid.", null)
                        } else {
                            reverseGeocodeCoordinates(lat, lng, result)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, KYC_IMAGE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "normalizeCapturedPhoto" -> {
                        val path = call.argument<String>("path")
                        val mirrorHorizontal = call.argument<Boolean>("mirrorHorizontal") ?: false
                        val cropToKtpLandscape = call.argument<Boolean>("cropToKtpLandscape") ?: false
                        val rotateDegrees = call.argument<Int>("rotateDegrees") ?: 0
                        val targetAspectRatio = call.argument<Double>("targetAspectRatio") ?: 1.585
                        if (path.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "Path foto tidak valid.", null)
                        } else {
                            val mainHandler = Handler(Looper.getMainLooper())
                            thread(start = true) {
                                val normalizedPath = KycImageNormalizer.normalizeCapturedPhoto(
                                    cacheDir = cacheDir,
                                    sourcePath = path,
                                    mirrorHorizontal = mirrorHorizontal,
                                    cropToKtpLandscape = cropToKtpLandscape,
                                    rotateDegrees = rotateDegrees,
                                    targetAspectRatio = targetAspectRatio,
                                )
                                mainHandler.post { result.success(normalizedPath) }
                            }
                        }
                    }
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

    private fun reverseGeocodeCoordinates(
        lat: Double,
        lng: Double,
        result: MethodChannel.Result
    ) {
        if (!Geocoder.isPresent()) {
            result.success(null)
            return
        }

        val geocoder = Geocoder(this, Locale.forLanguageTag("id-ID"))
        val mainHandler = Handler(Looper.getMainLooper())
        val replied = AtomicBoolean(false)

        fun replyOnce(payload: Map<String, String>?) {
            if (replied.compareAndSet(false, true)) {
                mainHandler.post { result.success(payload) }
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            try {
                geocoder.getFromLocation(lat, lng, 1, object : Geocoder.GeocodeListener {
                    override fun onGeocode(addresses: MutableList<Address>) {
                        replyOnce(addresses.firstOrNull()?.let { mapAndroidAddress(it) })
                    }

                    override fun onError(errorMessage: String?) {
                        replyOnce(null)
                    }
                })
            } catch (_: Exception) {
                replyOnce(null)
            }
        } else {
            thread(start = true) {
                val payload = try {
                    @Suppress("DEPRECATION")
                    val list = geocoder.getFromLocation(lat, lng, 1)
                    list?.firstOrNull()?.let { mapAndroidAddress(it) }
                } catch (_: Exception) {
                    null
                }
                replyOnce(payload)
            }
        }
    }

    private fun mapAndroidAddress(address: Address): Map<String, String> {
        val street = listOfNotNull(address.thoroughfare, address.subThoroughfare)
            .filter { it.isNotBlank() }
            .joinToString(" ")
        return mapOf(
            "formattedAddress" to (address.getAddressLine(0) ?: ""),
            "street" to street,
            "kelurahan" to (address.subLocality ?: ""),
            "kecamatan" to (address.locality ?: ""),
            "kabupatenKota" to (address.subAdminArea ?: ""),
            "provinsi" to (address.adminArea ?: "")
        )
    }
}
