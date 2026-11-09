package com.frecu.frecu

import android.content.Context
import android.net.ConnectivityManager
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.net.Inet4Address
import java.net.Inet6Address
import java.net.InetAddress
import java.net.NetworkInterface
import org.webrtc.NetworkChangeDetector
import org.webrtc.NetworkChangeDetector.ConnectionType
import org.webrtc.NetworkChangeDetector.NetworkInformation
import org.webrtc.NetworkMonitor
import org.webrtc.NetworkMonitorAutoDetect

/**
 * Detector de redes de WebRTC que, además de las redes de Android, cuenta la
 * zona Wi-Fi de este teléfono.
 *
 * WebRTC solo junta candidatos ICE en las redes que conoce ConnectivityManager
 * y ata cada socket a una de ellas. La interfaz de la zona Wi-Fi propia
 * (`swlan0`, `ap0`, `wlan1`…) no es una red de Android, así que quien comparte
 * su zona Wi-Fi no tenía ninguna ruta de voz hacia quienes se conectan a ella:
 * la señalización llegaba («hablando») y el audio no.
 *
 * Desde Android 15 la zona Wi-Fi es una red local de Android, pero sin
 * internet, y el detector de WebRTC solo pide redes con internet. Este
 * detector suma cada interfaz de zona Wi-Fi que WebRTC no ve: con el
 * identificador de su red si la tiene (WebRTC ata los sockets a ella) o, si no,
 * con la red sin especificar (0), con la que WebRTC no los ata y salen directo
 * por la interfaz. Las demás redes siguen igual. La zona Wi-Fi se vuelve a
 * mirar cada pocos segundos, por si se enciende o se apaga con la frecu
 * abierta.
 */
