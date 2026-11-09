package com.frecu.frecu

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Sensor de proximidad por `frecu/proximity` (activar) y
 * `frecu/proximity/events` (`true` cerca, `false` lejos).
 *
 * Mientras está activado, el bloqueo de proximidad apaga la pantalla cuando
 * el teléfono está en la oreja (como en una llamada) y la enciende al
 * alejarlo; así no se toca nada con la mejilla.
 */
object FrecuProximity {
    private const val METHODS = "frecu/proximity"
    private const val EVENTS = "frecu/proximity/events"

    private val main = Handler(Looper.getMainLooper())
    private var sink: EventChannel.EventSink? = null
    private var appContext: Context? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var near: Boolean? = null

    private val listener = object : SensorEventListener {
        override fun onSensorChanged(event: SensorEvent) {
            val distance = event.values.firstOrNull() ?: return
            val isNear = distance < event.sensor.maximumRange.coerceAtMost(5f)
            if (isNear == near) return
            near = isNear
            main.post { sink?.success(isNear) }
        }

        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit
    }

    fun install(context: Context, messenger: BinaryMessenger) {
        appContext = context.applicationContext
        MethodChannel(messenger, METHODS).setMethodCallHandler { call, result ->
            when (call.method) {
                "setEnabled" -> result.success(setEnabled(call.arguments as? Boolean ?: false))
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

    /** Activa o desactiva el sensor; devuelve si el teléfono tiene uno. */
    private fun setEnabled(on: Boolean): Boolean {
        val context = appContext ?: return false
        val sensors = context.getSystemService(Context.SENSOR_SERVICE) as? SensorManager
        val sensor = sensors?.getDefaultSensor(Sensor.TYPE_PROXIMITY) ?: return false
        if (on) {
            sensors.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_NORMAL)
            val power = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
            if (wakeLock == null &&
                power?.isWakeLockLevelSupported(PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK) == true
            ) {
                wakeLock = power.newWakeLock(
                    PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK,
                    "frecu:proximity",
                ).apply { acquire() }
            }
        } else {
            sensors.unregisterListener(listener)
            wakeLock?.let { if (it.isHeld) it.release() }
            wakeLock = null
            near = null
        }
        return true
    }
}
