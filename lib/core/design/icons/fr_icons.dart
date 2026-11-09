import 'package:frecu/core/design/icons/fr_icon_data.dart';

/// Íconos de Portadora: los del objeto `ICONS` de
/// `docs/diseno/prototipo/components.js`, con sus trazos copiados tal cual.
///
/// Se dibujan en código con `FrIcon` (rejilla de 24, trazo redondo y el color
/// del tema), sin fuente de íconos ni assets.
abstract final class FrIcons {
  /// Micrófono.
  static const mic = FrIconData('mic', [
    FrIconRect(9, 3, 6, 11.5, rx: 3),
    FrIconPath('M5.5 11.5a6.5 6.5 0 0 0 13 0M12 18v3M8.5 21h7'),
  ]);

  /// Micrófono silenciado.
  static const micOff = FrIconData('micOff', [
    FrIconPath(
      'M15 10V6a3 3 0 0 0-5.7-1.3M9 9.5v2a3 3 0 0 0 5 2.2M5.5 11.5a6.5 6.5 0 0 0 10.9 4.8M18.5 11.5c0 .7-.1 1.3-.3 1.9M12 18v3M8.5 21h7M4 4l16 16',
    ),
  ]);

  /// Walkie-talkie.
  static const walkie = FrIconData('walkie', [
    FrIconRect(6, 7, 12, 14, rx: 3.2),
    FrIconPath('M9 7V2.5M9.5 11.5h5M9.5 14.5h5M9.5 17.5h3'),
  ]);

  /// Micrófono abierto, con ondas a los lados.
  static const openMic = FrIconData('openMic', [
    FrIconRect(9.5, 4, 5, 9.5, rx: 2.5),
    FrIconPath(
      'M7 10.5a5 5 0 0 0 10 0M12 15.5V19.5M4.6 7.2a9 9 0 0 0 0 7.6M19.4 7.2a9 9 0 0 1 0 7.6',
    ),
  ]);

  /// Altavoz.
  static const speaker = FrIconData('speaker', [
    FrIconPath('M4 9.5h3.2L12 5.5v13l-4.8-4H4z'),
    FrIconPath('M15.5 9a4 4 0 0 1 0 6M18 6.5a7.6 7.6 0 0 1 0 11'),
  ]);

  /// Auricular del teléfono.
  static const earpiece = FrIconData('earpiece', [
    FrIconPath(
      'M7.2 3.5h2.6l1.5 4-2 1.6a10.4 10.4 0 0 0 5.6 5.6l1.6-2 4 1.5v2.6a2.2 2.2 0 0 1-2.4 2.2A16 16 0 0 1 5 5.9a2.2 2.2 0 0 1 2.2-2.4z',
    ),
  ]);

  /// Bluetooth.
  static const bluetooth = FrIconData('bluetooth', [
    FrIconPath('M7 7.5l10 9-5 4.5V3l5 4.5-10 9'),
  ]);

  /// Audífonos.
  static const headset = FrIconData('headset', [
    FrIconPath('M4 15.5V12a8 8 0 0 1 16 0v3.5'),
    FrIconRect(3.5, 14, 4, 6.5, rx: 1.6),
    FrIconRect(16.5, 14, 4, 6.5, rx: 1.6),
  ]);

  /// Código QR.
  static const qr = FrIconData('qr', [
    FrIconRect(4, 4, 6, 6, rx: 1.6),
    FrIconRect(14, 4, 6, 6, rx: 1.6),
    FrIconRect(4, 14, 6, 6, rx: 1.6),
    FrIconPath('M14 14h2.5v2.5M20 14v.01M14 20h.01M17 17.5V20h3v-3'),
  ]);

  /// Escanear con la cámara.
  static const scan = FrIconData('scan', [
    FrIconPath(
      'M4 8.5V6a2 2 0 0 1 2-2h2.5M15.5 4H18a2 2 0 0 1 2 2v2.5M20 15.5V18a2 2 0 0 1-2 2h-2.5M8.5 20H6a2 2 0 0 1-2-2v-2.5M4 12h16',
    ),
  ]);

  /// Más.
  static const plus = FrIconData('plus', [FrIconPath('M12 5v14M5 12h14')]);

  /// Ajustes, con dos deslizadores.
  static const sliders = FrIconData('sliders', [
    FrIconPath('M4 7h9M17 7h3M4 17h3M11 17h9'),
    FrIconCircle(15, 7, 2),
    FrIconCircle(9, 17, 2),
  ]);

  /// Atrás.
  static const back = FrIconData('back', [
    FrIconPath('M14.5 5.5L8 12l6.5 6.5'),
  ]);

  /// Adelante.
  static const chevron = FrIconData('chevron', [
    FrIconPath('M9.5 5.5L16 12l-6.5 6.5'),
  ]);

  /// Abajo.
  static const down = FrIconData('down', [
    FrIconPath('M6.5 9.5l5.5 5.5 5.5-5.5'),
  ]);

