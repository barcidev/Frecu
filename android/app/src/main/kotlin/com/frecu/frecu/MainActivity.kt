package com.frecu.frecu

import android.view.KeyEvent
import com.cloudwebrtc.webrtc.FlutterWebRTCPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Antes de la primera conexión de WebRTC: la voz también sale por la
        // zona Wi-Fi de este teléfono.
        HotspotNetworkDetector.install()
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        FrecuHaptics.install(this, messenger)
        VolumePtt.install(this, messenger)
        FrecuProximity.install(this, messenger)
        WindFilter.install(
            messenger,
            flutterEngine.plugins.get(FlutterWebRTCPlugin::class.java) as? FlutterWebRTCPlugin,
        )
        // La red de la frecu: el anfitrión la crea y el invitado entra a ella.
        LocalHotspot.install(this, messenger)
        FrecuWifi.install(this, messenger)
        // Invitar por NFC: el teléfono como etiqueta con la invitación.
        FrecuNfcHostService.install(this, messenger)
    }

    // El botón de volumen habla en la frecu si la persona lo activó.
    override fun dispatchKeyEvent(event: KeyEvent): Boolean =
        VolumePtt.onKey(event) || super.dispatchKeyEvent(event)
}
