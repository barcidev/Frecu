package com.frecu.frecu

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Servicio en primer plano de la frecu activa (canal `frecu/room_service`).
 *
 * Mantiene la voz con la pantalla apagada (micrófono y, si se comparte, la
 * ubicación) y muestra la frecu como un reproductor: una notificación de
 * medios atada a [FrecuMediaSession], con la carátula que dibuja la app, el
 * nombre de la frecu, lo que pasa en ella y sus botones. Los toques vuelven a
 * la app por el mismo canal (`action` con el id del botón).
 *
 * La app manda todo ya traducido y dibujado: `start` con el nombre del canal
 * de notificaciones y el contenido, `update` con el contenido nuevo,
 * `setLocation` y `stop`.
 */
class FrecuRoomService : Service() {
    companion object {
        private const val TAG = "FrecuRoomService"
        private const val METHODS = "frecu/room_service"
        private const val CHANNEL_ID = "frecu_foreground_service"
        private const val NOTIFICATION_ID = 4780
        private const val ACTION_START = "com.frecu.frecu.room.START"
        private const val ACTION_BUTTON = "com.frecu.frecu.room.BUTTON"
        private const val EXTRA_BUTTON = "button"

        /** Extra del toque en la tarjeta: `invite` abre la frecu con el QR. */
        const val EXTRA_OPEN = "com.frecu.frecu.room.OPEN"

        private val main = Handler(Looper.getMainLooper())
        private var methods: MethodChannel? = null
        private var appContext: Context? = null
        private var content: RoomContent? = null
        private var location = false
        private var channelName = "Frecu"
        private var channelDescription = ""
        private var instance: FrecuRoomService? = null

        fun install(context: Context, messenger: BinaryMessenger) {
            val app = context.applicationContext
            appContext = app
            FrecuMediaSession.onAction = { id -> dispatch(id) }
            methods = MethodChannel(messenger, METHODS).apply {
                setMethodCallHandler { call, result ->
                    val args = call.arguments as? Map<*, *>
                    when (call.method) {
                        "start" -> {
                            channelName = args?.get("channelName") as? String ?: channelName
                            channelDescription =
                                args?.get("channelDescription") as? String ?: channelDescription
                            location = args?.get("location") == true
                            content = RoomContent.from(args?.get("content") as? Map<*, *>)
                            result.success(start(app))
                        }
                        "update" -> {
                            content = RoomContent.from(args)
                            instance?.render()
                            result.success(null)
                        }
                        "setLocation" -> {
                            location = call.arguments == true
                            instance?.promote()
                            result.success(null)
                        }
                        "stop" -> {
                            stop(app)
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                }
            }
        }

        /**
         * Sin motor de Flutter no hay frecu: la voz y la conexión viven en él.
         * Al soltarlo (la app se cierra) también se va el servicio.
         */
        fun uninstall(context: Context) {
            methods?.setMethodCallHandler(null)
            methods = null
            FrecuMediaSession.onAction = null
            stop(context.applicationContext)
        }

        /** El toque en la tarjeta pidió abrir la frecu con [open] (`invite`). */
        fun opened(open: String?) {
            if (open == "invite") dispatch("invite")
        }

        private fun start(context: Context): Boolean = try {
            ContextCompat.startForegroundService(
                context,
                Intent(context, FrecuRoomService::class.java).setAction(ACTION_START),
            )
            true
        } catch (e: Exception) {
            Log.e(TAG, "Could not start the room service", e)
            false
        }

        private fun stop(context: Context) {
            content = null
            location = false
            context.stopService(Intent(context, FrecuRoomService::class.java))
        }

        private fun dispatch(id: String) {
            val channel = methods
            if (channel == null) {
                // Sin la app no hay a quién avisar: «Salir» al menos se va.
                if (id == "leave") appContext?.let { stop(it) }
                return
            }
            main.post { channel.invokeMethod("action", id) }
        }
    }

    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        createChannel()
        // La voz sigue con la pantalla apagada.
        wakeLock = (getSystemService(Context.POWER_SERVICE) as PowerManager)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Frecu:Room")
            .apply {
                setReferenceCounted(false)
                acquire()
            }
        FrecuMediaSession.setPlayer(this, true)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_BUTTON) {
            intent.getStringExtra(EXTRA_BUTTON)?.let { dispatch(it) }
        }
        if (content == null) {
            // Un botón de una notificación vieja, sin frecu: nada que mostrar.
            stopSelf()
            return START_NOT_STICKY
        }
        if (intent?.action != ACTION_BUTTON) promote()
        // Si Android mata la app, la frecu no vuelve sola.
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    /** Cerrar la app desde recientes termina la frecu. */
    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        stopSelf()
    }

    override fun onDestroy() {
        instance = null
        wakeLock?.run { if (isHeld) release() }
        wakeLock = null
        FrecuMediaSession.setPlayer(this, false)
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }

