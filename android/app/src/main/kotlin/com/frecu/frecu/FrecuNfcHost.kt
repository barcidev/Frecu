package com.frecu.frecu

import android.content.Context
import android.content.pm.PackageManager
import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * El teléfono como etiqueta NFC con la invitación (Host Card Emulation):
 * emula una etiqueta NDEF de tipo 4 (aplicación `D2760000850101`) de solo
 * lectura con un registro URI `frecu://join?…`. Quien acerque su teléfono la
 * lee como cualquier etiqueta: Android abre Frecu con el enlace, y Frecu en
 * «Por NFC» (también en iPhone) la lee directamente.
 *
 * Sirve la invitación mientras la app la fija por `frecu/nfc_host`
 * (`share` con la URI, o `null` para dejar de hacerlo); sin ella no responde
 * a la aplicación NDEF. Funciona con la pantalla encendida.
 */
class FrecuNfcHostService : HostApduService() {
    companion object {
        private const val CHANNEL = "frecu/nfc_host"

        /** Archivo NDEF que se sirve: NLEN (2 bytes) y el mensaje. */
        @Volatile
        private var ndefFile: ByteArray? = null

        private val NDEF_AID = hex("D2760000850101")
        private val CC_FILE_ID = hex("E103")
        private val NDEF_FILE_ID = hex("E104")
        private val OK = hex("9000")
        private val NOT_FOUND = hex("6A82")
        private val UNKNOWN = hex("6D00")
        private val WRONG_PARAMS = hex("6B00")

        /** Tamaño máximo del archivo NDEF que se anuncia en el CC. */
        private const val MAX_NDEF = 0x0400

        /**
         * Capability Container de una etiqueta tipo 4 v2.0: lectura libre y
         * escritura prohibida (solo lectura).
         */
        private val CC_FILE = byteArrayOf(
            0x00, 0x0F, // CCLEN
            0x20, // versión 2.0
            0x00, 0x7F, // MLe
            0x00, 0x7F, // MLc
            0x04, 0x06, // TLV del archivo NDEF
            0xE1.toByte(), 0x04, // id del archivo
            (MAX_NDEF shr 8).toByte(), (MAX_NDEF and 0xFF).toByte(),
            0x00, // lectura libre
            0xFF.toByte(), // sin escritura
        )

        fun install(context: Context, messenger: BinaryMessenger) {
            val hasHce = context.packageManager
                .hasSystemFeature(PackageManager.FEATURE_NFC_HOST_CARD_EMULATION)
            MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
                if (call.method != "share") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                ndefFile = (call.arguments as? String)?.let(::fileOf)
                result.success(hasHce)
            }
        }

        /** Archivo NDEF con un registro URI de [uri], sin prefijo abreviado. */
        internal fun fileOf(uri: String): ByteArray? {
            val payload = byteArrayOf(0x00) + uri.toByteArray(Charsets.UTF_8)
            val short = payload.size <= 0xFF
            val record = if (short) {
                // MB, ME, SR, TNF bien conocido.
                byteArrayOf(0xD1.toByte(), 0x01, payload.size.toByte(), 0x55) + payload
            } else {
                val n = payload.size
                byteArrayOf(
                    0xC1.toByte(), 0x01,
                    (n shr 24).toByte(), (n shr 16).toByte(), (n shr 8).toByte(), n.toByte(),
                    0x55,
                ) + payload
            }
            if (record.size + 2 > MAX_NDEF) return null
            return byteArrayOf((record.size shr 8).toByte(), record.size.toByte()) + record
        }

        private fun hex(text: String): ByteArray =
            text.chunked(2).map { it.toInt(16).toByte() }.toByteArray()
    }

    private enum class Selected { NONE, APP, CC, NDEF }

    private var selected = Selected.NONE

    override fun processCommandApdu(apdu: ByteArray, extras: Bundle?): ByteArray {
        val file = ndefFile
        if (apdu.size < 4) return UNKNOWN
        val ins = apdu[1].toInt() and 0xFF
        val p1 = apdu[2].toInt() and 0xFF
        return when (ins) {
            0xA4 -> select(apdu, p1, file)
            0xB0 -> read(apdu, p1, file)
            else -> UNKNOWN
        }
    }

    private fun select(apdu: ByteArray, p1: Int, file: ByteArray?): ByteArray {
        if (apdu.size < 5) return WRONG_PARAMS
        val length = apdu[4].toInt() and 0xFF
        if (apdu.size < 5 + length) return WRONG_PARAMS
        val data = apdu.copyOfRange(5, 5 + length)
        selected = when {
            p1 == 0x04 && data.contentEquals(NDEF_AID) && file != null -> Selected.APP
            p1 == 0x00 && selected != Selected.NONE && data.contentEquals(CC_FILE_ID) -> Selected.CC
            p1 == 0x00 && selected != Selected.NONE && data.contentEquals(NDEF_FILE_ID) -> Selected.NDEF
            else -> return NOT_FOUND.also { if (p1 == 0x04) selected = Selected.NONE }
        }
        return OK
    }

    private fun read(apdu: ByteArray, p1: Int, file: ByteArray?): ByteArray {
        val content = when (selected) {
            Selected.CC -> CC_FILE
            Selected.NDEF -> file ?: return NOT_FOUND
            else -> return NOT_FOUND
        }
        val offset = (p1 shl 8) or (apdu[3].toInt() and 0xFF)
        if (offset > content.size) return WRONG_PARAMS
        val wanted = if (apdu.size > 4) (apdu[4].toInt() and 0xFF).let { if (it == 0) 256 else it } else 256
        val end = minOf(content.size, offset + wanted)
        return content.copyOfRange(offset, end) + OK
    }

    override fun onDeactivated(reason: Int) {
        selected = Selected.NONE
    }
}