  /// Flecha hacia la derecha.
  static const arrow = FrIconData('arrow', [
    FrIconPath('M5 12h14M13 6l6 6-6 6'),
  ]);

  /// Cerrar.
  static const close = FrIconData('close', [
    FrIconPath('M6.5 6.5l11 11M17.5 6.5l-11 11'),
  ]);

  /// Candado.
  static const lock = FrIconData('lock', [
    FrIconRect(5, 10.5, 14, 10, rx: 3),
    FrIconPath('M8.5 10.5V8a3.5 3.5 0 0 1 7 0v2.5M12 14.5V17'),
  ]);

  /// Antena que emite.
  static const antenna = FrIconData('antenna', [
    FrIconPath('M12 10.5V21M8.5 21h7'),
    FrIconCircle(12, 8.2, 1.9),
    FrIconPath(
      'M8.3 4.8a5.2 5.2 0 0 0 0 6.8M15.7 4.8a5.2 5.2 0 0 1 0 6.8M5.4 2.6a8.8 8.8 0 0 0 0 11.2M18.6 2.6a8.8 8.8 0 0 1 0 11.2',
    ),
  ]);

  /// Personas.
  static const users = FrIconData('users', [
    FrIconCircle(9, 8.5, 3.5),
    FrIconPath(
      'M3 20a6 6 0 0 1 12 0M16 5.3a3.3 3.3 0 0 1 0 6.4M18 14.6a5.6 5.6 0 0 1 3 5.1',
    ),
  ]);

  /// Salir.
  static const exit = FrIconData('exit', [
    FrIconPath(
      'M14 4H7a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h7M10 12h10M16.5 8.5L20 12l-3.5 3.5',
    ),
  ]);

  /// Regenerar.
  static const regen = FrIconData('regen', [
    FrIconPath('M19.5 12a7.5 7.5 0 1 1-2.2-5.3M19.5 4v4.5H15'),
  ]);

  /// Hecho.
  static const check = FrIconData('check', [
    FrIconPath('M5 12.5l4.5 4.5L19 7.5'),
  ]);

  /// Alerta.
  static const alert = FrIconData('alert', [
    FrIconPath(
      'M10.3 4.6a2 2 0 0 1 3.4 0l7.4 12.8a2 2 0 0 1-1.7 3H4.6a2 2 0 0 1-1.7-3z',
    ),
    FrIconPath('M12 10v4M12 17v.01'),
  ]);

  /// Información.
  static const info = FrIconData('info', [
    FrIconCircle(12, 12, 9),
    FrIconPath('M12 11v5.5M12 7.5v.01'),
  ]);

  /// Wi-Fi.
  static const wifi = FrIconData('wifi', [
    FrIconPath(
      'M12 19v.01M8.6 15.4a4.8 4.8 0 0 1 6.8 0M5.6 12.3a9.1 9.1 0 0 1 12.8 0M2.6 9.2a13.4 13.4 0 0 1 18.8 0',
    ),
  ]);

  /// Punto de acceso.
  static const hotspot = FrIconData('hotspot', [
    FrIconRect(8, 10, 8, 11, rx: 2),
    FrIconPath('M8.6 6.6a4.8 4.8 0 0 1 6.8 0M6 4a8.5 8.5 0 0 1 12 0'),
  ]);

  /// Internet.
  static const globe = FrIconData('globe', [
    FrIconCircle(12, 12, 9),
    FrIconPath('M3 12h18M12 3a13.5 13.5 0 0 1 0 18M12 3a13.5 13.5 0 0 0 0 18'),
  ]);

  /// Rayo.
  static const flash = FrIconData('flash', [
    FrIconPath('M13.5 3L5.5 13.5H11L10 21l8.5-11H13z'),
  ]);

  /// Señal.
  static const signal = FrIconData('signal', [
    FrIconCircle(12, 12, 1.8),
    FrIconPath(
      'M8.6 8.6a4.8 4.8 0 0 0 0 6.8M15.4 8.6a4.8 4.8 0 0 1 0 6.8M5.6 5.6a9 9 0 0 0 0 12.8M18.4 5.6a9 9 0 0 1 0 12.8',
    ),
  ]);

  /// Borrar.
  static const backspace = FrIconData('backspace', [
    FrIconPath('M9 5.5h10a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H9l-6-6.5z'),
    FrIconPath('M12.5 9.5l4.5 5M17 9.5l-4.5 5'),
  ]);

  /// Editar.
  static const edit = FrIconData('edit', [
    FrIconPath('M14.5 5.5l4 4L8.5 19.5h-4v-4z'),
    FrIconPath('M12.5 7.5l4 4'),
  ]);

  /// Campana.
  static const bell = FrIconData('bell', [
    FrIconPath('M6 16.5V11a6 6 0 0 1 12 0v5.5l1.5 2h-15z'),
    FrIconPath('M10 21h4'),
  ]);

