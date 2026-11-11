---
kind: quick
---

# Ignorar los .DS_Store de macOS

## Objetivo

Los archivos `.DS_Store` que crea el Finder de macOS (como `docs/diseno/.DS_Store`) dejan de aparecer como archivos sin seguir en `git status`, en cualquier carpeta del repositorio.

Criterio: `.gitignore` termina con el bloque `# macOS` / `.DS_Store`, y `git check-ignore docs/diseno/.DS_Store` lo reconoce como ignorado.

## Archivos

- modificar .gitignore — añadir al final `# macOS` y `.DS_Store`

## Tareas

- [ ] T1: Ignorar los .DS_Store en .gitignore
  - files: .gitignore
  - verify: git check-ignore -q docs/diseno/.DS_Store