    /**
     * Pasa (o vuelve a pasar) a primer plano con los tipos de ahora:
     * micrófono y, mientras se comparte, ubicación. Si Android no deja la
     * ubicación, sigue solo con el micrófono.
     */
    private fun promote() {
        val notification = build()
        try {
            ServiceCompat.startForeground(this, NOTIFICATION_ID, notification, types(location))
        } catch (e: Exception) {
            Log.w(TAG, "Foreground with location refused; microphone only", e)
            try {
                ServiceCompat.startForeground(this, NOTIFICATION_ID, notification, types(false))
            } catch (e2: Exception) {
                Log.e(TAG, "Could not start the room service in the foreground", e2)
                stopSelf()
                return
            }
        }
        showInPlayer()
    }

    private fun types(withLocation: Boolean): Int {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return 0
        var types = ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
        if (withLocation) types = types or ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
        return types
    }

    /** Cambia lo que se ve sin volver a pasar a primer plano. */
    private fun render() {
        if (content == null) return
        val manager = NotificationManagerCompat.from(this)
        if (manager.areNotificationsEnabled()) {
            try {
                manager.notify(NOTIFICATION_ID, build())
            } catch (e: SecurityException) {
                Log.w(TAG, "Notifications not allowed", e)
            }
        }
        showInPlayer()
    }

    private fun showInPlayer() {
        val current = content ?: return
        FrecuMediaSession.show(current.title, current.subtitle, current.note, current.art, current.buttons)
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        // Baja: sin sonido ni vibración; los avisos de la frecu ya vibran.
        val channel = NotificationChannel(CHANNEL_ID, channelName, NotificationManager.IMPORTANCE_LOW).apply {
            description = channelDescription
            setShowBadge(false)
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    private fun build(): Notification {
        val current = content ?: RoomContent.empty
        val open = openIntent(current.tapInvites)
        FrecuMediaSession.setActivity(open)
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_frecu)
            .setContentTitle(current.title)
            .setContentText(current.subtitle)
            .setSubText(current.note)
            .setLargeIcon(current.art)
            .setColor(current.accent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setShowWhen(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCategory(NotificationCompat.CATEGORY_TRANSPORT)
            .setContentIntent(open)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
        current.buttons.forEachIndexed { index, button ->
            builder.addAction(button.icon, button.label, buttonIntent(button.id, index))
        }
        val style = androidx.media.app.NotificationCompat.MediaStyle()
            .setShowActionsInCompactView(*IntArray(minOf(3, current.buttons.size)) { it })
        FrecuMediaSession.token?.let { style.setMediaSession(it) }
        builder.setStyle(style)
        return builder.build()
    }

    /** Abre la frecu; con [invite], con la hoja del QR. */
    private fun openIntent(invite: Boolean): PendingIntent {
        val intent = Intent(this, MainActivity::class.java)
            .setAction(Intent.ACTION_MAIN)
            .addCategory(Intent.CATEGORY_LAUNCHER)
            .addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP,
            )
        if (invite) intent.putExtra(EXTRA_OPEN, "invite")
        return PendingIntent.getActivity(
            this,
            if (invite) 2 else 1,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private fun buttonIntent(id: String, index: Int): PendingIntent = PendingIntent.getService(
        this,
        100 + index,
        Intent(this, FrecuRoomService::class.java)
            .setAction(ACTION_BUTTON)
            .putExtra(EXTRA_BUTTON, id),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )
}

/** Lo que muestra la frecu, tal como lo manda la app. */
private class RoomContent(
    val title: String,
    val subtitle: String,
    val note: String?,
    val accent: Int,
    val art: Bitmap?,
    val buttons: List<RoomButton>,
    val tapInvites: Boolean,
) {
    companion object {
        private const val SIGNAL = 0xFFC4E05C.toInt()

        val empty = RoomContent("Frecu", "", null, SIGNAL, null, emptyList(), false)

        private val icons = mapOf(
            "mic" to R.drawable.ic_nt_mic,
            "micOff" to R.drawable.ic_nt_mic_off,
            "stop" to R.drawable.ic_nt_stop,
            "speaker" to R.drawable.ic_nt_speaker,
            "earpiece" to R.drawable.ic_nt_earpiece,
            "headset" to R.drawable.ic_nt_headset,
            "exit" to R.drawable.ic_nt_exit,
            "check" to R.drawable.ic_nt_check,
            "close" to R.drawable.ic_nt_close,
        )

        fun from(map: Map<*, *>?): RoomContent {
            if (map == null) return empty
            val art = (map["art"] as? ByteArray)?.let {
                try {
                    BitmapFactory.decodeByteArray(it, 0, it.size)
                } catch (e: Exception) {
                    Log.w("FrecuRoomService", "Bad artwork", e)
                    null
                }
            }
            val buttons = (map["buttons"] as? List<*>).orEmpty().mapNotNull { raw ->
                val button = raw as? Map<*, *> ?: return@mapNotNull null
                val id = button["id"] as? String ?: return@mapNotNull null
                RoomButton(
                    id = id,
                    label = button["label"] as? String ?: id,
                    icon = icons[button["icon"] as? String] ?: R.drawable.ic_stat_frecu,
                )
            }
            return RoomContent(
                title = map["title"] as? String ?: "Frecu",
                subtitle = map["subtitle"] as? String ?: "",
                note = map["note"] as? String,
                accent = (map["accent"] as? Number)?.toInt() ?: SIGNAL,
                art = art,
                buttons = buttons,
                tapInvites = map["tapInvites"] == true,
            )
        }
    }
}