  /// Cámara.
  static const camera = FrIconData('camera', [
    FrIconPath(
      'M4 8.5a2 2 0 0 1 2-2h2l1.5-2h5l1.5 2h2a2 2 0 0 1 2 2V18a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2z',
    ),
    FrIconCircle(12, 13, 3.5),
  ]);

  /// Nodos de la malla.
  static const nodes = FrIconData('nodes', [
    FrIconCircle(12, 5, 2),
    FrIconCircle(5, 19, 2),
    FrIconCircle(19, 19, 2),
    FrIconPath('M12 7v4.5M12 11.5L6.4 17.4M12 11.5l5.6 5.9'),
  ]);

  /// Volumen: teléfono con sus botones laterales.
  static const volume = FrIconData('volume', [
    FrIconRect(8, 2.5, 8, 19, rx: 3),
    FrIconPath('M19.5 7v4M12 6v.01'),
  ]);

  /// Punto relleno.
  static const dot = FrIconData('dot', [FrIconCircle(12, 12, 3, filled: true)]);

  /// Ubicación: alfiler de mapa.
  static const pin = FrIconData('pin', [
    FrIconPath(
      'M12 21s-6.5-6.2-6.5-11.2a6.5 6.5 0 0 1 13 0C18.5 14.8 12 21 12 21z',
    ),
    FrIconCircle(12, 9.8, 2.4),
  ]);

  /// Mensaje rápido: globo de texto.
  static const msg = FrIconData('msg', [
    FrIconPath(
      'M5 4.5h14a2 2 0 0 1 2 2v8.5a2 2 0 0 1-2 2h-7l-4.5 3.5V17H5a2 2 0 0 1-2-2V6.5a2 2 0 0 1 2-2z',
    ),
    FrIconPath('M8 9h8M8 12.5h5'),
  ]);

  /// SOS: baliza de alarma.
  static const sos = FrIconData('sos', [
    FrIconPath('M6.5 18.5V13a5.5 5.5 0 0 1 11 0v5.5'),
    FrIconPath('M4.5 21h15M12 2.5V5M4.2 6.2l1.8 1.8M19.8 6.2L18 8M12 11v4'),
  ]);

  /// NFC: ondas cortas desde un punto.
  static const nfc = FrIconData('nfc', [
    FrIconPath(
      'M9 8.5a5 5 0 0 1 0 7M12.2 6a8.6 8.6 0 0 1 0 12M15.4 3.5a12.2 12.2 0 0 1 0 17',
    ),
    FrIconCircle(5.5, 12, 1.4),
  ]);

  /// Viento.
  static const wind = FrIconData('wind', [
    FrIconPath('M3 9h11a3 3 0 1 0-3-3M3 13h15a3 3 0 1 1-3 3M3 17h6'),
  ]);

  /// Vibración: teléfono con marcas a los lados.
  static const vibrate = FrIconData('vibrate', [
    FrIconRect(8, 4, 8, 16, rx: 2.5),
    FrIconPath('M4.8 9v6M19.2 9v6M2 10.5v3M22 10.5v3'),
  ]);

  /// Oreja: auricular al acercar.
  static const ear = FrIconData('ear', [
    FrIconPath(
      'M7 9.5a5.5 5.5 0 0 1 11 0c0 3-2.5 4-3 6.5-.4 2.2-1.9 4-4.2 4A3.8 3.8 0 0 1 7 16.2',
    ),
    FrIconPath('M10 10a2.5 2.5 0 0 1 5 0c0 1.5-1.5 2-1.5 3.5'),
  ]);

  /// Combustible: surtidor.
  static const fuel = FrIconData('fuel', [
    FrIconRect(4, 4, 10, 16.5, rx: 2),
    FrIconPath(
      'M4 10.5h10M14 8.5l3.2 2.3a2 2 0 0 1 .8 1.6V17a1.5 1.5 0 0 0 3 0V9l-2.5-3',
    ),
  ]);

  /// Bandera: parada.
  static const flag = FrIconData('flag', [
    FrIconPath('M5.5 21V3.5M5.5 4.5h11l-2.2 4 2.2 4h-11'),
  ]);

  /// Todos los íconos, en el orden del prototipo.
  static const values = [
    mic,
    micOff,
    walkie,
    openMic,
    speaker,
    earpiece,
    bluetooth,
    headset,
    qr,
    scan,
    plus,
    sliders,
    back,
    chevron,
    down,
    arrow,
    close,
    lock,
    antenna,
    users,
    exit,
    regen,
    check,
    alert,
    info,
    wifi,
    hotspot,
    globe,
    flash,
    signal,
    backspace,
    edit,
    bell,
    camera,
    nodes,
    volume,
    dot,
    pin,
    msg,
    sos,
    nfc,
    wind,
    vibrate,
    ear,
    fuel,
    flag,
  ];
}
