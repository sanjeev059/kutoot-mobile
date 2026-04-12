package com.example.kutoot_mobile.upi

import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.net.Uri
import android.os.Build
/**
 * Discovers activities that handle [upi://pay] (repository layer for UPI app list).
 */
object UpiAppsRepository {

    private val preferredOrder = listOf(
        "com.google.android.apps.nbu.paisa.user",
        "com.phonepe.app",
        "net.one97.paytm",
        "in.org.npci.upiapp",
    )

    data class Row(
        val packageName: String,
        val label: String,
    )

    fun listUpiApps(pm: PackageManager): List<Row> {
        val uri = Uri.parse("upi://pay")
        val intent = Intent(Intent.ACTION_VIEW, uri)
        // Android 11+: broader resolution so GPay/PhonePe/etc. show up in the picker list.
        val flags =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                PackageManager.MATCH_DEFAULT_ONLY or PackageManager.MATCH_ALL
            } else {
                PackageManager.MATCH_DEFAULT_ONLY
            }
        val list: List<ResolveInfo> =
            try {
                pm.queryIntentActivities(intent, flags)
            } catch (_: Exception) {
                emptyList()
            }

        val rows = LinkedHashMap<String, Row>()
        for (ri in list) {
            val ai = ri.activityInfo ?: continue
            val pkg = ai.packageName ?: continue
            if (pkg == "com.android.chrome") continue
            val label = try {
                ri.loadLabel(pm).toString().ifBlank { pkg }
            } catch (_: Exception) {
                pkg
            }
            rows[pkg] = Row(packageName = pkg, label = label)
        }

        val ordered = mutableListOf<Row>()
        for (p in preferredOrder) {
            rows.remove(p)?.let { ordered.add(it) }
        }
        ordered.addAll(rows.values.sortedBy { it.label.lowercase() })
        return ordered
    }
}
