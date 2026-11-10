package com.frecu.frecu

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.media.AudioManager
import android.os.Bundle
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import android.view.KeyEvent
import androidx.core.content.IntentCompat
import androidx.media.VolumeProviderCompat

/**
 * La única sesión de medios de Frecu. La comparten dos partes:
 *
 * - [VolumePtt], que le pone un volumen propio para recibir el botón de
 *   volumen con la pantalla apagada;
 * - [FrecuRoomService], que la usa como reproductor: Android dibuja con ella
 *   la tarjeta de la frecu (como la de una app de música) en la cortina y en
 *   la pantalla bloqueada.
 *
 * Una sola sesión porque Android manda el volumen y los botones de los
 * audífonos a la sesión que suena; con dos, una le quitaría las teclas a la
 * otra. Vive mientras alguna de las dos la necesite y siempre está «sonando»:
 * así recibe las teclas y Android no esconde la tarjeta por estar en pausa.
 */
object FrecuMediaSession {
    private var session: MediaSessionCompat? = null
    private var volume: VolumeProviderCompat? = null
    private var player = false

    /**
     * Botones del reproductor y de los audífonos, por id (`mic`, `route`,
     * `leave`…). Lo atiende el servicio de la frecu.
     */
    var onAction: ((String) -> Unit)? = null

    /** Credencial de la sesión para el estilo de medios de la notificación. */
    val token: MediaSessionCompat.Token?
        get() = session?.sessionToken

    /** Volumen propio del botón de volumen para hablar, o `null` para soltarlo. */
    fun setVolumeProvider(context: Context, provider: VolumeProviderCompat?) {
        volume = provider
        sync(context)
    }

    /** Enciende o apaga el reproductor de la frecu. */
    fun setPlayer(context: Context, on: Boolean) {
        player = on
        sync(context)
    }

    /** Lo que abre la tarjeta al tocarla. */
    fun setActivity(intent: PendingIntent) {
        session?.setSessionActivity(intent)
    }

    /**
     * Muestra la frecu en el reproductor: [title] y [subtitle] como título y
     * artista, [art] como carátula (sin duración: no hay barra de progreso) y
     * [buttons] como acciones propias, con sus íconos.
     */
    fun show(title: String, subtitle: String, note: String?, art: Bitmap?, buttons: List<RoomButton>) {
        val current = session ?: return
        if (!player) return
        val metadata = MediaMetadataCompat.Builder()
            .putString(MediaMetadataCompat.METADATA_KEY_TITLE, title)
            .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, subtitle)
        if (note != null) metadata.putString(MediaMetadataCompat.METADATA_KEY_ALBUM, note)
        if (art != null) metadata.putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, art)
        current.setMetadata(metadata.build())
        current.setPlaybackState(state(buttons))
    }

    private fun sync(context: Context) {
        if (volume == null && !player) {
            release()
            return
        }
        val current = session ?: create(context)
        val provider = volume
        if (provider != null) {
            current.setPlaybackToRemote(provider)
        } else {
            // La voz de la frecu va por el canal de llamada: el volumen con la
            // pantalla apagada la sube y la baja a ella.
            current.setPlaybackToLocal(AudioManager.STREAM_VOICE_CALL)
        }
        if (!player) {
            current.setMetadata(null)
            current.setPlaybackState(state(emptyList()))
        }
    }

    /**
     * Siempre «sonando», sin reproducir ni pausar: el botón grande de Android
     * sería play/pausa, y en pausa Android esconde la tarjeta a los minutos.
     * Los botones van como acciones propias, con los íconos de Frecu.
     */
    private fun state(buttons: List<RoomButton>): PlaybackStateCompat {
        val builder = PlaybackStateCompat.Builder()
            .setState(
                PlaybackStateCompat.STATE_PLAYING,
                PlaybackStateCompat.PLAYBACK_POSITION_UNKNOWN,
                1f,
            )
            .setActions(0L)
        for (button in buttons) {
            builder.addCustomAction(
                PlaybackStateCompat.CustomAction.Builder(button.id, button.label, button.icon).build(),
            )
        }
        return builder.build()
    }

    private fun create(context: Context): MediaSessionCompat {
        val created = MediaSessionCompat(context.applicationContext, "Frecu").apply {
            setCallback(callback)
            setPlaybackState(state(emptyList()))
            isActive = true
        }
        session = created
        return created
    }

    private fun release() {
        session?.run {
            isActive = false
            release()
        }
        session = null
    }

    private val callback = object : MediaSessionCompat.Callback() {
        override fun onCustomAction(action: String?, extras: Bundle?) {
            if (action != null) onAction?.invoke(action)
        }

        /** Play/pausa de los audífonos: habla y corta, como el botón grande. */
        override fun onMediaButtonEvent(mediaButtonEvent: Intent): Boolean {
            val event = IntentCompat.getParcelableExtra(
                mediaButtonEvent,
                Intent.EXTRA_KEY_EVENT,
                KeyEvent::class.java,
            ) ?: return false
            return when (event.keyCode) {
                KeyEvent.KEYCODE_HEADSETHOOK,
                KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE,
                KeyEvent.KEYCODE_MEDIA_PLAY,
                KeyEvent.KEYCODE_MEDIA_PAUSE,
                -> {
                    if (player && event.action == KeyEvent.ACTION_DOWN && event.repeatCount == 0) {
                        onAction?.invoke("mic")
                    }
                    true
                }
                else -> false
            }
        }
    }
}

/** Botón de la frecu: [id] para la app, [label] accesible e [icon] dibujable. */
data class RoomButton(val id: String, val label: String, val icon: Int)
