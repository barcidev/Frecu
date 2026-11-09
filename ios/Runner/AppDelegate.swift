import AVFoundation
import AudioToolbox
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FrecuHaptics") {
      FrecuHaptics.install(messenger: registrar.messenger())
    }
  }
}

/// Vibración de la frecu por el canal `frecu/haptics`.
///
/// Con el micrófono abierto iOS calla la vibración, así que antes de vibrar
/// se permite durante la grabación. Con la app al frente los toques cortos
/// usan el motor háptico; en segundo plano, y para los avisos fuertes, la
/// vibración del sistema, que sí suena con la pantalla apagada mientras la
/// sesión de audio sigue activa.
enum FrecuHaptics {
  static func install(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "frecu/haptics", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "play", let pattern = call.arguments as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      play(pattern)
      result(nil)
    }
  }

  private static func play(_ pattern: String) {
    try? AVAudioSession.sharedInstance().setAllowHapticsAndSystemSoundsDuringRecording(true)
    let active = UIApplication.shared.applicationState == .active
    switch pattern {
    case "tick" where active:
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    case "talk" where active:
      UINotificationFeedbackGenerator().notificationOccurred(.success)
    case "alert" where active:
      UINotificationFeedbackGenerator().notificationOccurred(.warning)
    case "sos":
      vibrate(times: 3)
    case "tick", "talk", "alert":
      vibrate(times: 1)
    default:
      break
    }
  }

  /// Vibración del sistema [times] veces, separadas lo justo para notarlas.
  private static func vibrate(times: Int) {
    for i in 0..<times {
      DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600 * i)) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
      }
    }
  }
}
