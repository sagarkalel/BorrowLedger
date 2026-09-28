package com.example.borrow_ledger

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private companion object {
        const val UPI_CHANNEL = "com.example.borrow_ledger/upi"
        const val OPENED = "launched"
        const val UNAVAILABLE = "unavailable"

        val KNOWN_UPI_PACKAGES = mapOf(
            "com.google.android.apps.nbu.paisa.user" to "Google Pay",
            "com.phonepe.app" to "PhonePe",
            "net.one97.paytm" to "Paytm",
            "in.org.npci.upiapp" to "BHIM",
            "in.amazon.mShop.android.shopping" to "Amazon",
            "com.mobikwik_new" to "MobiKwik",
            "com.freecharge.android" to "Freecharge",
            "com.myairtel" to "Airtel Thanks",
            "com.dreamplug.androidapp" to "CRED",
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPI_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getUpiApps" -> result.success(findUpiApps().map { it.toMap() })
                    "openUpiApp" -> openUpiApp(call.argument<String>("packageName"), result)

                    else -> result.notImplemented()
                }
            }
    }

    private fun findUpiApps(): List<UpiApp> {
        val upiIntent = Intent(Intent.ACTION_VIEW, Uri.parse("upi://pay"))
        val intentApps = packageManager
            .queryIntentActivities(upiIntent, 0)
            .mapNotNull { resolveInfo ->
                val packageName = resolveInfo.activityInfo.packageName
                val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                    ?: return@mapNotNull null
                val label = packageManager
                    .getApplicationLabel(resolveInfo.activityInfo.applicationInfo)
                    .toString()
                UpiApp(
                    packageName = packageName,
                    label = label,
                    launchIntent = launchIntent,
                )
            }

        val knownApps = KNOWN_UPI_PACKAGES.mapNotNull { (packageName, fallbackLabel) ->
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                ?: return@mapNotNull null
            val label = runCatching {
                packageManager.getApplicationLabel(
                    packageManager.getApplicationInfo(packageName, 0),
                ).toString()
            }.getOrDefault(fallbackLabel)
            UpiApp(
                packageName = packageName,
                label = label,
                launchIntent = launchIntent,
            )
        }

        val upiApps = (intentApps + knownApps)
            .filter { it.packageName != packageName }
            .distinctBy { it.packageName }
            .sortedBy { it.label.lowercase() }

        return upiApps
    }

    private fun openUpiApp(packageName: String?, result: MethodChannel.Result) {
        if (packageName.isNullOrBlank()) {
            result.success(UNAVAILABLE)
            return
        }

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        if (launchIntent == null) {
            result.success(UNAVAILABLE)
            return
        }

        try {
            startActivity(launchIntent)
            result.success(OPENED)
        } catch (_: Exception) {
            result.success(UNAVAILABLE)
        }
    }

    private data class UpiApp(
        val packageName: String,
        val label: String,
        val launchIntent: Intent,
    ) {
        fun toMap(): Map<String, String> = mapOf(
            "packageName" to packageName,
            "label" to label,
        )
    }
}
