"""Genera la marca de Frecu y todos sus íconos desde una sola geometría.

La marca es la firma de señal de Frecu (`DRAW.brand` del prototipo y
`SignalSignature.brand` en la app): una figura de Lissajous 2:3 con fase 0,6.
Se eligió el 2026-11-09 entre cuatro propuestas (docs/diseno/logo).

Uso, desde la raíz del repositorio (macOS, con Google Chrome instalado):

    python3 docs/marca/generar_iconos.py

Escribe los SVG maestros en docs/marca/, los íconos de iOS (AppIcon), los de
Android (clásicos, adaptable, temático, notificación y splash de Android 12+)
y el ícono de 512 px para Google Play. Chrome sin interfaz rasteriza el SVG y
`sips` reduce cada tamaño; los PNG de iOS quedan en RGB sin canal alfa, como
pide la App Store.
"""

import json
import math
import pathlib
import shutil
import struct
import subprocess
import tempfile
import zlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
MARCA = ROOT / 'docs' / 'marca'
RES = ROOT / 'android' / 'app' / 'src' / 'main' / 'res'
APPICON = ROOT / 'ios' / 'Runner' / 'Assets.xcassets' / 'AppIcon.appiconset'
CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'

# Portadora (lib/core/design/tokens/fr_colors.dart).
LIME = '#C4E05C'
GRAPHITE = '#0C0E10'  # bg1 de noche: fondo del ícono
INK_DAY = '#0C0F0D'   # tinta de día (D8: de día el verde no es trazo)

# Geometría de la marca en una caja de 100 × 100.
A, B, PHASE = 2, 3, 0.6
RADIUS = 31.0
STROKE = 5.2
# En el ícono, la marca ocupa el 82 % de la loseta y la rodea un halo de señal.
ICON_SCALE = 0.82
HALO_OPACITY = 0.16
GLOW = 1.6


def mark_points(cx, cy, r, n=720):
    pts = []
    for i in range(n + 1):
        u = i / n * 2 * math.pi
        pts.append((cx + math.sin(A * u + PHASE) * r, cy + math.sin(B * u) * r))
    return pts


def svg_path(pts):
    return 'M' + ' L'.join(f'{x:.2f},{y:.2f}' for x, y in pts) + 'Z'


def android_path(pts):
    head, rest = pts[0], pts[1:]
    return f'M{head[0]:.2f},{head[1]:.2f}L' + ' '.join(f'{x:.2f},{y:.2f}' for x, y in rest) + 'Z'


MARK_D = svg_path(mark_points(50, 50, RADIUS))


def mark_svg(color):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
            f'<path d="{MARK_D}" fill="none" stroke="{color}" stroke-width="{STROKE}" '
            f'stroke-linecap="round" stroke-linejoin="round"/></svg>\n')


def icon_svg(tile=False):
    """Ícono completo: grafito, halo de señal y la marca con su brillo.

    Con [tile], la loseta va redondeada y con margen sobre fondo transparente
    (ícono clásico de Android); sin él, a sangre (iOS y Google Play).
    """
    off = (100 - 100 * ICON_SCALE) / 2
    clip = ('<clipPath id="t"><rect x="2" y="2" width="96" height="96" rx="21.5"/></clipPath>'
            if tile else '')
    body = (f'<rect width="100" height="100" fill="{GRAPHITE}"/>'
            '<rect width="100" height="100" fill="url(#h)"/>'
            f'<g transform="translate({off:.2f} {off:.2f}) scale({ICON_SCALE})" filter="url(#g)">'
            f'<path d="{MARK_D}" fill="none" stroke="{LIME}" stroke-width="{STROKE}" '
            'stroke-linecap="round" stroke-linejoin="round"/></g>')
    if tile:
        body = f'<g clip-path="url(#t)">{body}</g>'
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><defs>'
            f'<radialGradient id="h" cx="50%" cy="52%" r="50%"><stop offset="0" stop-color="{LIME}" '
            f'stop-opacity="{HALO_OPACITY}"/><stop offset="1" stop-color="{LIME}" stop-opacity="0"/></radialGradient>'
            f'<filter id="g" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="{GLOW}" '
            'result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>'
            f'{clip}</defs>{body}</svg>\n')


# --- Android: vectores ---------------------------------------------------

