package com.example.kutoot_mobile

import android.content.Intent
import com.razorpay.Checkout
import com.razorpay.ExternalWalletListener
import com.razorpay.PaymentData
import com.razorpay.PaymentResultWithDataListener
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

/**
 * Native Razorpay [Checkout.open] from the host activity so UPI **intent** (PhonePe, GPay, …)
 * is more reliable than the plugin’s CheckoutActivity/WebView path, which often falls back
 * to UPI Collect (manual @VPA).
 */
class MainActivity : FlutterActivity(), PaymentResultWithDataListener, ExternalWalletListener {

    private var razorpayChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
                        val json = unwrapToJsonObject(raw)
                        val checkout = Checkout()
                        checkout.setKeyID(json.getString("key"))
                        checkout.open(this, json)
                        result.success(null)
                    } catch (e: Exception) {
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
