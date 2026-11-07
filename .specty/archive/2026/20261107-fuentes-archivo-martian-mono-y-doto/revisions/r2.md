---
kind: standard
epic: 20261107-sistema-diseno-portadora
slice: C5
---

# Fuentes Archivo, Martian Mono y Doto empaquetadas en assets

## Objetivo

Empaquetar en `assets/fonts/` las fuentes variables Archivo, Martian Mono y Doto (OFL, del repositorio google/fonts) con su licencia, y declararlas en `pubspec.yaml` con los mismos nombres de familia que ya usan `FrFonts` y `FrType`. Así la app dibuja la tipografía de Portadora sin conexión a internet, en lugar de caer en la fuente del sistema.

## Fuera de alcance

- Cambios en `lib/`: `FrFonts` y `FrType` (C1) ya nombran las familias y los ejes.
- Descarga de fuentes en ejecución (`google_fonts`) y cursivas (la escala no las usa).
- Recortar glifos o rangos de ejes de los TTF (subsetting o instanciado): se empaquetan los archivos originales sin modificar.
- Registrar las licencias en `LicenseRegistry` para la pantalla de licencias: toca `lib/` (bootstrap o Ajustes).
- Íconos propios `FrIcons` (C11).

## Supuestos

- A1: Flutter mueve los ejes de una fuente variable declarada como un único asset por familia, sin `weight` en `pubspec.yaml`, mediante los `fontVariations` y el peso exacto que ya declara cada estilo de `FrType`.
  - impacto: alto
- A2: Las versiones actuales de google/fonts traen los ejes que usa la escala: Archivo `wght` 100–900 y `wdth` 62–125; Martian Mono `wght` 100–800 y `wdth` 75–112,5; Doto `ROND` 0–100 y `wght` 100–900.
- A3: Empaquetar los `OFL.txt` como assets basta para cumplir la licencia al distribuir las fuentes dentro de la app (cada copia lleva su aviso de copyright y la licencia).
- A4: Los archivos se toman sin modificar de `ofl/archivo`, `ofl/martianmono` y `ofl/doto` de google/fonts, comprobando que su hash de blob git coincide con el publicado.

## Criterios de aceptación

- AC1: CUANDO la app carga su bundle de assets sin red ENTONCES `FontManifest.json` declara las familias `Archivo`, `Martian Mono` y `Doto` con los mismos nombres que `FrFonts`, y el archivo de cada una carga desde los assets locales.
- AC2: CUANDO se lee cada fuente empaquetada ENTONCES es un TrueType variable válido cuyos ejes (`wght` y `wdth` en Archivo y Martian Mono; `wght` y `ROND` en Doto) cubren todos los valores de `fontVariations` de los estilos de `FrType.standard`.
- AC3: CUANDO se distribuye la app ENTONCES el `OFL.txt` de cada familia viaja en los assets y `pubspec.yaml` no depende de `google_fonts`.

## Diseño

- Un directorio por familia en `assets/fonts/` con su TTF variable renombrado sin corchetes (`Archivo.ttf`, `MartianMono.ttf`, `Doto.ttf`) y su `OFL.txt`.
- `pubspec.yaml` declara en `flutter.fonts` una familia por fuente con un solo asset (sin `weight` ni `style`) y en `flutter.assets` los tres `OFL.txt`.
- La prueba lee `FontManifest.json` y cada TTF con `rootBundle` (el mismo bundle local que usa la app), recorre la tabla `fvar` en Dart sin dependencias nuevas y la compara con las `fontVariations` de `FrType.standard`.

## Archivos

- crear assets/fonts/archivo/Archivo.ttf — Archivo variable (`wght`, `wdth`) de google/fonts.
- crear assets/fonts/archivo/OFL.txt — licencia de Archivo.
- crear assets/fonts/martianmono/MartianMono.ttf — Martian Mono variable (`wght`, `wdth`) de google/fonts.
- crear assets/fonts/martianmono/OFL.txt — licencia de Martian Mono.
- crear assets/fonts/doto/Doto.ttf — Doto variable (`ROND`, `wght`) de google/fonts.
- crear assets/fonts/doto/OFL.txt — licencia de Doto.
- modificar pubspec.yaml — declarar las tres familias y las licencias como assets.
- crear test/core/design/fr_fonts_assets_test.dart — familias del manifiesto, ejes de cada TTF y licencias en el bundle.