def vector(size_dp, viewport, paths, comment, gradient_ns=False):
    ns = ' xmlns:aapt="http://schemas.android.com/aapt"' if gradient_ns else ''
    return ('<?xml version="1.0" encoding="utf-8"?>\n'
            f'<!-- {comment}\n     Generado por docs/marca/generar_iconos.py. -->\n'
            f'<vector xmlns:android="http://schemas.android.com/apk/res/android"{ns}\n'
            f'    android:width="{size_dp}dp"\n    android:height="{size_dp}dp"\n'
            f'    android:viewportWidth="{viewport}"\n    android:viewportHeight="{viewport}">\n'
            f'{paths}</vector>\n')


def stroke_path(d, color, width):
    return ('    <path\n        android:fillColor="#00000000"\n'
            f'        android:strokeColor="{color}"\n        android:strokeWidth="{width:.2f}"\n'
            '        android:strokeLineCap="round"\n        android:strokeLineJoin="round"\n'
            f'        android:pathData="{d}" />\n')


def write_android_vectors():
    drawable = RES / 'drawable'
    # Ícono adaptable: 108 dp, de los que se ven los 72 centrales. La marca
    # guarda la proporción del ícono aprobado dentro de esos 72 dp.
    k = 0.72
    r = RADIUS * ICON_SCALE * k
    w = STROKE * ICON_SCALE * k
    fg = android_path(mark_points(54, 54, r, n=360))
    (drawable / 'ic_launcher_foreground.xml').write_text(vector(
        108, 108, stroke_path(fg, '@color/portadora_signal', w),
        'Marca de Frecu en el ícono adaptable (también su capa temática\n'
        '     monocroma): Lissajous 2:3 con fase 0,6, con la proporción del ícono.'))
    halo = ('    <path\n        android:fillColor="#FF0C0E10"\n        android:pathData="M0,0h108v108h-108z" />\n'
            '    <path android:pathData="M0,0h108v108h-108z">\n'
            '        <aapt:attr name="android:fillColor">\n'
            '            <gradient\n                android:type="radial"\n'
            f'                android:centerX="54"\n                android:centerY="{54 + 0.02 * 72:.2f}"\n'
            f'                android:gradientRadius="{0.5 * 72:.2f}"\n'
            f'                android:startColor="#{int(HALO_OPACITY * 255):02X}C4E05C"\n'
            '                android:endColor="#00C4E05C" />\n'
            '        </aapt:attr>\n    </path>\n')
    (drawable / 'ic_launcher_background.xml').write_text(vector(
        108, 108, halo, 'Fondo del ícono adaptable: grafito con el halo de señal.', gradient_ns=True))
    # Notificación: 24 dp con 2 dp de margen, en blanco; Android la tiñe.
    stat = android_path(mark_points(12, 12, 8.6, n=240))
    (drawable / 'ic_stat_frecu.xml').write_text(vector(
        24, 24, stroke_path(stat, '#FFFFFFFF', 2.2),
        'Ícono pequeño de la notificación de la frecu activa: la marca en silueta.'))
    # Splash de Android 12+: lienzo de 288 dp con la figura en el círculo de 192.
    k = 1.92
    splash = android_path(mark_points(144, 144, RADIUS * ICON_SCALE * k, n=360))
    (drawable / 'splash_mark.xml').write_text(vector(
        288, 288, stroke_path(splash, '@color/portadora_signal', STROKE * ICON_SCALE * k),
        'Marca de Frecu en la pantalla de inicio de Android 12+: 288 dp con\n'
        '     la figura dentro del círculo de 192 dp, con la proporción del ícono.'))


# --- PNG -----------------------------------------------------------------

def render(svg, px, out, transparent):
    with tempfile.TemporaryDirectory() as tmp:
        page = pathlib.Path(tmp) / 'icono.html'
        page.write_text(
            '<!doctype html><meta charset="utf-8"><style>html,body{margin:0;background:transparent;'
            f'overflow:hidden}}svg{{display:block;width:{px}px;height:{px}px}}</style>{svg}')
        args = [CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars',
                '--force-device-scale-factor=1', f'--window-size={px},{px}',
                f'--screenshot={out}', page.as_uri()]
        if transparent:
            args.insert(-1, '--default-background-color=00000000')
        subprocess.run(args, check=True, capture_output=True)


