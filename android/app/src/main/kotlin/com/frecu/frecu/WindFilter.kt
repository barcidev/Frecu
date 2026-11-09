package com.frecu.frecu

import com.cloudwebrtc.webrtc.FlutterWebRTCPlugin
import com.cloudwebrtc.webrtc.audio.AudioProcessingAdapter
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

/**
 * Filtro de viento por `frecu/wind_filter`: un paso alto Butterworth de 4.º
 * orden a [CUTOFF_HZ] sobre el micrófono, después del procesado de WebRTC
 * (eco, ruido, ganancia). Quita el retumbo grave del viento y del motor sin
 * tocar la voz, cuya inteligibilidad está por encima de 300 Hz.
 */
object WindFilter : AudioProcessingAdapter.ExternalAudioFrameProcessing {
    private const val CHANNEL = "frecu/wind_filter"
    private const val CUTOFF_HZ = 150.0

    /** Q de las dos secciones de un Butterworth de 4.º orden. */
    private val qs = doubleArrayOf(0.5411961, 1.3065630)

    private var sections = emptyArray<Biquad>()
    private var sampleRate = 0
    private var enabled = false

    /**
     * El plugin de WebRTC del motor de la app. No se usa
     * `FlutterWebRTCPlugin.sharedSingleton`: el servicio en primer plano
     * arranca un segundo motor que lo reemplaza por otro sin WebRTC.
     */
    private var plugin: FlutterWebRTCPlugin? = null

    fun install(messenger: BinaryMessenger, webrtc: FlutterWebRTCPlugin?) {
        plugin = webrtc
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method != "setEnabled") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            result.success(setEnabled(call.arguments as? Boolean ?: false))
        }
    }

    /** Activa o quita el filtro; devuelve si se pudo enganchar a WebRTC. */
    private fun setEnabled(on: Boolean): Boolean {
        val plugin = plugin ?: return false
        val capture = plugin.audioProcessingController?.capturePostProcessing ?: return false
        if (on == enabled) return true
        enabled = on
        if (on) capture.addProcessor(this) else capture.removeProcessor(this)
        return true
    }

    override fun initialize(sampleRateHz: Int, numChannels: Int) = configure(sampleRateHz)

    override fun reset(newRate: Int) = configure(newRate)

    @Synchronized
    private fun configure(sampleRateHz: Int) {
        if (sampleRateHz <= 0) return
        sampleRate = sampleRateHz
        sections = Array(qs.size) { Biquad.highPass(CUTOFF_HZ, sampleRateHz.toDouble(), qs[it]) }
    }

    /** Filtra en el sitio el tramo de [numFrames] muestras en coma flotante. */
    @Synchronized
    override fun process(numBands: Int, numFrames: Int, buffer: ByteBuffer) {
        // Cada tramo son 10 ms: la frecuencia sale de su largo, también si el
        // filtro se enganchó después de que WebRTC se inicializara.
        val rate = numFrames * 100
        if (rate != sampleRate) configure(rate)
        if (sections.isEmpty()) return
        val samples = buffer.order(ByteOrder.nativeOrder()).asFloatBuffer()
        val count = minOf(numFrames, samples.capacity())
        for (i in 0 until count) {
            var x = samples.get(i).toDouble()
            for (section in sections) x = section.next(x)
            samples.put(i, x.toFloat())
        }
    }

    /** Sección de segundo orden (forma directa I) del recetario de RBJ. */
    private class Biquad(
        private val b0: Double,
        private val b1: Double,
        private val b2: Double,
        private val a1: Double,
        private val a2: Double,
    ) {
        private var x1 = 0.0
        private var x2 = 0.0
        private var y1 = 0.0
        private var y2 = 0.0

        fun next(x: Double): Double {
            val y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
            x2 = x1
            x1 = x
            y2 = y1
            y1 = y
            return y
        }

        companion object {
            fun highPass(cutoff: Double, sampleRate: Double, q: Double): Biquad {
                val w0 = 2 * PI * cutoff / sampleRate
                val alpha = sin(w0) / (2 * q)
                val c = cos(w0)
                val a0 = 1 + alpha
                return Biquad(
                    b0 = (1 + c) / 2 / a0,
                    b1 = -(1 + c) / a0,
                    b2 = (1 + c) / 2 / a0,
                    a1 = -2 * c / a0,
                    a2 = (1 - alpha) / a0,
                )
            }
        }
    }
}
