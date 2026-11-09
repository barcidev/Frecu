package com.frecu.frecu

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.LocationManager
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.net.Inet4Address
import java.net.NetworkInterface

/**
 * Red de la frecu (canal `frecu/hotspot`): la zona Wi-Fi local que Android
 * crea para la app con `LocalOnlyHotspot`, sin internet y con nombre y clave
 * nuevos cada vez.
 *
 * La reserva vive en el proceso, no en la actividad: sigue al aire mientras
 * corre el servicio en primer plano de la frecu, y Android la apaga si el
 * proceso muere. `stopped` avisa a Dart cuando Android la apaga por su
 * cuenta (se encendió la zona Wi-Fi, modo avión…).
 *
 * `start` devuelve el nombre, la clave y, si aparece, la interfaz de la red
 * y la IPv4 de este teléfono en ella, o un error con el código que traduce
 * Dart: `unsupported`, `permission_nearby`, `permission_location`,
 * `location_off`, `incompatible_mode`, `no_channel`, `disallowed` o
 * `failed`.
 */
internal object LocalHotspot {
    private const val TAG = "Frecu"
    private const val CHANNEL = "frecu/hotspot"

    /** Cuánto se espera a que la interfaz de la red tenga su IPv4. */
    private const val INTERFACE_WAIT_MS = 3_000L
    private const val INTERFACE_POLL_MS = 150L

    /** Datos móviles, VPN y túneles: nunca son la interfaz de la red. */
    private val NOT_LAN = Regex(
        "^(lo|pdp_ip|rmnet|rev_rmnet|ccmni|clat|v4-|seth|wwan|radio|tun|tap|ppp|p2p|dummy|ifb|sit|ip6|ipsec)",
    )

    private val main = Handler(Looper.getMainLooper())
    private var channel: MethodChannel? = null
    private var reservation: WifiManager.LocalOnlyHotspotReservation? = null
    private var info: Map<String, String?>? = null
    private var pending: MutableList<MethodChannel.Result>? = null

    fun install(context: Context, messenger: BinaryMessenger) {
        val app = context.applicationContext
        channel = MethodChannel(messenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> start(app, result)
                    "stop" -> {
                        stop()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun start(context: Context, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.error("unsupported", null, null)
            return
        }
        info?.let {
            result.success(it)
            return
        }
        pending?.let {
            it.add(result)
            return
        }
        missingPermission(context)?.let {
            result.error(it, null, null)
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU && !locationEnabled(context)) {
            result.error("location_off", null, null)
            return
        }
        val wifi = context.getSystemService(WifiManager::class.java)
        if (wifi == null) {
            result.error("unsupported", null, null)
            return
        }
        pending = mutableListOf(result)
        request(context, wifi)
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun request(context: Context, wifi: WifiManager) {
        val before = ipv4Interfaces().keys
        try {
            wifi.startLocalOnlyHotspot(
                object : WifiManager.LocalOnlyHotspotCallback() {
                    override fun onStarted(started: WifiManager.LocalOnlyHotspotReservation) {
                        reservation = started
                        // La IPv4 de la interfaz llega un poco después: se espera fuera del hilo principal.
                        Thread {
                            val lan = awaitInterface(before)
                            main.post { publish(started, lan) }
                        }.start()
                    }

                    override fun onStopped() {
                        val wasUp = reservation != null
                        reservation = null
                        info = null
                        reply { it.error("failed", "stopped", null) }
                        if (wasUp) channel?.invokeMethod("stopped", null)
                    }

                    override fun onFailed(reason: Int) {
                        reservation = null
                        info = null
                        reply { it.error(failureCode(reason), null, null) }
                    }
                },
                main,
            )
        } catch (error: SecurityException) {
            Log.w(TAG, "Local hotspot needs a permission", error)
            reply { it.error(permissionCode(), error.message, null) }
        } catch (error: RuntimeException) {
            Log.w(TAG, "Could not start the local hotspot", error)
            reply { it.error("failed", error.message, null) }
        }
    }

    /** Responde a quienes esperaban la red, ya con su interfaz si apareció. */
    @RequiresApi(Build.VERSION_CODES.O)
    private fun publish(started: WifiManager.LocalOnlyHotspotReservation, lan: Pair<String, String>?) {
        if (reservation !== started) return
        val (ssid, passphrase) = credentials(started)
        if (ssid.isNullOrEmpty()) {
            stop()
            reply { it.error("failed", "no ssid", null) }
            return
        }
        val described = mapOf(
            "ssid" to ssid,
            "passphrase" to passphrase,
            "interface" to lan?.first,
            "address" to lan?.second,
        )
        info = described
        reply { it.success(described) }
    }

    fun stop() {
        try {
            reservation?.close()
        } catch (error: RuntimeException) {
            Log.w(TAG, "Could not stop the local hotspot", error)
        }
        reservation = null
        info = null
    }

    private fun reply(answer: (MethodChannel.Result) -> Unit) {
        val waiting = pending ?: return
        pending = null
        waiting.forEach(answer)
    }

    /** Nombre y clave de la red, sin comillas. */
    @Suppress("DEPRECATION")
    @RequiresApi(Build.VERSION_CODES.O)
    private fun credentials(started: WifiManager.LocalOnlyHotspotReservation): Pair<String?, String?> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val config = started.softApConfiguration
            val ssid = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                config.wifiSsid?.toString()
            } else {
                config.ssid
            }
            return ssid?.removeSurrounding("\"") to config.passphrase
        }
        val config = started.wifiConfiguration
        return config?.SSID?.removeSurrounding("\"") to config?.preSharedKey?.removeSurrounding("\"")
    }

