package com.frecu.frecu

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Antes de la primera conexión de WebRTC: la voz también sale por la
        // zona Wi-Fi de este teléfono.
        HotspotNetworkDetector.install()
        super.configureFlutterEngine(flutterEngine)
        FrecuHaptics.install(this, flutterEngine.dartExecutor.binaryMessenger)
        VolumePtt.install(this, flutterEngine.dartExecutor.binaryMessenger)
        FrecuProximity.install(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    // El botón de volumen habla en la frecu si la persona lo activó.
    override fun dispatchKeyEvent(event: KeyEvent): Boolean =
        VolumePtt.onKey(event) || super.dispatchKeyEvent(event)
}