## Tareas

- [x] T1: Fuentes variables y licencias en assets declaradas en `pubspec.yaml`
  - files: assets/fonts/archivo/Archivo.ttf, assets/fonts/archivo/OFL.txt, assets/fonts/martianmono/MartianMono.ttf, assets/fonts/martianmono/OFL.txt, assets/fonts/doto/Doto.ttf, assets/fonts/doto/OFL.txt, pubspec.yaml, test/core/design/fr_fonts_assets_test.dart
  - ac: AC1, AC2, AC3
  - verify: flutter test

## Riesgos

- R1: Peso de las fuentes variables en el APK (R3 de la épica): 1,21 MiB sin comprimir (Archivo 643 KiB, Doto 446 KiB, Martian Mono 145 KiB), unos 340 KiB comprimidos — mitigación: sin cursivas; si el APK pesa demasiado, instanciar Archivo a `wdth` 100–125 y `wght` 400–720 en un cambio aparte.
- R2: Con las fuentes reales, las pruebas de widgets que miden texto podrían cambiar — mitigación: la verificación de T1 corre toda la suite.

## Cierre

### Resumen

- `assets/fonts/archivo/Archivo.ttf`, `assets/fonts/martianmono/MartianMono.ttf` y `assets/fonts/doto/Doto.ttf`: TTF variables de google/fonts (`ofl/archivo`, `ofl/martianmono`, `ofl/doto`) sin modificar, cada uno con su `OFL.txt`. Su hash de blob git coincide con el publicado y las sumas de todas sus tablas son correctas.
- Ejes empaquetados: Archivo `wght` 100–900 y `wdth` 62–125; Martian Mono `wght` 100–800 y `wdth` 75–112,5; Doto `ROND` 0–100 y `wght` 100–900. Cubren todos los valores de `FrType.standard`.
- `pubspec.yaml` declara las familias `Archivo`, `Martian Mono` y `Doto` (los nombres de `FrFonts`) con un solo asset cada una y los tres `OFL.txt` como assets. Sin `google_fonts` ni dependencias nuevas; `lib/` no cambia.
- Peso (R3 de la épica): 1.263.980 bytes sin comprimir, 1,21 MiB (Archivo 658.596, Doto 456.924, Martian Mono 148.460); con deflate -9, unos 347.021 bytes (≈ 339 KiB, Archivo 253.582, Martian Mono 77.325, Doto 16.114). No se midió en un APK real: `flutter build apk --release` falla en esta máquina porque el SDK de Android no tiene la plataforma `android-37` que pide `permission_handler_android`.
- Verificado: `test/core/design/fr_fonts_assets_test.dart` (AC1–AC3) en verde, `flutter test` completo en verde y `flutter analyze` sin avisos.

### Desviaciones

- Ninguna respecto al plan. T1 tocó 8 archivos (Specty recomienda 5 como máximo) y se mantuvo en una sola tarea: 6 de ellos son copias de fuentes y licencias.

### Decisiones

- Un directorio por familia y archivos renombrados sin corchetes (`Archivo[wdth,wght].ttf` → `Archivo.ttf`) para que las rutas de los assets sean simples.
- Sin cursivas (`Archivo-Italic`, 724 KiB): la escala de `FrType` no las usa.
- Sin recortar glifos ni rangos de ejes: los TTF originales se pueden comprobar contra google/fonts y comprimidos suman ≈ 339 KiB.
- La prueba lee `FontManifest.json` y los TTF con `rootBundle`, el mismo bundle local que usa la app, y recorre la tabla `fvar` y las sumas de las tablas en Dart, sin dependencias nuevas.

### Pendientes

- Registrar las licencias OFL en `LicenseRegistry` para que salgan en la pantalla de licencias (toca `lib/`; P34).
- Medir el aumento real del APK de release cuando el SDK tenga `android-37` (P36) y, si pesa demasiado, instanciar Archivo a `wdth` 100–125 y `wght` 400–720 (P35).
