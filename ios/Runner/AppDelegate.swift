import AVFoundation
import AudioToolbox
import Flutter
import NetworkExtension
import UIKit
import WebRTC
import flutter_webrtc

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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FrecuWindFilter") {
      WindFilter.install(messenger: registrar.messenger())
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

/// Filtro de viento por `frecu/wind_filter`: paso alto Butterworth de 4.º
/// orden a 150 Hz sobre el micrófono, después del procesado de WebRTC. Quita
/// el retumbo grave del viento y del motor sin tocar la voz.
final class WindFilter: NSObject, ExternalAudioProcessingDelegate {
  private static let shared = WindFilter()
  private static let cutoff = 150.0
  /// Q de las dos secciones de un Butterworth de 4.º orden.
  private static let qs = [0.5411961, 1.3065630]

  private let lock = NSLock()
  private var sections: [Biquad] = []
  private var sampleRate = 0.0
  private var enabled = false

  static func install(messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: "frecu/wind_filter", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        guard call.method == "setEnabled" else {
          result(FlutterMethodNotImplemented)
          return
        }
        result(shared.setEnabled(call.arguments as? Bool ?? false))
      }
  }

  private func setEnabled(_ on: Bool) -> Bool {
    guard on != enabled else { return true }
    enabled = on
    let adapter = AudioManager.sharedInstance().capturePostProcessingAdapter
    if on {
      adapter.addProcessing(self)
    } else {
      adapter.removeProcessing(self)
    }
    return true
  }

  func audioProcessingInitialize(withSampleRate sampleRateHz: Int, channels: Int) {
    configure(Double(sampleRateHz))
  }

  func audioProcessingProcess(_ audioBuffer: RTCAudioBuffer) {
    lock.lock()
    defer { lock.unlock() }
    // Cada tramo son 10 ms: la frecuencia sale de su largo.
    let rate = Double(audioBuffer.frames) * 100
    if rate != sampleRate { configureLocked(rate) }
    guard !sections.isEmpty, audioBuffer.channels > 0 else { return }
    let samples = audioBuffer.rawBuffer(forChannel: 0)
    for i in 0..<audioBuffer.frames {
      var x = Double(samples[i])
      for s in 0..<sections.count { x = sections[s].next(x) }
      samples[i] = Float(x)
    }
  }

  func audioProcessingRelease() {}

  private func configure(_ rate: Double) {
    lock.lock()
    defer { lock.unlock() }
    configureLocked(rate)
  }

  private func configureLocked(_ rate: Double) {
    guard rate > 0 else { return }
    sampleRate = rate
    sections = Self.qs.map { Biquad.highPass(cutoff: Self.cutoff, sampleRate: rate, q: $0) }
  }

  /// Sección de segundo orden (forma directa I) del recetario de RBJ.
  private struct Biquad {
    let b0, b1, b2, a1, a2: Double
    var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0

    mutating func next(_ x: Double) -> Double {
      let y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
      x2 = x1
      x1 = x
      y2 = y1
      y1 = y
      return y
    }

    static func highPass(cutoff: Double, sampleRate: Double, q: Double) -> Biquad {
      let w0 = 2 * Double.pi * cutoff / sampleRate
      let alpha = sin(w0) / (2 * q)
      let c = cos(w0)
      let a0 = 1 + alpha
      return Biquad(
        b0: (1 + c) / 2 / a0, b1: -(1 + c) / a0, b2: (1 + c) / 2 / a0,
        a1: -2 * c / a0, a2: (1 - alpha) / a0)
    }
  }
}