def resize(src, px, out):
    subprocess.run(['sips', '-z', str(px), str(px), str(src), '--out', str(out)],
                   check=True, capture_output=True)


def _chunks(data):
    pos = 8
    while pos < len(data):
        length = struct.unpack('>I', data[pos:pos + 4])[0]
        yield data[pos + 4:pos + 8], data[pos + 8:pos + 8 + length]
        pos += 12 + length


def _paeth(a, b, c):
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    return b if pb <= pc else c


def to_rgb(path, background=(0x0C, 0x0E, 0x10)):
    """Reescribe un PNG RGBA de 8 bits como RGB (sin canal alfa)."""
    data = path.read_bytes()
    chunks = list(_chunks(data))
    w, h, depth, color, _, _, interlace = struct.unpack('>IIBBBBB', chunks[0][1])
    if color == 2:
        return
    if (depth, color, interlace) != (8, 6, 0):
        raise ValueError(f'{path}: formato PNG no previsto ({depth}, {color}, {interlace})')
    raw = zlib.decompress(b''.join(body for kind, body in chunks if kind == b'IDAT'))
    stride, bpp = w * 4, 4
    prev = bytearray(stride)
    out = bytearray()
    i = 0
    for _ in range(h):
        kind = raw[i]
        line = bytearray(raw[i + 1:i + 1 + stride])
        i += 1 + stride
        for x in range(stride):
            left = line[x - bpp] if x >= bpp else 0
            up = prev[x]
            if kind == 1:
                line[x] = (line[x] + left) & 255
            elif kind == 2:
                line[x] = (line[x] + up) & 255
            elif kind == 3:
                line[x] = (line[x] + ((left + up) >> 1)) & 255
            elif kind == 4:
                line[x] = (line[x] + _paeth(left, up, prev[x - bpp] if x >= bpp else 0)) & 255
        prev = line
        out.append(0)
        for x in range(0, stride, 4):
            r, g, b, a = line[x:x + 4]
            for c, bg in zip((r, g, b), background):
                out.append((c * a + bg * (255 - a) + 127) // 255)
    ihdr = struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)

    def chunk(kind, body):
        return struct.pack('>I', len(body)) + kind + body + struct.pack('>I', zlib.crc32(kind + body) & 0xFFFFFFFF)

    path.write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', ihdr) + chunk(b'IDAT', zlib.compress(bytes(out), 9))
                     + chunk(b'IEND', b''))


def write_pngs():
    with tempfile.TemporaryDirectory() as tmp:
        tmp = pathlib.Path(tmp)
        full, tile = tmp / 'full.png', tmp / 'tile.png'
        render(icon_svg(), 1024, full, transparent=False)
        render(icon_svg(tile=True), 1024, tile, transparent=True)
        # iOS: cada archivo del catálogo con su tamaño en píxeles, sin alfa.
        contents = json.loads((APPICON / 'Contents.json').read_text())
        for image in contents['images']:
            name = image.get('filename')
            if not name:
                continue
            points = float(image['size'].split('x')[0])
            scale = int(image['scale'].rstrip('x'))
            px = round(points * scale)
            out = APPICON / name
            if px == 1024:
                shutil.copy(full, out)
            else:
                resize(full, px, out)
            to_rgb(out)
        # Android clásico (antes de Android 8): loseta redondeada.
        for density, px in (('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)):
            resize(tile, px, RES / f'mipmap-{density}' / 'ic_launcher.png')
        # Google Play: 512 px a sangre; la tienda aplica su máscara.
        resize(full, 512, MARCA / 'frecu-icono-512.png')
        to_rgb(MARCA / 'frecu-icono-512.png')


def main():
    MARCA.mkdir(parents=True, exist_ok=True)
    (MARCA / 'frecu-marca.svg').write_text(mark_svg(LIME))
    (MARCA / 'frecu-marca-dia.svg').write_text(mark_svg(INK_DAY))
    (MARCA / 'frecu-marca-monocromo.svg').write_text(mark_svg('#FFFFFF'))
    (MARCA / 'frecu-icono.svg').write_text(icon_svg())
    write_android_vectors()
    write_pngs()
    print('Marca e íconos generados.')


if __name__ == '__main__':
    main()