internal class HotspotNetworkDetector(
    private val observer: NetworkChangeDetector.Observer,
    private val context: Context,
) : NetworkChangeDetector {
    private val inner = NetworkMonitorAutoDetect(ForwardingObserver(), context)
    private val handler = Handler(Looper.getMainLooper())

    @Volatile
    private var hotspot: List<NetworkInformation> = scan()

    @Volatile
    private var destroyed = false

    private val rescan = object : Runnable {
        override fun run() {
            if (destroyed) return
            refresh()
            handler.postDelayed(this, RESCAN_MS)
        }
    }

    init {
        handler.postDelayed(rescan, RESCAN_MS)
    }

    override fun getCurrentConnectionType(): ConnectionType {
        val type = inner.currentConnectionType
        // Solo con la zona Wi-Fi (sin datos ni Wi-Fi) igual hay red local.
        return if (type == ConnectionType.CONNECTION_NONE && hotspot.isNotEmpty()) {
            ConnectionType.CONNECTION_WIFI
        } else {
            type
        }
    }

    override fun supportNetworkCallback(): Boolean = inner.supportNetworkCallback()

    override fun getActiveNetworkList(): List<NetworkInformation>? {
        val networks = inner.activeNetworkList ?: return null
        return networks + hotspot
    }

    override fun destroy() {
        destroyed = true
        handler.removeCallbacks(rescan)
        inner.destroy()
    }

    /** Vuelve a mirar las interfaces y avisa a WebRTC si la zona Wi-Fi cambió. */
    @Synchronized
    private fun refresh() {
        val current = scan()
        if (current.map(::signature) == hotspot.map(::signature)) return
        hotspot.map { it.handle }.distinct().forEach(observer::onNetworkDisconnect)
        hotspot = current
        current.forEach(observer::onNetworkConnect)
    }

    /**
     * Interfaces de la zona Wi-Fi propia que WebRTC no ve: encendidas y con
     * IPv4, con el identificador de su red de Android si la tienen.
     */
    private fun scan(): List<NetworkInformation> = try {
        val seen = inner.activeNetworkList.orEmpty().map { it.name }.toSet()
        val handles = androidNetworkHandles()
        NetworkInterface.getNetworkInterfaces()?.toList().orEmpty()
            .filter { it.isUp && !it.isLoopback && it.name !in seen }
            .filter { HOTSPOT_INTERFACE.matches(it.name) }
            .mapNotNull { iface ->
                val addresses = iface.inetAddresses.toList().filter(::isUsable)
                if (addresses.none { it is Inet4Address }) return@mapNotNull null
                NetworkInformation(
                    iface.name,
                    ConnectionType.CONNECTION_WIFI,
                    ConnectionType.CONNECTION_NONE,
                    handles[iface.name] ?: UNSPECIFIED_HANDLE,
                    addresses.map { NetworkChangeDetector.IPAddress(it.address) }.toTypedArray(),
                    NetworkChangeDetector.NetworkSlice.NO_SLICE,
                )
            }
    } catch (error: Exception) {
        Log.w(TAG, "Could not look for the hotspot interface", error)
        emptyList()
    }

    /** Identificador de la red de Android de cada interfaz que la tiene. */
    @Suppress("DEPRECATION")
    private fun androidNetworkHandles(): Map<String, Long> {
        val connectivity = context.getSystemService(ConnectivityManager::class.java)
            ?: return emptyMap()
        return connectivity.allNetworks
            .mapNotNull { network ->
                connectivity.getLinkProperties(network)?.interfaceName
                    ?.let { name -> name to network.networkHandle }
            }
            .toMap()
    }

    private fun isUsable(address: InetAddress): Boolean = when (address) {
        is Inet4Address -> !address.isLoopbackAddress && !address.isLinkLocalAddress
        is Inet6Address -> !address.isLoopbackAddress && !address.isLinkLocalAddress
        else -> false
    }

    private fun signature(network: NetworkInformation): String =
        "${network.name}#${network.handle}:" +
            network.ipAddresses.joinToString { it.address.contentToString() }

    /** Pasa a WebRTC lo que detecta Android, con la clave de pruebas de campo de siempre. */
    private inner class ForwardingObserver : NetworkChangeDetector.Observer() {
        override fun onConnectionTypeChanged(newConnectionType: ConnectionType) =
            observer.onConnectionTypeChanged(newConnectionType)

        override fun onNetworkConnect(networkInfo: NetworkInformation) =
            observer.onNetworkConnect(networkInfo)

        override fun onNetworkDisconnect(networkHandle: Long) =
            observer.onNetworkDisconnect(networkHandle)

        override fun onNetworkPreference(types: List<ConnectionType>, preference: Int) =
            observer.onNetworkPreference(types, preference)

        override fun getFieldTrialsString(): String = observer.fieldTrialsString
    }

    companion object {
        private const val TAG = "Frecu"

        /** Red sin especificar: WebRTC no ata los sockets de esta interfaz. */
        const val UNSPECIFIED_HANDLE = 0L

        private const val RESCAN_MS = 5_000L

        /** Nombres de interfaces de zona Wi-Fi y anclaje (como `tetherable*Regexs`). */
        private val HOTSPOT_INTERFACE =
            Regex("^(wlan|softap|swlan|ap|ap_br_wlan|ap_br_softap|ap_br_swlan|rndis|ncm|usb|bt-pan)\\d*$")

        private var installed = false

        /**
         * Instala el detector para todo el proceso. Va antes de la primera
         * conexión de WebRTC (después WebRTC ya no deja cambiarlo); si algo
         * falla, WebRTC sigue con su detector de siempre.
         */
        @Synchronized
        fun install() {
            if (installed) return
            try {
                NetworkMonitor.getInstance().setNetworkChangeDetectorFactory { observer, context ->
                    try {
                        HotspotNetworkDetector(observer, context)
                    } catch (error: Throwable) {
                        Log.w(TAG, "Falling back to the default WebRTC network detector", error)
                        NetworkMonitorAutoDetect(observer, context)
                    }
                }
                installed = true
            } catch (error: Throwable) {
                Log.w(TAG, "Could not install the hotspot-aware WebRTC network detector", error)
            }
        }
    }
}
