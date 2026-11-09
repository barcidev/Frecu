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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FrecuProximity") {
      FrecuProximity.install(messenger: registrar.messenger())
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

/// Sensor de proximidad por `frecu/proximity` (activar) y
/// `frecu/proximity/events` (`true` cerca, `false` lejos). Con el sensor
/// activado iOS apaga la pantalla sola al acercar el teléfono a la oreja.
final class FrecuProximity: NSObject, FlutterStreamHandler {
  private static let shared = FrecuProximity()
  private var sink: FlutterEventSink?

  static func install(messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: "frecu/proximity", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        guard call.method == "setEnabled" else {
          result(FlutterMethodNotImplemented)
          return
        }
        result(shared.setEnabled(call.arguments as? Bool ?? false))
      }
    FlutterEventChannel(name: "frecu/proximity/events", binaryMessenger: messenger)
      .setStreamHandler(shared)
  }

  /// Activa o desactiva el sensor; devuelve si el teléfono tiene uno.
  private func setEnabled(_ on: Bool) -> Bool {
    let device = UIDevice.current
    let center = NotificationCenter.default
    if on {
      device.isProximityMonitoringEnabled = true
      guard device.isProximityMonitoringEnabled else { return false }
      center.addObserver(
        self,
        selector: #selector(changed),
        name: UIDevice.proximityStateDidChangeNotification,
        object: device
      )
    } else {
      center.removeObserver(self, name: UIDevice.proximityStateDidChangeNotification, object: device)
      device.isProximityMonitoringEnabled = false
    }
    return true
  }

  @objc private func changed() {
    sink?(UIDevice.current.proximityState)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    sink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }
}
