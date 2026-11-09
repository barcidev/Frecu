package com.frecu.frecu

import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Vibración de la frecu por el canal `frecu/haptics`.
 *
 * Vibra como aviso de comunicación (`USAGE_COMMUNICATION_REQUEST`), que el
 * sistema deja pasar con la pantalla apagada y en ahorro de batería, a
 * diferencia de la respuesta táctil normal, que se apaga si la persona
 * desactivó la vibración al tocar.
 */
object FrecuHaptics {
    private const val CHANNEL = "frecu/haptics"

    /** Esperas y pulsos en milisegundos de cada patrón (ver HapticPattern). */
    private val patterns = mapOf(
        "tick" to longArrayOf(0, 22),
        "talk" to longArrayOf(0, 28, 70, 28),
        "alert" to longArrayOf(0, 70, 90, 70),
        "sos" to longArrayOf(0, 420, 160, 420, 160, 420),
    )

    fun install(context: Context, messenger: BinaryMessenger) {
        val appContext = context.applicationContext
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method != "play") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val timings = patterns[call.arguments as? String]
            if (timings == null) {
                result.error("bad_pattern", "Unknown pattern ${call.arguments}", null)
                return@setMethodCallHandler
            }
            vibrate(appContext, timings)
            result.success(null)
        }
    }

    private fun vibrate(context: Context, timings: LongArray) {
        val vibrator = vibratorOf(context) ?: return
        if (!vibrator.hasVibrator()) return
        val effect = VibrationEffect.createWaveform(timings, -1)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            vibrator.vibrate(
                effect,
                VibrationAttributes.createForUsage(
                    VibrationAttributes.USAGE_COMMUNICATION_REQUEST,
                ),
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(
                effect,
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION_COMMUNICATION_REQUEST)
                    .build(),
            )
        }
    }

    private fun vibratorOf(context: Context): Vibrator? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)
                ?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
}