    /**
     * La interfaz que apareció con la red y su IPv4, esperando a que tenga
     * dirección; nula si no aparece a tiempo.
     */
    private fun awaitInterface(before: Set<String>): Pair<String, String>? {
        val deadline = System.currentTimeMillis() + INTERFACE_WAIT_MS
        while (System.currentTimeMillis() < deadline) {
            ipv4Interfaces().entries.firstOrNull { it.key !in before }?.let { return it.toPair() }
            try {
                Thread.sleep(INTERFACE_POLL_MS)
            } catch (_: InterruptedException) {
                return null
            }
        }
        return null
    }

    /** Interfaces encendidas con IPv4 de red local, por nombre. */
    private fun ipv4Interfaces(): Map<String, String> = try {
        NetworkInterface.getNetworkInterfaces()?.toList().orEmpty()
            .filter { it.isUp && !it.isLoopback && !NOT_LAN.containsMatchIn(it.name) }
            .mapNotNull { iface ->
                iface.inetAddresses.toList()
                    .filterIsInstance<Inet4Address>()
                    .firstOrNull { !it.isLinkLocalAddress && !it.isLoopbackAddress }
                    ?.let { iface.name to (it.hostAddress ?: return@let null) }
            }
            .toMap()
    } catch (error: Exception) {
        Log.w(TAG, "Could not list the network interfaces", error)
        emptyMap()
    }

    private fun missingPermission(context: Context): String? {
        val (permission, code) = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Manifest.permission.NEARBY_WIFI_DEVICES to "permission_nearby"
        } else {
            Manifest.permission.ACCESS_FINE_LOCATION to "permission_location"
        }
        val granted = context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
        return if (granted) null else code
    }

    private fun permissionCode(): String =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) "permission_nearby" else "permission_location"

    @Suppress("DEPRECATION")
    private fun locationEnabled(context: Context): Boolean {
        val location = context.getSystemService(LocationManager::class.java) ?: return true
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            location.isLocationEnabled
        } else {
            location.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                location.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        }
    }

    private fun failureCode(reason: Int): String = when (reason) {
        WifiManager.LocalOnlyHotspotCallback.ERROR_INCOMPATIBLE_MODE -> "incompatible_mode"
        WifiManager.LocalOnlyHotspotCallback.ERROR_NO_CHANNEL -> "no_channel"
        WifiManager.LocalOnlyHotspotCallback.ERROR_TETHERING_DISALLOWED -> "disallowed"
        else -> "failed"
    }
}
