package com.frecu.frecu

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Antes de la primera conexión de WebRTC: la voz también sale por la
        // zona Wi-Fi de este teléfono.
        HotspotNetworkDetector.install()
        super.configureFlutterEngine(flutterEngine)
        FrecuHaptics.install(this, flutterEngine.dartExecutor.binaryMessenger)
    }
}
