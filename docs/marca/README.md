# Marca de Frecu

La marca es la **firma de señal de Frecu**: una figura de Lissajous 2:3 con fase 0,6, de trazo redondo. Viene del sistema de diseño Portadora:

- en el prototipo aprobado es `DRAW.brand`;
- en la app es `SignalSignature.brand`.

Es la misma familia de curvas que las firmas de cada persona. Es también la figura en la que se pliega la portadora en la intro de arranque. Se eligió el 2026-11-09 entre cuatro propuestas; las propuestas están en `docs/diseno/logo/`.

## Archivos

| Archivo | Uso |
|---|---|
| `frecu-marca.svg` | Marca en lima, sobre fondos oscuros. |
| `frecu-marca-dia.svg` | Marca en tinta, sobre fondos claros. De día el verde no es trazo (decisión D8). |
| `frecu-marca-monocromo.svg` | Silueta blanca para notificaciones y usos monocromos. |
| `frecu-icono.svg` | Ícono completo: grafito, halo de señal y la marca con su brillo. |
| `frecu-icono-512.png` | Ícono para Google Play (512 × 512, sin canal alfa). |
| `generar_iconos.py` | Genera todo lo anterior y los íconos de la app desde la misma geometría. |

## Colores

- **Señal (lima):** `#C4E05C`.
- **Grafito**, fondo del ícono: `#0C0E10`.
- **Vacío de noche**, fondo de la app y del splash: `#060708`.
- **Tinta de día:** `#0C0F0D`.

## Uso

- Trazo redondo y sin relleno. No rotar, deformar ni cambiar los parámetros de la curva.
- Tamaño mínimo: 16 px.
- Aire alrededor: al menos un cuarto del ancho de la marca.
- Sobre fondos claros va en tinta. El lima solo acompaña como halo o relleno.

## Dónde se aplica

**iOS**
- Ícono de la app en todos los tamaños del catálogo `AppIcon`, en RGB y sin canal alfa.
- La pantalla de lanzamiento es solo el vacío de noche; la marca aparece enseguida en la intro de la app.

**Android**
- Ícono clásico: `mipmap-*/ic_launcher.png`.
- Ícono adaptable: `drawable/ic_launcher_foreground.xml` sobre `drawable/ic_launcher_background.xml`, con el halo.
- Ícono temático de Android 13+: la capa monocroma del ícono adaptable.
- Notificación de la frecu activa (la tarjeta tipo reproductor): `drawable/ic_stat_frecu.xml`, la marca en silueta. La pone `FrecuRoomService.kt` como ícono pequeño (`setSmallIcon`), teñida con el acento de la frecu; también es el ícono de respaldo de un botón sin dibujable propio.
- Splash de Android 12+: `drawable/splash_mark.xml`.

**En la app**
- Final de la intro de arranque.
- Cabecera del inicio, junto a la palabra «frecu».

## Regenerar

Desde la raíz del repositorio, en macOS y con Google Chrome instalado:

```bash
python3 docs/marca/generar_iconos.py
```
