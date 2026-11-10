package com.frecu.frecu

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.KeyEvent
import androidx.media.VolumeProviderCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Hablar con el botón de volumen (solo Android), por los canales
 * `frecu/volume_ptt` (activar) y `frecu/volume_ptt/events` (pulsaciones).
 *
 * - Con la app al frente, la actividad recibe las teclas antes que el
 *   sistema: «down» al pulsar y «up» al soltar, para mantener pulsado y
 *   hablar. El volumen no cambia.
 * - Con la pantalla apagada las teclas no llegan a la actividad. La sesión
 *   de medios de Frecu ([FrecuMediaSession]), con volumen propio, recibe cada
 *   pulsación como un ajuste, sin soltar: se envía «toggle» (pulsa para
 *   empezar y otra vez para terminar).
 */
object VolumePtt {
    private const val METHODS = "frecu/volume_ptt"
    private const val EVENTS = "frecu/volume_ptt/events"

    private val main = Handler(Looper.getMainLooper())
    private var sink: EventChannel.EventSink? = null
    private var provider: VolumeProviderCompat? = null
    private var appContext: Context? = null

    /** Activado por la app: preferencia encendida y una frecu abierta. */
    @Volatile
    var enabled = false
        private set

    fun install(context: Context, messenger: BinaryMessenger) {
        appContext = context.applicationContext
        MethodChannel(messenger, METHODS).setMethodCallHandler { call, result ->
            when (call.method) {
                "setEnabled" -> {
                    setEnabled(call.arguments as? Boolean ?: false)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        EventChannel(messenger, EVENTS).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                sink = events
            }

            override fun onCancel(arguments: Any?) {
                sink = null
            }
        })
    }

    private fun setEnabled(on: Boolean) {
        enabled = on
        if (on) startSession() else stopSession()
    }

    /**
     * Teclas de la actividad al frente; devuelve si las usó (y entonces el
     * volumen no cambia).
     */
    fun onKey(event: KeyEvent): Boolean {
        if (!enabled) return false
        if (event.keyCode != KeyEvent.KEYCODE_VOLUME_UP &&
            event.keyCode != KeyEvent.KEYCODE_VOLUME_DOWN
        ) {
            return false
        }
        when (event.action) {
            KeyEvent.ACTION_DOWN -> if (event.repeatCount == 0) emit("down")
            KeyEvent.ACTION_UP -> emit("up")
        }
        return true
    }

    private fun emit(event: String) {
        main.post { sink?.success(event) }
    }

    private fun startSession() {
        if (provider != null) return
        val context = appContext ?: return
        val volume = object : VolumeProviderCompat(
            VOLUME_CONTROL_RELATIVE,
            100,
            50,
        ) {
            override fun onAdjustVolume(direction: Int) {
                if (direction != 0) emit("toggle")
            }
        }
        provider = volume
        FrecuMediaSession.setVolumeProvider(context, volume)
    }

    private fun stopSession() {
        if (provider == null) return
        provider = null
        appContext?.let { FrecuMediaSession.setVolumeProvider(it, null) }
    }
}
