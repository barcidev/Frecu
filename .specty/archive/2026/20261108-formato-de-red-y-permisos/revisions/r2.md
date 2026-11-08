---
kind: standard
epic: 20261108-pendientes-portadora
slice: C8
---

# Formato de red y permisos

## Objetivo

Pasar `dart format` a los cuatro archivos de red y permisos que quedan de P99, para que `dart format --set-exit-if-changed` no los marque. Es un cambio de solo formato: no cambia ningún comportamiento ni ninguna aserción de las pruebas.

## Fuera de alcance

- Los otros dos archivos de P99, que formatean C1 y C5.
- Cualquier cambio de lógica, de nombres o de aserciones en estos archivos.

## Supuestos

- A1: `dart format` solo cambia espacios, saltos de línea y comas finales, así que las pruebas existentes siguen pasando sin tocarlas a mano.

## Criterios de aceptación

- AC1: CUANDO se ejecuta `dart format --output=none --set-exit-if-changed` sobre `network_state.dart`, `permission_repository_impl.dart`, `permission_datasource_test.dart` y `permission_repository_impl_test.dart` ENTONCES sale con código 0 sin cambios, y `flutter analyze` y `flutter test` siguen en verde.
  - test: manual

## Archivos

- modificar lib/features/network/domain/entities/network_state.dart — formato de `dart format` (P99)
- modificar lib/features/permissions/data/repositories/permission_repository_impl.dart — formato de `dart format` (P99)
- modificar test/features/permissions/data/permission_datasource_test.dart — formato de `dart format`, sin cambiar aserciones (P99)
- modificar test/features/permissions/data/permission_repository_impl_test.dart — formato de `dart format`, sin cambiar aserciones (P99)

## Tareas

- [x] T1: Pasar `dart format` a los archivos de red y permisos
  - files: lib/features/network/domain/entities/network_state.dart, lib/features/permissions/data/repositories/permission_repository_impl.dart, test/features/permissions/data/permission_datasource_test.dart, test/features/permissions/data/permission_repository_impl_test.dart
  - ac: AC1
  - verify: dart format --output=none --set-exit-if-changed lib/features/network/domain/entities/network_state.dart lib/features/permissions/data/repositories/permission_repository_impl.dart test/features/permissions/data/permission_datasource_test.dart test/features/permissions/data/permission_repository_impl_test.dart && flutter analyze && flutter test
  - type: style

## Cierre

### Resumen

- `dart format` pasado a `network_state.dart`, `permission_repository_impl.dart`, `permission_datasource_test.dart` y `permission_repository_impl_test.dart` (parte de P99 que toca a C8).
- El diff sin espacios solo reparte la firma del constructor de `PermissionRepositoryImpl` y parte en varias líneas los `test(...)` de nombre largo, con su coma final; ninguna aserción cambia.
- AC1 comprobado: `dart format --set-exit-if-changed` sobre los 4 archivos sale con 0 (0 changed), `flutter analyze` sin problemas y `flutter test` con 582 pruebas en verde.

### Desviaciones

- Ninguna.

### Decisiones

- Tarea de tipo `style` sin fase de pruebas: un cambio de solo formato no admite una prueba que falle sin el código, y AC1 queda como `test: manual`, comprobado por la verificación de la tarea.

### Pendientes

- Ninguno.
