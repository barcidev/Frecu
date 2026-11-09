import AVFoundation
import AudioToolbox
import Flutter
import NetworkExtension
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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FrecuWifi") {
      FrecuWifi.install(messenger: registrar.messenger())
    }
  }
}

/// Conexión del invitado a la red de la frecu por el canal `frecu/wifi`.
///
/// `join` conecta a la red con `NEHotspotConfiguration` (el sistema pide
/// confirmar) y sin `joinOnce`, que la soltaría con la app en segundo plano o
/// la pantalla apagada. `release` olvida la red que conectó la app, y el
/// teléfono vuelve a su Wi-Fi. En iOS la app no tiene que atarse a la red:
/// `route` responde que no.
///
/// Errores de `join`: `declined` (se canceló el aviso) o `failed`. Que el
/// teléfono ya estuviera en esa red cuenta como conectado.
enum FrecuWifi {
  /// Red que conectó la app; solo esa se olvida al salir de la frecu.
  private static var joinedSSID: String?

  static func install(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "frecu/wifi", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      let arguments = call.arguments as? [String: Any]
      switch call.method {
      case "route":
        result(false)
      case "join":
        join(
          ssid: arguments?["ssid"] as? String,
          passphrase: arguments?["passphrase"] as? String,
          result: result
        )
      case "release":
        release()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func join(ssid: String?, passphrase: String?, result: @escaping FlutterResult) {
    guard let ssid, !ssid.isEmpty else {
      result(FlutterError(code: "failed", message: "no ssid", details: nil))
      return
    }
    let configuration: NEHotspotConfiguration
    if let passphrase, !passphrase.isEmpty {
      configuration = NEHotspotConfiguration(ssid: ssid, passphrase: passphrase, isWEP: false)
    } else {
      configuration = NEHotspotConfiguration(ssid: ssid)
    }
    configuration.joinOnce = false
    NEHotspotConfigurationManager.shared.apply(configuration) { error in
      DispatchQueue.main.async {
        guard let error = error as NSError? else {
          joinedSSID = ssid
          result(nil)
          return
        }
        if error.domain == NEHotspotConfigurationErrorDomain {
          switch NEHotspotConfigurationError(rawValue: error.code) {
          case .alreadyAssociated:
            result(nil)
            return
          case .userDenied:
            result(FlutterError(code: "declined", message: nil, details: nil))
            return
          default:
            break
          }
        }
        result(FlutterError(code: "failed", message: error.localizedDescription, details: nil))
      }
    }
  }

  private static func release() {
    guard let ssid = joinedSSID else { return }
    joinedSSID = nil
    NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: ssid)
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
