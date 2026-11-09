package com.frecu.frecu

import android.content.Context
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.WifiNetworkSpecifier
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.net.Inet4Address

/**
 * Conexión del invitado a la red de la frecu (canal `frecu/wifi`).
 *
 * Una Wi-Fi sin internet, como la red de la frecu, no es la red por defecto
 * de Android si hay datos móviles: sin más, los sockets de la app saldrían
 * por los datos y no llegarían al anfitrión. Por eso la app se ata a la Wi-Fi
 * de la frecu mientras dura:
 *
 * - `route`: si el teléfono ya está en la red del anfitrión (`host`), ata la
 *   app a ella y la sigue: si esa red vuelve tras salir del rango, la ata de
 *   nuevo. Si no está, desata la app.
 * - `join`: conecta a la red `ssid` con el aviso del sistema
 *   (`WifiNetworkSpecifier`, Android 10 o posterior) y ata la app a ella. La
 *   petición sigue viva para que Android vuelva a conectar al regresar al
 *   rango. Errores: `unsupported` (Android 9 o anterior), `declined` (se
 *   canceló el aviso o la red no apareció en él) o `failed`.
 * - `release`: suelta la red (el teléfono vuelve a su Wi-Fi) y desata la app.
 */
internal object FrecuWifi {
    private const val TAG = "Frecu"
    private const val CHANNEL = "frecu/wifi"
    private val IPV4 = Regex("^\\d{1,3}(\\.\\d{1,3}){3}$")

    private val main = Handler(Looper.getMainLooper())
    private var joinCallback: ConnectivityManager.NetworkCallback? = null
    private var routeCallback: ConnectivityManager.NetworkCallback? = null
    private var pendingJoin: MethodChannel.Result? = null
    private var bound: Network? = null

    fun install(context: Context, messenger: BinaryMessenger) {
        val app = context.applicationContext
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "route" -> result.success(route(app, call.argument<String>("host")))
                "join" -> join(app, call.argument<String>("ssid"), call.argument<String>("passphrase"), result)
                "release" -> {
                    release(app)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun connectivity(context: Context): ConnectivityManager? =
        context.getSystemService(ConnectivityManager::class.java)

    @Suppress("DEPRECATION")
    private fun route(context: Context, host: String?): Boolean {
        val target = host?.takeIf(IPV4::matches)?.let(::ipv4) ?: return false
        val manager = connectivity(context) ?: return false
        unregister(manager, routeCallback)
        routeCallback = null
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onLinkPropertiesChanged(network: Network, properties: LinkProperties) {
                if (reaches(properties, target)) bind(manager, network)
            }

            override fun onLost(network: Network) {
                if (bound == network) bind(manager, null)
            }
        }
        val request = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
            .removeCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()
        try {
            manager.registerNetworkCallback(request, callback, main)
            routeCallback = callback
        } catch (error: RuntimeException) {
            Log.w(TAG, "Could not follow the room network", error)
        }
        val network = try {
            manager.allNetworks.firstOrNull { candidate ->
                manager.getLinkProperties(candidate)?.let { reaches(it, target) } == true
            }
        } catch (error: RuntimeException) {
            Log.w(TAG, "Could not list the networks", error)
            null
        }
        // Sin la red del anfitrión, la app no queda atada a una red vieja.
        bind(manager, network)
        return network != null
    }

    private fun join(context: Context, ssid: String?, passphrase: String?, result: MethodChannel.Result) {
        if (ssid.isNullOrEmpty()) {
            result.error("failed", "no ssid", null)
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.error("unsupported", null, null)
            return
        }
        val manager = connectivity(context)
        if (manager == null) {
            result.error("failed", "no connectivity", null)
            return
        }
        request(manager, ssid, passphrase, result)
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    private fun request(manager: ConnectivityManager, ssid: String, passphrase: String?, result: MethodChannel.Result) {
        unregister(manager, joinCallback)
        joinCallback = null
        pendingJoin?.error("declined", "superseded", null)
        pendingJoin = result
        val specifier = WifiNetworkSpecifier.Builder()
            .setSsid(ssid)
            .apply { if (!passphrase.isNullOrEmpty()) setWpa2Passphrase(passphrase) }
            .build()
        val request = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
            .removeCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .setNetworkSpecifier(specifier)
            .build()
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                bind(manager, network)
                pendingJoin?.success(null)
                pendingJoin = null
            }

            override fun onUnavailable() {
                if (joinCallback === this) joinCallback = null
                pendingJoin?.error("declined", null, null)
                pendingJoin = null
            }

            override fun onLost(network: Network) {
                if (bound == network) bind(manager, null)
            }
        }
        try {
            manager.requestNetwork(request, callback, main)
            joinCallback = callback
        } catch (error: RuntimeException) {
            Log.w(TAG, "Could not request the room network", error)
            pendingJoin = null
            result.error("failed", error.message, null)
        }
    }

    private fun release(context: Context) {
        val manager = connectivity(context) ?: return
        unregister(manager, joinCallback)
        joinCallback = null
        unregister(manager, routeCallback)
        routeCallback = null
        pendingJoin?.error("declined", "released", null)
        pendingJoin = null
        bind(manager, null)
    }

    private fun bind(manager: ConnectivityManager, network: Network?) {
        if (bound == network) return
        try {
            manager.bindProcessToNetwork(network)
            bound = network
        } catch (error: RuntimeException) {
            Log.w(TAG, "Could not bind the app to the room network", error)
        }
    }

    private fun unregister(manager: ConnectivityManager, callback: ConnectivityManager.NetworkCallback?) {
        if (callback == null) return
        try {
            manager.unregisterNetworkCallback(callback)
        } catch (_: RuntimeException) {
            // Ya no estaba registrada (p. ej. tras onUnavailable).
        }
    }

    /** Verdadero si [target] está en la subred de alguna IPv4 de [properties]. */
    private fun reaches(properties: LinkProperties, target: Int): Boolean =
        properties.linkAddresses.any { link ->
            val address = link.address as? Inet4Address ?: return@any false
            val prefix = link.prefixLength.coerceIn(0, 32)
            val mask = if (prefix == 0) 0 else -1 shl (32 - prefix)
            (toInt(address) and mask) == (target and mask)
        }

    private fun ipv4(text: String): Int? {
        val parts = text.split('.').map { it.toIntOrNull() ?: return null }
        if (parts.size != 4 || parts.any { it !in 0..255 }) return null
        return parts.fold(0) { value, part -> (value shl 8) or part }
    }

    private fun toInt(address: Inet4Address): Int =
        address.address.fold(0) { value, byte -> (value shl 8) or (byte.toInt() and 0xff) }
}
