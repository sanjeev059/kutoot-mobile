package com.example.kutoot_mobile

import android.content.Intent
import android.util.Log
import com.example.kutoot_mobile.upi.UpiAppsRepository
import com.razorpay.Checkout
import com.razorpay.ExternalWalletListener
import com.razorpay.PaymentData
import com.razorpay.PaymentResultWithDataListener
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

/**
 * Native Razorpay [Checkout.open] from the host activity so UPI **intent** (PhonePe, GPay, …)
 * is more reliable than the plugin’s CheckoutActivity/WebView path, which often falls back
 * to UPI Collect (manual @VPA).
 */
class MainActivity : FlutterFragmentActivity(), PaymentResultWithDataListener, ExternalWalletListener {

    private var razorpayChannel: MethodChannel? = null
    private var upiAppsChannel: MethodChannel? = null

    companion object {
        private const val TAG = "KutootRzp"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        upiAppsChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.kutoot.app/upi_apps",
        )
        upiAppsChannel?.setMethodCallHandler { call, res ->
            when (call.method) {
                "listInstalledUpiApps" -> {
                    try {
                        val rows = UpiAppsRepository.listUpiApps(packageManager)
                        val list = rows.map { r ->
                            mapOf(
                                "packageName" to r.packageName,
                                "label" to r.label,
                            )
                        }
                        res.success(list)
                    } catch (e: Exception) {
                        res.error("UPI_APPS", e.message, null)
                    }
                }
                else -> res.notImplemented()
            }
        }
        razorpayChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.kutoot.app/razorpay_native",
        )
        razorpayChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "open" -> {
                    try {
                        @Suppress("UNCHECKED_CAST")
                        val raw = call.argument<Any>("options")
                            ?: throw IllegalArgumentException("missing options")
                        var json = unwrapToJsonObject(raw)
                        json = mergeRazorpayUpiIntentPayload(json)
                        logRazorpayPayloadBeforeOpen(json)
                        val checkout = Checkout()
                        checkout.setKeyID(json.getString("key"))
                        checkout.open(this, json)
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e(TAG, "Checkout.open failed", e)
                        result.error("OPEN_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        try {
            Checkout.handleActivityResult(
                this,
                requestCode,
                resultCode,
                data,
                this,
                this,
            )
        } catch (_: Exception) {
        }
    }

    override fun onPaymentSuccess(razorpayPaymentId: String?, paymentData: PaymentData?) {
        Log.w(TAG, "onPaymentSuccess paymentId=${paymentData?.paymentId ?: razorpayPaymentId}")
        val payload = mapOf(
            "razorpay_payment_id" to (paymentData?.paymentId ?: razorpayPaymentId ?: ""),
            "razorpay_order_id" to (paymentData?.orderId ?: ""),
            "razorpay_signature" to (paymentData?.signature ?: ""),
        )
        razorpayChannel?.invokeMethod("onSuccess", payload)
    }

    override fun onPaymentError(code: Int, description: String?, paymentData: PaymentData?) {
        razorpayChannel?.invokeMethod(
            "onError",
            mapOf(
                "code" to code,
                "message" to (description ?: "Payment failed"),
            ),
        )
    }

    override fun onExternalWalletSelected(walletName: String?, paymentData: PaymentData?) {
        razorpayChannel?.invokeMethod(
            "onExternalWallet",
            mapOf("walletName" to (walletName ?: "")),
        )
    }

    private fun unwrapToJsonObject(value: Any): JSONObject {
        val wrapped = toJsonValue(value)
        if (wrapped is JSONObject) return wrapped
        return JSONObject().put("_raw", wrapped.toString())
    }

    /**
     * Razorpay Android: [method] = JSONObject.put("upi", true) + [upi_app_package_name] for intent.
     * See https://razorpay.com/docs/payments/payment-gateway/android-integration/standard/payment-methods/
     */
    private fun mergeRazorpayUpiIntentPayload(json: JSONObject): JSONObject {
        if (json.optString("_[flow]", "") != "intent") return json
        val pkg = json.optString("upi_app_package_name", "").trim()
        val method = JSONObject()
        method.put("upi", true)
        json.put("method", method)
        if (pkg.isNotEmpty()) {
            json.put("upi_app_package_name", pkg)
        } else {
            json.remove("upi_app_package_name")
        }
        if (!json.has("webview_intent")) {
            json.put("webview_intent", true)
        }
        return json
    }

    /**
     * Use WARN so lines show with default filters. Example:
     * `adb logcat KutootRzp:W *:S`
     * (`adb logcat -s KutootRzp` alone can omit tag:priority on some adb builds.)
     */
    private fun logRazorpayPayloadBeforeOpen(json: JSONObject) {
        val flow = json.optString("_[flow]", "")
        val pkg = json.optString("upi_app_package_name", "").trim()
        val method = json.opt("method")
        val key = json.optString("key", "")
        val keyMasked = when {
            key.length <= 8 -> "***"
            else -> key.take(8) + "…"
        }
        val installed = if (pkg.isNotEmpty()) {
            packageManager.getLaunchIntentForPackage(pkg) != null
        } else {
            null
        }
        Log.w(
            TAG,
            "Checkout.open flow=$flow order_id=${json.optString("order_id", "")} " +
                "amount=${json.optString("amount", "")} key=$keyMasked " +
                "method=$method upi_pkg=$pkg upi_installed=$installed " +
                "webview_intent=${json.opt("webview_intent")}",
        )
    }

    private fun toJsonValue(value: Any?): Any {
        return when (value) {
            null -> JSONObject.NULL
            is Map<*, *> -> {
                val o = JSONObject()
                for ((k, v) in value) {
                    if (k != null) o.put(k.toString(), toJsonValue(v))
                }
                o
            }
            is List<*> -> {
                val a = JSONArray()
                for (e in value) {
                    a.put(toJsonValue(e))
                }
                a
            }
            is Boolean -> value
            is Int -> value
            is Long -> value
            is Double -> value
            is Float -> value.toDouble()
            is String -> value
            else -> value.toString()
        }
    }
}
